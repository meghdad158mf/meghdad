-- =====================================================================
-- جریان — مهاجرت ۰۱۵: بخش «افراد و مجموعه‌ها»
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: بخش «افراد و مجموعه‌ها» تا این مهاجرت فقط placeholder بود.
-- ساختار نهایی این بخش پنج دسته‌ی اصلی داره: فعالان سیاسی‌اجتماعی،
-- اساتید سیاسی‌اجتماعی، شرکت‌کننده در برنامه‌ها، جامعه مخاطب، و یک تب
-- آنالیز که آمار تجمیعی بقیه رو نشون می‌ده. فعلاً فقط دو دسته‌ی اول
-- (فعالان → زیرشاخه‌ی «افراد»، و اساتید) واقعاً پیاده‌سازی می‌شن —
-- «تشکل‌ها»/«مجموعه‌ها» و دو دسته‌ی دیگه (شرکت‌کننده/جامعه مخاطب)
-- بعداً که زیرشاخه‌هاشون مشخص شد اضافه می‌شن.
--
-- سمت (افراد) و حوزه‌ی تخصصی (اساتید) چندانتخابی‌ان — یک نفر می‌تونه
-- هم‌زمان چند سمت/حوزه‌ی تخصصی داشته باشه — برای همین به‌جای یک ستون
-- FK ساده، یک جدول واسط (many-to-many) دارن. مرتبه‌ی علمی/حوزوی اساتید
-- تک‌انتخابیه (یک نفر یک مرتبه در یک زمان داره)، پس همچنان یک ستون FK
-- ساده روی خودِ professors.
--
-- ⚠️ ستون national_id (کد ملی) روی هر دو جدول people/professors اضافه
-- شده و طبق تصمیم صریح کاربر، هم مدیر هم بیننده می‌تونن ببیننش (RLS
-- policy فعلی sel_people/sel_professors هیچ تغییری نکرده، چون از اول
-- به هر دو نقش SELECT می‌داد). این داده حساسه — اگه بعداً تصمیم عوض
-- شد که فقط مدیر ببینتش، باید یا ستون از select ویو حذف بشه یا یک
-- view/policy جدا برای بیننده نوشته بشه.
--
-- جدول‌ها:
--   person_positions      — سمت/جایگاه (فعالان)، جدول پویا و قابل‌مدیریت
--   people                — خودِ افراد (فعالان)، هر ردیف یک نفر
--   people_positions      — جدول واسط: کدام فرد کدام سمت‌ها را دارد (چندتایی)
--   professor_specialties — حوزه/رشته‌ی تخصصی اساتید، پویا و قابل‌مدیریت
--   professor_ranks       — مرتبه‌ی علمی/حوزوی اساتید، پویا و قابل‌مدیریت
--   professors            — خودِ اساتید، هر ردیف یک نفر
--   professor_specialty_links — جدول واسط: کدام استاد کدام حوزه‌های
--                                تخصصی را دارد (چندتایی)
-- =====================================================================

create table if not exists person_positions (
  id         serial primary key,
  name       text not null unique,
  created_at timestamptz not null default now()
);

alter table person_positions enable row level security;
drop policy if exists sel_person_positions on person_positions;
create policy sel_person_positions on person_positions for select to app_admin, app_viewer using (true);
drop policy if exists rw_person_positions on person_positions;
create policy rw_person_positions  on person_positions for all    to app_admin              using (true) with check (true);
grant select on person_positions to app_viewer;
grant select, insert, update, delete on person_positions to app_admin;
grant usage, select on sequence person_positions_id_seq to app_admin;

insert into person_positions (name) values
  ('طلبه'), ('استاد حوزه'), ('روحانی/امام جماعت'), ('فعال دانشجویی'),
  ('فعال رسانه‌ای'), ('نماینده/مسئول تشکل'), ('چهره‌ی دانشگاهی'), ('سایر')
on conflict (name) do nothing;

create table if not exists people (
  id           serial primary key,
  name         text not null,
  national_id  text,
  city         text,
  importance   text not null default 'عادی' check (importance in ('برجسته','عادی')),
  affiliation  text,
  channel_id   int references channels(id) on delete set null,
  notes        text,
  created_at   timestamptz not null default now()
);

create index if not exists idx_people_name on people(name);

