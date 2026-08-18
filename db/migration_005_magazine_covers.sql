-- =====================================================================
-- جریان — مهاجرت ۰۰۵: Storage bucket عمومی برای جلد مجلات
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره.
--
-- زمینه: کاروسل صفحه‌ی نخست باید جلد واقعی مجلات رو نشون بده، بدون
-- این‌که برای هر کارت یه signed URL جدا صدا بزنه (که برای بایگانی
-- خصوصی magazines لازمه). چون تصویر جلد فقط یه پیش‌نمایش تبلیغاتیه
-- (نه خودِ محتوای کامل مجله)، یه bucket عمومی جدا براش کافیه —
-- می‌شه با یه URL ثابت مستقیم توی <img> نشونش داد.
-- =====================================================================

insert into storage.buckets (id, name, public)
values ('magazine-covers', 'magazine-covers', true)
on conflict (id) do nothing;

drop policy if exists magazine_covers_storage_select on storage.objects;
create policy magazine_covers_storage_select on storage.objects
  for select to app_admin, app_viewer
  using (bucket_id = 'magazine-covers');

drop policy if exists magazine_covers_storage_write on storage.objects;
create policy magazine_covers_storage_write on storage.objects
  for all to app_admin
  using (bucket_id = 'magazine-covers')
  with check (bucket_id = 'magazine-covers');
