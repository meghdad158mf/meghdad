-- =====================================================================
-- جریان — اسکیمای پایه (پایش ایتا + پایش تلگرام، یک دیتابیس مشترک)
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
--
-- قبل از اجرا سه‌جا را جایگزین کنید (جست‌وجو کنید: <...>):
--   1) <YOUR_JWT_SECRET>   → Project Settings → API → JWT Settings → Legacy JWT Secret
--   2) <ADMIN_PASSWORD>    → رمز عبور دلخواه برای نقش «مدیر»
--   3) <VIEWER_PASSWORD>   → رمز عبور دلخواه برای نقش «بیننده»
-- =====================================================================

-- ---------- افزونه‌ها ----------
create extension if not exists pgcrypto with schema extensions;
create extension if not exists pgjwt    with schema extensions;

-- ---------- نقش‌های سطح Postgres (برای دسترسی دوسطحی) ----------
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'app_admin') then
    create role app_admin nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'app_viewer') then
    create role app_viewer nologin noinherit;
  end if;
end $$;

grant app_admin  to authenticator;
grant app_viewer to authenticator;

-- ---------- جدول‌ها ----------
create table if not exists categories (
  id         serial primary key,
  name       text not null unique,
  color      text not null default '#EAB393',
  created_at timestamptz not null default now()
);

create table if not exists channels (
  id          serial primary key,
  platform    text not null check (platform in ('eitaa','telegram')),
  username    text not null,                 -- بدون @
  title       text,
  type        text not null default 'news_agency' check (type in ('news_agency','person')),
  category_id int references categories(id) on delete set null,
  active      boolean not null default true,
  added_at    timestamptz not null default now(),
  unique (platform, username)
);

create table if not exists posts (
  id               bigserial primary key,
  channel_id       int not null references channels(id) on delete cascade,
  platform         text not null check (platform in ('eitaa','telegram')),
  platform_post_id text not null,             -- postId (ایتا) یا msg_id (تلگرام)
  text             text,
  media_type       text,                      -- photo | video | document | null
  media_path       text,
  link             text,
  views            int default 0,
  forwards         int default 0,
  posted_at        timestamptz,
  scraped_at       timestamptz not null default now(),
  raw              jsonb,
  unique (channel_id, platform_post_id)
);

create index if not exists idx_posts_channel_time on posts (channel_id, posted_at desc);
create index if not exists idx_posts_platform      on posts (platform);
create index if not exists idx_channels_platform    on channels (platform);

-- تنظیمات داخلی (رمزهای عبور هش‌شده) — هرگز مستقیم از API قابل‌خواندن نیست
create table if not exists app_config (
  key   text primary key,
  value text not null
);

-- ---------- RLS ----------
alter table categories enable row level security;
alter table channels   enable row level security;
alter table posts      enable row level security;
alter table app_config enable row level security;   -- بدون هیچ policy = کاملاً قفل، فقط از طریق توابع SECURITY DEFINER

drop policy if exists sel_categories on categories;
create policy sel_categories on categories for select to app_admin, app_viewer using (true);
drop policy if exists rw_categories on categories;
create policy rw_categories  on categories for all    to app_admin              using (true) with check (true);

drop policy if exists sel_channels on channels;
create policy sel_channels on channels for select to app_admin, app_viewer using (true);
drop policy if exists rw_channels on channels;
create policy rw_channels  on channels for all    to app_admin              using (true) with check (true);

drop policy if exists sel_posts on posts;
create policy sel_posts on posts for select to app_admin, app_viewer using (true);
drop policy if exists rw_posts on posts;
create policy rw_posts  on posts for all    to app_admin              using (true) with check (true);

-- ---------- گرنت‌ها ----------
grant usage on schema public to app_admin, app_viewer;

grant select on categories, channels, posts to app_viewer;
grant select, insert, update, delete on categories, channels, posts to app_admin;
grant usage, select on all sequences in schema public to app_admin;

-- ---------- ورود (login) ----------
-- رمز JWT داخل همان جدول قفل‌شده‌ی app_config نگه داشته می‌شود (نه تنظیمات سطح
-- دیتابیس، چون Supabase اجازه‌ی ALTER DATABASE ... SET را روی پلن مدیریت‌شده نمی‌دهد).
create or replace function public.login(password text)
returns json
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  admin_hash  text;
  viewer_hash text;
  role_name   text;
  secret      text;
begin
  select value into admin_hash  from app_config where key = 'admin_password_hash';
  select value into viewer_hash from app_config where key = 'viewer_password_hash';

  if admin_hash is not null and crypt(password, admin_hash) = admin_hash then
    role_name := 'app_admin';
  elsif viewer_hash is not null and crypt(password, viewer_hash) = viewer_hash then
    role_name := 'app_viewer';
  else
    raise exception 'invalid password' using errcode = '28P01';
  end if;

  select value into secret from app_config where key = 'jwt_secret';

  return json_build_object(
    'token', sign(
      json_build_object(
        'role', role_name,
        'exp',  extract(epoch from (now() + interval '24 hours'))::integer
      ),
      secret
    ),
    'role', role_name
  );
