// Hangout push notifications.
//
// Called by Supabase Database Webhooks (see supabase/README.md) on:
//   group_members INSERT  -> "Asha joined Friday dinner lot"
//   sessions      INSERT  -> "Asha started picking somewhere to eat"
//   sessions      UPDATE  -> swiping opened / winner revealed
//   swipes        INSERT  -> host: "Everyone's voted" (once per session)
//   bills         INSERT  -> "Asha split the bill: you owe ₹600"
//
// Sends through FCM HTTP v1 with a Firebase service account. Every message
// carries data { type, group_id, session_id } so a tap opens the right screen.
//
// Secrets (supabase secrets set ...):
//   FCM_SERVICE_ACCOUNT  the service account JSON, as one string
//   WEBHOOK_SECRET       shared with the webhooks' x-webhook-secret header
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.

import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

type Row = Record<string, unknown>;
type Payload = {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Row | null;
  old_record: Row | null;
};
type Push = {
  userIds: string[];
  title: string;
  body: string;
  data: Record<string, string>;
};

const db: SupabaseClient = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

Deno.serve(async (req) => {
  if (req.headers.get("x-webhook-secret") !== Deno.env.get("WEBHOOK_SECRET")) {
    return new Response("forbidden", { status: 403 });
  }
  let payload: Payload;
  try {
    payload = await req.json();
  } catch {
    return new Response("bad request", { status: 400 });
  }

  try {
    const push = await route(payload);
    if (push && push.userIds.length > 0) await send(push);
    return Response.json({ sent: push?.userIds.length ?? 0 });
  } catch (e) {
    console.error("notify failed", payload.table, payload.type, e);
    return new Response("error", { status: 500 });
  }
});

async function route(p: Payload): Promise<Push | null> {
  const r = p.record;
  if (!r) return null;

  if (p.table === "group_members" && p.type === "INSERT") {
    if (r.role === "owner") return null; // Creating a crew isn't news.
    const [name, crew, members] = await Promise.all([
      displayName(r.user_id as string),
      crewName(r.group_id as string),
      crewMembers(r.group_id as string),
    ]);
    return {
      userIds: members.filter((id) => id !== r.user_id),
      title: crew,
      body: `${name} joined the crew`,
      data: { type: "crew_joined", group_id: r.group_id as string },
    };
  }

  if (p.table === "sessions" && r.group_id) {
    const groupId = r.group_id as string;
    const host = r.user_id as string;
    const what = r.mode === "hunger" ? "somewhere to eat" : "somewhere to go";
    const data = { group_id: groupId, session_id: r.id as string };

    if (p.type === "INSERT") {
      const [name, crew, members] = await Promise.all([
        displayName(host),
        crewName(groupId),
        crewMembers(groupId),
      ]);
      return {
        userIds: members.filter((id) => id !== host),
        title: crew,
        body: `${name} started picking ${what}. Drop your pin.`,
        data: { ...data, type: "session_setup" },
      };
    }

    if (p.type === "UPDATE" && r.status !== p.old_record?.status) {
      if (r.status === "swiping") {
        const [crew, members] = await Promise.all([
          crewName(groupId),
          crewMembers(groupId),
        ]);
        return {
          userIds: members.filter((id) => id !== host),
          title: crew,
          body: `Swiping's open. Find ${what}.`,
          data: { ...data, type: "swiping" },
        };
      }
      if (r.status === "revealed") {
        const [crew, members, winner] = await Promise.all([
          crewName(groupId),
          crewMembers(groupId),
          winnerName(r.id as string),
        ]);
        return {
          userIds: members.filter((id) => id !== host),
          title: winner ? "It's decided" : "The votes are in",
          body: winner ? `${crew} is going to ${winner}` : `No clear winner for ${crew} this time`,
          data: { ...data, type: "revealed" },
        };
      }
    }
    return null;
  }

  if (p.table === "swipes" && p.type === "INSERT") {
    return await allVoted(r.session_id as string);
  }

  if (p.table === "bills" && p.type === "INSERT") {
    const { data: session } = await db
      .from("sessions")
      .select("group_id")
      .eq("id", r.session_id as string)
      .single();
    if (!session?.group_id) return null;
    const payer = r.payer_id as string;
    const [name, shares] = await Promise.all([
      displayName(payer),
      db.from("bill_shares").select("user_id, amount_paise").eq("bill_id", r.id as string),
    ]);
    // One message per person: each carries their own amount.
    for (const s of shares.data ?? []) {
      if (s.user_id === payer || s.amount_paise <= 0) continue;
      await send({
        userIds: [s.user_id],
        title: "Split the bill",
        body: `${name} paid. You owe ${rupees(s.amount_paise)}.`,
        data: {
          type: "bill",
          group_id: session.group_id,
          session_id: r.session_id as string,
        },
      });
    }
    return null;
  }

  return null;
}