alter table people enable row level security;
drop policy if exists sel_people on people;
create policy sel_people on people for select to app_admin, app_viewer using (true);
drop policy if exists rw_people on people;
create policy rw_people  on people for all    to app_admin              using (true) with check (true);
grant select on people to app_viewer;
grant select, insert, update, delete on people to app_admin;
grant usage, select on sequence people_id_seq to app_admin;

create table if not exists people_positions (
  person_id   int not null references people(id) on delete cascade,
  position_id int not null references person_positions(id) on delete cascade,
  primary key (person_id, position_id)
);

alter table people_positions enable row level security;
drop policy if exists sel_people_positions on people_positions;
create policy sel_people_positions on people_positions for select to app_admin, app_viewer using (true);
drop policy if exists rw_people_positions on people_positions;
create policy rw_people_positions  on people_positions for all    to app_admin              using (true) with check (true);
grant select on people_positions to app_viewer;
grant select, insert, update, delete on people_positions to app_admin;

create table if not exists professor_specialties (
  id         serial primary key,
  name       text not null unique,
  created_at timestamptz not null default now()
);

alter table professor_specialties enable row level security;
drop policy if exists sel_professor_specialties on professor_specialties;
create policy sel_professor_specialties on professor_specialties for select to app_admin, app_viewer using (true);
drop policy if exists rw_professor_specialties on professor_specialties;
create policy rw_professor_specialties  on professor_specialties for all    to app_admin              using (true) with check (true);
grant select on professor_specialties to app_viewer;
grant select, insert, update, delete on professor_specialties to app_admin;
grant usage, select on sequence professor_specialties_id_seq to app_admin;

insert into professor_specialties (name) values
  ('علوم سیاسی'), ('جامعه‌شناسی'), ('فقه و حقوق'), ('علوم قرآن و حدیث'),
  ('فلسفه و کلام'), ('اقتصاد'), ('تاریخ و تمدن اسلامی'), ('سایر')
on conflict (name) do nothing;

create table if not exists professor_ranks (
  id         serial primary key,
  name       text not null unique,
  created_at timestamptz not null default now()
);

alter table professor_ranks enable row level security;
drop policy if exists sel_professor_ranks on professor_ranks;
create policy sel_professor_ranks on professor_ranks for select to app_admin, app_viewer using (true);
drop policy if exists rw_professor_ranks on professor_ranks;
create policy rw_professor_ranks  on professor_ranks for all    to app_admin              using (true) with check (true);
grant select on professor_ranks to app_viewer;
grant select, insert, update, delete on professor_ranks to app_admin;
grant usage, select on sequence professor_ranks_id_seq to app_admin;

insert into professor_ranks (name) values
  ('حجت‌الاسلام'), ('حجت‌الاسلام و المسلمین'), ('آیت‌الله'),
  ('استادیار'), ('دانشیار'), ('استاد تمام'), ('سایر')
on conflict (name) do nothing;

create table if not exists professors (
  id            serial primary key,
  name          text not null,
  national_id   text,
  city          text,
  institution   text,
  rank_id       int references professor_ranks(id) on delete set null,
  importance    text not null default 'عادی' check (importance in ('برجسته','عادی')),
  notes         text,
  created_at    timestamptz not null default now()
);

create index if not exists idx_professors_name on professors(name);

alter table professors enable row level security;
drop policy if exists sel_professors on professors;
create policy sel_professors on professors for select to app_admin, app_viewer using (true);
drop policy if exists rw_professors on professors;
create policy rw_professors  on professors for all    to app_admin              using (true) with check (true);
grant select on professors to app_viewer;
grant select, insert, update, delete on professors to app_admin;
grant usage, select on sequence professors_id_seq to app_admin;

create table if not exists professor_specialty_links (
  professor_id  int not null references professors(id) on delete cascade,
  specialty_id  int not null references professor_specialties(id) on delete cascade,
  primary key (professor_id, specialty_id)
);

alter table professor_specialty_links enable row level security;
drop policy if exists sel_professor_specialty_links on professor_specialty_links;
create policy sel_professor_specialty_links on professor_specialty_links for select to app_admin, app_viewer using (true);
drop policy if exists rw_professor_specialty_links on professor_specialty_links;
create policy rw_professor_specialty_links  on professor_specialty_links for all    to app_admin              using (true) with check (true);
grant select on professor_specialty_links to app_viewer;
grant select, insert, update, delete on professor_specialty_links to app_admin;
