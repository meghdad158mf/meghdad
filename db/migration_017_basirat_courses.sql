-- =====================================================================
-- جریان — مهاجرت ۰۱۷: تب «بسته‌های آموزشی بصیرت» (بخش تحلیلی)
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره (idempotent).
--
-- زمینه: مدرسه‌ی مجازی بصیرت بسته‌های آموزشی تحلیلی مستقلی داره که
-- خودشون میزبانی می‌کنن (نه فایل ما). این جدول فقط پوستر + عنوان +
-- توضیح کوتاه + لینک بیرونی به صفحه‌ی همون آموزش رو نگه می‌داره — برخلاف
-- magazines/archive_reports هیچ فایل واقعی (PDF/عکس) توی Storage خودمون
-- ذخیره نمی‌شه، فقط یه bucket عمومی برای پوستر لازمه.
-- =====================================================================

create table if not exists basirat_courses (
  id            serial primary key,
  title         text not null,
  description   text,
  poster_url    text,                 -- لینک عمومی bucket basirat-course-posters یا null
  external_url  text not null,        -- لینک صفحه‌ی همین آموزش در سایت مدرسه مجازی بصیرت
  sort_order    int  not null default 0,
  created_at    timestamptz not null default now()
);

alter table basirat_courses enable row level security;

drop policy if exists sel_basirat_courses on basirat_courses;
create policy sel_basirat_courses on basirat_courses for select to app_admin, app_viewer using (true);
drop policy if exists rw_basirat_courses on basirat_courses;
create policy rw_basirat_courses  on basirat_courses for all    to app_admin              using (true) with check (true);

grant select on basirat_courses to app_viewer;
grant select, insert, update, delete on basirat_courses to app_admin;
grant usage, select on sequence basirat_courses_id_seq to app_admin;

-- ---------- Storage bucket عمومی برای پوستر آموزش‌ها ----------
insert into storage.buckets (id, name, public)
values ('basirat-course-posters', 'basirat-course-posters', true)
on conflict (id) do nothing;

drop policy if exists basirat_course_posters_storage_select on storage.objects;
create policy basirat_course_posters_storage_select on storage.objects
  for select to app_admin, app_viewer
  using (bucket_id = 'basirat-course-posters');

drop policy if exists basirat_course_posters_storage_write on storage.objects;
create policy basirat_course_posters_storage_write on storage.objects
  for all to app_admin
  using (bucket_id = 'basirat-course-posters')
  with check (bucket_id = 'basirat-course-posters');
