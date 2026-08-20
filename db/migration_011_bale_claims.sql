-- =====================================================================
-- جریان — مهاجرت ۰۱۱: افزودن پلتفرم «بله» برای تب «ادعاها و شایعات»
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: تب جدید «ادعاها و شایعات» توی صفحه‌ی اخبار رسمی، پست‌های
-- کانال بله «@rasadfakenews» (رصد شایعات) رو نشون می‌ده. برخلاف
-- ایتا/تلگرام/وب‌سایت، این اولین‌باره که platform='bale' استفاده
-- می‌شه، پس باید به CHECK constraint اضافه بشه (همون الگوی افزودن
-- 'website' در migration_002).
-- =====================================================================

alter table channels drop constraint if exists channels_platform_check;
alter table channels add constraint channels_platform_check
  check (platform in ('eitaa','telegram','website','bale'));

alter table posts drop constraint if exists posts_platform_check;
alter table posts add constraint posts_platform_check
  check (platform in ('eitaa','telegram','website','bale'));

-- ---------- کانال پیش‌فرض «ادعاها و شایعات» ----------
insert into channels (platform, username, title, type, show_in_news, active) values
  ('bale', 'rasadfakenews', 'رصد شایعات', 'news_agency', true, true)
on conflict (platform, username) do nothing;
