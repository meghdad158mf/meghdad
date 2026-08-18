-- =====================================================================
-- جریان — مهاجرت ۰۰۴: ترتیب نمایش مجلات
-- این فایل را کامل در Supabase SQL Editor پیست و اجرا کنید.
-- ایمن برای اجرای چندباره.
--
-- حذف مجله نیازی به تغییر اسکیما نداره (همون DELETE استاندارد روی
-- جدول magazines، که RLS و grant موجود از قبل به app_admin اجازه‌ش
-- رو می‌ده). این مهاجرت فقط برای امکان جابجایی ترتیب مجلات توی گرید.
-- =====================================================================

alter table magazines add column if not exists sort_order int not null default 0;

-- مجلات موجود (که همه sort_order=0 دارن) رو بر اساس تاریخ بارگذاری
-- شماره‌گذاری کن تا جابجایی ترتیب از همون اول معنی‌دار باشه.
-- (فقط ردیف‌هایی که هنوز مقدار پیش‌فرض ۰ رو دارن؛ روی مجلات جدید که
-- خودِ فرانت‌اند موقع آپلود sort_order مشخص می‌ده، اثر نمی‌ذاره.)
with numbered as (
  select id, row_number() over (order by uploaded_at desc) as rn
  from magazines
  where sort_order = 0
)
update magazines
set sort_order = numbered.rn
from numbered
where magazines.id = numbered.id;
