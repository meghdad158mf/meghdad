-- =====================================================================
-- جریان — مهاجرت ۰۰۹: منطقه‌ی جغرافیایی پویا (مثل دسته‌بندی‌های موضوعی)
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ⚠️ برخلاف بقیه‌ی مهاجرت‌ها، این یکی idempotent نیست (چون در آخر
-- ستون قدیمی channels.region حذف می‌شه) — فقط یک‌بار اجرا کنید.
--
-- زمینه: قبلاً منطقه‌ی جغرافیایی (داخلی/منطقه‌ای/بین‌المللی) فقط سه
-- مقدار ثابت با CHECK constraint روی channels.region بود — برخلاف
-- دسته‌بندی موضوعی (categories) که یک جدول واقعیه و از پنل مدیریت
-- قابل افزودن/حذفه. این مهاجرت جدول regions رو می‌سازه (دقیقاً مثل
-- categories) و channels.region (متن ثابت) رو با channels.region_id
-- (اشاره‌گر به این جدول) جایگزین می‌کنه.
-- =====================================================================

create table if not exists regions (
  id         serial primary key,
  name       text not null unique,
  created_at timestamptz not null default now()
);

alter table regions enable row level security;

drop policy if exists sel_regions on regions;
create policy sel_regions on regions for select to app_admin, app_viewer using (true);
drop policy if exists rw_regions on regions;
create policy rw_regions  on regions for all    to app_admin              using (true) with check (true);

grant select on regions to app_viewer;
grant select, insert, update, delete on regions to app_admin;
grant usage, select on sequence regions_id_seq to app_admin;

-- سه منطقه‌ی قبلی به‌عنوان ردیف‌های اولیه (از این به بعد قابل ویرایش/حذف از پنل)
insert into regions (name) values ('داخلی'), ('منطقه‌ای'), ('بین‌المللی')
  on conflict (name) do nothing;

alter table channels add column if not exists region_id int references regions(id) on delete set null;

update channels set region_id = (select id from regions where name = 'داخلی')
  where region = 'domestic' and region_id is null;
update channels set region_id = (select id from regions where name = 'منطقه‌ای')
  where region = 'regional' and region_id is null;
update channels set region_id = (select id from regions where name = 'بین‌المللی')
  where region = 'international' and region_id is null;

alter table channels drop constraint if exists channels_region_check;
alter table channels drop column if exists region;
