-- ============================================================
-- Hangout — 003: lock down the bill functions
--
-- Run AFTER 002_complete_app.sql. Safe to run more than once.
--
--   1. set_bill_shares checked `v_payer <> auth.uid()`, which is null (not
--      true) for a signed-out caller, so it let them through. Replaced with
--      `is distinct from`.
--   2. New functions are executable by everyone by default, including the
--      signed-out `anon` role. The bill functions and the sign-up trigger are
--      now signed-in only (the trigger: nobody, it only runs as a trigger).
--      is_group_member and is_session_participant stay executable by anon:
--      RLS policies call them for whoever is querying, and they only answer
--      "am I a member", which is always false when signed out.
-- ============================================================

-- ─── 1. set_bill_shares ──────────────────────────────────────────────────────

create or replace function public.set_bill_shares(
  p_bill_id uuid,
  p_shares  jsonb  -- [{"user_id": "...", "amount_paise": 12345}, ...]
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_payer uuid;
  v_total bigint;
  v_sum   bigint;
  v_count int;
  v_match int;
begin
  select payer_id, total_paise into v_payer, v_total
    from public.bills where id = p_bill_id;
  if not found then raise exception 'no_bill'; end if;
  if v_payer is distinct from auth.uid() then raise exception 'not_payer'; end if;

  select count(*), coalesce(sum((s->>'amount_paise')::bigint), 0)
    into v_count, v_sum
    from jsonb_array_elements(p_shares) s;
  if v_sum <> v_total then raise exception 'shares_must_add_up'; end if;
  if exists (
    select 1 from jsonb_array_elements(p_shares) s
    where (s->>'amount_paise')::bigint < 0
  ) then
    raise exception 'negative_share';
  end if;

  select count(*) into v_match
    from jsonb_array_elements(p_shares) s
    join public.bill_shares bs
      on bs.bill_id = p_bill_id and bs.user_id = (s->>'user_id')::uuid;
  if v_match <> v_count
     or v_count <> (select count(*) from public.bill_shares where bill_id = p_bill_id) then
    raise exception 'shares_must_cover_members';
  end if;

  update public.bill_shares bs
    set amount_paise = (s->>'amount_paise')::bigint
    from jsonb_array_elements(p_shares) s
    where bs.bill_id = p_bill_id and bs.user_id = (s->>'user_id')::uuid;

  update public.bills set updated_at = now() where id = p_bill_id;
end;
$$;

-- ─── 2. Execute rights ───────────────────────────────────────────────────────
-- Supabase also grants anon execute directly (default privileges), so revoking
-- from public alone isn't enough.

revoke execute on function public.create_bill(uuid, bigint, text, uuid[]) from public, anon;
revoke execute on function public.set_bill_shares(uuid, jsonb)            from public, anon;
revoke execute on function public.set_share_paid(uuid, uuid, boolean)     from public, anon;
revoke execute on function public.delete_bill(uuid)                       from public, anon;

grant execute on function public.create_bill(uuid, bigint, text, uuid[]) to authenticated;
grant execute on function public.set_bill_shares(uuid, jsonb)            to authenticated;
grant execute on function public.set_share_paid(uuid, uuid, boolean)     to authenticated;
grant execute on function public.delete_bill(uuid)                       to authenticated;

revoke execute on function public.handle_new_user() from public, anon, authenticated;