end;
$$;

revoke all on function public.login(text) from public;
grant execute on function public.login(text) to anon;

-- تغییر رمز عبور — فقط مدیر می‌تواند صدا بزند
create or replace function public.change_password(target_role text, new_password text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if coalesce(current_setting('request.jwt.claims', true)::json->>'role', '') <> 'app_admin' then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if target_role not in ('admin','viewer') then
    raise exception 'invalid role';
  end if;
  update app_config
    set value = crypt(new_password, gen_salt('bf'))
    where key = target_role || '_password_hash';
end;
$$;

revoke all on function public.change_password(text, text) from public;
grant execute on function public.change_password(text, text) to app_admin;

-- ---------- رمزهای عبور اولیه + رمز JWT ----------
insert into app_config (key, value) values
  ('admin_password_hash',  crypt('<ADMIN_PASSWORD>',  gen_salt('bf'))),
  ('viewer_password_hash', crypt('<VIEWER_PASSWORD>', gen_salt('bf'))),
  ('jwt_secret',           '<YOUR_JWT_SECRET>')
on conflict (key) do update set value = excluded.value;

-- ---------- داده‌ی اولیه: دسته‌بندی‌ها ----------
insert into categories (name, color) values
  ('تحلیل راهبردی', '#EAB393'),
  ('سیاسی',         '#EAB393'),
  ('اجتماعی',        '#EAB393'),
  ('اقتصادی',        '#EAB393'),
  ('فرهنگی',         '#EAB393'),
  ('بین‌الملل',       '#EAB393')
on conflict (name) do nothing;

-- ---------- داده‌ی اولیه: ۲۲ کانال ایتا (از طرح فعلی) + ۳ کانال تلگرام
-- که بعداً از پنل مدیریت اضافه شده بودن (به‌روز شده در migration_021) ----------
insert into channels (platform, username, title, type, active) values
  ('eitaa', 'soada_ir',                 'سعداء',                                  'news_agency', true),
  ('eitaa', 'levayar_ir',               'افکاری | سواد رسانه',                    'person',      true),
  ('eitaa', 'naslnew',                  'سعید کیقبادی | نسل نو',                  'person',      true),
  ('eitaa', 'hamidrezamashooghi',       'حمیدرضامعشوقی| مهران‌عمرانی',            'person',      true),
  ('eitaa', 'tahlilrahbordi_mantaghe',  'تحلیل سیاسی منطقه و جهان',               'news_agency', true),
  ('eitaa', 'ghese_ghahremanha',        'قصه قهرمان ها',                          'news_agency', true),
  ('eitaa', 'hby62090',                 'شیخک...',                                'person',      true),
  ('eitaa', 'Rezamahvashi',             'ایران و جهان',                           'news_agency', true),
  ('eitaa', 'BehrouzDelavar',           '«گفت» و «گو» | بهروز دلاور',             'person',      true),
  ('eitaa', 'salamatmorteza',           'مرتضی سلامت/ الگوریتم شاد زیستن',        'person',      true),
  ('eitaa', 'M_R_Hasan_Beygi',          'محمدرضا حسن بیگی',                       'person',      true),
  ('eitaa', 'J_T_zahraii135',           'روایتی‌نو | سید سعید زهرایی',            'person',      true),
  ('eitaa', 'salehparvar',              'صالح پرور «شیخ صالح»',                   'person',      true),
  ('eitaa', 'mabavi',                   'محمد ابوی سانی | قیام',                  'person',      true),
  ('eitaa', 'rebbiion',                 'تشکل طلبگی ربیون',                       'news_agency', true),
  ('eitaa', 'majidfatemiarfa',          'کاف‌ِمیم | مجید فاطمی ارفع',             'person',      true),
  ('eitaa', 'taamolaat',                'محمد الهی خراسانی - مکتوبات و جلسات',    'person',      true),
  ('eitaa', 'mojtaba_ariani',           'مجتبی آریانی | نوجوان ایرانی',           'person',      true),
  ('eitaa', 'h_ebrahimiavval',          'حسین ابراهیمی اول',                      'person',      true),
  ('eitaa', 'm_a_tavallaie',            'تأملات | تولايی',                        'person',      true),
  ('eitaa', 'mohsendoaei',              'سید محمدمحسن دعایی',                     'person',      true),
  ('eitaa', 'seyyed_kazem_roohbakhsh',  'سید کاظم روح بخش',                       'person',      true),
  ('telegram', 'MostafaTajzadeh',       'مصطفی تاجزاده',                          'news_agency', true),
  ('telegram', 'iranintltv',            'ایران اینترنشنال',                       'news_agency', true),
  ('telegram', 'farsivoa',              'صدای آمریکا',                            'news_agency', true)
on conflict (platform, username) do nothing;
