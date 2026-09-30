-- ============================================================
-- Hangout — 002: complete the app
--
-- Run AFTER schema.sql, in Supabase Dashboard → SQL Editor → New query.
-- Safe to run more than once.
--
-- What this adds or fixes:
--   1. RLS helpers that don't recurse, and two policy fixes
--      (group_members referenced itself; solo sessions were world-readable).
--   2. Session columns: filters (so the host's filters survive reopening the
--      lobby) and all_voted_at (so "everyone's voted" is announced once).
--   3. session_results: de-duplicated, unique per (session, place), updatable
--      by the host.
--   4. memory_dismissals — "Didn't go" hides a memory for that person.
--   5. payment_details — a person's UPI ID, private to them.
--   6. bills + bill_shares, written only through the functions below, so
--      shares always add up to the total.
--   7. Realtime for every table the app watches.
--   8. Profile privacy: phone numbers and push tokens stop being readable
--      by every signed-in user.
-- ============================================================

-- ─── 1. RLS helpers ──────────────────────────────────────────────────────────
-- security definer: they read group_members without re-entering its policy,
-- which is what made the original group_members policy recurse.

-- The parameter is named gid to match the live function: create or replace
-- can't rename a parameter, and dropping it would drop the policies using it.
create or replace function public.is_group_member(gid uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.group_members
    where group_id = gid and user_id = auth.uid()
  );
$$;

create or replace function public.is_session_participant(p_session_id uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.sessions s
    where s.id = p_session_id
      and (
        s.user_id = auth.uid()
        or (s.group_id is not null and exists (
              select 1 from public.group_members gm
              where gm.group_id = s.group_id and gm.user_id = auth.uid()))
      )
  );
$$;

grant execute on function public.is_group_member(uuid) to authenticated;
grant execute on function public.is_session_participant(uuid) to authenticated;

-- A policy on group_members that queried group_members is rejected by Postgres
-- as infinite recursion.
drop policy if exists "Members can view group members" on public.group_members;
create policy "Members can view group members"
  on public.group_members for select
  using (public.is_group_member(group_id));

-- `group_id is null or …` made every solo session readable by every signed-in
-- user. Own sessions stay readable through "Session creator can manage session".
drop policy if exists "Group members can view sessions" on public.sessions;
create policy "Group members can view sessions"
  on public.sessions for select
  using (group_id is not null and public.is_group_member(group_id));

-- ─── 2. Session columns ──────────────────────────────────────────────────────

alter table public.sessions add column if not exists filters jsonb;
alter table public.sessions add column if not exists all_voted_at timestamptz;

-- ─── 3. Session results ──────────────────────────────────────────────────────
-- Results were re-inserted every time they were computed. Keep one row per
-- (session, place), then enforce it.

delete from public.session_results a
  using public.session_results b
  where a.session_id = b.session_id
    and a.place_id = b.place_id
    and a.ctid < b.ctid;

create unique index if not exists session_results_session_place_key
  on public.session_results (session_id, place_id);

-- The host re-saving results (an upsert) needs update rights too.
drop policy if exists "Session creator can update results" on public.session_results;
create policy "Session creator can update results"
  on public.session_results for update
  using (
    exists (
      select 1 from public.sessions s
      where s.id = session_results.session_id and s.user_id = auth.uid()
    )
  );

-- ─── 4. "Didn't go" ──────────────────────────────────────────────────────────

create table if not exists public.memory_dismissals (
  session_id uuid not null references public.sessions(id) on delete cascade,
  user_id    uuid not null default auth.uid()
             references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (session_id, user_id)
);

alter table public.memory_dismissals enable row level security;

drop policy if exists "Users read own dismissals" on public.memory_dismissals;
create policy "Users read own dismissals"
  on public.memory_dismissals for select
  using (user_id = auth.uid());

drop policy if exists "Users dismiss sessions they took part in" on public.memory_dismissals;
create policy "Users dismiss sessions they took part in"
  on public.memory_dismissals for insert
  with check (user_id = auth.uid() and public.is_session_participant(session_id));

drop policy if exists "Users undo own dismissals" on public.memory_dismissals;
create policy "Users undo own dismissals"
  on public.memory_dismissals for delete
  using (user_id = auth.uid());

-- ─── 5. Payment details ──────────────────────────────────────────────────────
-- Kept out of `profiles`, which every signed-in user can read.

create table if not exists public.payment_details (
  user_id    uuid primary key default auth.uid()
             references public.profiles(id) on delete cascade,
  upi_id     text not null,
  updated_at timestamptz default now()
);

alter table public.payment_details enable row level security;

drop policy if exists "Users manage own payment details" on public.payment_details;
create policy "Users manage own payment details"
  on public.payment_details for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ─── 6. Bills ────────────────────────────────────────────────────────────────
-- Amounts are integer paise, so an even split never loses or invents a paisa.
-- The payer's UPI ID is copied onto the bill: participants need it to pay,
-- and it shouldn't change under an existing bill.

