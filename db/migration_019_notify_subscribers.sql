-- =====================================================================
-- جریان — مهاجرت ۰۱۹: ثبت‌نام اطلاع‌رسانی انتشار «بسته تحلیلی جریان»
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: هر فردی (بدون نیاز به ورود به سامانه) می‌تواند از صفحه‌ی ورود
-- شماره موبایل خودش را ثبت کند تا هر وقت شماره‌ی جدید «بسته تحلیلی
-- جریان» منتشر شد، پیامک اطلاع‌رسانی برایش ارسال شود. ارسال واقعی پیامک
-- فعلاً خودکار نیست — مدیر هر وقت خودش صلاح دید، از پنل «خروجی‌گیری»
-- لیست شماره‌ها را می‌بیند/خروجی می‌گیرد و از طریق سامانه‌ی پیامکی جدا
-- ارسال می‌کند؛ این جدول فقط جمع‌آوری و مدیریت لیست مشترکین است.
-- =====================================================================

create table if not exists notify_subscribers (
  id          serial primary key,
  phone       text not null check (phone ~ '^09[0-9]{9}$'),
  created_at  timestamptz not null default now(),
  notified_at timestamptz,           -- آخرین باری که مدیر برایش پیامک اطلاع‌رسانی فرستاد (دستی)
  unique (phone)
);

alter table notify_subscribers enable row level security;

-- ثبت‌نام از صفحه‌ی ورود بدون نیاز به احراز هویت (نقش anon پیش‌فرض Supabase)
drop policy if exists ins_notify_subscribers on notify_subscribers;
create policy ins_notify_subscribers on notify_subscribers for insert to anon with check (true);

drop policy if exists sel_notify_subscribers on notify_subscribers;
create policy sel_notify_subscribers on notify_subscribers for select to app_admin using (true);
drop policy if exists rw_notify_subscribers on notify_subscribers;
create policy rw_notify_subscribers  on notify_subscribers for all    to app_admin using (true) with check (true);

grant usage on schema public to anon;
grant insert on notify_subscribers to anon;
grant usage, select on sequence notify_subscribers_id_seq to anon;

grant select, insert, update, delete on notify_subscribers to app_admin;
grant usage, select on sequence notify_subscribers_id_seq to app_admin;
