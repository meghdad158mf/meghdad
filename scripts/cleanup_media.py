"""
پاک‌سازی روزانه‌ی عکس/فیلم‌های قدیمی‌تر از RETENTION_DAYS روز از Supabase Storage.
با GitHub Actions یک‌بار در روز اجرا می‌شود.

چرا: عکس و فیلم برخلاف متن پست حجم زیادی می‌گیرن و فضای Storage
Supabase محدوده. به‌جای نگه‌داشتن همیشگی، فقط چند روز اخیر نگه داشته
می‌شه (فعلاً موقتاً ۱ روز، نگاه کن به کامنت بالای RETENTION_DAYS)؛
media_type روی پست دست‌نخورده می‌مونه (تا UI بدونه رسانه‌ای
وجود داشته)، فقط media_path/media_storage_path/media_fetched_at پاک
می‌شن. برای ایتا media_source_url (لینک اصلی) نگه داشته می‌شه — اگه
همون پست هنوز توی صفحه‌ی عمومی کانال باشه، اجرای بعدی collect_eitaa.py
دوباره دانلودش می‌کنه؛ برای تلگرام چون کالکتور فقط پیام‌های تازه رو
می‌گیره (نه قدیمی‌ها رو دوباره)، رسانه‌ی منقضی‌شده‌ی تلگرام دیگه
خودکار بازیابی نمی‌شه.

همین منطق برای عکس صفحه‌ی اول روزنامه‌ها (bucket newspaper-covers) هم
تکرار شده — چون تب «روزنامه‌ها» فقط آخرین تاریخ موجود رو نشون می‌ده،
پاک‌شدن نسخه‌های قدیمی‌تر روی چیزی که کاربر می‌بینه اثر نداره؛ فقط
عنوان/تاریخ/اسلاگ ردیف نگه داشته می‌شه، نه خودِ عکس.

نیاز به این متغیرهای محیطی دارد (GitHub Secrets):
  SUPABASE_URL, SUPABASE_ANON_KEY, ADMIN_PASSWORD
"""

import datetime
import os
import sys

import requests

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_ANON_KEY = os.environ["SUPABASE_ANON_KEY"]
ADMIN_PASSWORD = os.environ["ADMIN_PASSWORD"]

REQUEST_TIMEOUT = 30
MEDIA_BUCKET = "post-media"
NEWSPAPER_BUCKET = "newspaper-covers"
# موقتاً از ۳ به ۱ روز کم شده بود (۲۶ شهریور ۱۴۰۵) چون post-media به‌تنهایی
# با پنجره‌ی ۳ روزه حدود ۳.۵ گیگ می‌شد. بعد از مهاجرت به پروژه‌ی جدید
# سوپابیس (۱۵ شهریور ۱۴۰۵)، معلوم شد حتی ۱ روز هم کافی نیست — همون
# پروژه‌ی تازه‌ی رایگان با فقط چند ساعت جمع‌آوری به بیش از ۱ گیگ Storage
# رسید (۷۶۸ فایل، ~۱۰۱۷ مگابایت فقط توی post-media). برای همین موقتاً
# به نصف روز (۱۲ ساعت) کم شده. ⚠️ برای posts (که datetime کامل با ساعت
# دارن) این عدد دقیق اعمال می‌شه؛ برای newspapers (که فقط تاریخ روز رو
# دارن، بدون ساعت) چون date - timedelta(days=0.5) در پایتون به ۰ روز
# گرد می‌شه، عملاً همون رفتار «۱ روز» رو حفظ می‌کنه — تفاوتی نداره،
# چون دقت روزنامه‌ها همین‌قدر خودش روزانه‌ست. بعد از تصمیم نهایی
# زیرساخت (ارتقا به Pro یا VPS شخصی) این عدد باید به ۳ برگرده.
RETENTION_DAYS = 0.5


def login() -> str:
    r = requests.post(
        f"{SUPABASE_URL}/rest/v1/rpc/login",
        headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
        json={"password": ADMIN_PASSWORD},
        timeout=REQUEST_TIMEOUT,
    )
    r.raise_for_status()
    return r.json()["token"]


def auth_headers(token: str) -> dict:
    return {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }


