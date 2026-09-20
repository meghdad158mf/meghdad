-- =====================================================================
-- جریان — مهاجرت ۰۲۸: کانال‌های پیش‌فرض تب «اخبار حوزه»
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره.
--
-- زمینه: کاربر سه سایت خبری حوزه (هرکدوم دارای RSS) رو معرفی کرد تا به
-- تب مستقل «اخبار حوزه» (migration_027) وصل بشن. چون همه‌شون RSS دارن،
-- نیازی به اسکرپر جدید نیست — collect_rss.py موجود از روی همین سه کانال
-- خودکار جمع‌آوری می‌کنه.
-- =====================================================================

insert into channels (platform, username, title, type, active) values
  ('website', 'https://www.hozehkh.com/rss.aspx',   'خبرگزاری حوزه خراسان', 'news_agency', true),
  ('website', 'https://www.hawzahnews.com/rss/tp/1', 'خبرگزاری حوزه',        'news_agency', true),
  ('website', 'https://rasanews.ir/fa/rss/5',        'خبرگزاری رسا',         'news_agency', true)
on conflict (platform, username) do nothing;

update channels set
  show_in_news = true,
  show_in_hawza = true
where (platform, username) in (
  ('website', 'https://www.hozehkh.com/rss.aspx'),
  ('website', 'https://www.hawzahnews.com/rss/tp/1'),
  ('website', 'https://rasanews.ir/fa/rss/5')
);
