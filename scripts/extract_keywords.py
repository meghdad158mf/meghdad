"""
هر ۲ ساعت (مستقل از news-insights) Edge Function «extract-post-keywords» رو
صدا می‌زنه تا برای پست‌های تازه (که هنوز posts.ai_keywords ندارن) کلیدواژه‌ی
هوش مصنوعی استخراج و ذخیره بشه — پایه‌ی تطبیق خودکار موضوعات «پرونده ویژه».

چرا مستقل از news-insights: اون هر ۶ ساعت اجرا می‌شه ولی کالکتورهای اصلی
(collect-eitaa/collect-telegram/collect-rss) هر ۲ ساعت پست تازه میارن؛ اگه
استخراج کلیدواژه به کرون ۶ساعته گره بخوره، پست‌های تازه تا ۶ ساعت بدون
کلیدواژه می‌مونن و هر اجرا هم باید دسته‌ی بزرگ‌تری رو پردازش کنه. این
اسکریپت زمان‌بندی جدای خودش رو داره (.github/workflows/extract-keywords.yml)
که عمداً دقیقاً وسط فاصله‌ی دو اجرای متوالی کالکتورها قرار گرفته تا تداخل
نداشته باشن.

resumable به‌طور طبیعی: Edge Function همیشه قدیمی‌ترین پست‌های
ai_keywords IS NULL رو می‌گیره (نه فقط پست‌های اخیر) — اگه یه اجرا fail
بشه، اجرای بعدی خودکار از همونجا ادامه می‌ده، هیچ پستی جا نمی‌مونه.

نیاز به این متغیرهای محیطی دارد (GitHub Secrets، از قبل برای بقیه هم
استفاده می‌شن):
  SUPABASE_URL, SUPABASE_ANON_KEY, ADMIN_PASSWORD
"""

import os
import sys

import requests

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_ANON_KEY = os.environ["SUPABASE_ANON_KEY"]
ADMIN_PASSWORD = os.environ["ADMIN_PASSWORD"]

REQUEST_TIMEOUT = 120  # پاسخ هوش مصنوعی روی دسته‌ای از پست‌ها ممکنه چند ثانیه طول بکشه
BATCH_LIMIT = 30


def login() -> str:
    r = requests.post(
        f"{SUPABASE_URL}/rest/v1/rpc/login",
        headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
        json={"password": ADMIN_PASSWORD},
        timeout=30,
    )
    r.raise_for_status()
    return r.json()["token"]


def main() -> None:
    token = login()
    r = requests.post(
        f"{SUPABASE_URL}/functions/v1/extract-post-keywords",
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        json={"limit": BATCH_LIMIT},
        timeout=REQUEST_TIMEOUT,
    )
    if not r.ok:
        print(f"[!] extract-post-keywords failed: {r.status_code} {r.text[:500]}", file=sys.stderr)
        sys.exit(1)
    data = r.json()
    print(f"[done] {data.get('processed', 0)} post(s) keyworded, {data.get('matched', 0)} dossier match(es)")


if __name__ == "__main__":
    main()
