-- =====================================================================
-- جریان — مهاجرت ۰۲۲: کش تحلیل هوش مصنوعی «اخبار منتخب» + «موضوعات ترند»
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: تب «آنالیز» بخش «اخبار و رویدادها» دو ویجت داره که به‌جای
-- شمارش آماری ساده (که نتیجه‌ش گاهی بی‌معنی بود — مثلاً تکه‌های تاریخ یا
-- متن تکراری سایت‌های خبری به‌عنوان «موضوع ترند» درمی‌اومد)، حالا از
-- هوش مصنوعی واقعی (لیارا، از طریق Edge Function) استفاده می‌کنن:
--   ۱) «اخبار منتخب» — ۱۰ خبر مهم‌تر (نه صرفاً جدیدترین)، بر اساس تکرار
--      زیاد بین منابع یا حساسیت موضوع، به تشخیص هوش مصنوعی
--   ۲) «موضوعات ترند» — موضوعات پرتکرار واقعی، نه شمارش آماری خام
--
-- به‌خاطر هزینه‌ی هر درخواست هوش مصنوعی، این تحلیل هر بار که کاربر تب
-- «آنالیز» رو باز می‌کنه اجرا نمی‌شه — فقط روزی دو بار (هر ۱۲ ساعت،
-- scripts/analyze_news_insights.py از GitHub Actions) روی پنجره‌ی
-- ۱۲ساعته‌ی خودش اجرا می‌شه و نتیجه همین‌جا کش می‌شه؛ فرانت‌اند همیشه
-- فقط آخرین ردیف رو می‌خونه.
-- =====================================================================

create table if not exists news_ai_insights (
  id              serial primary key,
  computed_at     timestamptz not null default now(),
  window_hours    int not null default 12,
  selected_posts  jsonb not null default '[]',   -- [{"id": 123, "reason": "..."}, ...]
  topics          jsonb not null default '[]',   -- [{"name": "...", "weight": 7}, ...]
  created_at      timestamptz not null default now()
);

create index if not exists idx_news_ai_insights_computed_at on news_ai_insights (computed_at desc);

alter table news_ai_insights enable row level security;

-- فرانت‌اند (هر دو نقش) فقط می‌خونه؛ نوشتنش دست اسکریپت GitHub Actionه
-- که با توکن مدیر (public.login() با ADMIN_PASSWORD) وارد می‌شه
drop policy if exists sel_news_ai_insights on news_ai_insights;
create policy sel_news_ai_insights on news_ai_insights for select to app_admin, app_viewer using (true);
drop policy if exists rw_news_ai_insights on news_ai_insights;
create policy rw_news_ai_insights  on news_ai_insights for all    to app_admin              using (true) with check (true);

grant select on news_ai_insights to app_viewer;
grant select, insert, update, delete on news_ai_insights to app_admin;
grant usage, select on sequence news_ai_insights_id_seq to app_admin;
