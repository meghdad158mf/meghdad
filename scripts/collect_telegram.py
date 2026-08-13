"""
جمع‌آوری دوره‌ای پیام‌های کانال‌های تلگرام و ذخیره در Supabase.
با GitHub Actions طبق زمان‌بندی اجرا می‌شود — نه یک listener همیشه‌روشن،
بلکه هر بار فقط پیام‌های جدیدتر از آخرین پیامِ ذخیره‌شده‌ی هر کانال را می‌گیرد.

نیاز به این متغیرهای محیطی دارد (GitHub Secrets):
  SUPABASE_URL        مثل https://xxxxx.supabase.co
  SUPABASE_ANON_KEY    کلید anon پروژه
  ADMIN_PASSWORD       رمز عبور «مدیر»
  TG_API_ID            از my.telegram.org
  TG_API_HASH
  TG_SESSION            رشته‌ی خروجی scripts/telegram_session_to_string.py
"""

import asyncio
import os
import sys

import requests
from telethon import TelegramClient
from telethon.sessions import StringSession
from telethon.tl.types import MessageMediaPhoto, MessageMediaDocument

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_ANON_KEY = os.environ["SUPABASE_ANON_KEY"]
ADMIN_PASSWORD = os.environ["ADMIN_PASSWORD"]
TG_API_ID = int(os.environ["TG_API_ID"])
TG_API_HASH = os.environ["TG_API_HASH"]
TG_SESSION = os.environ["TG_SESSION"]

REQUEST_TIMEOUT = 20
MESSAGES_PER_CHANNEL_LIMIT = 200  # سقف ایمنی برای هر اجرا، در حالت عادی خیلی کمتره


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


def fetch_telegram_channels(token: str) -> list[dict]:
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/channels",
        headers=auth_headers(token),
        params={"platform": "eq.telegram", "active": "eq.true", "select": "id,username"},
        timeout=REQUEST_TIMEOUT,
    )
    r.raise_for_status()
    return r.json()


def fetch_last_post_id(token: str, channel_id: int) -> int:
    # platform_post_id is TEXT (shared with eitaa's non-numeric ids), so it can't
    # be sorted numerically in SQL — order by posted_at instead, which is a real
    # timestamptz and reflects the same chronological order for telegram messages.
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/posts",
        headers=auth_headers(token),
        params={
            "channel_id": f"eq.{channel_id}",
            "platform": "eq.telegram",
            "select": "platform_post_id",
            "order": "posted_at.desc",
            "limit": "1",
        },
        timeout=REQUEST_TIMEOUT,
    )
    r.raise_for_status()
    rows = r.json()
    return int(rows[0]["platform_post_id"]) if rows else 0


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


def media_type_of(msg) -> str | None:
    if not msg.media:
        return None
    if isinstance(msg.media, MessageMediaPhoto):
        return "photo"
    if isinstance(msg.media, MessageMediaDocument):
        return "document"
    return "other"


async def collect_channel(client: TelegramClient, token: str, channel: dict) -> int:
    username = channel["username"]
    channel_id = channel["id"]
    last_id = fetch_last_post_id(token, channel_id)

    posts = []
    async for msg in client.iter_messages(username, min_id=last_id, limit=MESSAGES_PER_CHANNEL_LIMIT):
        posts.append(
            {
                "channel_id": channel_id,
                "platform": "telegram",
                "platform_post_id": str(msg.id),
                "text": msg.message or "",
                "media_type": media_type_of(msg),
                "views": getattr(msg, "views", 0) or 0,
                "forwards": getattr(msg, "forwards", 0) or 0,
                "posted_at": msg.date.isoformat() if msg.date else None,
            }
        )

    upsert_posts(token, posts)
    return len(posts)


async def main() -> None:
    token = login()
    channels = fetch_telegram_channels(token)
    print(f"[*] {len(channels)} active telegram channel(s) to scan")

    async with TelegramClient(StringSession(TG_SESSION), TG_API_ID, TG_API_HASH) as client:
        total = 0
        for channel in channels:
            try:
                n = await collect_channel(client, token, channel)
                total += n
                print(f"[+] @{channel['username']}: {n} new message(s)")
            except Exception as e:
                print(f"[!] @{channel['username']}: {e}", file=sys.stderr)

    print(f"[done] total new messages: {total}")


if __name__ == "__main__":
    asyncio.run(main())
