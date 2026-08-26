-- =====================================================================
-- جریان — مهاجرت ۰۱۲: عکس پیش‌فرض هر منبع خبری (کانال)
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره.
--
-- زمینه: پست‌هایی که خودشون عکس ندارن (مثلاً پست‌های متنی صرف) توی تب
-- «شبکه‌های اجتماعی» به‌جای عکس، یه باکس خالی placeholder نشون می‌دن.
-- این مهاجرت یه ستون avatar_url به channels اضافه می‌کنه (لینک عمومی
-- عکس پیش‌فرض همون کانال، قابل‌آپلود از پنل «مدیریت کانال‌ها») + یه
-- bucket عمومی جدا (channel-avatars) برای نگه‌داری خودِ فایل — دقیقاً
-- همون الگوی magazine-covers (migration_005).
-- =====================================================================

alter table channels add column if not exists avatar_url text;

insert into storage.buckets (id, name, public)
values ('channel-avatars', 'channel-avatars', true)
on conflict (id) do nothing;

drop policy if exists channel_avatars_storage_select on storage.objects;
create policy channel_avatars_storage_select on storage.objects
  for select to app_admin, app_viewer
  using (bucket_id = 'channel-avatars');

drop policy if exists channel_avatars_storage_write on storage.objects;
create policy channel_avatars_storage_write on storage.objects
  for all to app_admin
  using (bucket_id = 'channel-avatars')
  with check (bucket_id = 'channel-avatars');
