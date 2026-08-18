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


def remove_storage_objects(token: str, paths: list[str]) -> None:
    if not paths:
        return
    r = requests.post(
        f"{SUPABASE_URL}/storage/v1/object/remove/{MEDIA_BUCKET}",
        headers=auth_headers(token),
        json={"prefixes": paths},
        timeout=REQUEST_TIMEOUT,
    )
    if not r.ok:
        print(f"[!] storage remove failed: {r.status_code} {r.text[:300]}", file=sys.stderr)


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
        print(f"[!] clear media fields failed: {r.status_code} {r.text[:300]}", file=sys.stderr)


def main() -> None:
    token = login()
    expired = fetch_expired_posts(token)
    print(f"[*] {len(expired)} post(s) with media older than {RETENTION_DAYS} day(s)")
    if not expired:
        return

    paths = [p["media_storage_path"] for p in expired if p.get("media_storage_path")]
    ids = [p["id"] for p in expired]

    remove_storage_objects(token, paths)
    clear_post_media(token, ids)
    print(f"[done] cleaned up {len(expired)} post(s)")


if __name__ == "__main__":
    main()
