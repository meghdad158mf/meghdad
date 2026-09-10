-- =====================================================================
-- جریان — مهاجرت ۰۲۴: «خبرنامه مدارس»
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: تب «خبرنامه مدارس» (بخش «اخبار و رویدادها») یه خبرنامه‌ی
-- قابل‌دانلود (چاپ/PDF، ۲ صفحه‌ی A4) می‌سازه: صفحه‌ی اول «ادعاها و
-- شایعات»، صفحه‌ی دوم دوستونه («شبکه‌های اجتماعی و وب‌سایت‌ها» +
-- «پرونده ویژه»). طبق تصمیم صریح کاربر، این جدول **آرشیو نداره** —
-- فقط مجموعه‌ی «فعلیِ منتشرشده» رو نگه می‌داره؛ هر بار مدیر «انتشار
-- خبرنامه‌ی امروز» رو بزنه، کل جدول پاک و با مجموعه‌ی تازه جایگزین
-- می‌شه (نه insert اضافه‌شونده).
-- =====================================================================

create table if not exists newsletter_posts (
  id         serial primary key,
  section    text not null check (section in ('claims','news','dossier')),
  post_id    int not null references posts(id) on delete cascade,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (section, post_id)
);

create index if not exists idx_newsletter_posts_section on newsletter_posts (section, sort_order);

alter table newsletter_posts enable row level security;

drop policy if exists sel_newsletter_posts on newsletter_posts;
create policy sel_newsletter_posts on newsletter_posts for select to app_admin, app_viewer using (true);
drop policy if exists rw_newsletter_posts on newsletter_posts;
create policy rw_newsletter_posts  on newsletter_posts for all    to app_admin              using (true) with check (true);

grant select on newsletter_posts to app_viewer;
grant select, insert, update, delete on newsletter_posts to app_admin;
grant usage, select on sequence newsletter_posts_id_seq to app_admin;
