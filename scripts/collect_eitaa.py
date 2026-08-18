"""
جمع‌آوری دوره‌ای پست‌های کانال‌های عمومی ایتا و ذخیره در Supabase.
با GitHub Actions طبق زمان‌بندی اجرا می‌شود (نه روی سیستم شخصی).

نیاز به این متغیرهای محیطی دارد (به‌صورت GitHub Secrets تنظیم می‌شوند):
  SUPABASE_URL        مثل https://xxxxx.supabase.co
  SUPABASE_ANON_KEY    کلید anon پروژه (Project Settings → API)
  ADMIN_PASSWORD       همان رمز عبور «مدیر» که در schema.sql تنظیم شد

منطق پارس HTML عیناً از ورک‌فلوی n8n «Eitaa - Multi-channel to Data Table»
گرفته شده.

عکس: با تست روی صفحه‌ی واقعی تأیید شد — لینک عکس روی style attribute
عنصر etme_widget_message_photo_wrap با فرمت
"background-image: url('/download_xxx?token=...')" میاد (با فاصله بعد
از دو‌نقطه، و لینک نسبیه — باید https://eitaa.com جلوش اضافه بشه؛ هر
دو نکته باعث باگ نسخه‌ی اول این فایل بودن، الان فیکس شدن).
فیلم: هنوز روی صفحه‌ی واقعی تست نشده — فرض شده همون کلاس
etme_widget_message_video_player برای تشخیص ویدیو کافیه و فقط تصویر
بندانگشتی (poster) قابل استخراجه، نه خودِ فایل پخش‌شدنی — پس برای
ویدیو media_path همون بندانگشتیه، نه دانلود کامل. اگه اولین ویدیوی
واقعی توی لاگ media_type='video' نگرفت، این فرض هم نیاز به بررسی داره.
"""

import datetime
import os
import re
import sys
import time
from html import unescape

import requests
from bs4 import BeautifulSoup

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_ANON_KEY = os.environ["SUPABASE_ANON_KEY"]
ADMIN_PASSWORD = os.environ["ADMIN_PASSWORD"]

REQUEST_TIMEOUT = 20
POLITE_DELAY_SECONDS = 2
MEDIA_BUCKET = "post-media"
MAX_MEDIA_BYTES = 15 * 1024 * 1024  # ۱۵ مگابایت — برای اینکه فضای Storage/زمان اجرا با فایل‌های خیلی بزرگ پر نشه

POST_ID_RE = re.compile(r'data-post="([^"]+)"')
TEXT_RE = re.compile(r'class="etme_widget_message_text js-message_text"[^>]*>(.*?)</div>', re.S)
BG_IMAGE_RE = re.compile(r"background-image:\s*url\('([^']+)'\)")
TAG_RE = re.compile(r"<[^>]*>")


def strip_tags(html: str) -> str:
    text = TAG_RE.sub(" ", html)
    text = unescape(text)
    return re.sub(r"\s+", " ", text).strip()


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


def fetch_eitaa_channels(token: str) -> list[dict]:
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/channels",
        headers=auth_headers(token),
        params={"platform": "eq.eitaa", "active": "eq.true", "select": "id,username"},
        timeout=REQUEST_TIMEOUT,
    )
    r.raise_for_status()
    return r.json()


def upload_media(token: str, storage_path: str, content: bytes, content_type: str) -> str:
    r = requests.post(
        f"{SUPABASE_URL}/storage/v1/object/{MEDIA_BUCKET}/{storage_path}",
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {token}",
            "Content-Type": content_type or "application/octet-stream",
        },
        data=content,
        timeout=REQUEST_TIMEOUT,
    )
    r.raise_for_status()
    return f"{SUPABASE_URL}/storage/v1/object/public/{MEDIA_BUCKET}/{storage_path}"


