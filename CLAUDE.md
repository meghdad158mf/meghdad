# جریان — راهنمای پروژه برای Claude

این فایل به‌صورت خودکار توسط Claude Code خونده می‌شه. هدفش اینه که هر جلسه‌ی جدید (چت جدید) بدون نیاز به توضیح دوباره، بفهمه پروژه چیه، تا کجا پیش رفته، و چی مونده.

## ⚠️ شاخه‌ی کاری — این رو اول بخون

**شاخه‌ی زنده و واقعی این پروژه `claude/new-project-8ekywm`ه، نه `main`.** GitHub Pages از همین شاخه سرو می‌شه:
`https://meghdad158mf.github.io/meghdad/design/ita-monitoring-prototype.html`

هارنس Claude Code معمولاً یه شاخه‌ی دیگه رو به‌صورت پیش‌فرض لوکال چک‌اوت می‌کنه که **قدیمی و نامرتبطه** — اگه گیت‌گرپ یا Read روی فایل‌های لوکال چیزی متفاوت از چیزی که اینجا توضیح داده شده نشون داد، نگران نشو، یعنی روی شاخه‌ی اشتباهی — همیشه اول `git fetch origin claude/new-project-8ekywm` بزن و کارت رو از `origin/claude/new-project-8ekywm` شروع کن، نه از فایل لوکال چک‌اوت‌شده.

**روش کار همیشگی**: `git checkout -b <شاخه‌ی-جدید> origin/claude/new-project-8ekywm` → تغییر بده → با Playwright و داده‌ی موک پیش‌نمایش بگیر (روش دقیق پایین‌تر) → اسکرین‌شات رو با `SendUserFile` برای کاربر بفرست و صریح بپرس تأیید می‌کنه یا نه → فقط بعد از تأیید، commit + push + یه Pull Request به‌سمت `claude/new-project-8ekywm` (نه `main`!) → قبل از مرج حتماً `pull_request_read` با متد `get_commits` رو چک کن که کامیت درست توی PR هست → مرج → با `get_file_contents`/`git diff` تأیید کن تغییر واقعاً نشسته (zero-diff بین شاخه‌ی محلی و `origin/claude/new-project-8ekywm` بعد از `fetch`) → به کاربر بگو Ctrl+F5 بزنه. **پوش مستقیم به `claude/new-project-8ekywm` مسدوده** — همیشه از مسیر شاخه‌ی جدید + PR برو، حتی برای تغییرات کوچیک.

## پروژه چیه؟

**«جریان»** یک سامانه‌ی رصد رسانه‌ایه برای **اداره‌ی رصد و راهبری سیاسی‌اجتماعی حوزه‌ی علمیه‌ی خراسان**.

قبل از این پروژه، یک سیستم مستقل و کاملاً کارکننده برای پایش تلگرام از قبل وجود داشت (Python + FastAPI + SQLite + Telethon، روی سیستم شخصی کاربر). این پروژه اون سیستم رو با ایتا یکی کرد و کل زیرساخت رو از «سیستم شخصی» به «کاملاً ابری و رایگان» منتقل کرد.

## ساختار صفحه‌ی نخست (وضعیت فعلی — به‌روز)

از بالا به پایین، صفحه‌ی نخست (`sec-dashboard`) این بخش‌ها رو داره:

