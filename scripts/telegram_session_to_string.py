"""
ابزار یک‌بارمصرف — فقط روی سیستم شخصی (همان‌جایی که session_collector.session
از قبل لاگین شده وجود دارد) اجرا کنید، نه در GitHub Actions.

فایل session باینری فعلی را به یک رشته‌ی متنی (StringSession) تبدیل می‌کند تا
بشود آن را به‌صورت یک GitHub Secret (متنی) ذخیره کرد؛ بعد از اجرای این اسکریپت
دیگر نیازی به خودِ فایل .session نیست.

اجرا:
    pip install telethon python-dotenv
    python scripts/telegram_session_to_string.py
"""

import os

from dotenv import load_dotenv
from telethon.sync import TelegramClient
from telethon.sessions import StringSession

load_dotenv()

API_ID = int(os.environ["TG_API_ID"])
API_HASH = os.environ["TG_API_HASH"]
OLD_SESSION_NAME = "session_collector"  # همون فایل session_collector.session

with TelegramClient(OLD_SESSION_NAME, API_ID, API_HASH) as client:
    string_session = StringSession.save(client.session)
    print("\n=== این رشته را به‌عنوان GitHub Secret به اسم TG_SESSION ذخیره کنید ===\n")
    print(string_session)
    print("\n========================================================================\n")
