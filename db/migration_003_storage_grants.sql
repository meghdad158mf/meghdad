-- =====================================================================
-- جریان — مهاجرت ۰۰۳: گرنت دسترسی به schema استوریج
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
--
-- زمینه: بعد از اجرای migration_002 (که RLS policyهای storage.objects
-- رو برای app_admin/app_viewer ساخت)، آپلود مجله با خطای
-- «permission denied for schema storage» (403) رد می‌شد. دلیلش این
-- بود که RLS policy به‌تنهایی کافی نیست — قبلش باید خودِ schema و
-- جدول‌هاش هم به این دو نقش grant بشن (چیزی که برای نقش‌های پیش‌فرض
-- Supabase مثل authenticated از قبل انجام شده، ولی برای نقش‌های
-- سفارشی این پروژه نه).
-- =====================================================================

grant usage on schema storage to app_admin, app_viewer;
grant select on storage.buckets to app_admin, app_viewer;
grant select on storage.objects to app_admin, app_viewer;
grant insert, update, delete on storage.objects to app_admin;
