// ترجمه‌ی تیتر و متن پست‌های تب «وب‌سایت‌ها» به فارسی، از طریق درگاه هوش
// مصنوعی لیارا (Liara AI Gateway، فرمت سازگار با OpenAI). کلید API لیارا
// فقط اینجا (سمت سرور، به‌صورت secret) نگه داشته می‌شه و هیچ‌وقت به
// فرانت‌اند فرستاده نمی‌شه — چون برخلاف anon key سوپابیس، این کلید پولیه
// و هیچ RLSای ازش محافظت نمی‌کنه.
//
// چون این پروژه از یه سیستم لاگین سفارشی (public.login()) با JWT خودش
// استفاده می‌کنه، نه Auth استاندارد سوپابیس، اعتبارسنجی توکن ورودی رو
// به‌جای پیاده‌سازی جدا، با یه کوئری سبک به PostgREST انجام می‌دیم — اگه
// PostgREST توکن رو قبول کنه (یعنی نقش app_admin/app_viewer داره)، معتبره.
//
// دیپلوی: `supabase functions deploy translate --no-verify-jwt`
// (--no-verify-jwt لازمه چون توکن ورودی، JWT استاندارد Auth سوپابیس نیست)
// سکرت لازم: LIARA_API_KEY (از Project Settings → Edge Functions → Secrets)

const LIARA_BASE_URL = "https://ai.liara.ir/api/6a9271a1d6564b043acdefe1/v1";
const LIARA_MODEL = "openai/gpt-4o-mini";

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
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return jsonResponse({ error: "unauthorized" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const authCheck = await fetch(`${supabaseUrl}/rest/v1/categories?select=id&limit=1`, {
      headers: { apikey: anonKey ?? "", Authorization: `Bearer ${token}` },
    });
    if (!authCheck.ok) return jsonResponse({ error: "unauthorized" }, 401);

    const { title, text } = await req.json();
    if (!title && !text) return jsonResponse({ title: "", text: "" });

    const liaraKey = Deno.env.get("LIARA_API_KEY");
    const aiRes = await fetch(`${LIARA_BASE_URL}/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${liaraKey}` },
      body: JSON.stringify({
        model: LIARA_MODEL,
        temperature: 0.2,
        messages: [
          {
            role: "system",
            content:
              'You translate news titles and bodies into fluent, natural Persian (Farsi). ' +
              'Respond with ONLY a raw JSON object like {"title":"...","text":"..."} and nothing else ' +
              "— no markdown fences, no extra commentary. Keep the same meaning and tone; do not summarize.",
          },
          { role: "user", content: JSON.stringify({ title: title || "", text: text || "" }) },
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

    let parsed: { title?: string; text?: string };
    try {
      parsed = JSON.parse(content);
    } catch {
      parsed = { title: "", text: content };
    }

    return jsonResponse({ title: parsed.title || "", text: parsed.text || "" });
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
