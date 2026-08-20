-- =====================================================================
-- جریان — مهاجرت ۰۱۰: تب «روزنامه‌ها» (صفحه‌ی اول روزنامه‌های کشور)
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- منبع داده: سایت جار (jaaar.com/kiosk) — تصویر صفحه‌ی اول روزنامه‌ها.
-- برخلاف جلد مجلات (که hotlink مستقیم به سرور خودمونه)، این‌جا خودِ
-- عکس دانلود و در Storage خودمون آپلود می‌شه (bucket عمومی
-- newspaper-covers) — دقیقاً همون الگوی media_storage_path که برای
-- عکس/فیلم پست‌های تلگرام/ایتا استفاده شده (migration_008)، چون
-- لینک‌دادن مستقیم به سرور جار ریسک محدودیت Referer/hotlink داره و
-- از همین محیط قابل تست نبود.
--
-- چون این عکس‌ها حجم دارن و هر روز ~۴۰ روزنامه اضافه می‌شه، فقط ۳ روز
-- اخیر نگه داشته می‌شه (اسکریپت scripts/cleanup_media.py) — دقیقاً
-- همون سیاست عکس/فیلم پست‌ها، برای این‌که فضای ۵۰۰ مگابایتی رایگان
-- Supabase پر نشه. ردیف جدول (عنوان/تاریخ/اسلاگ) نگه داشته می‌شه،
-- فقط image_url/media_storage_path بعد از ۳ روز خالی می‌شن.
-- =====================================================================

create table if not exists newspapers (
  id                 serial primary key,
  slug               text not null,
  title              text not null,
  edition_date       date not null,
  image_url          text,
  media_storage_path text,
  reader_url         text,
  scraped_at         timestamptz not null default now(),
  unique (slug, edition_date)
);

alter table newspapers enable row level security;

drop policy if exists sel_newspapers on newspapers;
create policy sel_newspapers on newspapers for select to app_admin, app_viewer using (true);
drop policy if exists rw_newspapers on newspapers;
create policy rw_newspapers  on newspapers for all    to app_admin              using (true) with check (true);

grant select on newspapers to app_viewer;
grant select, insert, update, delete on newspapers to app_admin;
grant usage, select on sequence newspapers_id_seq to app_admin;

-- ---------- Storage bucket عمومی برای عکس صفحه‌ی اول روزنامه‌ها ----------
insert into storage.buckets (id, name, public)
values ('newspaper-covers', 'newspaper-covers', true)
on conflict (id) do nothing;

drop policy if exists newspaper_covers_storage_select on storage.objects;
create policy newspaper_covers_storage_select on storage.objects
  for select to app_admin, app_viewer
  using (bucket_id = 'newspaper-covers');

drop policy if exists newspaper_covers_storage_write on storage.objects;
create policy newspaper_covers_storage_write on storage.objects
  for all to app_admin
  using (bucket_id = 'newspaper-covers')
  with check (bucket_id = 'newspaper-covers');
