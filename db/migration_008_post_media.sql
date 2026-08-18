-- =====================================================================
-- جریان — مهاجرت ۰۰۸: ذخیره‌ی واقعی عکس/فیلم پست‌ها (ایتا و تلگرام)
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: تا الان media_path هیچ‌وقت پر نمی‌شد — فقط media_type
-- تشخیص داده می‌شد (اونم فقط برای تلگرام)، بدون دانلود خودِ فایل.
-- از این مهاجرت به بعد:
--   - کالکتورها عکس/فیلم رو واقعاً دانلود و در Storage آپلود می‌کنن
--   - media_path = لینک عمومی فایل ما (برای نمایش مستقیم <img>/دانلود)
--   - media_storage_path = مسیر دقیق فایل در bucket (برای حذف بعدی)
--   - media_source_url = لینک اصلی رسانه در مبدأ (فقط ایتا — تلگرام
--     چنین لینک پایداری نداره)
--   - media_fetched_at = چه‌موقع دانلود شده؛ یک job روزانه‌ی جدید
--     (scripts/cleanup_media.py) هر چیزی که از ۳ روز قدیمی‌تر باشه
--     رو از Storage پاک می‌کنه (media_path/media_fetched_at رو null
--     می‌کنه، media_type دست‌نخورده می‌مونه که UI بدونه رسانه‌ای
--     وجود داشته) — برای اینکه دیتابیس/فضای Storage پر نشه.
-- =====================================================================

alter table posts add column if not exists media_storage_path text;
alter table posts add column if not exists media_source_url text;
alter table posts add column if not exists media_fetched_at timestamptz;

insert into storage.buckets (id, name, public)
values ('post-media', 'post-media', true)
on conflict (id) do nothing;

drop policy if exists post_media_storage_select on storage.objects;
create policy post_media_storage_select on storage.objects
  for select to app_admin, app_viewer
  using (bucket_id = 'post-media');

drop policy if exists post_media_storage_write on storage.objects;
create policy post_media_storage_write on storage.objects
  for all to app_admin
  using (bucket_id = 'post-media')
  with check (bucket_id = 'post-media');