create table if not exists public.bills (
  id          uuid primary key default gen_random_uuid(),
  session_id  uuid not null unique references public.sessions(id) on delete cascade,
  payer_id    uuid not null references public.profiles(id),
  payer_upi   text not null,
  total_paise bigint not null check (total_paise > 0),
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

create table if not exists public.bill_shares (
  bill_id      uuid not null references public.bills(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  amount_paise bigint not null check (amount_paise >= 0),
  paid_at      timestamptz,
  primary key (bill_id, user_id)
);

alter table public.bills       enable row level security;
alter table public.bill_shares enable row level security;

-- Read: anyone in the session. Write: only through the functions below.
drop policy if exists "Participants read bills" on public.bills;
create policy "Participants read bills"
  on public.bills for select
  using (public.is_session_participant(session_id));

drop policy if exists "Participants read bill shares" on public.bill_shares;
create policy "Participants read bill shares"
  on public.bill_shares for select
  using (exists (
    select 1 from public.bills b
    where b.id = bill_shares.bill_id
      and public.is_session_participant(b.session_id)
  ));

-- Create a bill for a revealed group session and split it evenly.
-- The caller is the payer; their own share is marked paid.
create or replace function public.create_bill(
  p_session_id  uuid,
  p_total_paise bigint,
  p_payer_upi   text,
  p_member_ids  uuid[]
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid     uuid := auth.uid();
  v_group   uuid;
  v_status  text;
  v_upi     text := trim(coalesce(p_payer_upi, ''));
  v_members uuid[];
  v_n       int;
  v_base    bigint;
  v_rem     bigint;
  v_i       int := 0;
  v_member  uuid;
  v_bill    uuid;
begin
  if v_uid is null then raise exception 'not_signed_in'; end if;

  select group_id, status into v_group, v_status
    from public.sessions where id = p_session_id;
  if not found or v_group is null then raise exception 'not_a_group_session'; end if;
  if not public.is_group_member(v_group) then raise exception 'not_a_member'; end if;
  if v_status not in ('revealed', 'completed') then raise exception 'not_revealed'; end if;
  if p_total_paise is null or p_total_paise <= 0 then raise exception 'invalid_total'; end if;
  if v_upi !~ '^[A-Za-z0-9._-]{2,64}@[A-Za-z][A-Za-z0-9]{1,63}$' then
    raise exception 'invalid_upi';
  end if;
  if exists (select 1 from public.bills where session_id = p_session_id) then
    raise exception 'bill_exists';
  end if;

  -- Only current crew members, the payer always included, each once.
  select array_agg(m order by m) into v_members
    from (
      select distinct m from unnest(coalesce(p_member_ids, '{}') || v_uid) as m
    ) d
    where exists (
      select 1 from public.group_members gm
      where gm.group_id = v_group and gm.user_id = d.m
    );
  v_n := coalesce(array_length(v_members, 1), 0);
  if v_n = 0 then raise exception 'no_members'; end if;

  insert into public.bills (session_id, payer_id, payer_upi, total_paise)
    values (p_session_id, v_uid, v_upi, p_total_paise)
    returning id into v_bill;

  -- Even split; the leftover paise go one each to the first members.
  v_base := p_total_paise / v_n;
  v_rem  := p_total_paise % v_n;
  foreach v_member in array v_members loop
    insert into public.bill_shares (bill_id, user_id, amount_paise, paid_at)
      values (
        v_bill,
        v_member,
        v_base + case when v_i < v_rem then 1 else 0 end,
        case when v_member = v_uid then now() end
      );
    v_i := v_i + 1;
  end loop;

  insert into public.payment_details (user_id, upi_id)
    values (v_uid, v_upi)
    on conflict (user_id) do update
      set upi_id = excluded.upi_id, updated_at = now();

  return v_bill;
end;
$$;

-- Replace share amounts (payer only). Must cover exactly the existing members
-- and add up to the total.
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

-- Mark a share paid or unpaid: your own, or anyone's if you're the payer.
create or replace function public.set_share_paid(
  p_bill_id uuid,
  p_user_id uuid,
  p_paid    boolean
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_payer uuid;
begin
  select payer_id into v_payer from public.bills where id = p_bill_id;
  if not found then raise exception 'no_bill'; end if;
  if auth.uid() is distinct from p_user_id and auth.uid() is distinct from v_payer then
    raise exception 'not_allowed';
  end if;

  update public.bill_shares
    set paid_at = case when p_paid then coalesce(paid_at, now()) end
    where bill_id = p_bill_id and user_id = p_user_id;
  if not found then raise exception 'no_share'; end if;

  -- Touch the bill so clients watching bills see every change.
  update public.bills set updated_at = now() where id = p_bill_id;
end;
$$;

-- Delete a bill (payer only), e.g. to re-enter the total.
create or replace function public.delete_bill(p_bill_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from public.bills where id = p_bill_id and payer_id = auth.uid();
  if not found then raise exception 'not_payer'; end if;
end;
$$;

grant execute on function public.create_bill(uuid, bigint, text, uuid[]) to authenticated;
grant execute on function public.set_bill_shares(uuid, jsonb) to authenticated;
grant execute on function public.set_share_paid(uuid, uuid, boolean) to authenticated;
grant execute on function public.delete_bill(uuid) to authenticated;

-- ─── 7. Realtime ─────────────────────────────────────────────────────────────
-- The app streams these tables; each must be in the realtime publication.

do $$
declare
  t text;
begin
  foreach t in array array[
    'group_members', 'sessions', 'session_locations', 'swipes',
    'bills', 'bill_shares'
  ] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception
      when duplicate_object then null;  -- already published
    end;
  end loop;
end;
$$;

-- ─── 8. Profile privacy ──────────────────────────────────────────────────────
-- Every signed-in user can read every profile row (crews show names and
-- avatars), and that used to include everyone's phone number and push token.
-- Rows stay readable; only the public columns do. phone and fcm_token are left
-- to their owner's writes and the service role (the notify function).

revoke select on public.profiles from anon, authenticated;
grant select (id, display_name, avatar_url, nickname, avatar_id, created_at)
  on public.profiles to authenticated;