/// Tells the host once, when the last crew member finishes swiping.
async function allVoted(sessionId: string): Promise<Push | null> {
  const { data: session } = await db
    .from("sessions")
    .select("id, user_id, group_id, status, all_voted_at")
    .eq("id", sessionId)
    .single();
  if (!session?.group_id || session.status !== "swiping" || session.all_voted_at) {
    return null;
  }

  const [members, places, swipes] = await Promise.all([
    crewMembers(session.group_id),
    db.from("suggested_places").select("id", { count: "exact", head: true })
      .eq("session_id", sessionId),
    db.from("swipes").select("user_id").eq("session_id", sessionId),
  ]);
  const placeCount = places.count ?? 0;
  if (placeCount === 0) return null;
  const perUser = new Map<string, number>();
  for (const s of swipes.data ?? []) {
    perUser.set(s.user_id, (perUser.get(s.user_id) ?? 0) + 1);
  }
  if (!members.every((id) => (perUser.get(id) ?? 0) >= placeCount)) return null;

  // Claim the notification; a concurrent swipe that also sees "all done"
  // updates nothing and stays quiet.
  const { data: claimed } = await db
    .from("sessions")
    .update({ all_voted_at: new Date().toISOString() })
    .eq("id", sessionId)
    .is("all_voted_at", null)
    .select("id");
  if (!claimed || claimed.length === 0) return null;

  return {
    userIds: [session.user_id],
    title: await crewName(session.group_id),
    body: "Everyone's voted. Reveal the winner.",
    data: { type: "all_voted", group_id: session.group_id, session_id: sessionId },
  };
}

// ─── Lookups ──────────────────────────────────────────────────────────────────

async function displayName(userId: string): Promise<string> {
  const { data } = await db
    .from("profiles")
    .select("nickname, display_name")
    .eq("id", userId)
    .single();
  return (data?.display_name || data?.nickname || "Someone") as string;
}

async function crewName(groupId: string): Promise<string> {
  const { data } = await db.from("groups").select("name").eq("id", groupId).single();
  return (data?.name ?? "Your crew") as string;
}

async function crewMembers(groupId: string): Promise<string[]> {
  const { data } = await db.from("group_members").select("user_id").eq("group_id", groupId);
  return (data ?? []).map((m) => m.user_id as string);
}

async function winnerName(sessionId: string): Promise<string | null> {
  const { data } = await db
    .from("session_results")
    .select("suggested_places(name)")
    .eq("session_id", sessionId)
    .eq("is_winner", true)
    .limit(1)
    .maybeSingle();
  const place = data?.suggested_places as { name?: string } | null | undefined;
  return place?.name ?? null;
}

/// ₹1,00,000 grouping, paise only when there are any.
function rupees(paise: number): string {
  const r = Math.floor(paise / 100);
  const p = paise % 100;
  const s = String(r);
  const last3 = s.slice(-3);
  const head = s.slice(0, -3).replace(/\B(?=(\d{2})+(?!\d))/g, ",");
  const grouped = head ? `${head},${last3}` : last3;
  return `₹${grouped}${p ? "." + String(p).padStart(2, "0") : ""}`;
}

// ─── FCM ──────────────────────────────────────────────────────────────────────

type ServiceAccount = { project_id: string; client_email: string; private_key: string };
let cachedToken: { value: string; expires: number } | null = null;

async function send(push: Push) {
  const { data: profiles } = await db
    .from("profiles")
    .select("id, fcm_token")
    .in("id", push.userIds)
    .not("fcm_token", "is", null);
  if (!profiles || profiles.length === 0) return;

  const sa: ServiceAccount = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!);
  const token = await accessToken(sa);
  const url = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

  await Promise.all(profiles.map(async (p) => {
    const res = await fetch(url, {
      method: "POST",
      headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
      body: JSON.stringify({
        message: {
          token: p.fcm_token,
          notification: { title: push.title, body: push.body },
          data: push.data,
          android: { priority: "high" },
        },
      }),
    });
    if (res.ok) return;
    const text = await res.text();
    // The app was uninstalled or the token rotated: stop sending to it.
    if (res.status === 404 || text.includes("UNREGISTERED")) {
      await db.from("profiles").update({ fcm_token: null }).eq("id", p.id);
    } else {
      console.error("fcm send failed", res.status, text);
    }
  }));
}

async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expires > now + 60) return cachedToken.value;

  const enc = (o: unknown) => b64url(new TextEncoder().encode(JSON.stringify(o)));
  const unsigned = `${enc({ alg: "RS256", typ: "JWT" })}.${enc({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })}`;

  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)),
  );

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${b64url(sig)}`,
    }),
  });
  if (!res.ok) throw new Error(`oauth ${res.status}: ${await res.text()}`);
  const json = await res.json();
  cachedToken = { value: json.access_token, expires: now + (json.expires_in ?? 3600) };
  return cachedToken.value;
}

function b64url(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
