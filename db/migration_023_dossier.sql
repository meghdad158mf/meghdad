-- =====================================================================
-- جریان — مهاجرت ۰۲۳: کلیدواژه‌های هوش مصنوعی پست‌ها + بخش «پرونده ویژه»
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: تب «پرونده ویژه» (بخش «اخبار و رویدادها») اخبار مرتبط با چند
-- موضوع موقت/چرخشی (که مدیر تعیین می‌کنه و ممکنه هر چند روز عوض بشه) رو
-- جدا گروه‌بندی نشون می‌ده. برای اینکه هر بار موضوعی تعریف/تغییر می‌کنه
-- لازم نباشه هوش مصنوعی کل تاریخچه‌ی پست‌ها رو دوباره بخونه (هزینه‌ی
-- توکن)، هر پست فقط یک‌بار (وقتی جمع‌آوری می‌شه) با هوش مصنوعی به
-- چندتا کلیدواژه‌ی فارسی/دقیق/بدون‌ابهام برچسب می‌خوره
-- (posts.ai_keywords)؛ تطبیق موضوع بعدش فقط یه مقایسه‌ی متنی ساده و
-- رایگانه (نه هوش مصنوعی).
--
-- posts.ai_keywords = NULL یعنی «هنوز بررسی نشده» (کاندید اجرای بعدی
-- scripts/extract_keywords.py، هر ۲ ساعت)؛ آرایه‌ی خالی '{}' یعنی
-- «بررسی شد ولی کلیدواژه‌ی معناداری نداشت» — این تفاوت عمدیه تا پستی
-- که هیچ‌وقت کلیدواژه‌ی مفیدی نمی‌گیره، هر اجرا دوباره به هوش مصنوعی
-- فرستاده نشه.
-- =====================================================================

alter table posts add column if not exists ai_keywords text[];
alter table posts add column if not exists ai_keywords_extracted_at timestamptz;

-- برای کوئری «پست‌های بدون کلیدواژه» (ORDER BY posted_at ASC) توی
-- extract-post-keywords، تا اجرای بعدی همیشه از قدیمی‌ترین جامونده ادامه بده
create index if not exists idx_posts_ai_keywords_null on posts (posted_at) where ai_keywords is null;

-- ---------- موضوعات موقت «پرونده ویژه» ----------
create table if not exists dossier_topics (
  id         serial primary key,
  name       text not null,
  keywords   text not null,   -- جدا با ویرگول، برای تطبیق با posts.ai_keywords — مثل news_topics
  active     boolean not null default true,   -- فقط موضوعات active به بیننده نشون داده می‌شن
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table dossier_topics enable row level security;

drop policy if exists sel_dossier_topics on dossier_topics;
create policy sel_dossier_topics on dossier_topics for select to app_admin, app_viewer using (true);
drop policy if exists rw_dossier_topics on dossier_topics;
create policy rw_dossier_topics  on dossier_topics for all    to app_admin              using (true) with check (true);

grant select on dossier_topics to app_viewer;
grant select, insert, update, delete on dossier_topics to app_admin;
grant usage, select on sequence dossier_topics_id_seq to app_admin;

-- ---------- پست‌های منتسب به هر موضوع (خودکار یا دستی) ----------
create table if not exists dossier_topic_posts (
  id         serial primary key,
  topic_id   int not null references dossier_topics(id) on delete cascade,
  post_id    int not null references posts(id) on delete cascade,
  source     text not null default 'auto' check (source in ('auto','manual')),
  excluded   boolean not null default false,   -- مدیر بدون حذف کامل می‌تونه یه مورد خودکار رو از دید بیننده پنهان کنه
  created_at timestamptz not null default now(),
  unique (topic_id, post_id)
);

create index if not exists idx_dossier_topic_posts_topic on dossier_topic_posts (topic_id);

alter table dossier_topic_posts enable row level security;

drop policy if exists sel_dossier_topic_posts on dossier_topic_posts;
create policy sel_dossier_topic_posts on dossier_topic_posts for select to app_admin, app_viewer using (true);
drop policy if exists rw_dossier_topic_posts on dossier_topic_posts;
create policy rw_dossier_topic_posts  on dossier_topic_posts for all    to app_admin              using (true) with check (true);

grant select on dossier_topic_posts to app_viewer;
grant select, insert, update, delete on dossier_topic_posts to app_admin;
grant usage, select on sequence dossier_topic_posts_id_seq to app_admin;