def download_and_store_media(token: str, source_url: str, channel_id: int, post_id: str) -> dict | None:
    try:
        resp = requests.get(source_url, timeout=REQUEST_TIMEOUT, stream=True)
        resp.raise_for_status()
        content = resp.content
        if len(content) > MAX_MEDIA_BYTES:
            print(f"    [!] media too big ({len(content)} bytes), skipping download: {source_url}", file=sys.stderr)
            return None
        content_type = resp.headers.get("Content-Type", "image/jpeg")
        ext = ".mp4" if "video" in content_type else ".jpg"
        storage_path = f"eitaa/{channel_id}/{post_id}{ext}"
        public_url = upload_media(token, storage_path, content, content_type)
        return {"media_path": public_url, "media_storage_path": storage_path}
    except Exception as e:
        print(f"    [!] media download failed for {source_url}: {e}", file=sys.stderr)
        return None


def extract_posts(html: str, channel_id: int) -> list[dict]:
    soup = BeautifulSoup(html, "html.parser")
    posts = []
    seen_ids = set()
    for wrap in soup.select(".js-widget_message_wrap"):
        wrap_html = str(wrap)
        post_id_m = POST_ID_RE.search(wrap_html)
        if not post_id_m:
            continue
        post_id = post_id_m.group(1)
        if post_id in seen_ids:
            # پیوندهای فوروارد/پیش‌نمایش گاهی همون data-post رو توی یک بلوک تودرتو
            # تکرار می‌کنن — بدون این فیلتر، upsert روی دو ردیف هم‌آیدی خطا می‌ده.
            continue
        seen_ids.add(post_id)
        text_m = TEXT_RE.search(wrap_html)
        text = strip_tags(text_m.group(1)) if text_m else ""

        # عکس و ویدیو هردو با همین کلاس نمایش داده می‌شن (background-image روی یه
        # لینک/دیو)؛ برای ویدیو این فقط تصویر بندانگشتیه، نه خودِ فایل قابل‌پخش.
        photo_el = wrap.find(class_="etme_widget_message_photo_wrap")
        media_source_url = None
        media_type = None
        if photo_el is not None:
            style = photo_el.get("style", "")
            bg_m = BG_IMAGE_RE.search(style)
            if bg_m:
                media_source_url = bg_m.group(1)
                if media_source_url.startswith("/"):
                    media_source_url = "https://eitaa.com" + media_source_url
                is_video = wrap.find(class_="etme_widget_message_video_player") is not None
                media_type = "video" if is_video else "photo"

        posts.append(
            {
                "channel_id": channel_id,
                "platform": "eitaa",
                "platform_post_id": post_id,
                "text": text,
                "link": f"https://eitaa.com/{post_id}",
                "media_type": media_type,
                "media_source_url": media_source_url,
            }
        )
    return posts


def upsert_posts(token: str, posts: list[dict]) -> None:
    if not posts:
        return
    r = requests.post(
        f"{SUPABASE_URL}/rest/v1/posts",
        headers={**auth_headers(token), "Prefer": "resolution=merge-duplicates,return=minimal"},
        params={"on_conflict": "channel_id,platform_post_id"},
        json=posts,
        timeout=REQUEST_TIMEOUT,
    )
    if not r.ok:
        print(f"    [!] upsert failed: {r.status_code} {r.text[:300]}", file=sys.stderr)


def main() -> None:
    token = login()
    channels = fetch_eitaa_channels(token)
    print(f"[*] {len(channels)} active eitaa channel(s) to scan")

    total_saved = 0
    total_media = 0
    for i, ch in enumerate(channels):
        username = ch["username"]
        channel_id = ch["id"]
        try:
            resp = requests.get(f"https://eitaa.com/{username}", timeout=REQUEST_TIMEOUT)
            resp.raise_for_status()
            posts = extract_posts(resp.text, channel_id)
            for p in posts:
                if p.get("media_source_url"):
                    stored = download_and_store_media(token, p["media_source_url"], channel_id, p["platform_post_id"])
                    if stored:
                        p["media_path"] = stored["media_path"]
                        p["media_storage_path"] = stored["media_storage_path"]
                        p["media_fetched_at"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
                        total_media += 1
            upsert_posts(token, posts)
            total_saved += len(posts)
            print(f"[+] @{username}: {len(posts)} post(s)")
        except Exception as e:
            print(f"[!] @{username}: {e}", file=sys.stderr)

        if i < len(channels) - 1:
            time.sleep(POLITE_DELAY_SECONDS)

    print(f"[done] total posts processed: {total_saved}, media downloaded: {total_media}")


if __name__ == "__main__":
    main()
