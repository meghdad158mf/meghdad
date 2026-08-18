-- =====================================================================
-- جریان — مهاجرت ۰۰۶: منابع خبری «اخبار رسمی» (فاز ۱ — بخش مطالعه)
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: بخش «اخبار رسمی» علاوه بر ایتا/تلگرام از فیدهای RSS
-- سایت‌های خبری هم تغذیه می‌شه (platform='website'، که از قبل در
-- migration_002 برای همین منظور اضافه شده بود). این مهاجرت دو چیز
-- اضافه می‌کنه که هنوز نبودن:
--   ۱) ستون region روی channels — حوزه‌ی جغرافیایی منبع
--      (داخلی/منطقه‌ای/بین‌المللی)، فقط برای منابع خبری معنا داره،
--      برای کانال‌های شخصیت/کنشگری مجازی معمولی می‌تونه خالی بمونه.
--   ۲) ستون title روی posts — برای عنوان خبر (پست‌های ایتا/تلگرام
--      عنوان جدا ندارن، فقط پست‌های RSS دارن).
-- فیلترهای هوش مصنوعی (کلیدواژه، ترجمه، احساسات) بخشی از فاز ۲ هستن
-- و عمداً اینجا نیستن.
-- =====================================================================

alter table channels add column if not exists region text;
alter table channels drop constraint if exists channels_region_check;
alter table channels add constraint channels_region_check
  check (region is null or region in ('domestic','regional','international'));

alter table posts add column if not exists title text;

-- ---------- منابع پیش‌فرض خبری (قابل ویرایش/حذف از پنل مدیریت کانال‌ها) ----------
insert into channels (platform, username, title, type, region, active) values
  ('website',  'https://www.isna.ir/rss',               'ایسنا',               'news_agency', 'domestic',      true),
  ('website',  'https://www.mehrnews.com/rss',           'خبرگزاری مهر',        'news_agency', 'domestic',      true),
  ('telegram', 'isna_farsi',                             'ایسنا (تلگرام)',      'news_agency', 'domestic',      true),
  ('telegram', 'mehrnewsagency',                         'مهر (تلگرام)',        'news_agency', 'domestic',      true),
  ('eitaa',    'isna',                                   'ایسنا (ایتا)',        'news_agency', 'domestic',      true),
  ('eitaa',    'mehrnews',                                'مهر (ایتا)',          'news_agency', 'domestic',      true),
  ('website',  'https://www.alarabiya.net/farsi/rss.xml', 'العربیه فارسی',       'news_agency', 'regional',      true),
  ('telegram', 'AlArabiya_Farsi',                        'العربیه (تلگرام)',    'news_agency', 'regional',      true),
  ('website',  'https://feeds.bbci.co.uk/persian/rss.xml','بی‌بی‌سی فارسی',      'news_agency', 'international', true),
  ('telegram', 'bbcpersian',                             'بی‌بی‌سی (تلگرام)',    'news_agency', 'international', true)
on conflict (platform, username) do nothing;
