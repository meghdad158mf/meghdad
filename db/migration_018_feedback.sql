-- =====================================================================
-- جریان — مهاجرت ۰۱۸: کارت «ثبت نظر و پیشنهاد» پایین صفحه نخست
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: کارت همیشه‌نمایان پایین صفحه‌ی نخست که هم مدیر هم بیننده
-- می‌تونن نظر/پیشنهادشون رو ثبت کنن. برخلاف بقیه‌ی جدول‌ها، اینجا
-- «بیننده» هم اجازه‌ی insert داره (تنها استثنای این پروژه) — چون خودِ
-- ثبت نظر کاریه که باید هر دو نقش بتونن انجامش بدن؛ خوندن نظرات ثبت‌شده
-- فقط برای مدیر باز می‌مونه (فعلاً UI مدیریتی برای دیدنشون ساخته نشده،
-- ولی از طریق Table Editor خودِ Supabase قابل‌مشاهده‌ست).
-- =====================================================================

create table if not exists feedback (
  id         bigserial primary key,
  name       text,
  message    text not null,
  created_at timestamptz not null default now()
);

alter table feedback enable row level security;

drop policy if exists sel_feedback on feedback;
create policy sel_feedback on feedback for select to app_admin using (true);
drop policy if exists ins_feedback on feedback;
create policy ins_feedback on feedback for insert to app_admin, app_viewer with check (true);
drop policy if exists upd_feedback on feedback;
create policy upd_feedback on feedback for update, delete to app_admin using (true) with check (true);

grant select, insert, update, delete on feedback to app_admin;
grant insert on feedback to app_viewer;
grant usage, select on sequence feedback_id_seq to app_admin, app_viewer;
