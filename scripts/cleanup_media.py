"""
پاک‌سازی روزانه‌ی عکس/فیلم‌های قدیمی‌تر از ۳ روز از Supabase Storage.
با GitHub Actions یک‌بار در روز اجرا می‌شود.

چرا: عکس و فیلم برخلاف متن پست حجم زیادی می‌گیرن و فضای Storage
Supabase محدوده. به‌جای نگه‌داشتن همیشگی، فقط ۳ روز اخیر نگه داشته
می‌شه؛ media_type روی پست دست‌نخورده می‌مونه (تا UI بدونه رسانه‌ای
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
RETENTION_DAYS = 3


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


def remove_storage_objects(token: str, bucket: str, paths: list[str]) -> None:
    if not paths:
        return
    r = requests.post(
        f"{SUPABASE_URL}/storage/v1/object/remove/{bucket}",
        headers=auth_headers(token),
        json={"prefixes": paths},
        timeout=REQUEST_TIMEOUT,
    )
    if not r.ok:
        print(f"[!] storage remove failed ({bucket}): {r.status_code} {r.text[:300]}", file=sys.stderr)


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
    remove_storage_objects(token, MEDIA_BUCKET, paths)
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
    remove_storage_objects(token, NEWSPAPER_BUCKET, paths)
    clear_newspaper_media(token, ids)
    print(f"[done] cleaned up {len(expired)} newspaper edition(s)")


def main() -> None:
    token = login()
    cleanup_post_media(token)
    cleanup_newspaper_covers(token)


if __name__ == "__main__":
    main()
