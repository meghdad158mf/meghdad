-- =====================================================================
-- جریان — مهاجرت ۰۲۱: به‌روزرسانی کانال‌های پیش‌فرض مطابق وضعیت واقعی
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: بعد از یک بازسازی کامل دیتابیس (schema.sql + همه‌ی migrationها
-- روی یک پروژه‌ی تازه‌ی سوپابیس، به‌خاطر پر شدن سهمیه‌ی Storage پروژه‌ی
-- قبلی)، معلوم شد لیست کانال‌های پیش‌فرض دیگه با واقعیت هم‌خونی نداره:
--   ۱) چندتا کانال پیش‌فرض قدیمی migration_006 (ایسنا/مهر/العربیه/
--      بی‌بی‌سی-تلگرام) قبلاً از پنل مدیریت حذف شده بودن و دیگه لازم
--      نیستن — بدون این مهاجرت، هر بازسازی بعدی دوباره اضافه‌شون می‌کرد.
--   ۲) چندتا کانال خبری وب‌سایتی (نیویورک‌تایمز، فاکس‌نیوز، وال‌استریت
--      ژورنال، اسکای‌نیوز، سی‌ان‌ان، فرانس۲۴، دویچه‌وله، گاردین،
--      واشنگتن‌پست) و چندتا کانال تلگرامی (مصطفی تاجزاده، ایران
--      اینترنشنال، صدای آمریکا) بعداً از پنل مدیریت اضافه شده بودن،
--      ولی جزو «پیش‌فرض» دیتابیس نبودن.
-- این مهاجرت وضعیت واقعی فعلی رو به‌عنوان پیش‌فرض ثبت می‌کنه، تا هر
-- بازسازی بعدی دقیقاً از همین‌جا شروع بشه.
--
-- ⚠️ باید بعد از migration_009 (برای regions) و migration_012 (برای
-- avatar_url) اجرا بشه — به همین دلیل شماره‌ش از همه‌ی migrationهای
-- موجود بزرگ‌تره.
-- =====================================================================

-- منطقه‌ی جغرافیایی سفارشی که از پنل مدیریت اضافه شده بود (فراتر از
-- سه‌تای پیش‌فرض migration_009)
insert into regions (name) values ('فارسی زبان معاند')
on conflict (name) do nothing;

-- حذف کانال‌های پیش‌فرض قدیمی migration_006 که دیگه استفاده نمی‌شن
delete from channels where (platform, username) in (
  ('website',  'https://www.isna.ir/rss'),
  ('website',  'https://www.mehrnews.com/rss'),
  ('telegram', 'isna_farsi'),
  ('telegram', 'mehrnewsagency'),
  ('eitaa',    'isna'),
  ('eitaa',    'mehrnews'),
  ('website',  'https://www.alarabiya.net/farsi/rss.xml'),
  ('telegram', 'AlArabiya_Farsi'),
  ('telegram', 'bbcpersian')
);

-- کانال‌های خبری وب‌سایتی که بعداً از پنل مدیریت اضافه شده بودن
insert into channels (platform, username, title, type, active) values
  ('website', 'https://www.nytimes.com/svc/collections/v1/publish/https://www.nytimes.com/section/world/middleeast/rss.xml', 'نیویورک تایمز - خاورمیانه', 'news_agency', true),
  ('website', 'https://moxie.foxnews.com/google-publisher/world.xml', 'فاکس نیوز - اخبار جهان', 'news_agency', true),
  ('website', 'https://feeds.a.dj.com/rss/RSSWorldNews.xml', 'وال استریت ژورنال - اخبار جهان', 'news_agency', true),
  ('website', 'https://feeds.skynews.com/feeds/rss/world.xml', 'اسکای نیوز - جهان', 'news_agency', true),
  ('website', 'http://rss.cnn.com/rss/edition_world.rss', 'سی ان ان - اخبار جهان', 'news_agency', true),
  ('website', 'https://www.france24.com/en/middle-east/rss', 'فراتس24 - خاورمیانه', 'news_agency', true),
  ('website', 'https://rss.dw.com/xml/rss-en-all', 'دویجه وله - عمومی', 'news_agency', true),
  ('website', 'https://www.theguardian.com/world/rss', 'گاردین - اخبار جهان', 'news_agency', true),
  ('website', 'https://feeds.washingtonpost.com/rss/world', 'واشنگتن پست - اخبار جهان', 'news_agency', true)
on conflict (platform, username) do nothing;

-- کانال‌های تلگرامی که بعداً از پنل مدیریت اضافه شده بودن (اگه schema.sql
-- قدیمی‌تر بدون این ۳ کانال اجرا شده باشه، این‌جا هم اضافه‌شون می‌کنیم)
insert into channels (platform, username, title, type, active) values
  ('telegram', 'MostafaTajzadeh', 'مصطفی تاجزاده', 'news_agency', true),
  ('telegram', 'iranintltv',      'ایران اینترنشنال', 'news_agency', true),
  ('telegram', 'farsivoa',        'صدای آمریکا', 'news_agency', true)
on conflict (platform, username) do nothing;

-- ---------- تنظیم دقیق دسته‌بندی/منطقه/عضویت مطابق وضعیت واقعی فعلی ----------

update channels set
  category_id = (select id from categories where name = 'سیاسی'),
  region_id = (select id from regions where name = 'بین‌المللی'),
  show_in_news = true, show_in_cyberspace = false, show_in_people = false
where (platform, username) in (
  ('website', 'https://feeds.bbci.co.uk/persian/rss.xml'),
  ('website', 'https://www.nytimes.com/svc/collections/v1/publish/https://www.nytimes.com/section/world/middleeast/rss.xml'),
  ('website', 'https://moxie.foxnews.com/google-publisher/world.xml'),
  ('website', 'https://feeds.a.dj.com/rss/RSSWorldNews.xml'),
  ('website', 'https://feeds.skynews.com/feeds/rss/world.xml'),
  ('website', 'http://rss.cnn.com/rss/edition_world.rss'),
  ('website', 'https://rss.dw.com/xml/rss-en-all'),
  ('website', 'https://www.theguardian.com/world/rss'),
  ('website', 'https://feeds.washingtonpost.com/rss/world')
);

update channels set
  category_id = (select id from categories where name = 'سیاسی'),
  region_id = null,
  show_in_news = true, show_in_cyberspace = false, show_in_people = false
where platform = 'website' and username = 'https://www.france24.com/en/middle-east/rss';

update channels set
  category_id = (select id from categories where name = 'سیاسی'),
  region_id = null,
  show_in_news = false, show_in_cyberspace = false, show_in_people = true
where platform = 'telegram' and username = 'MostafaTajzadeh';

update channels set
  category_id = (select id from categories where name = 'سیاسی'),
  region_id = (select id from regions where name = 'فارسی زبان معاند'),
  avatar_url = 'https://tfppjveupcxisepteibn.supabase.co/storage/v1/object/public/channel-avatars/1787398789719-sg90pr-2.png',
  show_in_news = true, show_in_cyberspace = false, show_in_people = false
where platform = 'telegram' and username = 'iranintltv';

update channels set
  category_id = (select id from categories where name = 'سیاسی'),
  region_id = (select id from regions where name = 'فارسی زبان معاند'),
  avatar_url = 'https://tfppjveupcxisepteibn.supabase.co/storage/v1/object/public/channel-avatars/1787929672324-zyxyvo-618dCg7mNpL.png',
  show_in_news = true, show_in_cyberspace = false, show_in_people = false
where platform = 'telegram' and username = 'farsivoa';
