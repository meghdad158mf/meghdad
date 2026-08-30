-- =====================================================================
-- جریان — مهاجرت ۰۲۰: موضوعات جستجوی ذخیره‌شده («اخبار رسمی»)
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: چون سیستم هنوز طبقه‌بندی خودکار موضوعی روی هر پست نداره
-- (اون بخش «تحلیل هوش مصنوعی واقعی» جزو کارهای آینده‌ست)، این جدول یه
-- راه‌حل سبک‌تره: مدیر از پنل «تنظیمات» چندتا «موضوع» با یه لیست
-- کلیدواژه (جدا با ویرگول) تعریف می‌کنه؛ توی تب‌های «شبکه‌های اجتماعی»/
-- «وب‌سایت‌ها»/«ادعاها و شایعات»، با کلیک روی چیپ همون موضوع، فرانت‌اند
-- خودش کلیدواژه‌ها رو توی جستجوی متنی موجود می‌ذاره و با OR بین
-- کلیدواژه‌ها فیلتر می‌کنه (نه AND) — یعنی هر پستی که حداقل یکی از
-- کلیدواژه‌ها رو توی عنوان/متنش داشته باشه، نشون داده می‌شه.
-- =====================================================================

create table if not exists news_topics (
  id         serial primary key,
  name       text not null,
  keywords   text not null,   -- کلیدواژه‌ها جدا با ویرگول، مثل «انتخابات, دولت, مجلس»
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table news_topics enable row level security;

drop policy if exists sel_news_topics on news_topics;
create policy sel_news_topics on news_topics for select to app_admin, app_viewer using (true);
drop policy if exists rw_news_topics on news_topics;
create policy rw_news_topics  on news_topics for all    to app_admin              using (true) with check (true);

grant select on news_topics to app_viewer;
grant select, insert, update, delete on news_topics to app_admin;
grant usage, select on sequence news_topics_id_seq to app_admin;
