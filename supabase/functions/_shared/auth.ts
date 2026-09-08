// اعتبارسنجی مشترک برای همه‌ی Edge Functionهای این پروژه که نیاز به «کاربر
// واردشده» دارن. چون این پروژه از سیستم لاگین سفارشی خودش (public.login(),
// JWT با pgjwt) استفاده می‌کنه، نه Auth استاندارد سوپابیس، به‌جای پیاده‌سازی
// جدای اعتبارسنجی JWT، توکن ورودی رو با یه کوئری سبک و واقعی به PostgREST
// چک می‌کنیم — اگه PostgREST قبولش کنه (یعنی نقش app_admin/app_viewer
// داره)، توکن معتبره.

export async function fetchPostForUser(
  req: Request,
  postId: number,
): Promise<{ title: string | null; text: string | null } | null> {
  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return null;

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const res = await fetch(`${supabaseUrl}/rest/v1/posts?id=eq.${postId}&select=title,text`, {
    headers: { apikey: anonKey ?? "", Authorization: `Bearer ${token}` },
  });
  if (!res.ok) return null;
  const rows = await res.json();
  return Array.isArray(rows) && rows.length ? rows[0] : null;
}

// یه کوئری واقعی به PostgREST با توکن خودِ کاربر — هم اعتبارسنجی ورود
// رو انجام می‌ده (چون RLS جدول posts فقط به app_admin/app_viewer اجازه‌ی
// select می‌ده) هم پست‌های واقعی رو برمی‌گردونه؛ برای Edge Functionهایی
// که نیاز به یه دسته پست دارن (نه فقط یکی)، نه یه postId مشخص
export async function fetchRecentNewsPostsForUser(
  req: Request,
  hours: number,
  limit = 150,
): Promise<Array<{ id: number; channel_id: number; title: string | null; text: string | null; posted_at: string | null; channels: { title: string | null } | null }> | null> {
  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return null;

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const headers = { apikey: anonKey ?? "", Authorization: `Bearer ${token}` };

  // فقط کانال‌های «شبکه‌های اجتماعی» + «وب‌سایت‌ها» (show_in_news، غیر از بله)
  const chRes = await fetch(
    `${supabaseUrl}/rest/v1/channels?select=id&show_in_news=eq.true&platform=neq.bale`,
    { headers },
  );
  if (!chRes.ok) return null;
  const channels: Array<{ id: number }> = await chRes.json();
  if (!channels.length) return [];
  const ids = channels.map((c) => c.id).join(",");

  const cutoff = new Date(Date.now() - hours * 3600 * 1000).toISOString();
  // resource embedding با channels(title) — PostgREST خودش از روی FK
  // posts.channel_id → channels.id این join رو انجام می‌ده
  const postsRes = await fetch(
    `${supabaseUrl}/rest/v1/posts?select=id,channel_id,title,text,posted_at,channels(title)&channel_id=in.(${ids})&posted_at=gte.${cutoff}&order=posted_at.desc&limit=${limit}`,
    { headers },
  );
  if (!postsRes.ok) return null;
  return await postsRes.json();
}

// برای extract-post-keywords («پرونده ویژه») — جدیدترین پست‌هایی که
// هنوز posts.ai_keywords ندارن (NULL، نه آرایه‌ی خالی). ORDER BY
// posted_at DESC عمداست: «پرونده ویژه» روی موضوعات موقت/جاری کار
// می‌کنه، پس پست‌های تازه اولویت دارن — اگه از قدیمی‌ترین شروع می‌شد
// (نسخه‌ی قبلی این تابع)، با وجود backlog پست‌های قدیمی (که موقع
// اضافه‌شدن این ستون همه NULL شدن)، ممکن بود روزها طول بکشه تا
// پردازش به پست‌های واقعاً تازه/مرتبط برسه. resumability همچنان
// برقراره چون معیار «پردازش‌شده» ai_keywords IS NULL هست، نه ترتیب —
// backlog قدیمی هم بالأخره توی اجراهای بعدی (وقتی دیگه پست تازه‌ی
// بی‌کلیدواژه‌ای نمونده) پردازش می‌شه، فقط اولویت با تازه‌هاست.
export async function fetchPostsMissingKeywords(
  req: Request,
  limit = 30,
): Promise<Array<{ id: number; title: string | null; text: string | null }> | null> {
  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return null;

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const headers = { apikey: anonKey ?? "", Authorization: `Bearer ${token}` };

  // همون منبع خبری news-insights: کانال‌های «شبکه‌های اجتماعی» + «وب‌سایت‌ها» (show_in_news، غیر از بله)
  const chRes = await fetch(
    `${supabaseUrl}/rest/v1/channels?select=id&show_in_news=eq.true&platform=neq.bale`,
    { headers },
  );
  if (!chRes.ok) return null;
  const channels: Array<{ id: number }> = await chRes.json();
  if (!channels.length) return [];
  const ids = channels.map((c) => c.id).join(",");

  const postsRes = await fetch(
    `${supabaseUrl}/rest/v1/posts?select=id,title,text&channel_id=in.(${ids})&ai_keywords=is.null&order=posted_at.desc&limit=${limit}`,
    { headers },
  );
  if (!postsRes.ok) return null;
  return await postsRes.json();
}
