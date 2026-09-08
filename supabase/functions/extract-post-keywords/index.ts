// استخراج یک‌باره‌ی کلیدواژه‌ی هوش مصنوعی برای هر پست (پایه‌ی بخش «پرونده ویژه»)
//
// چرا: تب «پرونده ویژه» اخبار مرتبط با موضوعات موقت/چرخشی (مدیر تعیین
// می‌کنه، ممکنه هر چند روز عوض بشه) رو جدا نشون می‌ده. اگه بخوایم هر بار
// موضوعی تعریف/تغییر می‌کنه هوش مصنوعی کل تاریخچه‌ی پست‌ها رو دوباره
// بخونه، هزینه‌ی توکن زیاد می‌شه. به‌جاش هر پست فقط یک‌بار (وقتی
// posts.ai_keywords هنوز NULLه) با هوش مصنوعی به چندتا کلیدواژه‌ی
// فارسی/دقیق/بدون‌ابهام برچسب می‌خوره؛ تطبیق موضوع بعدش فقط یه
// مقایسه‌ی متنی سادهٔ رایگانه (نه هوش مصنوعی).
//
// هر ۲ ساعت، **مستقل** از news-insights (نه هم‌زمان با اون، نه هم‌زمان
// با کالکتورها) از GitHub Actions (scripts/extract_keywords.py، با توکن
// مدیر) صدا زده می‌شه.
//
// resumable + اولویت با تازه‌ها: fetchPostsMissingKeywords همیشه
// جدیدترین پست‌های ai_keywords IS NULL رو می‌گیره (ORDER BY posted_at
// DESC، چون این فیچر روی موضوعات موقت/جاری کار می‌کنه) — اگه یه اجرا
// fail بشه یا نصفه بمونه، اجرای بعدی خودکار همون‌ها رو دوباره امتحان
// می‌کنه؛ backlog قدیمی هم بالأخره (وقتی دیگه پست تازه‌ی بی‌کلیدواژه‌ای
// نمونده) توی اجراهای بعدی پردازش می‌شه.
//
// مثل translate/news-insights: ورودی فقط limit (اختیاری) هست، نه خودِ
// متن — خودِ تابع پست‌های واقعی رو از دیتابیس (با توکن کاربر) می‌خونه، تا
// نتونه دروازه‌ی آزاد هوش مصنوعی برای متن دلخواه بشه.
//
// دیپلوی خودکاره (.github/workflows/deploy-edge-functions.yml) — سکرت‌های
// لازم (LIARA_API_KEY, SUPABASE_ACCESS_TOKEN) از قبل برای translate/
// news-insights تنظیم شدن، نیازی به تنظیم دوباره نیست.

import { fetchPostsMissingKeywords } from "../_shared/auth.ts";

