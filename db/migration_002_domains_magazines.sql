-- =====================================================================
-- جریان — مهاجرت ۰۰۲: حوزه‌های رصد + کتابخانه‌ی مجلات
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- برخلاف schema.sql، این فایل رمزهای عبور/JWT را دست نمی‌زند و
-- می‌شود چند بار بی‌خطر روی دیتابیس فعلی اجرا کرد (idempotent).
--
-- زمینه: سایت حالا بر اساس ۴ «حوزه‌ی رصد» سازمان‌دهی می‌شود، نه فقط
-- پلتفرم (ایتا/تلگرام):
--   ۱) رصد فضای مجازی  = همه‌ی کانال‌های ایتا + تلگرام (platform in ('eitaa','telegram'))
--   ۲) رصد اخبار        = کانال‌های خبرگزاری (type='news_agency', فارغ از پلتفرم)
--                          + منابع وب‌سایتی جدید (platform='website')
--   ۳) رصد فعالیت مدارس = داده‌ی دستی/اکسل — جدولش در مهاجرت بعدی می‌آید
--                          (بعد از دیدن ساختار فایل اکسل کاربر)
--   ۴) رصد برنامه تشکل‌ها = همان، داده‌ی دستی/اکسل
-- عضویت در حوزه‌ی ۱ و ۲ محاسبه‌شده است (از روی platform/type)، نه یک
-- ستون جداگانه — چون قاعده‌اش ثابت و ساده است.
-- =====================================================================

-- ---------- افزودن پلتفرم «website» برای منابع خبری غیرکانالی ----------
alter table channels drop constraint if exists channels_platform_check;
alter table channels add constraint channels_platform_check
  check (platform in ('eitaa','telegram','website'));

alter table posts drop constraint if exists posts_platform_check;
alter table posts add constraint posts_platform_check
  check (platform in ('eitaa','telegram','website'));

-- ---------- جدول حوزه‌های رصد ----------
create table if not exists domains (
  id         serial primary key,
  key        text not null unique,   -- 'cyberspace' | 'news' | 'schools' | 'orgs'
  name       text not null,
  sort_order int  not null default 0,
  created_at timestamptz not null default now()
);

alter table domains enable row level security;

drop policy if exists sel_domains on domains;
create policy sel_domains on domains for select to app_admin, app_viewer using (true);
drop policy if exists rw_domains on domains;
create policy rw_domains  on domains for all    to app_admin              using (true) with check (true);

grant select on domains to app_viewer;
grant select, insert, update, delete on domains to app_admin;
grant usage, select on sequence domains_id_seq to app_admin;

insert into domains (key, name, sort_order) values
  ('cyberspace', 'رصد فضای مجازی',       1),
  ('news',       'رصد اخبار',            2),
  ('schools',    'رصد فعالیت مدارس',     3),
  ('orgs',       'رصد برنامه تشکل‌ها',   4)
on conflict (key) do nothing;

-- ---------- جدول کتابخانه‌ی مجلات (بخش تحلیلی) ----------
create table if not exists magazines (
  id           serial primary key,
  title        text not null,
  issue_no     text,
  publish_date date,
  file_type    text not null check (file_type in ('pdf','images')),
  files        jsonb not null default '[]'::jsonb,   -- مسیرهای فایل در Supabase Storage (bucket: magazines)
  cover_url    text,
  notes        text,
  uploaded_at  timestamptz not null default now()
);

alter table magazines enable row level security;

drop policy if exists sel_magazines on magazines;
create policy sel_magazines on magazines for select to app_admin, app_viewer using (true);
drop policy if exists rw_magazines on magazines;
create policy rw_magazines  on magazines for all    to app_admin              using (true) with check (true);

grant select on magazines to app_viewer;
grant select, insert, update, delete on magazines to app_admin;
grant usage, select on sequence magazines_id_seq to app_admin;

-- ---------- Storage bucket برای فایل مجلات (خصوصی، فقط از طریق JWT امضاشده) ----------
insert into storage.buckets (id, name, public)
values ('magazines', 'magazines', false)
on conflict (id) do nothing;

drop policy if exists magazines_storage_select on storage.objects;
create policy magazines_storage_select on storage.objects
  for select to app_admin, app_viewer
  using (bucket_id = 'magazines');

drop policy if exists magazines_storage_write on storage.objects;
create policy magazines_storage_write on storage.objects
  for all to app_admin
  using (bucket_id = 'magazines')
  with check (bucket_id = 'magazines');
