-- =====================================================================
-- جریان — مهاجرت ۰۱۱: بخش «برنامه مدارس» — گالری اسکرین‌شات تحلیل‌های Power BI
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: بخش «برنامه مدارس» تا این مهاجرت فقط placeholder بود. تصمیم
-- نهایی این شد که تحلیل واقعی مدارس همچنان توی خودِ Power BI کاربر
-- انجام بشه (نه این‌که داده‌ی خام وارد Supabase و نمودار از نو ساخته
-- بشه) — فقط نتیجه‌ی نهایی به‌صورت اسکرین‌شات از پنل مدیریت آپلود و
-- توی این صفحه به‌صورت گالری نمایش داده می‌شه. دقیقاً همون الگوی
-- ذخیره‌سازی که برای جلد مجلات/روزنامه‌ها استفاده شده (bucket عمومی).
-- =====================================================================

create table if not exists school_reports (
  id                  serial primary key,
  title               text,
  image_url           text not null,
  media_storage_path  text,
  sort_order          int not null default 0,
  uploaded_at         timestamptz not null default now()
);

alter table school_reports enable row level security;

drop policy if exists sel_school_reports on school_reports;
create policy sel_school_reports on school_reports for select to app_admin, app_viewer using (true);
drop policy if exists rw_school_reports on school_reports;
create policy rw_school_reports  on school_reports for all    to app_admin              using (true) with check (true);

grant select on school_reports to app_viewer;
grant select, insert, update, delete on school_reports to app_admin;
grant usage, select on sequence school_reports_id_seq to app_admin;

-- ---------- Storage bucket عمومی برای اسکرین‌شات‌های گزارش مدارس ----------
insert into storage.buckets (id, name, public)
values ('school-reports', 'school-reports', true)
on conflict (id) do nothing;

drop policy if exists school_reports_storage_select on storage.objects;
create policy school_reports_storage_select on storage.objects
  for select to app_admin, app_viewer
  using (bucket_id = 'school-reports');

drop policy if exists school_reports_storage_write on storage.objects;
create policy school_reports_storage_write on storage.objects
  for all to app_admin
  using (bucket_id = 'school-reports')
  with check (bucket_id = 'school-reports');