const LIARA_BASE_URL = "https://ai.liara.ir/api/6a9271a1d6564b043acdefe1/v1";
const LIARA_MODEL = "openai/gpt-4o-mini";
const DEFAULT_LIMIT = 40;
const TEXT_TRUNCATE = 400;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    let limit = DEFAULT_LIMIT;
    try {
      const body = await req.json();
      if (body?.limit) limit = Number(body.limit) || DEFAULT_LIMIT;
    } catch {
      // بدنه‌ی خالی هم مجازه — همون پیش‌فرض استفاده می‌شه
    }

    const posts = await fetchPostsMissingKeywords(req, limit);
    if (posts === null) return jsonResponse({ error: "unauthorized" }, 401);
    if (!posts.length) {
      return jsonResponse({ processed: 0, matched: 0, note: "no posts pending" });
    }

    const compact = posts.map((p) => ({
      id: p.id,
      title: p.title || null,
      text: (p.text || "").slice(0, TEXT_TRUNCATE),
    }));

    const liaraKey = Deno.env.get("LIARA_API_KEY");
    const aiRes = await fetch(`${LIARA_BASE_URL}/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${liaraKey}` },
      body: JSON.stringify({
        model: LIARA_MODEL,
        temperature: 0.1,
        messages: [
          {
            role: "system",
            content:
              "You extract keywords from a batch of Persian/English news posts (each with an id, title, text). " +
              "For EVERY post in the batch, without exception, return exactly one entry — never skip a post, " +
              "even if it has no meaningful content (in that case return an empty keywords array for it).\n" +
              "Each entry: {\"id\": <one of the given post ids, exactly>, \"keywords\": [<Persian keyword " +
              "strings>]}.\n" +
              "Rules for keywords:\n" +
              "- Always write keywords in Persian, regardless of the post's original language (translate " +
              "entity/topic names, do not leave them in the source language).\n" +
              "- Cover every important topic, person, and organization mentioned in the post. Do NOT force a " +
              "fixed count — use as many as truly needed to fully capture the post (could be 3, could be 9).\n" +
              "- Each keyword must be self-contained and unambiguous on its own. A bare generic term like " +
              "\"وزارت خارجه\" or \"رئیس‌جمهور\" is NOT acceptable if it could belong to more than one country " +
              "or organization — always specify which one, e.g. \"وزارت خارجه ایران\" vs \"وزارت خارجه آمریکا\", " +
              "\"رئیس‌جمهور ایران\" vs \"رئیس‌جمهور آمریکا\".\n" +
              'Respond with ONLY a raw JSON object like {"results":[{"id":1,"keywords":["..."]}, ...]} and ' +
              "nothing else — no markdown fences, no extra commentary. The results array MUST have exactly one " +
              "entry per input post id, using only ids from the given list.",
          },
          { role: "user", content: JSON.stringify(compact) },
        ],
      }),
    });

    if (!aiRes.ok) {
      const detail = await aiRes.text();
      return jsonResponse({ error: "ai request failed", detail }, 502);
    }

    const aiData = await aiRes.json();
    let content: string = aiData?.choices?.[0]?.message?.content || "{}";
    content = content.trim().replace(/^```json\s*/i, "").replace(/^```\s*/, "").replace(/```\s*$/, "");

    let parsed: { results?: Array<{ id: number; keywords?: string[] }> };
    try {
      parsed = JSON.parse(content);
    } catch {
      parsed = {};
    }

    // اعتبارسنجی: idهای هذیان‌گفته‌شده حذف می‌شن؛ هر id فقط یک‌بار اعمال می‌شه
    const validIds = new Set(posts.map((p) => p.id));
    const results = new Map<number, string[]>();
    for (const r of parsed.results || []) {
      const id = Number(r.id);
      if (!validIds.has(id) || results.has(id)) continue;
      const keywords = Array.isArray(r.keywords)
        ? r.keywords.map((k) => String(k).slice(0, 80)).filter(Boolean).slice(0, 20)
        : [];
      results.set(id, keywords);
    }

    // پست‌هایی که هوش مصنوعی جا انداخته (پاسخ ناقص) رو هم صریح با آرایه‌ی
    // خالی علامت می‌زنیم — طبق طراحی، هیچ پستی نباید بدون رد بمونه، وگرنه
    // NULL می‌مونه و هر اجرا دوباره براش فرستاده می‌شه
    for (const p of posts) {
      if (!results.has(p.id)) results.set(p.id, []);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const authHeader = req.headers.get("Authorization") || "";
    const writeHeaders = {
      apikey: anonKey ?? "",
      Authorization: authHeader,
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    };

    const nowIso = new Date().toISOString();
    let updated = 0;
    for (const [id, keywords] of results) {
      const patchRes = await fetch(`${supabaseUrl}/rest/v1/posts?id=eq.${id}`, {
        method: "PATCH",
        headers: writeHeaders,
        body: JSON.stringify({ ai_keywords: keywords, ai_keywords_extracted_at: nowIso }),
      });
      if (patchRes.ok) updated++;
    }

    // تطبیق خودکار موضوعات فعال «پرونده ویژه» با کلیدواژه‌های تازه —
    // مقایسه‌ی متنی ساده (نه هوش مصنوعی)، برای همین دسته‌ی تازه‌پردازش‌شده
    const topicsRes = await fetch(
      `${supabaseUrl}/rest/v1/dossier_topics?select=id,keywords&active=eq.true`,
      { headers: { apikey: anonKey ?? "", Authorization: authHeader } },
    );
    let matched = 0;
    if (topicsRes.ok) {
      const topics: Array<{ id: number; keywords: string }> = await topicsRes.json();
      const inserts: Array<{ topic_id: number; post_id: number; source: string }> = [];
      for (const topic of topics) {
        const topicKeywords = topic.keywords.split(",").map((k) => k.trim()).filter(Boolean);
        if (!topicKeywords.length) continue;
        for (const [postId, postKeywords] of results) {
          if (!postKeywords.length) continue;
          const hasMatch = topicKeywords.some((tk) =>
            postKeywords.some((pk) => pk.includes(tk) || tk.includes(pk))
          );
          if (hasMatch) inserts.push({ topic_id: topic.id, post_id: postId, source: "auto" });
        }
      }
      if (inserts.length) {
        // on_conflict + resolution=ignore-duplicates: چون همین پست ممکنه
        // قبلاً دستی هم به همین موضوع اضافه شده باشه (unique(topic_id,post_id))
        const insertRes = await fetch(
          `${supabaseUrl}/rest/v1/dossier_topic_posts?on_conflict=topic_id,post_id`,
          {
            method: "POST",
            headers: { ...writeHeaders, Prefer: "resolution=ignore-duplicates,return=minimal" },
            body: JSON.stringify(inserts),
          },
        );
        if (insertRes.ok) matched = inserts.length;
      }
    }

    return jsonResponse({ processed: updated, matched });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
