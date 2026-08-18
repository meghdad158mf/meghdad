-- =====================================================================
-- جریان — مهاجرت ۰۰۷: عضویت مستقل هر کانال در حوزه‌های نمایش
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: تا الان عضویت کانال در «اخبار رسمی» و «کنشگری مجازی» از روی
-- فیلدهای دیگه (type، platform) حدس زده می‌شد، که برای کانال‌های
-- قدیمی درست از آب درنمی‌اومد (خیلی از کانال‌های کنشگری هم مقدار
-- پیش‌فرض type='news_agency' رو داشتن). حالا هر کانال سه فیلد کاملاً
-- مستقل داره — یک کانال می‌تونه هم‌زمان توی چند حوزه باشه، یا هیچ‌کدوم:
--
--   show_in_news        نمایش در «اخبار رسمی»
--   show_in_cyberspace   نمایش در «کنشگری مجازی»
--   show_in_people        نمایش در «افراد و شخصیت‌ها» (صفحه‌اش هنوز
--                          ساخته نشده، این فقط ستون رو آماده می‌کنه)
--
-- برای کانال‌های جدید بعد از این مهاجرت، هر سه پیش‌فرض false هستن —
-- یعنی مدیر باید دستی از پنل «مدیریت کانال‌ها» تیک بزنه، هیچی خودکار
-- نیست. اما چون «کنشگری مجازی» تا امروز همیشه همه‌ی کانال‌های موجود
-- رو نشون می‌داد، برای این‌که چیزی که همین الان قابل‌دیدن است ناپدید
-- نشه، show_in_cyberspace برای کانال‌های از قبل موجود true بک‌فیل
-- می‌شه (به‌جز پلتفرم website، چون اونا صرفاً منابع خبری‌ان).
-- =====================================================================

alter table channels add column if not exists show_in_news boolean not null default false;
alter table channels add column if not exists show_in_cyberspace boolean not null default false;
alter table channels add column if not exists show_in_people boolean not null default false;

-- حفظ رفتار فعلی «کنشگری مجازی» برای کانال‌های از قبل موجود
update channels set show_in_cyberspace = true where platform <> 'website';

-- منابع RSS همیشه صرفاً برای اخبار رسمی اضافه می‌شن
update channels set show_in_news = true where platform = 'website';

-- ۶ منبع خبری ایتا/تلگرامی که در migration_006 seed شدن
update channels set show_in_news = true
where (platform, username) in (
  ('telegram', 'isna_farsi'),
  ('telegram', 'mehrnewsagency'),
  ('eitaa',    'isna'),
  ('eitaa',    'mehrnews'),
  ('telegram', 'AlArabiya_Farsi'),
  ('telegram', 'bbcpersian')
);
-- این ۶ منبع طبق قاعده‌ی بالا (show_in_cyberspace = true where platform <> 'website')
-- در «کنشگری مجازی» هم می‌مونن — یعنی هم‌زمان توی هر دو حوزه هستن، دقیقاً
-- همون عضویت چندگانه‌ای که خواسته شده. اگه نخواستید، از پنل مدیریت کانال‌ها
-- تیکش رو بردارید.