def remove_storage_objects(token: str, bucket: str, paths: list[str]) -> bool:
    """حذف واقعی فایل‌ها از Storage. مسیر درست حذف گروهی متد DELETE روی
    /object/{bucket} است (نه POST به /object/remove/{bucket} — اون یه
    مسیر نامعتبره که «remove» رو به‌جای اسم باکت تفسیر می‌کنه و همیشه
    با «Bucket not found» شکست می‌خوره، بدون این‌که چیزی واقعاً حذف بشه).
    خروجی bool تا caller بدونه واقعاً حذف انجام شده یا نه — چون اگه این
    حذف fail بشه ولی رکورد دیتابیس پاک بشه، فایل برای همیشه orphan
    می‌مونه (رد دیتابیسی‌اش از دست می‌ره ولی خودش توی Storage جا می‌مونه).
    """
    if not paths:
        return True
    r = requests.delete(
        f"{SUPABASE_URL}/storage/v1/object/{bucket}",
        headers=auth_headers(token),
        json={"prefixes": paths},
        timeout=REQUEST_TIMEOUT,
    )
    if not r.ok:
        print(f"[!] storage remove failed ({bucket}): {r.status_code} {r.text[:300]}", file=sys.stderr)
        return False
    return True


def fetch_expired_posts(token: str) -> list[dict]:
    cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=RETENTION_DAYS)).isoformat()
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/posts",
        headers=auth_headers(token),
        params={
            "media_fetched_at": f"lt.{cutoff}",
            "media_storage_path": "not.is.null",
            "select": "id,media_storage_path",
            "limit": "1000",
        },
        timeout=REQUEST_TIMEOUT,
    )
    r.raise_for_status()
    return r.json()


def clear_post_media(token: str, post_ids: list[int]) -> None:
    if not post_ids:
        return
    ids_list = ",".join(str(i) for i in post_ids)
    r = requests.patch(
        f"{SUPABASE_URL}/rest/v1/posts",
        headers={**auth_headers(token), "Prefer": "return=minimal"},
        params={"id": f"in.({ids_list})"},
        json={"media_path": None, "media_storage_path": None, "media_fetched_at": None},
        timeout=REQUEST_TIMEOUT,
    )
    if not r.ok:
        print(f"[!] clear post media fields failed: {r.status_code} {r.text[:300]}", file=sys.stderr)


def cleanup_post_media(token: str) -> None:
    expired = fetch_expired_posts(token)
    print(f"[*] {len(expired)} post(s) with media older than {RETENTION_DAYS} day(s)")
    if not expired:
        return
    paths = [p["media_storage_path"] for p in expired if p.get("media_storage_path")]
    ids = [p["id"] for p in expired]
    if not remove_storage_objects(token, MEDIA_BUCKET, paths):
        print("[!] skipping DB cleanup for this batch — storage delete failed, retry next run", file=sys.stderr)
        return
    clear_post_media(token, ids)
    print(f"[done] cleaned up {len(expired)} post(s)")


def fetch_expired_newspapers(token: str) -> list[dict]:
    cutoff = (datetime.date.today() - datetime.timedelta(days=RETENTION_DAYS)).isoformat()
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/newspapers",
        headers=auth_headers(token),
        params={
            "edition_date": f"lt.{cutoff}",
            "media_storage_path": "not.is.null",
            "select": "id,media_storage_path",
            "limit": "1000",
        },
        timeout=REQUEST_TIMEOUT,
    )
    r.raise_for_status()
    return r.json()


def clear_newspaper_media(token: str, ids: list[int]) -> None:
    if not ids:
        return
    ids_list = ",".join(str(i) for i in ids)
    r = requests.patch(
        f"{SUPABASE_URL}/rest/v1/newspapers",
        headers={**auth_headers(token), "Prefer": "return=minimal"},
        params={"id": f"in.({ids_list})"},
        json={"image_url": None, "media_storage_path": None},
        timeout=REQUEST_TIMEOUT,
    )
    if not r.ok:
        print(f"[!] clear newspaper media fields failed: {r.status_code} {r.text[:300]}", file=sys.stderr)


def cleanup_newspaper_covers(token: str) -> None:
    expired = fetch_expired_newspapers(token)
    print(f"[*] {len(expired)} newspaper edition(s) older than {RETENTION_DAYS} day(s)")
    if not expired:
        return
    paths = [p["media_storage_path"] for p in expired if p.get("media_storage_path")]
    ids = [p["id"] for p in expired]
    if not remove_storage_objects(token, NEWSPAPER_BUCKET, paths):
        print("[!] skipping DB cleanup for this batch — storage delete failed, retry next run", file=sys.stderr)
        return
    clear_newspaper_media(token, ids)
    print(f"[done] cleaned up {len(expired)} newspaper edition(s)")


def main() -> None:
    token = login()
    cleanup_post_media(token)
    cleanup_newspaper_covers(token)


if __name__ == "__main__":
    main()