1. **هدر/توپ‌بار** (`.topbar`): سمت راست دکمه‌ی منوی «بخش‌ها» (`#nav-menu`/`#nav-menu-btn`) + مسیر «سامانه هوشمند جریان / [عنوان صفحه‌ی جاری]». ⚠️ آیکون برند قدیمی (نمودار میله‌ای، `.topbar-badge`) دیگه صرفاً دکوراتیو نیست — با همون شکل ظاهری (مربع گرد هلویی‌رنگ) جایگزین آیکون منوی همبرگری شده و کلیکش `toggleNavMenu()` رو صدا می‌زنه، نه ناوبری به خونه؛ کلیک روی خودِ متن «سامانه هوشمند جریان / ...» (`.topbar-brand-text`) هنوز می‌بره صفحه‌ی نخست. با کلیک، یه دراپ‌داون به **سمت چپ** باز می‌شه (`#nav-menu-list.nav-menu-grid`، پس‌زمینه‌ی گرادیانی هلویی مثل `.package-card`، دوستونه): ستون اول «عرصه‌های رصد» (اخبار رسمی با ۴ زیرتب `goToNewsTab`، کنشگری مجازی، برنامه مدارس، افراد و مجموعه‌ها با ۳ زیرتب `goToPeopleTab`)؛ ستون دوم «بسته تحلیلی جریان» + «ضمیمه جریان» (۲ زیرتب `openSupplementTab`) — دقیقاً معماری واقعی صفحه‌ی نخست، نه گروه‌بندی دلخواه. سمت چپ توپ‌بار: وضعیت «به‌روزرسانی خودکار هر ۲ ساعت» (نقطه‌ی سبز چشمک‌زن + متن)، دراپ‌داون «مدیریت» (خروجی‌گیری/تنظیمات، فقط مدیر)، دکمه‌ی خروج. **در موبایل (زیر ۶۴۰px) یک‌ردیفه شده**: نام کامل سامانه و متن وضعیت مخفی می‌شن (فقط نقطه‌ی سبز چشمک‌زن می‌مونه، بدون متن — با `font-size:0` نه `display:none`، تا نمادش حفظ بشه)، دکمه‌های «مدیریت»/منوی «بخش‌ها» فقط آیکون (بدون متن/فلش) نشون می‌دن. ⚠️ دکمه‌ی «بازگشت به صفحه نخست» (`.section-back`) که قبلاً بالای هر صفحه‌ی اختصاصی بود، چون این منو جایگزینش شد، از همه‌ی صفحات حذف شده — دیگه نیست.
2. **هرو** (`.dash-hero-grid`): تیتر «نبض فضای سیاسی اجتماعی در حوزه علمیه خراسان»، توضیح، **پنل آماری ۶تایی** (`#dash-hero-stats`، تابع `renderDashHeroStats()`): کانال پایش‌شونده / خبرگزاری / شخصیت / پلتفرم / مدرسه / بسته تحلیل — همه با اعداد فارسی (`toFaDigits`). «مدرسه» عدد ثابت (`schoolsCount = 126`) از آخرین گزارش Power BI کاربر — چون تحلیل مدارس توی خودِ Power BI انجام می‌شه و اینجا فقط گالری اسکرین‌شاته (بخش «برنامه مدارس» رو پایین‌تر ببین)، منبع زنده‌ای براش نیست؛ با هر گزارش جدید باید دستی به‌روز بشه. `margin-top: 50px` روی خودِ `.dash-hero-grid` (نه `margin-bottom` مشترک `.topbar`) فاصله‌ی بیشتری از هدر ایجاد می‌کنه.
3. **دو کارت راهنمای سریع** (`.quicknav-grid`، دو `.quicknav-card`): «می‌خواهم عرصه‌های رصد را ببینم!» (کلیک → `scrollToDomainGrid()`) و «می‌خواهم بسته تحلیلی جریان را ببینم!» (کلیک → `scrollToPackageCard()`) — هر دو فقط اسکرول *داخل همون صفحه*، نه ناوبری واقعی. کارت‌ها بدون آیکون/دکمه، فقط عنوان+توضیح، وسط‌چین و کم‌عرض. کادر هرو با `padding-bottom: 100px` تا نصف پشت این دو کارت کشیده شده (`margin: -72px` روی خودِ `.quicknav-grid` این افکت رو می‌سازه).
4. **«چرا جریان»** (`.why-jarian-card`): یه کادر تمام‌عرض **مستقیم روی بوم تیره** (بدون پس‌زمینه — نسخه‌ی قبلی که ته‌رنگ گرادیانی هلویی `.package-card` رو تکرار می‌کرد جمع شد، چون رنگ برند زودتر از خودِ کارت اصلی مصرف می‌شد) با یه `border` ظریف (`rgba(255,255,255,0.34)`) دور کل بلوک تا از بقیه‌ی صفحه جدا بمونه، شامل سه ستون (`.why-jarian-grid` داخلش) با خط جداکننده‌ی عمودی هم‌رنگ بین ستون‌ها: «رصد لحظه‌ای» / «تحلیل تخصصی» / «دسترسی اختصاصی» — هرکدوم یه تگ عنوان کوتاه (`var(--accent)` رنگ، نه `--accent-strong`، چون الان زمینه‌ی کارت تیره‌ست نه روشن)، یه خط کوتاه زیرش (`.why-jarian-bar`، با هاور کش میاد)، و یه پاراگراف توضیح به رنگ سفید نیمه‌شفاف. `margin-top: 160px`. ⚠️ نسخه‌ی خیلی قبلی‌تر که این سه ستون رو بدون هیچ قابی مستقیم روی بوم تیره نشون می‌داد (با یه خط اتصال موج‌دار زیرش، نه border مستطیلی) توسط کاربر رد شده بود — نسخه‌ی فعلی چون قاب مستطیلی داره فرق می‌کنه و مجدداً تأیید شده.
5. **«عرصه‌های رصد و تحلیل»** (`.section-label` + `.domain-grid`، ۴ کارت `.domain-card`): اخبار رسمی، کنشگری مجازی، برنامه مدارس، افراد و مجموعه‌ها. بدون تگ زیرمجموعه. هر ۴ کارت یک تصویر آیکون سه‌بعدی illustrated واقعی دارن (`images/domain-icon-{news,cyberspace,schools,people}.webp`، کلاس `.domain-icon.is-illustrated`). کارت‌ها هیچ قاب/پس‌زمینه‌ای ندارن — مستقیم روی بوم تیره. کلیک هر کارت → `switchSection('overview'|'posts'|'schools'|'people')` — **همه‌ی ۴ صفحه الان کامل پیاده‌سازی شده‌ان** (دیگه هیچ‌کدوم placeholder نیستن؛ جزئیات هرکدوم پایین‌تر). در موبایل ۲ستونه (زیر ۹۰۰px). `.section-label` خودش `margin-top: 160px` داره (فاصله‌ی زیاد از کارت «چرا جریان» بالاش) و `scroll-margin-top: 140px` (برای وقتی `scrollToDomainGrid()` بهش اسکرول می‌کنه، تا تیتر چسبیده به لبه‌ی بالای صفحه دیده نشه).
6. **متن توضیحی** (`.domain-caption`): یه پاراگراف کوتاه وسط‌چین (سه‌خطی) زیر ردیف کارت‌ها که چهار عرصه رو خلاصه توضیح می‌ده.
7. **ردیف میان‌برهای زیربخش‌ها** (`.domain-shortcuts`، ۱۴ مورد): زیر توضیح سه‌خطی، لینک‌های pill-شکل به همه‌ی زیرتب‌های سه عرصه‌ای که تب دارن (اخبار رسمی: ۷ تا، کنشگری مجازی: ۲ تا، افراد و مجموعه‌ها: ۵ تا — «برنامه مدارس» تب نداره پس ازش چیزی نیومده؛ «ضمیمه جریان» هم چون یکی از این چهار عرصه‌ی رصد نیست، اینجا لینک نداره). موارد فعال `<a onclick="goToNewsTab(tab)"|"goToPeopleTab(tab)"|"switchSection('posts')">` و موارد هنوز غیرفعال `<span class="domain-shortcut-disabled">...<span class="news-soon">به‌زودی</span></span>` (بدون گروه‌بندی با اسم عرصه — فقط اسم خودِ تب، کنار هم؛ چون بدون اسم عرصه دو مورد «آنالیز» تکراری می‌شدن، به «آنالیز اخبار»/«آنالیز افراد»/«آنالیز کنشگری» تغییر نام دادن تا مشخص باشن). `goToNewsTab(tab)`/`goToPeopleTab(tab)` هر دو ابتدا `switchSection` می‌زنن بعد تب داخلی رو عوض می‌کنن — تعریفشون بلافاصله بعد از `switchSection()` توی کد اومده.
8. **کارت «بسته تحلیلی جریان»** (`.package-card`، کارت هلویی‌رنگ یکپارچه — قبلاً دو بلوک جدا بود، توی PR #122 یکی شدن): بالا (`.package-top`) تصویر (`images/analysis-illustration.webp`) + عنوان/توضیح/گرید۱۰تایی خطی (ثابت، نه از دیتابیس — خط خبری، تحلیل اخبار روز، مهم‌ترین اخبار، نگاه جامعه‌شناسی سیاسی، اصل ماجرا، تحلیل سازمان‌ها، یادداشت طلاب، خارج از دید، نبض افکار، تحلیل اندیشگده‌ها)؛ زیرش (`.package-divider` بعد) کاروسل افقی جلد مجلات از دیتابیس (`#mag-carousel-home`، جدول `magazines`) با فلش چپ/راست (جهت **تأیید و تست‌شده**: راست=«›»=بعدی، چپ=«‹»=قبلی) و دکمه‌ی «مشاهده‌ی همه» به `sec-reports`. `margin-top: 200px` (بالای کارت، از ردیف میان‌برهای بالاش جدا می‌کنه) + `scroll-margin-top: 90px` (برای `scrollToPackageCard()`).
9. **کارت «اطلاع از انتشار بسته تحلیلی جریان»** (`.notify-card`، بین کارت هلویی و ویجت «ضمیمه جریان»؛ بدون پس‌زمینه — مستقیم روی بوم تیره، وسط‌چین، `max-width: 460px`، با خط جداکننده‌ی عمودی چپ‌وراست (`rgba(255,255,255,0.32)`) و یه آیکون زنگوله‌ی دایره‌ای هلویی‌رنگ بالای عنوان؛ `margin-top: 120px`): کاربر واردشده (مدیر یا بیننده — این کارت پشت ورود به سامانه‌ست، نه صفحه‌ی ورود عمومی) شماره موبایلش رو، با اعتبارسنجی فرمت `09xxxxxxxxx` و تبدیل خودکار ارقام فارسی به انگلیسی (`faDigitsToEn()`)، توی جدول `notify_subscribers` ثبت می‌کنه (`subscribeNotify()`). ارسال واقعی پیامک اطلاع‌رسانی وقتی شماره‌ی جدیدی از «بسته تحلیلی جریان» منتشر شد **فعلاً خودکار نیست** — مدیر از پنل «مدیریت ← خروجی‌گیری» (بخش «مشترکین اطلاع‌رسانی بسته جریان»، `loadNotifySubscribers()`/`renderNotifySubscribers()`) لیست شماره‌ها رو می‌بینه، با دکمه‌ی «دانلود لیست شماره‌ها (CSV)» خروجی می‌گیره و از یه سامانه‌ی پیامکی جدا خودش ارسال می‌کنه؛ بعد دکمه‌ی «علامت‌گذاری به‌عنوان اطلاع‌رسانی‌شده» رو می‌زنه (ستون `notified_at`) تا خروجی بعدی فقط شماره‌های جدید رو نشون بده.
10. **ویجت «ضمیمه جریان»** (`.basirat-widget-block`، تنها ویجت عمومی زیر کارت هلویی، `margin: 220px 0 220px` — فاصله‌ی بالا/پایین عمداً برابر): دو بخش روی هم:
    - **بالا** (`.basirat-widget-top`، طرح دوستونه): سمت راست عنوان+توضیح («ضمیمه جریان» / «محتوای تکمیلی برای تعمیق عرصه‌های رصد و تحلیل»)، سمت چپ ردیف آیکون دایره‌ای دسته‌بندی محتوا (`#basirat-grid-home`، `renderBasiratHomeGrid()`، آرایه‌ی ثابت `SUPP_CONTENT_TYPES`: کتاب/مقالات/**نشریات**/ویدئو/صوت/سخنرانی — مستقل از داده‌ی واقعی `BASIRAT_COURSES`). کلیک هر آیکون → `openSupplementTab(tab)`؛ همه‌شون می‌برن تب `'basirat'` **به‌جز «نشریات»** (سومی از راست) که عمداً می‌بره تب `'archive'`، چون قراره حس بده همون کارسول پایینش رو باز کرده. (آیکون «مصاحبه» حذف شده، جاش «نشریات» اومده.)
    - **پایین** (`.supp-archive-block`، تمام‌عرض، با کادر و ته‌رنگ گرادیانی هلویی): کارسول واقعاً اسکرول‌پذیر افقی «سایر بسته‌های تحلیلی» (`#archive-grid-home`، `renderArchiveHomeGrid()`، جدول `archive_reports`، حداکثر ۶ آیتم). بدون سربرگ جدا — عنوان+«مشاهده‌ی همه» به‌شکل یه کارت عملی (`.supp-archive-viewall-card`) **ته کارسول** (چون DOM آخره و صفحه RTLه، سمت چپ درمیاد) با `position:sticky; left:0` قرار گرفته تا با اسکرول از دید خارج نشه (باگ واقعی گزارش‌شده و رفع‌شده). کارت‌های پوستر عرض ۱۶۰px دارن تا با تعداد فعلی آرشیو (~۵ تا) + کارت «مشاهده‌ی همه»، هر ۶ تا بدون اسکرول جا بشن.
11. **کارت «ثبت نظر و پیشنهاد»** (`.feedback-card`، همیشه‌نمایان، سطح روشن `var(--surface)` — برخلاف بقیه‌ی بخش‌های صفحه‌ی نخست): فرم ساده (نام اختیاری + پیام اجباری) که با `submitFeedback(event)` روی جدول `feedback` می‌شینه. **تنها استثنای پروژه برای insert بدون محدودیت نقش**: نقش «بیننده» هم اجازه‌ی insert روی این جدول رو داره (بقیه‌ی جدول‌ها فقط مدیر می‌نویسه — به‌جز `notify_subscribers` که insertش برای هر دو نقش مدیر/بیننده بازه، نه فقط بیننده). نتایج فقط از پنل مدیریت («مدیریت» ← «نظرات کاربران»، `switchSection('feedback')`، بخش admin-only) قابل‌مشاهده و حذفه — لیست‌شدن با `loadFeedbackList()`/`renderFeedbackList()` (با `textContent` نه `innerHTML`، چون متن ورودی بیننده‌ست و باید در برابر XSS امن باشه).
12. **فوتر** (`.app-footer`): تماس، آدرس، نهاد مسئول.

⚠️ نکات باز/فلگ‌شده که حل نشدن (به «قدم بعدی» پایین نگاه کن): داده‌ی تستی احتمالی توی مجلات/آرشیو/بصیرت (نیاز به بررسی مجدد از پنل مدیریت)، سه سیستم آیکون متفاوت (کارت‌های اصلی سه‌بعدی illustrated / تصویر بخش «بسته تحلیلی جریان» گرادیانی‌تخت / گرید ۱۰تایی خطی).

## روش پیش‌نمایش قبل از مرج (Playwright + داده‌ی موک)

قبل از هر تغییر UI، حتماً با Playwright پیش‌نمایش بگیر و اسکرین‌شات رو برای تأیید کاربر بفرست، **قبل از commit/push**. الگوی درست:

1. فایل رو کپی کن به یه پوشه‌ی scratchpad، عکس‌ها و فونت‌ها رو هم از شاخه‌ی درست بردار (چون لوکال ممکنه نداشته باشتشون):
   ```
   git --git-dir=/home/user/meghdad/.git archive origin/claude/new-project-8ekywm design/images design/fonts | tar -x --strip-components=1
   ```
2. قبل از مارکر `// ---- boot ----`، بوت اصلی رو با این جایگزین کن (نه با صداکردن مستقیم `enterDash` — باید `loadAll()` هم صدا زده بشه). ⚠️ **این لیست باید کامل باشه** — `loadAll()` همه‌ی این توابع رو صدا می‌زنه و اگه حتی یکی override نشده باشه، fetch واقعی به Supabase (که این محیط بهش دسترسی نداره) fail می‌شه و چون `loadAll().then(...)` بدون `.catch()`ه، کل promise chain reject می‌شه و `enterDash` هیچ‌وقت صدا زده نمی‌شه — نتیجه: صفحه‌ی ورود (login) به‌جای داشبورد نشون داده می‌شه، بدون هیچ خطای واضحی (این باگ واقعاً یه‌بار رخ داد و کلی وقت گرفت تا پیدا بشه):
   ```js
   loadChannels = async function(){ CHANNELS = []; };
   loadCategories = async function(){ CATEGORIES = []; };
   loadRegions = async function(){ REGIONS = []; };   // اگه فیلترهای اخبار رسمی/منطقه رو تست می‌کنی حتماً پر کن، وگرنه چیپ منطقه خالی می‌مونه
   loadNewsTopics = async function(){ NEWS_TOPICS = []; };   // اگه چیپ‌های «موضوع» تب وب‌سایت‌ها رو تست می‌کنی حتماً پر کن
   loadPosts = async function(){ POSTS_CACHE = []; };
   loadMagazines = async function(){ MAGAZINES = []; };
   loadArchiveReports = async function(){ ARCHIVE_REPORTS = []; };
   loadBasiratCourses = async function(){ BASIRAT_COURSES = []; };
   loadSchoolReports = async function(){ SCHOOL_REPORTS = []; };
   loadPeople = async function(){ PEOPLE = []; };
   loadPersonPositions = async function(){ PERSON_POSITIONS = []; };
   loadProfessors = async function(){ PROFESSORS = []; };
   loadProfessorSpecialties = async function(){ PROFESSOR_SPECIALTIES = []; };
   loadProfessorRanks = async function(){ PROFESSOR_RANKS = []; };
   loadNewspapers = async function(){ NEWSPAPERS = []; };
   currentRole = 'app_admin';   // ⚠️ اسم متغیر currentRole‌ه، نه ROLE — با ROLE کار نمی‌کنه و applyRoleUI() چیزی نشون نمی‌ده
   authToken = 'fake-token';
   applyRoleUI();
   loadAll().then(()=> enterDash('dashboard'));
   ```
   اگه صفحه بعد از اجرا همچنان روی «ورود» موند (نه داشبورد)، اول چک کن که همه‌ی `loadX` بالا override شدن؛ اگه فرقی نکرد، با `page.on('pageerror', ...)`/`page.on('console', ...)` خطاهای واقعی رو بگیر (معمولاً `Failed to fetch` یا مشابه، از یه `loadX` جا‌افتاده میاد).
3. با `NODE_PATH=/opt/node22/lib/node_modules node script.js` اجرا کن (پکیج playwright به‌صورت گلوبال نصبه، `require('playwright')` مستقیم کار نمی‌کنه بدون NODE_PATH). مرورگر: `executablePath: '/opt/pw-browsers/chromium'`.
4. برای تست موبایل، `viewport: { width: 390, height: 900 }` (یا ۸۴۴) رو امتحان کن؛ برای چک اسکرول افقی، `document.body.scrollWidth` رو با `document.documentElement.clientWidth` مقایسه کن (باید مساوی باشن).
5. برای تست دکمه‌ی «ترجمه به فارسی» (بخش «هوش مصنوعی» رو ببین)، چون این محیط به Edge Function واقعی دسترسی نداره، با `page.route('**/functions/v1/translate', route => route.fulfill({...}))` جواب ساختگی بده (`{title, text}`) — منطق UI (جایگزینی متن، toggle) رو می‌شه این‌جوری تست کرد، ولی فراخوانی واقعی به لیارا رو نه؛ اون رو باید بعد از push خودِ کاربر روی سایت واقعی تست کنه.

## معماری فعلی

```
GitHub Actions (کالکتورها با cron دوره‌ای، پاک‌سازی روزانه — فقط از شاخه‌ی main اجرا می‌شن، نگاه کن به نکته‌ی عملیاتی پایین)
    │
    ├── scripts/collect_eitaa.py     ── اسکرپ HTML صفحات عمومی eitaa.com (بدون نیاز به API)
    ├── scripts/collect_telegram.py  ── Telethon، polling دوره‌ای (نه listener زنده) + دانلود عکس/فیلم پست‌ها
    ├── scripts/collect_rss.py       ── فید RSS سایت‌های خبری (platform='website')
    ├── scripts/collect_newspapers.py── صفحه‌ی اول روزنامه‌ها از کیوسک جار (jaaar.com/kiosk)
    ├── scripts/collect_bale.py      ── کانال «رصد شایعات» (@rasadfakenews) پیام‌رسان بله، برای تب «ادعاها و شایعات» — پارس React Flight payload سمت‌سرور صفحه‌ی ble.ir (نه API رسمی)
    └── scripts/cleanup_media.py     ── روزانه: رسانه‌ی پست‌های قدیمی‌تر از RETENTION_DAYS رو از Storage پاک می‌کنه (فعلاً موقتاً ۱ روز، نگاه کن به «نکات عملیاتی» پایین)
    │
    ▼
Supabase (Postgres + PostgREST رایگان)
    │  دو نقش Postgres: app_admin / app_viewer
    │  ورود با پسورد مشترک از طریق تابع public.login() (pgcrypto برای هش، pgjwt برای توکن)
    │  RLS: بیننده فقط خواندن، مدیر خواندن/نوشتن
    │  Storage: ۹ bucket — magazines (خصوصی)، magazine-covers، post-media، newspaper-covers،
    │           channel-avatars، school-reports، archive-reports (خصوصی)، archive-report-covers،
    │           basirat-course-posters — همه‌ی خصوصی‌ها با signed URL کوتاه‌عمر باز می‌شن
    ▼
design/ita-monitoring-prototype.html  ── فرانت‌اند تک‌فایلی، مستقیم با fetch به PostgREST/Storage وصله
    │
    ▼ (فقط برای ترجمه‌ی هوش‌مصنوعی — نگاه کن به بخش «هوش مصنوعی» پایین)
Supabase Edge Function (supabase/functions/translate) ── درگاه هوش مصنوعی لیارا
```

هیچ بک‌اند سفارشی سنتی (FastAPI و مشابه) وجود نداره — فرانت‌اند مستقیم با Supabase حرف می‌زنه؛ تنها استثنا یه Edge Function سبک (Deno، سمت Supabase) برای ترجمه‌ست، چون کلید هوش مصنوعی نمی‌تونه توی فرانت‌اند هاردکد بشه (بخش «هوش مصنوعی» پایین رو ببین).

**نکته‌ی مهم:** کالکتورها/جاب‌های GitHub Actions فقط از شاخه‌ی `main` اجرا می‌شن (رفتار پیش‌فرض GitHub)، پس هر بار که `scripts/*.py` یا `.github/workflows/*.yml` روی `claude/new-project-8ekywm` تغییر می‌کنه، باید همون تغییر با یه PR جدا به `main` هم sync بشه. **روش این پروژه**: یه branch از `origin/main` بساز (`git checkout -b <شاخه‌جدید> origin/main`)، `origin/claude/new-project-8ekywm` رو کامل داخلش merge کن (`git merge origin/claude/new-project-8ekywm`) — این معمولاً یه عالمه فایل دیگه (فرانت‌اند، migrationها) رو هم میاره چون `main` معمولاً چند PR عقب‌تره؛ اشکالی نداره، این روال استانداردیه که تا الان چندین‌بار همین‌طوری انجام شده (PRهای «sync: به‌روزرسانی main با claude/new-project-8ekywm») — بعد PR بزن به `main`. وگرنه تغییر روی شاخه‌ی زنده می‌مونه ولی هیچ‌وقت واقعاً اجرا نمی‌شه.

**نکته‌ی تجربه‌شده:** اولین اجرای `collect_telegram.py` بعد از هر بار خالی‌کردن جدول `posts` (یا اضافه‌شدن کانال جدید) کلی کندتر از اجرای عادیه، چون باید کل بک‌فیل (تا `MESSAGES_PER_CHANNEL_LIMIT=200` پیام قدیمی) رو بگیره و همزمان عکس/فیلم هر پیام رو هم دانلود کنه. `timeout-minutes` این ورک‌فلو **۴۰**ه (هم روی `claude/new-project-8ekywm` هم `main`) که برای یه بک‌فیل کامل کافیه؛ اجراهای بعدی (increment) خیلی سریع‌تر می‌شن.

**نکته‌ی حجم Storage:** پلن رایگان Supabase فقط ۱ گیگابایت Storage می‌ده. باکت `post-media` (عکس/فیلم واقعی پست‌ها) به‌تنهایی بیشترین حجم رو می‌گیره — با حساب سرانگشتی حدود ۱.۲ گیگ/روز جمع‌آوری می‌شه. اگه لازم شد حجم Storage رو دوباره چک کنی، این کوئری رو بده کاربر توی SQL Editor اجرا کنه:
```sql
select bucket_id, count(*) as file_count, round(sum((metadata->>'size')::bigint) / 1024.0 / 1024.0, 1) as size_mb
from storage.objects group by bucket_id order by size_mb desc;
```
(این محیط دسترسی شبکه‌ی مستقیم به دامنه‌ی Supabase رو نداره — نمی‌شه از اینجا مستقیم کوئری زد یا Storage API صدا زد؛ همیشه باید از کاربر خواست خودش توی داشبورد/SQL Editor اجرا کنه و نتیجه رو برگردونه.)

## هوش مصنوعی — ترجمه‌ی اختیاری پست‌ها (اولین Edge Function این پروژه)

دکمه‌ی «ترجمه به فارسی» (فقط تب «وب‌سایت‌ها»، جزئیات کامل رفتار UI توی بخش «اخبار رسمی» پایین‌تره) از یه سرویس هوش مصنوعی واقعی استفاده می‌کنه، نه یه API ترجمه‌ی ساده — کاربر پروژه از **لیارا** (سرویس ایرانی، `ai.liara.ir`، درگاهی سازگار با فرمت OpenAI به مدل‌های مختلف) یه کلید API گرفته.

**چرا Edge Function لازم شد**: کلید API لیارا برخلاف anon key سوپابیس، پولیه و هیچ RLSای ازش محافظت نمی‌کنه — نمی‌شه مثل SUPABASE_ANON_KEY توی فرانت‌اند هاردکدش کرد (هرکسی View Source بزنه می‌تونه بدزدتش). راه‌حل: `supabase/functions/translate` — یه Edge Function (Deno، سمت Supabase) که کلید رو به‌عنوان secret سمت سرور نگه می‌داره و بین فرانت‌اند و لیارا واسطه می‌شه.

**نکات امنیتی مهم طراحی** (اگه فیچر مشابهی بعداً اضافه شد، همین الگو رو تکرار کن):
- فرانت‌اند به Edge Function فقط **`postId`** می‌فرسته، نه خودِ متن — چون اگه متن آزاد قبول می‌کرد، هر کاربر واردشده می‌تونست از تابع به‌عنوان یه دروازه‌ی رایگان به هوش مصنوعی برای هر متن دلخواهی (نه فقط ترجمه‌ی پست‌های واقعی) سوءاستفاده کنه.
- اعتبارسنجی ورود کاربر با پیاده‌سازی جدای JWT انجام نمی‌شه (چون این پروژه JWT سفارشی خودش رو داره، نه Auth استاندارد سوپابیس) — به‌جاش `supabase/functions/_shared/auth.ts` (مشترک، برای Edge Functionهای آینده هم قابل‌استفاده) توکن کاربر رو مستقیم با یه کوئری واقعی به PostgREST (`GET /rest/v1/posts?id=eq.<postId>`) چک می‌کنه؛ همین یه کوئری هم اعتبارسنجی ورود رو انجام می‌ده هم متن واقعی/دست‌نخورده رو برمی‌گردونه.
- با این‌حال، محدودیت **تعداد درخواست در واحد زمان (rate limit)** پیاده نشده — یعنی تئوریاً یه کاربر واردشده (مدیر یا حتی بیننده) می‌تونه پشت‌سرهم پست‌های واقعی رو اسپم-ترجمه کنه و هزینه‌ی حساب لیارا رو بالا ببره. برای یه تیم کوچیک/قابل‌اعتماد داخلی فعلاً قابل‌قبول در نظر گرفته شده؛ اگه لازم شد، باید یه جدول شمارش درخواست اضافه بشه.

**دیپلوی خودکاره، نه دستی**: `.github/workflows/deploy-edge-functions.yml` با هر تغییر توی `supabase/functions/**` (روی همین شاخه‌ی `claude/new-project-8ekywm`) خودش `supabase functions deploy` رو اجرا می‌کنه. ⚠️ چون این ورک‌فلو **push-based**‌ه (نه `schedule`)، برخلاف کالکتورهای cron نیازی به sync جدا با `main` نداره — GitHub محدودیت «فقط از default branch» رو فقط برای تریگر `schedule` اعمال می‌کنه، نه `push`/`workflow_dispatch`.

**دو تا secret که فقط یک‌بار برای همیشه دستی تنظیم شدن** (اگه Edge Function جدیدی اضافه شد، این دو تا از قبل کافیه، نیازی به تنظیم دوباره نیست):
- `LIARA_API_KEY` — توی داشبورد سوپابیس، Project Settings ← Edge Functions ← Secrets. این محیط بهش دسترسی نداره و مقدارش رو نمی‌دونه.
- `SUPABASE_ACCESS_TOKEN` — یه GitHub Secret، از یه توکن **اختصاصی و کم‌دسترس** سوپابیس (Account ← Access Tokens؛ scope: فقط پروژه‌ی این سایت + فقط «Application Services → Edge Functions: Read-write»، نه Full access) — استفاده می‌شه توسط `deploy-edge-functions.yml` برای دیپلوی. ⚠️ **این توکن حدوداً ۹۰ روزه منقضی می‌شه** (سقفی که سوپابیس گذاشته، هیچ گزینه‌ی «بدون انقضا» نداشت) — تاریخ ساخته‌شدنش ۲۹ مرداد/شهریور ۱۴۰۵ (۲۹ اوت ۲۰۲۶) بود؛ حدود اواخر آبان/آذر ۱۴۰۵ (اواخر نوامبر ۲۰۲۶) منقضی می‌شه و باید یه توکن جدید ساخته و جایگزین همین secret بشه، وگرنه دیپلوی خودکار بی‌سروصدا شکست می‌خوره.

## ساختار ریپو

```
db/schema.sql                              اسکیمای پایه (channels, posts, categories, app_config, login/change_password) — دست نزن، رمزها رو ریست می‌کنه اگه دوباره کامل اجرا بشه
db/migration_002_domains_magazines.sql     جدول domains + magazines، پلتفرم website، bucket خصوصی magazines
db/migration_003_storage_grants.sql        grant های schema/table سطح storage به app_admin/app_viewer (بدون این، هر bucket جدید 403 می‌ده)
db/migration_004_magazine_sort_delete.sql  ستون sort_order روی magazines
db/migration_005_magazine_covers.sql       bucket عمومی magazine-covers + policy
db/migration_006_news_sources.sql          ستون region (متنی، بعداً با migration_009 جایگزین شد) روی channels + title روی posts + ۱۰ منبع پیش‌فرض خبری (ایسنا/مهر/العربیه/بی‌بی‌سی فارسی)
db/migration_007_news_membership.sql       سه ستون مستقل show_in_news/show_in_cyberspace/show_in_people روی channels — عضویت هر کانال در هر حوزه دیگه از type/platform حدس زده نمی‌شه
db/migration_008_post_media.sql            ستون‌های media_storage_path/media_source_url/media_fetched_at روی posts + bucket عمومی post-media (دانلود واقعی عکس/فیلم)
db/migration_009_dynamic_regions.sql       جدول regions (پویا، مثل categories) + channels.region_id — جایگزین ستون متنی region با CHECK ثابت (غیر idempotent، فقط یک‌بار اجرا شده)
db/migration_010_newspapers.sql            جدول newspapers + bucket عمومی newspaper-covers (تب «روزنامه‌ها»)
db/migration_011_bale_claims.sql           پلتفرم 'bale' روی channels/posts + کانال پیش‌فرض «رصد شایعات» (@rasadfakenews) برای تب «ادعاها و شایعات»
db/migration_012_channel_avatar.sql        ستون avatar_url روی channels + bucket عمومی channel-avatars (عکس پیش‌فرض کانال برای پست‌های بدون عکس)
db/migration_013_school_reports.sql        جدول school_reports + bucket عمومی school-reports (گالری اسکرین‌شات Power BI برای «برنامه مدارس»)
db/migration_014_school_reports_files.sql  ستون‌های file_type/file_name روی school_reports (پشتیبانی PDF/اکسل، نه فقط عکس)
db/migration_015_people.sql                بخش «افراد و مجموعه‌ها»: person_positions, people, people_positions, professor_specialties, professor_ranks, professors, professor_specialty_links
db/migration_016_archive_reports.sql       جدول archive_reports + bucket خصوصی archive-reports + bucket عمومی archive-report-covers (تب «دیدن سایر بسته‌های تحلیلی»)
db/migration_017_basirat_courses.sql       جدول basirat_courses + bucket عمومی basirat-course-posters (تب/ویجت «بسته‌های آموزش تحلیلی»)
db/migration_018_feedback.sql              جدول feedback (کارت «ثبت نظر و پیشنهاد» صفحه‌ی نخست) — تنها جدول با اجازه‌ی insert برای نقش بیننده
db/migration_019_notify_subscribers.sql    جدول notify_subscribers (کارت «اطلاع از انتشار بسته تحلیلی جریان» صفحه‌ی نخست) — insert برای هر دو نقش app_admin/app_viewer، select/update/delete فقط مدیر
db/migration_020_news_topics.sql           جدول news_topics (اسم + کلیدواژه‌های جدا با ویرگول) — چیپ‌های «موضوع» تب «وب‌سایت‌ها»ی «اخبار رسمی»؛ select هر دو نقش، insert/update/delete فقط مدیر
db/migration_021_current_channel_defaults.sql  به‌روزرسانی لیست کانال‌های پیش‌فرض مطابق وضعیت واقعی (بعد از مهاجرت به پروژه‌ی جدید سوپابیس) — حذف کانال‌های قدیمی migration_006 که دیگه استفاده نمی‌شن + اضافه‌کردن کانال‌های خبری وب‌سایتی/تلگرامی که بعداً از پنل اضافه شده بودن؛ باید بعد از migration_009 (regions) و migration_012 (avatar_url) اجرا بشه
db/seed_telegram_channels.sql              ۴ کانال پیش‌فرض تلگرام
scripts/requirements.txt                   وابستگی‌های مشترک پایتون همه‌ی اسکریپت‌ها (requests, beautifulsoup4, telethon, python-dotenv, feedparser)
scripts/collect_eitaa.py                   کالکتور ایتا
scripts/collect_telegram.py                کالکتور تلگرام (شامل دانلود عکس/فیلم)
scripts/collect_rss.py                     کالکتور RSS سایت‌های خبری (platform=website)
scripts/collect_newspapers.py              کالکتور صفحه‌ی اول روزنامه‌ها از کیوسک جار (jaaar.com/kiosk) — دانلود واقعی عکس، نه hotlink
scripts/collect_bale.py                    کالکتور کانال بله «رصد شایعات» — پارس HTML رندرشده‌ی سمت‌سرور (React Flight payload)، نه API رسمی بله
scripts/cleanup_media.py                   جاب روزانه‌ی پاک‌سازی رسانه‌ی قدیمی‌تر از RETENTION_DAYS از Storage (عکس/فیلم پست‌ها + عکس روزنامه‌ها؛ فعلاً موقتاً ۱ روز)
scripts/telegram_session_to_string.py      ابزار یک‌بارمصرف محلی
.github/workflows/collect-eitaa.yml
.github/workflows/collect-telegram.yml     timeout-minutes: 40 (به‌خاطر بک‌فیل اولیه + دانلود رسانه، نگاه کن به «معماری فعلی»)
.github/workflows/collect-rss.yml
.github/workflows/collect-newspapers.yml
.github/workflows/collect-bale.yml         چندبار در روز (ساعت‌های مشخص به وقت ایران)، timeout-minutes: 15
.github/workflows/cleanup-media.yml
.github/workflows/deploy-edge-functions.yml   push-based (نه schedule)، با تغییر supabase/functions/** خودکار دیپلوی می‌کنه — نگاه کن به بخش «هوش مصنوعی»
supabase/functions/translate/index.ts      Edge Function ترجمه‌ی اختیاری پست‌های تب «وب‌سایت‌ها» (لیارا AI) — بخش «هوش مصنوعی» بالاتر رو ببین
supabase/functions/_shared/auth.ts         اعتبارسنجی مشترک (توکن کاربر → کوئری واقعی PostgREST) برای همه‌ی Edge Functionهای این پروژه
design/ita-monitoring-prototype.html       فرانت‌اند کامل (تک‌فایل HTML/CSS/JS)
design/fonts/                              فونت IRANSansX (وریبل + Regular، وصل با @font-face)
design/images/dashboard-hero.webp          تصویرسازی هرو داشبورد (پس‌زمینه‌ی شفاف)
design/images/domain-icon-{news,cyberspace,schools,people}.webp   آیکون‌های سه‌بعدی illustrated ۴ کارت اصلی
design/images/analysis-illustration.webp   تصویر بخش «بسته تحلیلی جریان»
design/images/basirat-logo.webp            لوگوی مدرسه مجازی بصیرت
.claude/skills/ui-ux-pro-max/              اسکیل طراحی نصب‌شده توسط یک سشن دیگه (چک‌لیست‌های UI/UX)
.claude/skills/animate/                    ساخت انیمیشن CSS/WAAPI از صفر (+ RECIPES.md)
.claude/skills/review-animations/          ریویوی سخت‌گیرانه‌ی کد انیمیشن، جدول Before/After (+ STANDARDS.md)
.claude/skills/improve-animations/         ممیزی کل فایل برای انیمیشن + پلن‌نویسی (+ AUDIT.md، PLAN-TEMPLATE.md)
.claude/skills/find-animation-opportunities/  فقط-خواندنی: جاهایی که باید انیمیت بشن ولی نیستن رو پیدا می‌کنه
.claude/skills/animation-vocabulary/       واژه‌نامه‌ی معکوس اسم افکت‌های انیمیشن
.claude/skills/prototype/                  چند نسخه‌ی متفاوت از یه تکه UI پشت یه پیکر شناور برای مقایسه (+ PICKER.md)
.claude/skills/gsap-core/                  کتابخونه‌ی GSAP — API اصلی (gsap.to/from/fromTo, easing, stagger, matchMedia)
.claude/skills/gsap-timeline/              GSAP — توالی چند انیمیشن (gsap.timeline)
.claude/skills/gsap-scrolltrigger/         GSAP — انیمیشن وابسته به اسکرول (pin, scrub, parallax)
.claude/skills/gsap-plugins/               GSAP — پلاگین‌ها (Flip, Draggable, SplitText, MorphSVG...)
.claude/skills/gsap-utils/                 GSAP — توابع کمکی ریاضی (clamp, mapRange, snap...)
.claude/skills/gsap-performance/           GSAP — بهینه‌سازی (transform/opacity, will-change, quickTo)
```

همه‌ی migration فایل‌ها **باید دستی** توسط کاربر در Supabase SQL Editor اجرا بشن — چیزی خودکار نیست. اگه یه فیچر جدید نیاز به جدول/bucket جدید داره، فایل migration بعدی رو با شماره‌ی بعدی بساز (نه دست‌زدن به قدیمی‌ها).

## جدول‌های دیتابیس (خلاصه)

- **channels**: id, platform (`eitaa`|`telegram`|`website`|`bale`)، username, title, type (`news_agency`|`person`), category_id, **region_id** (FK به `regions`، nullable)، **avatar_url** (عکس پیش‌فرض کانال، migration_012)، **show_in_news / show_in_cyberspace / show_in_people** (boolean، مستقل از هم)، active
- **posts**: id, channel_id, platform, platform_post_id, text, **title** (پست‌های RSS و بله پر می‌کنن)، media_type, **media_storage_path**، **media_source_url** (فقط ایتا)، **media_fetched_at**، posted_at, scraped_at, views, forwards, link — یکتا روی (channel_id, platform_post_id)
- **regions**: id, name, created_at — منطقه‌ی جغرافیایی منبع خبری (پویا، مثل categories؛ migration_009)
- **categories**: id, name, color — دسته‌بندی موضوعی، محور جدا از حوزه‌ی رصد
- **domains**: id, key, name, sort_order — فقط رفرنس/مستندسازی (migration_002)، فرانت‌اند مستقیم از روی `.domain-card`های هاردکد کار می‌کنه، اهمیت عملی نداره.
- **magazines**: id, title, issue_no, publish_date, file_type (`pdf`|`images`), files (jsonb، bucket خصوصی magazines)، cover_url (bucket magazine-covers)، sort_order، uploaded_at — «بسته تحلیلی جریان» خودِ جریان
- **newspapers**: id, slug, title, edition_date, image_url (bucket `newspaper-covers`)، media_storage_path، reader_url، scraped_at — یکتا روی (slug, edition_date)؛ migration_010
- **school_reports**: id, title, image_url, media_storage_path, **file_type** (`image`|`pdf`|`excel`، migration_014)، **file_name**، sort_order, uploaded_at — گالری اسکرین‌شات/فایل Power BI برای «برنامه مدارس»؛ bucket عمومی `school-reports`؛ migration_013/014
- **people / person_positions / people_positions**: افراد (فعالان سیاسی‌اجتماعی) — `people` هر ردیف یک نفر (national_id، city، importance، affiliation، channel_id، notes)؛ `person_positions` سمت‌های پویا و قابل‌مدیریت؛ `people_positions` جدول واسط many-to-many (یک نفر چند سمت)؛ migration_015
- **professors / professor_specialties / professor_ranks / professor_specialty_links**: اساتید سیاسی‌اجتماعی — `professors` هر ردیف یک نفر (national_id، city، institution، rank_id تک‌انتخابی، importance، notes)؛ `professor_specialties` حوزه‌ی تخصصی پویا و **چندانتخابی** (جدول واسط `professor_specialty_links`)؛ `professor_ranks` مرتبه‌ی علمی/حوزوی پویا و تک‌انتخابی؛ migration_015. ⚠️ ستون `national_id` روی هر دو جدول `people`/`professors` طبق تصمیم صریح کاربر برای هر دو نقش (مدیر و بیننده) قابل‌مشاهده‌ست.
- **archive_reports**: id, title, **source_org** (نهاد تولیدکننده)، publish_date, file_type, files (jsonb، bucket خصوصی archive-reports)، cover_url (bucket archive-report-covers)، sort_order، uploaded_at — دقیقاً الگوی `magazines` ولی برای تولیدات تحلیلی نهادهای دیگه (نه خودِ جریان)؛ migration_016
- **basirat_courses**: id, title, description, poster_url (bucket basirat-course-posters)، **external_url** (لینک بیرونی به سایت بصیرت — هیچ فایل واقعی توی Storage خودمون ذخیره نمی‌شه، فقط پوستر+لینک)، sort_order، created_at؛ migration_017
- **app_config**: رمزهای هش‌شده‌ی مدیر/بیننده + رمز JWT (فقط از طریق توابع SECURITY DEFINER قابل‌خوندنه)
- **feedback**: id, name (اختیاری)، message (اجباری)، created_at — کارت «ثبت نظر و پیشنهاد» صفحه‌ی نخست؛ migration_018. ⚠️ **تنها استثنای پروژه**: نقش «بیننده» هم اجازه‌ی insert داره (بقیه‌ی جدول‌ها فقط مدیر می‌نویسه)؛ select/update/delete فقط مدیر.
- **notify_subscribers**: id, phone (با CHECK فرمت `^09[0-9]{9}$`، یکتا)، created_at، notified_at (nullable — آخرین باری که مدیر برایش پیامک دستی فرستاد) — کارت «اطلاع از انتشار بسته تحلیلی جریان» صفحه‌ی نخست؛ migration_019. insert برای هر دو نقش app_admin/app_viewer بازه (چون این کارت پشت ورود به سامانه‌ست، نه صفحه‌ی عمومی)؛ select/update/delete فقط مدیر، از پنل «مدیریت ← خروجی‌گیری».
- **news_topics**: id, name, keywords (متن، کلیدواژه‌ها جدا با ویرگول، مثل «انتخابات, دولت, مجلس»)، sort_order، created_at — موضوعات جستجوی ذخیره‌شده برای تب «وب‌سایت‌ها»ی «اخبار رسمی» (چون طبقه‌بندی خودکار موضوعی روی هر پست هنوز نیست، این یه جایگزین سبک‌تره)؛ migration_020. مدیریت (افزودن/حذف) از پنل «مدیریت ← تنظیمات»؛ select هر دو نقش، insert/update/delete فقط مدیر.

## بخش تحلیلی (`sec-reports`، دیگه تب نداره)

⚠️ قبلاً («مهاجرت کتابخانه‌ی مجلات») سه تب مستقل داشت («مجلات جریان» / «بسته‌های آموزش تحلیلی» / «دیدن سایر بسته‌های تحلیلی») — طبق خواسته‌ی صریح کاربر، دو تای دوم/سوم از اینجا جدا شدن و رفتن به یه بخش کاملاً مستقل به‌اسم **«ضمیمه جریان»** (پایین‌تر ببین). `sec-reports` الان **فقط و فقط «مجلات جریان»** رو داره، بدون هیچ تب‌بندی‌ای — یه پنل‌پیل «بخش تحلیلی» و مستقیم زیرش `#magazine-grid`.

- **«مجلات جریان»** (`#reports-tab-own`): کتابخانه‌ی اصلی مجلات خودِ جریان، جدول `magazines`. بارگذاری: فایل اصلی (PDF یا چند عکس) → bucket خصوصی `magazines`؛ جلد (اختیاری) → bucket عمومی `magazine-covers`. مدیریت (فقط مدیر): حذف (فایل Storage + ردیف با هم)، جابجایی ترتیب.

نمایش فایل اصلی (نه پوستر): مودال تمام‌صفحه (`#magazine-viewer`) — PDF با iframe، عکس با `<img>` (راست‌کلیک/درگ غیرفعال، جلوگیری کامل از دانلود نیست، به کاربر گفته شده).

## بخش «ضمیمه جریان» (`sec-supplement`، بخش مستقل، دو زیرتب)

بخش کاملاً جدا و هم‌سطح با «بخش تحلیلی»، نه زیرمجموعه‌ش (تصمیم صریح کاربر). دسترسی از کارت هومپیج (بالاتر ببین) یا مستقیم `switchSection('supplement')`. تب‌ها (`#supplement-page-tabs`، دلجیت‌شده روی کلیک با `data-supplement-tab`، تابع یکتای `openSupplementTab(tab)` هم از کد هم از هومپیج صداش می‌زنن):

1. **«سایر بسته‌های تحلیلی»** (`data-supplement-tab="archive"`، پیش‌فرض/تب اول): بایگانی تولیدات تحلیلی نهادهای دیگر (نه خودِ جریان)، جدول `archive_reports`. کارت‌ها (`#archive-report-grid`، کلاس `.magazine-card.archive-report-card`) برخلاف بقیه‌ی کارت‌های `.magazine-card`، **زمینه‌ی سفید ندارن** — بدون قاب، مستقیم روی بوم تیره (عیناً `.home-poster-card` هومپیج، رنگ متن‌ها هم به همین خاطر روشنه، نه رنگ تیره‌ی پیش‌فرض `.mag-title`/`.mag-meta`). به‌جای `.mag-icon` کوچیک، یه قاب تصویر جلد بلند دارن (`.archive-report-poster`، aspect-ratio 5/7، `cover_url` واقعی یا آیکون جایگزین) — عیناً همون تصویری که تو کارسول هومپیج دیده می‌شه. **دکمه‌ی «مشاهده» ندارن** — کلیک روی خودِ تصویر جلد فایل رو باز می‌کنه (`openArchiveReportFile`)؛ کنترل‌های مدیریتی (جابجایی/حذف) فقط برای مدیر می‌مونن.
2. **«بسته‌های آموزشی»** (`data-supplement-tab="basirat"`، تب دوم): بسته‌های آموزشی مدرسه مجازی بصیرت — عنوان، توضیح کوتاه، پوستر (`.basirat-poster`، aspect 16/9)، لینک بیرونی «مشاهده در بصیرت». جدول `basirat_courses`. دست‌نخورده مونده (زمینه‌ی سفید `.magazine-card` معمولی رو داره، مثل قبل).

هر دو تب پنل بارگذاری مخصوص خودشون رو دارن (`#archive-report-upload-panel` / `#basirat-upload-panel`، فقط مدیر).

## بخش «اخبار رسمی» (`sec-overview`، پنج تب واقعی + سه placeholder)

- **تب‌ها** (`.news-page-tabs` بالای صفحه): «شبکه‌های اجتماعی» (`study`، پیش‌فرض)، «وب‌سایت‌ها» (`website`)، «روزنامه‌ها» (`newspapers`، جزئیات پایین‌تر)، «ادعاها و شایعات» (`claims`) — چهارتا فعالن؛ «پرونده ویژه»، «خبرخوان مدارس»، «آنالیز» غیرفعال با نشان «به‌زودی». `setNewsPageTab(tab)` جابه‌جا می‌کنه.
- **عضویت کانال در این صفحه**: `newsChannels()` = `CHANNELS.filter(c => c.show_in_news)`. مستقل از «کنشگری مجازی» (`show_in_cyberspace`). از پنل «مدیریت کانال‌ها» با سه چک‌باکس مستقل کنترل می‌شه.
- **تب «ادعاها و شایعات» (`claims`)**: فیلتر می‌کنه روی `platform === 'bale'` (فقط کانال «رصد شایعات»، migration_011). متن پست‌ها با `claimsTextDisplay()` و کلاس `.claims-text` (کلمپ ۴ خطی، متفاوت از بقیه‌ی تب‌ها) نمایش داده می‌شه چون ساختار پست‌های این کانال (موضوع/الگوی انتشار/رسانه‌های منتشرکننده) با بقیه فرق داره — `collect_bale.py` قبلاً موضوع رو جدا کرده و `posts.title` گذاشته.
- **ردیف فیلترها** (`newsState = {region, time, sources, query, page, dateFrom, dateTo}`):
  - **زمان** (`#news-time-seg`): دکمه‌های همه/امروز/دیروز/هفته گذشته + `<details id="news-daterange-details">` داخل همون کادر segmented. ⚠️ هندلر `#news-time-seg` باید `!b.dataset.t` رو گارد کنه و `querySelectorAll` رو به `> button` محدود کنه، وگرنه کلیک روی «پاک‌کردن بازه» اشتباه تشخیص داده می‌شه.
  - **منطقه** (`#news-region-row`، `renderNewsRegionChips()`): پویا از جدول `regions`.
  - **منابع** (`#news-source-details`/`#news-source-list`، `populateNewsSourceOptions()`): چندانتخابی.
- **منبع RSS** (`collect_rss.py`، `platform='website'`) هم مثل ایتا/تلگرام/بله پست تولید می‌کنه؛ `posts.title` برای RSS و بله پر می‌شه (ایتا/تلگرام عنوان جدا ندارن).
- **موضوعات جستجوی ذخیره‌شده** (فقط تب «وب‌سایت‌ها»، `#news-topic-filter-row`/`#news-topic-row`، جدول `news_topics`، migration_020): چون طبقه‌بندی خودکار موضوعی روی هر پست هنوز نیست (اون جزو «تحلیل هوش مصنوعی واقعی»ی کارهای آینده‌ست)، این یه جایگزین سبک‌تره — مدیر از پنل «تنظیمات» چندتا موضوع با اسم + کلیدواژه‌های جدا با ویرگول تعریف می‌کنه (`renderTopicGrid()`)؛ کاربر با کلیک روی چیپ هر موضوع (`renderNewsTopicRow()`)، کلیدواژه‌ها خودکار توی همون جستجوی متنی موجود می‌شینه و `filteredNewsPosts()` با **OR** بین کلیدواژه‌ها (نه AND؛ تشخیص با split روی ویرگول) فیلتر می‌کنه؛ تایپ دستی توی سرچ، انتخاب موضوع رو پاک می‌کنه و به چیپ «همه» برمی‌گرده. کنار دکمه‌ی «جستجوی هوشمند» جا گرفته (همون ردیف سرچ‌باکس)، نه یه ردیف جدا؛ ردیف فقط وقتی نمایش داده می‌شه که `newsState.platform === 'website'` باشه و حداقل یه موضوع ذخیره شده باشه (`updateNewsTopicVisibility()`، از `setNewsPageTab()` و `renderNewsTopicRow()` صدا زده می‌شه) — عمداً توی «شبکه‌های اجتماعی»/«ادعاها و شایعات»/«روزنامه‌ها» نیست، چون این فیچر مخصوص مرور مقالات موضوعی سایت‌های خبریه.
- **ترجمه‌ی اختیاری به فارسی** (فقط پست‌های `platform=website`، دکمه‌ی `.news-translate-btn`/`translatePost(id)`، کنار «مشاهده‌ی منبع»): با کلیک، تیتر و متن پست با هوش مصنوعی واقعی (لیارا، مدل `openai/gpt-4o-mini`، از طریق Edge Function — جزئیات کامل معماری/امنیتش توی بخش «هوش مصنوعی» بالاتره؛ نسخه‌ی اولیه از MyMemory استفاده می‌کرد که به‌خاطر محدودیت ۵۰۰ کاراکتری و کیفیت پایین‌تر جایگزین شد) ترجمه و **به‌جای** متن اصلی جایگزین می‌شه (نه زیرش، تا ارتفاع کارت عوض نشه)؛ برای تمایز، رنگ متن/تیتر ترجمه‌شده هلویی (`.is-translated`) می‌شه. کلیک دوباره متن اصلی رو برمی‌گردونه؛ نتیجه توی `NEWS_TRANSLATION_CACHE` (حافظه، نه دیتابیس) کش می‌شه تا toggle رفت‌وبرگشت دوباره درخواست نزنه. بعد از هر جایگزینی، وضعیت «نمایش بیشتر»/کلمپ سه‌خطی دوباره محاسبه می‌شه (`resetNewsTextExpand()` + `updateNewsMoreButtons()`) چون طول متن با ترجمه فرق می‌کنه. عمداً فقط `website` (نه شبکه‌های اجتماعی/ادعاها) چون محتوای اون دو تا معمولاً از قبل فارسیه.

## تب «روزنامه‌ها» (داخل `sec-overview`)

- **دسترسی**: یکی از تب‌های بالای صفحه‌ی اخبار رسمی (بالاتر ببین). `setNewsPageTab('newspapers')`.
- **نمایش**: گرید کاور (`.newspaper-grid`/`.newspaper-card`) از **آخرین تاریخ موجود** توی جدول `newspapers` (نه لزوماً امروز تقویمی). کلیک روی هر کاور با `data-viewer-kind="image"`/`wireMediaViewerClicks()` تمام‌صفحه باز می‌شه.
- **منبع داده**: سایت جار (`jaaar.com/kiosk`) — سمت سرور رندر می‌شه، هر روزنامه یه `div.element-item.issue` با `data-slug` + `img[data-full-image]` + `.actions[data-date]` + `.header .rtl`. دسته‌ی «مجله» (`category-6`) فیلتر می‌شه.
- ⚠️ **عکس hotlink نیست، واقعاً دانلود و در bucket خودمون آپلود می‌شه** (`newspaper-covers`) — همون الگوی `media_storage_path` پست‌ها.
- **پاک‌سازی خودکار**: `cleanup_media.py` نسخه‌های قدیمی‌تر از `RETENTION_DAYS` (فعلاً موقتاً ۱ روز) رو هم از `newspaper-covers` پاک می‌کنه — فقط `image_url`/`media_storage_path` خالی می‌شن، ردیف می‌مونه.
- **ردیف برچسب تاریخ** (`#newspaper-date-tabs`، `renderNewspaperDateTabs()`): همیشه ۲ گزینه‌ی ثابت («امروز»/«دیروز»، آرایه‌ی `slots = [0, 1]`) نشون می‌ده، نه لیست دینامیک از تاریخ‌های موجود — فقط گزینه‌ای که واقعاً توی `NEWSPAPER_DATES` داده داره کلیک‌پذیره (`.news-seg button:disabled` برای بقیه). طبق نکته‌ی عملیاتی ۱۳ بالاتر، وقتی `RETENTION_DAYS` به ۳ برگرده، این آرایه هم باید به `[0, 1, 2]` برگرده.

## بخش «افراد و مجموعه‌ها» (`sec-people`، کامل پیاده‌سازی شده)

- **دسترسی**: تب‌های بالای صفحه (`#people-top-tabs`، دلجیت‌شده روی کلیک با `data-people-tab`، **تابع مستقل ندارن** — برای اسکریپت شبیه‌سازی کلیک باید `.click()` روی دکمه‌ی موردنظر صدا زده بشه): «اساتید سیاسی‌اجتماعی» (`professors`، پیش‌فرض)، «فعالان سیاسی‌اجتماعی» (`activists`)، «آنالیز» (`analytics`) فعال؛ «شرکت‌کننده در برنامه‌ها» و «جامعه مخاطب» هنوز غیرفعال («به‌زودی» — این دو دسته و «تشکل‌ها/مجموعه‌ها» عمداً بعداً پیاده می‌شن، وقتی زیرشاخه‌هاشون مشخص بشه).
- **تب فعالان**: نمایش جدولی از `people`، سمت (`person_positions`، چندانتخابی many-to-many) نمایش داده می‌شه. ستون **کد ملی** قابل‌مشاهده برای هر دو نقش (تصمیم صریح کاربر).
- **تب اساتید**: نمایش جدولی از `professors` — دانشگاه/حوزه (`institution`)، حوزه‌ی تخصصی (`professor_specialties`، چندانتخابی)، مرتبه‌ی علمی/حوزوی (`professor_ranks`، تک‌انتخابی). کد ملی اینجا هم قابل‌مشاهده.
- **بارگذاری گروهی از اکسل**: هم برای فعالان هم اساتید، ستون‌ها به ترتیب ثابت (بدون سرستون).
- **تب آنالیز**: آمار تجمیعی + نمودار میله‌ای از هر دو جدول.

## بخش «برنامه مدارس» (`sec-schools`، کامل پیاده‌سازی شده — گالری Power BI)

- تصمیم نهایی: تحلیل واقعی مدارس همچنان توی خودِ Power BI کاربر انجام می‌شه (نه اینکه داده‌ی خام وارد Supabase بشه) — فقط نتیجه‌ی نهایی به‌صورت اسکرین‌شات/فایل از پنل مدیریت آپلود و به‌شکل گالری نمایش داده می‌شه.
- **آپلود**: تصویر، PDF، یا اکسل (`file_type`). عنوان اختیاری (پیش‌فرض «گزارش بدون عنوان» اگه خالی بمونه). نام خام فایل هیچ‌جا نشون داده نمی‌شه، فقط عنوانی که مدیر تایپ کرده.
- **نمایش**: عکس‌ها تمام‌عرض و پشت‌سرهم روی خودِ صفحه (نه گرید thumbnail که نیاز به کلیک داشته باشه)؛ PDF/اکسل به‌شکل کارت فایل فشرده که در تب جدید باز می‌شه.
- **آمار مرتبط**: `schoolsCount = 126` روی هرو صفحه نخست (بالاتر ببین) — دستی، نه از این جدول محاسبه می‌شه.

## جزئیات مهم طراحی (برای هماهنگی سشن‌های بعدی)

- **سیستم بصری کل اپ**: «کارت روشن شناور روی بوم تیره‌ی یکپارچه». اکثر پنل/کارت محتوا (`.panel`, `.stat-card`, `.magazine-card`, کارت‌های ورود) یک سطح روشن (`var(--surface)`) شناور روی بوم تیره دارن. **استثنا**: کارت‌های صفحه‌ی نخست (`.domain-card`، `.quicknav-card`) هیچ قاب/پس‌زمینه‌ای ندارن (به‌جز `.quicknav-card` که سطح روشن داره، برخلاف `.domain-card`) — این تصمیم قطعیه، اگه جای دیگه‌ای اشاره‌ای متفاوت دیدی منسوخه. رنگ اصلی برند (سرمه‌ای #16202a + هلویی #EAB393) عوض نشده.
- **الگوی `scroll-margin-top`**: برای هر عنصری که مقصد یه اسکرول برنامه‌ای (`scrollIntoView`) می‌شه، به‌جای `block:'start'` خام (که دقیقاً می‌چسبونتش به لبه‌ی بالای viewport)، `scroll-margin-top` روی خودِ عنصر بذار تا یه فاصله‌ی قابل‌کنترل از بالا بمونه. این الگو الان روی `.section-label` (۱۴۰px) و `.package-card` (۹۰px) استفاده شده.
- **باگ رفع‌شده**: قانون CSS `#view-login{ display:flex }` روی خودِ ID باعث می‌شد صفحه‌ی ورود همیشه نمایش داده بشه، مستقل از کلاس `active`. الان `#view-login.active`ه.
- تصویرسازی هرو داشبورد (`design/images/dashboard-hero.webp`) عمداً **پس‌زمینه‌ی شفاف** داره — هیچ‌وقت با فایل تخت‌رنگ جایگزینش نکن.
- بخش «داشبورد» همه‌جا به «صفحه نخست» تغییر نام داده. فقط شناسه‌های داخلی کد (`sec-dashboard`, `switchSection('dashboard')`, کلید `dashboard` در `TITLES`) هنوز انگلیسی/قدیمی‌ان — عمداً دست نخورده.
- کارت‌های «اخبار رسمی»/«برنامه مدارس» هنوز از کلید‌های داخلی قدیمی استفاده می‌کنن (`overview`/`schools`) — اسم نمایشی به‌روزه، id/key کد نه، عمداً.
- Storage bucketهای خصوصی (`magazines`, `archive-reports`) با **signed URL کوتاه‌عمر (۶۰ ثانیه)** باز می‌شن؛ bucketهای عمومی مستقیم با URL ثابت.
- **همه‌ی ۴ آیکون کارت اصلی الان فایل تصویر واقعی‌ان** (`.webp`) — دیگه SVG گرادیانی دستی نیستن، اون روش منسوخه.

## نکات مهم عملیاتی (حتماً بخون قبل از کار)

1. **تمام تغییرات باید از مسیر شاخه‌ی جدید + Pull Request به `claude/new-project-8ekywm` برن** (نه push مستقیم — مسدوده؛ نه PR به `main`). قبل از هر مرج، `get_commits` رو چک کن که کامیت درست توی PR هست؛ بعد از مرج، `git fetch` + `git diff` (zero-diff) تأیید کن که واقعاً نشسته.
2. **قبل از هر تغییر UI، پیش‌نمایش Playwright بگیر و اسکرین‌شات رو با `SendUserFile` برای تأیید صریح کاربر بفرست** — فقط بعد از تأیید کلامی کاربر commit/push/PR/merge کن. الگوی پیش‌نمایش بالاتر توضیح داده شده (⚠️ حتماً همه‌ی `loadX` override بشه، وگرنه صفحه‌ی ورود جای داشبورد می‌مونه).
3. **اگه کاربر عکسی رو مستقیم توی چت paste کنه (نه پیوست `@`)**، اول با جست‌وجوی ترنسکریپت سشن (`.jsonl`، بلوک‌های base64 `image`) امتحان کن استخراجش کنی. فقط اگه واقعاً پیدا نشد، از کاربر بخواه به‌عنوان پیوست واقعی دوباره بفرسته.
4. **رمزهای عبور/کلیدهای حساس هرگز نباید توی چت گفته بشن** — `ADMIN_PASSWORD`، `TG_SESSION`، `TG_API_HASH`، رمز دیتابیس Supabase، JWT secret، `LIARA_API_KEY` (secret سمت سوپابیس) و `SUPABASE_ACCESS_TOKEN` (GitHub Secret، برای دیپلوی خودکار Edge Function — بخش «هوش مصنوعی» رو ببین) همه جای امن نگه داشته می‌شن، من هیچ‌کدومشون رو نمی‌دونم و نباید بخوام بدونم.
5. **`SUPABASE_URL` و `SUPABASE_ANON_KEY` محرمانه نیستن** — هاردکد شدن توی فرانت‌اند، چون anon key عمومیه و RLS امنیتش رو تضمین می‌کنه. با این‌حال، این محیط (Claude Code remote sandbox) دسترسی شبکه‌ی مستقیم به دامنه‌ی Supabase رو **نداره** (سیاست شبکه‌ی سشن مسدودش می‌کنه) — برای هر بررسی داده‌ی زنده باید از کاربر خواست خودش کوئری/چک رو انجام بده (SQL Editor یا داشبورد Storage/Usage).
6. **کالکتورها/جاب‌های GitHub Actions فقط از `main` اجرا می‌شن** — پس هر تغییر توی `scripts/*.py` یا `.github/workflows/*.yml` باید علاوه بر merge به `claude/new-project-8ekywm`، با یه PR جدا هم به `main` sync بشه (روش دقیق توی «معماری فعلی» بالاتر — کل شاخه merge می‌شه، نه فقط فایل مورد نظر).
7. کاربر با گیت/GitHub خیلی راحت نیست — هر مرحله دقیق و مرحله‌به‌مرحله توضیح داده بشه. برای دیباگ خطاهای Supabase/Storage: F12 → Network → کلیک روی درخواست قرمز → تب Response. نکته: DevTools کاربر گاهی پاسخ‌ها رو زود از حافظه پاک می‌کنه؛ بگو لاگ رو Clear کنه و یه‌بار امتحان کنه.
8. کاربر اسکیل `ui-ux-pro-max` نصب کرده. پیشنهادهای رنگ/فونتِ خودکارش با هویت بصری این پروژه نمی‌خونه — فقط چک‌لیست‌های تخصصی‌ش (دسترس‌پذیری، تعامل، تایپوگرافی) رو استفاده کن.
9. **Artifact محدودیت داره** برای این پروژه: فونت‌های relative path لود نمی‌شن و CSP جلوی فراخوانی Supabase رو می‌گیره. برای نسخه‌ی کاملاً واقعی، لینک GitHub Pages بده؛ برای پیش‌نمایش سریع بدون داده‌ی واقعی، از روش Playwright+موک بالا استفاده کن.
10. جهت فلش‌های کاروسل مجلات **حل شده** — اگه کسی گفت برعکسه، اول با تست خودکار (Playwright، چک `scrollLeft` واقعی) دوباره تأیید کن قبل از تغییر کورکورانه‌ی `dir`.
11. **قبل از ساختن هر Storage bucket جدید**، علاوه بر RLS policy، grant سطح schema/table هم لازمه (migration_003) — یه‌بار برای کل schema `storage` انجام شده، برای bucketهای بعدی فقط RLS policy مخصوص همون bucket رو بنویس.
12. **کارت «کنشگری مجازی» فعلاً تصمیم موقته**: کلیک روی کارت می‌بره به `posts` مستقیم. صفحه‌ی `posts` الان خودش دو تب داره («پست‌های منتشر شده» فعال، «آنالیز» غیرفعال) ولی هنوز یه hub مستقل کامل نیست.
13. ⚠️ **`RETENTION_DAYS` توی `scripts/cleanup_media.py` موقتاً از ۳ به ۱ روز کم شده** (۲۶ شهریور ۱۴۰۵، بعد از ایمیل هشدار Fair Use پلن رایگان Supabase). دلیل: باکت `post-media` با پنجره‌ی ۳ روزه حدود ۳.۵ گیگابایت می‌شد (سقف پلن رایگان Storage فقط ۱ گیگابایته)؛ جاب پاک‌سازی خودش سالم بود، فقط حجم روزانه‌ی جمع‌آوری‌شده (~۱.۲ گیگ/روز) با پنجره‌ی ۳ روزه همخونی نداشت. **این تغییر موقتیه** — بعد از تصمیم مهاجرت (ارتقا به Supabase Pro یا مهاجرت به VPS شخصی) باید `RETENTION_DAYS` توی هر دو شاخه به ۳ برگرده. ⚠️ **وابستگی فراموش‌نشدنی**: به همین دلیل، ردیف برچسب تاریخ توی تب «روزنامه‌ها» (`renderNewspaperDateTabs()`، تابع JS توی فرانت‌اند) هم فعلاً فقط ۲ گزینه‌ی ثابت («امروز»/«دیروز»، آرایه‌ی `slots = [0, 1]`) نشون می‌ده، چون «۲ روز قبل» با این تنظیم همیشه بدون داده بود. وقتی `RETENTION_DAYS` به ۳ برگرده، این آرایه هم باید به `[0, 1, 2]` برگرده تا «۲ روز قبل» دوباره قابل‌انتخاب بشه.
14. ⚠️ **منسوخ/تاریخی**: قبلاً «بخش تحلیلی» (`sec-reports`) سه تب مستقل داشت و توابع `openReportsBasiratTab()`/`openReportsArchiveTab()` مستقیم صفحه‌ی نخست رو بهشون می‌بردن. الان **دیگه این‌طوری نیست** — `sec-reports` فقط «مجلات جریان» رو داره (بدون تب)، و دو تب دیگه به یه بخش کاملاً مستقل به‌اسم «ضمیمه جریان» (`sec-supplement`) منتقل شدن که تابع یکتای `openSupplementTab(tab)` رو داره. جزئیات کامل توی بخش‌های «بخش تحلیلی» و «بخش ضمیمه جریان» بالاتر.
15. ⚠️ **یادآوری تاریخ‌دار**: `SUPABASE_ACCESS_TOKEN` (GitHub Secret، برای دیپلوی خودکار Edge Function، بخش «هوش مصنوعی» بالاتر) حدود اواخر آبان/آذر ۱۴۰۵ (اواخر نوامبر ۲۰۲۶) منقضی می‌شه — اگه تاریخ سشن از اون گذشته و دیپلوی خودکار (`.github/workflows/deploy-edge-functions.yml`) شکست خورد، اول همینو چک کن؛ باید کاربر یه توکن جدید (با همون scope کم‌دسترس: فقط این پروژه + فقط Edge Functions Read-write) بسازه و جایگزین همین secret کنه.
16. **بسته‌ی اسکیل انیمیشن نصب‌شده (منشأ: فلسفه‌ی طراحی امیل کوالسکی، emilkowal.ski)** — فقط ۶ تای زیر که واقعاً روی استک خالص CSS/JS این پروژه (بدون فریمورک، بدون build) قابل‌اجرا بودن نصب شدن: `animate` (ساخت انیمیشن از صفر)، `review-animations` (ریویوی سخت‌گیرانه‌ی کد انیمیشن)، `improve-animations` (ممیزی کل فایل + پلن‌نویسی)، `find-animation-opportunities` (پیداکردن جاهای بی‌انیمیشن)، `animation-vocabulary` (واژه‌نامه)، `prototype` (چند نسخه‌ی UI پشت یه پیکر برای مقایسه). ⚠️ **این‌ها بخشی از یه بسته‌ی بزرگ‌تر بودن** که عمداً رد شدن چون فرض React/Next.js/npm می‌کردن یا کاملاً بی‌ربط بودن: `apple-design` (فلسفه‌ی فلوئید اپل، نصفش به کتابخونه‌ی Motion/Framer وابسته)، `ask-sonner`+API (راهنمای کتابخونه‌ی toast مخصوص React)، `pick-ui-library` (پیشنهاد کتابخونه‌های npm)، `emil-design-eng` (هم‌پوشان با `review-animations` ولی مثال‌هاش گاهی Framer Motion)، `animate-expo`+RECIPES (React Native/Expo)، `write-swift` (زبان Swift/iOS)، `design-taste-frontend` (React/Next.js/Tailwind v4). **اگه در آینده یکی از این بخش‌های ردشده واقعاً لازم شد** (مثلاً اگه یه‌روز جریان به React/فریمورک مهاجرت کرد، یا نیاز به کتابخونه‌ی toast واقعی شد، یا کدنویسی Swift/iOS واردش شد)، همون اسکیل مربوطه رو با همین الگو (`.claude/skills/<name>/SKILL.md` + فایل‌های همراه) اضافه کن — فایل‌های اصلیشون توی تاریخچه‌ی همین سشن (آپلودهای کاربر در گفتگوی نصب اسکیل) موجودن.
17. **بسته‌ی اسکیل GSAP نصب‌شده (رسمی، از خودِ gsap.com)** — ۶ تای مرتبط با استک جریان نصب شدن: `gsap-core`، `gsap-timeline`، `gsap-scrolltrigger` (به‌خصوص مفید چون صفحه‌ی نخست طولانی و اسکرول‌محوره)، `gsap-plugins`، `gsap-utils`، `gsap-performance`. `gsap-react` و `gsap-frameworks` (مخصوص Vue/Svelte) عمداً رد شدن چون جریان فریمورک نداره. ⚠️ **نکته‌ی مهم نصب**: راهنمای `gsap-plugins` فرض می‌کنه `npm install gsap` دارید — چون جریان بدون build کار می‌کنه، GSAP و پلاگین‌هاش باید از CDN (مثلاً cdnjs) با تگ `<script>` لود بشن، نه با `import`؛ بعد از لود، ثبت پلاگین با همون الگوی خودِ اسکیل (`gsap.registerPlugin(ScrollTrigger)`) طبیعتاً کار می‌کنه چون از global استفاده می‌کنه.

## قدم بعدی (موارد باز — هیچ‌کدوم بدون درخواست صریح کاربر پیش نره)

- **داده‌ی احتمالاً تستی توی مجلات/آرشیو/بصیرت**: قبلاً (چند نسخه پیش) عنوان‌های تستی مثل "d"/"r"/"ds" دیده شده بود؛ از اون‌موقع تعداد مجلات/آرشیو/بسته‌های بصیرت رشد کرده (طبق `dash-hero-stats` و ویجت‌های جدید صفحه نخست) ولی این محیط دسترسی مستقیم به دیتابیس نداره تا تأیید کنه دیتای واقعیه یا نه — اگه کاربر گفت هنوز چیز تستی می‌بینه، از پنل مدیریت مربوطه پاک/جایگزین کن.
- **سه سیستم آیکون متفاوت روی صفحه‌ی نخست** (کارت‌های اصلی سه‌بعدی illustrated / تصویر «بسته تحلیلی جریان» گرادیانی‌تخت / گرید ۱۰تایی خطی تک‌رنگ) — فلگ‌شده، تصمیمی گرفته نشده.
- **«کنشگری مجازی» احتمالاً به یه صفحه‌ی hub مستقل‌تر نیاز داره** (الان دو تب داره ولی تب دومش «آنالیز» هنوز غیرفعاله).
- UI ویرایش نام دسته‌بندی‌های موضوعی (سیاسی/اجتماعی/...) هنوز ساخته نشده.
- تحلیل هوش مصنوعی واقعی روی محتوا (طبقه‌بندی موضوعی خودکار، تحلیل احساسات و مشابه — چیزی که قبلاً برای n8n + Claude API برنامه‌ریزی شده بود) هنوز فقط UI نمونه‌ست. ⚠️ این با فیچر «ترجمه به فارسی» (بخش «هوش مصنوعی» بالاتر) فرق داره — اون یکی الان واقعی و فعاله (لیارا AI، از طریق Edge Function)، فقط محدود به همون یه کاربرد (ترجمه) هست.
- خروجی Excel هنوز کار نمی‌کنه (toast «به‌زودی» می‌ده؛ CSV/JSON واقعیه).
- «شرکت‌کننده در برنامه‌ها» و «جامعه مخاطب» (زیرمجموعه‌های «افراد و مجموعه‌ها») و «تشکل‌ها/مجموعه‌ها» هنوز پیاده نشدن — منتظر مشخص‌شدن زیرشاخه‌هاشون از کاربر (migration_015 رو ببین).
- بحث «مهاجرت به VPS شخصی در برابر ارتقا به Supabase Pro» باز مونده — فوریه چون **Storage** (۱ گیگابایت رایگان) رد شده و باعث کاهش موقت `RETENTION_DAYS` به ۱ روز شده (نکته‌ی عملیاتی ۱۳) — بعد از تصمیم‌گیری، اون مقدار باید به ۳ برگرده.
