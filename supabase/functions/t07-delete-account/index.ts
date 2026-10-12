import { createClient } from "https://esm.sh/@supabase/supabase-js@2.117.3";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json"
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), { status, headers: cors });
}

async function activeSession(url: string, anonKey: string, token: string) {
  const r = await fetch(url + "/rest/v1/rpc/t07_session_status", {
    method: "POST",
    headers: {
      apikey: anonKey,
      Authorization: "Bearer " + token,
      "Content-Type": "application/json"
    },
    body: "{}"
  });
  if (!r.ok) return false;
  return (await r.json()) === true;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "METHOD_NOT_ALLOWED" });

  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";

  if (!token) return json(401, { error: "AUTH_REQUIRED" });
  if (!(await activeSession(url, anonKey, token))) return json(401, { error: "SESSION_NOT_ACTIVE" });

  const admin = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false }
  });
  const { data, error } = await admin.auth.getUser(token);
  const user = data?.user;
  if (error || !user) return json(401, { error: "AUTH_REQUIRED" });

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) return json(500, { error: "ACCOUNT_DELETE_FAILED" });

  return json(200, { ok: true, deleted_user: true, diary_data_cascade: true });
});
