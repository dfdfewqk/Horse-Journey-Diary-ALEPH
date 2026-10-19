import { createClient } from "https://esm.sh/@supabase/supabase-js@2.117.3";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-user-id",
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
  const value = await r.json();
  return value === true;
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
  if (!(await activeSession(url, anonKey, token))) {
    return json(401, { error: "SESSION_NOT_ACTIVE" });
  }

  const admin = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false }
  });
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  const user = userData?.user;
  if (userError || !user) return json(401, { error: "AUTH_REQUIRED" });

  let body: any = {};
  try { body = await req.json(); } catch { return json(400, { error: "INVALID_JSON" }); }

  const resourceMap: Record<string, string> = {
    plans: "t07_plans",
    tasks: "t07_tasks",
    execution_records: "t07_execution_records"
  };
  const table = resourceMap[String(body.resource || "plans")];
  const action = String(body.action || "list");
  if (!table) return json(400, { error: "INVALID_RESOURCE" });

  // URL/header/body에 다른 user_id가 들어와도 소유자는 항상 JWT의 user.id로 결정한다.
  const ignoredOwner = body.user_id ?? req.headers.get("X-User-Id") ?? null;

  if (action === "list") {
    const { data, error } = await admin.from(table).select("*").eq("user_id", user.id);
    if (error) return json(500, { error: "QUERY_FAILED" });
    return json(200, {
      ok: true,
      owner_source: "authenticated_session",
      requested_user_id_ignored: ignoredOwner !== null,
      count: data?.length ?? 0,
      data
    });
  }

  const id = String(body.id || "");
  if (!id) return json(400, { error: "ID_REQUIRED" });

  const { data: target, error: targetError } = await admin
    .from(table).select("id,user_id").eq("id", id).maybeSingle();

  if (targetError) return json(500, { error: "QUERY_FAILED" });
  if (!target || target.user_id !== user.id) {
    return json(404, { error: "NOT_FOUND" });
  }

  if (action === "read") {
    const { data, error } = await admin.from(table).select("*").eq("id", id).eq("user_id", user.id).single();
    if (error) return json(404, { error: "NOT_FOUND" });
    return json(200, { ok: true, data });
  }

  if (action === "update") {
    // 이 보호 테스트 API는 서비스 키를 사용하므로 수정할 필드를 제한한다.
    const allowed: Record<string,string[]> = {
      plans: ["title","start_date","end_date","priority","success_criteria","estimated_minutes"],
      tasks: ["title","description","due_date","priority","tag","estimated_minutes"],
      execution_records: ["blocked_reason"]
    };
    const resource=String(body.resource || "plans");
    const patch=body.patch && typeof body.patch==="object" && !Array.isArray(body.patch) ? body.patch : {};
    const keys=Object.keys(patch);
    if(!keys.length || keys.some(k=>!allowed[resource].includes(k))) return json(400,{error:"INVALID_UPDATE_FIELDS"});
    const safePatch=Object.fromEntries(keys.map(k=>[k,patch[k]]));
    const { data, error } = await admin.from(table).update(safePatch).eq("id", id).eq("user_id", user.id).select("*");
    if (error) return json(400, { error: "UPDATE_FAILED" });
    return json(200, { ok: true, data });
  }

  if (action === "delete") {
    const { error } = await admin.from(table).delete().eq("id", id).eq("user_id", user.id);
    if (error) return json(400, { error: "DELETE_FAILED" });
    return json(200, { ok: true, deleted: id });
  }

  return json(400, { error: "INVALID_ACTION" });
});
