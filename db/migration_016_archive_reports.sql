-- =====================================================================
-- جریان — مهاجرت ۰۱۶: تب «آرشیو تولیدات دیگران» (بخش تحلیلی)
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: کاروسل «بسته‌های تحلیلی تولید شده» صفحه‌ی نخست و جدول
-- magazines فقط برای تولیدات خودِ جریانه. این مهاجرت یه جدول کاملاً
-- جدا و مستقل می‌سازه (archive_reports) برای بایگانی تولیدات تحلیلی
-- نهادهای دیگه — همون ساختار داده و Storage جدول magazines
-- (migration_002/migration_004/migration_005)، فقط با یه ستون اضافه‌ی
-- source_org (نام نهاد تولیدکننده) به‌جای issue_no.
-- =====================================================================

create table if not exists archive_reports (
  id           serial primary key,
  title        text not null,
  source_org   text not null,
  publish_date date,
  file_type    text not null check (file_type in ('pdf','images')),
  files        jsonb not null default '[]'::jsonb,   -- مسیرهای فایل در Storage (bucket خصوصی: archive-reports)
  cover_url    text,                                  -- لینک عمومی bucket: archive-report-covers
  sort_order   int  not null default 0,
  uploaded_at  timestamptz not null default now()
);

alter table archive_reports enable row level security;

drop policy if exists sel_archive_reports on archive_reports;
create policy sel_archive_reports on archive_reports for select to app_admin, app_viewer using (true);
drop policy if exists rw_archive_reports on archive_reports;
create policy rw_archive_reports  on archive_reports for all    to app_admin              using (true) with check (true);

grant select on archive_reports to app_viewer;
grant select, insert, update, delete on archive_reports to app_admin;
grant usage, select on sequence archive_reports_id_seq to app_admin;

-- ---------- Storage bucket برای فایل آرشیو (خصوصی، فقط از طریق JWT امضاشده) ----------
insert into storage.buckets (id, name, public)
values ('archive-reports', 'archive-reports', false)
on conflict (id) do nothing;

drop policy if exists archive_reports_storage_select on storage.objects;
create policy archive_reports_storage_select on storage.objects
  for select to app_admin, app_viewer
  using (bucket_id = 'archive-reports');

drop policy if exists archive_reports_storage_write on storage.objects;
create policy archive_reports_storage_write on storage.objects
  for all to app_admin
  using (bucket_id = 'archive-reports')
  with check (bucket_id = 'archive-reports');

-- ---------- Storage bucket عمومی برای جلد (نمایش مستقیم بدون signed URL) ----------
insert into storage.buckets (id, name, public)
values ('archive-report-covers', 'archive-report-covers', true)
on conflict (id) do nothing;

drop policy if exists archive_report_covers_storage_select on storage.objects;
create policy archive_report_covers_storage_select on storage.objects
  for select to app_admin, app_viewer
  using (bucket_id = 'archive-report-covers');

drop policy if exists archive_report_covers_storage_write on storage.objects;
create policy archive_report_covers_storage_write on storage.objects
  for all to app_admin
  using (bucket_id = 'archive-report-covers')
  with check (bucket_id = 'archive-report-covers');
