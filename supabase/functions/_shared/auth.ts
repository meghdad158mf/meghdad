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
