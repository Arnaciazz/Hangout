-- ============================================================
-- Shuffle App — Supabase Schema (Phase 1: Auth + Groups)
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- Enable UUID extension (already on by default in Supabase)
create extension if not exists "pgcrypto";

-- ─── Public Profiles ─────────────────────────────────────────────────────────
-- Mirrors auth.users. Auto-created via trigger on sign-up.

create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  avatar_url   text,
  phone        text,
  fcm_token    text,
  created_at   timestamptz default now()
);

-- Auto-create profile row when a new user signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name, avatar_url, phone)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      split_part(coalesce(new.email, ''), '@', 1),
      'User'
    ),
    new.raw_user_meta_data->>'avatar_url',
    new.phone
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─── Groups ───────────────────────────────────────────────────────────────────

create table if not exists public.groups (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  mode        text not null check (mode in ('hunger', 'travel')),
  created_by  uuid not null references public.profiles(id),
  invite_code text unique not null,
  created_at  timestamptz default now()
);

-- ─── Group Members ────────────────────────────────────────────────────────────

create table if not exists public.group_members (
  group_id  uuid references public.groups(id) on delete cascade,
  user_id   uuid references public.profiles(id) on delete cascade,
  role      text default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz default now(),
  primary key (group_id, user_id)
);

-- ─── Row Level Security ───────────────────────────────────────────────────────

alter table public.profiles     enable row level security;
alter table public.groups       enable row level security;
alter table public.group_members enable row level security;

-- profiles: any authenticated user can read all profiles (for showing member names)
create policy "Profiles readable by authenticated users"
  on public.profiles for select
  using (auth.role() = 'authenticated');

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- groups: authenticated users can read all groups
-- (needed so a user can find a group by invite code before they are a member)
create policy "Groups readable by authenticated users"
  on public.groups for select
  using (auth.role() = 'authenticated');

create policy "Authenticated users can create groups"
  on public.groups for insert
  with check (auth.uid() = created_by);

create policy "Owner can update group"
  on public.groups for update
  using (auth.uid() = created_by);

create policy "Owner can delete group"
  on public.groups for delete
  using (auth.uid() = created_by);

-- group_members: members can see other members of groups they belong to
create policy "Members can view group members"
  on public.group_members for select
  using (
    exists (
      select 1 from public.group_members gm
      where gm.group_id = group_members.group_id
        and gm.user_id = auth.uid()
    )
  );

create policy "Users can add themselves to a group"
  on public.group_members for insert
  with check (auth.uid() = user_id);

create policy "Users can remove themselves from a group"
  on public.group_members for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Phase 2: Sessions + Places + Swipes
-- ============================================================

-- ─── Sessions ────────────────────────────────────────────────────────────────

create table if not exists public.sessions (
  id          uuid primary key default gen_random_uuid(),
  group_id    uuid references public.groups(id) on delete cascade,  -- null = solo
  user_id     uuid not null references public.profiles(id),          -- creator / solo player
  mode        text not null check (mode in ('hunger', 'travel')),
  type        text not null check (type in ('group', 'solo')),
  status      text not null default 'setup'
              check (status in ('setup', 'swiping', 'revealed', 'completed')),
  started_at  timestamptz,
  completed_at timestamptz,
  created_at  timestamptz default now()
);

-- ─── Session Locations (area inputs from members) ────────────────────────────

create table if not exists public.session_locations (
  id          uuid primary key default gen_random_uuid(),
  session_id  uuid not null references public.sessions(id) on delete cascade,
  added_by    uuid not null references public.profiles(id),
  place_name  text not null,
  lat         decimal(10, 8),
  lng         decimal(11, 8),
  radius_km   int default 3,
  created_at  timestamptz default now()
);

-- ─── Suggested Places (fetched from Google Places, stored per session) ────────

create table if not exists public.suggested_places (
  id                    uuid primary key default gen_random_uuid(),
  session_id            uuid not null references public.sessions(id) on delete cascade,
  google_place_id       text not null,
  name                  text not null,
  address               text,
  lat                   decimal(10, 8),
  lng                   decimal(11, 8),
  rating                decimal(2, 1),
  rating_count          int,
  price_level           int,
  is_open_now           boolean,
  opening_hours_display text,
  phone                 text,
  website_url           text,
  google_maps_uri       text,
  dineout_url           text,
  eazydiner_url         text,
  photos                jsonb default '[]',
  reviews               jsonb default '[]',
  cuisine_type          text,
  display_order         int default 0,
  cached_at             timestamptz default now()
);

-- ─── Swipes ───────────────────────────────────────────────────────────────────

create table if not exists public.swipes (
  id         uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  user_id    uuid not null references public.profiles(id),
  place_id   uuid not null references public.suggested_places(id),
  direction  text not null check (direction in ('yes', 'no')),
  swiped_at  timestamptz default now(),
  unique (session_id, user_id, place_id)
);

-- ─── Session Results (computed after all members finish) ──────────────────────

create table if not exists public.session_results (
  id              uuid primary key default gen_random_uuid(),
  session_id      uuid not null references public.sessions(id) on delete cascade,
  place_id        uuid not null references public.suggested_places(id),
  yes_votes       int default 0,
  no_votes        int default 0,
  vote_percentage decimal(5, 2),
  rank            int,
  is_winner       boolean default false
);

-- ─── RLS for new tables ───────────────────────────────────────────────────────

alter table public.sessions          enable row level security;
alter table public.session_locations enable row level security;
alter table public.suggested_places  enable row level security;
alter table public.swipes            enable row level security;
alter table public.session_results   enable row level security;

-- Sessions: readable by the creator or by any group member
create policy "Session creator can manage session"
  on public.sessions for all
  using (auth.uid() = user_id);

create policy "Group members can view sessions"
  on public.sessions for select
  using (
    group_id is null or
    exists (
      select 1 from public.group_members gm
      where gm.group_id = sessions.group_id
        and gm.user_id = auth.uid()
    )
  );

-- Session locations: readable by session participants
create policy "Session participants can manage locations"
  on public.session_locations for all
  using (
    exists (
      select 1 from public.sessions s
      where s.id = session_locations.session_id
        and (s.user_id = auth.uid() or
             exists (select 1 from public.group_members gm
                     where gm.group_id = s.group_id and gm.user_id = auth.uid()))
    )
  );

-- Suggested places: readable by session participants
create policy "Session participants can view places"
  on public.suggested_places for select
  using (
    exists (
      select 1 from public.sessions s
      where s.id = suggested_places.session_id
        and (s.user_id = auth.uid() or
             exists (select 1 from public.group_members gm
                     where gm.group_id = s.group_id and gm.user_id = auth.uid()))
    )
  );

create policy "Session creator can insert places"
  on public.suggested_places for insert
  with check (
    exists (
      select 1 from public.sessions s
      where s.id = suggested_places.session_id and s.user_id = auth.uid()
    )
  );

-- Swipes: each user manages their own
create policy "Users manage own swipes"
  on public.swipes for all
  using (auth.uid() = user_id);

create policy "Session participants can view swipes"
  on public.swipes for select
  using (
    exists (
      select 1 from public.sessions s
      where s.id = swipes.session_id
        and (s.user_id = auth.uid() or
             exists (select 1 from public.group_members gm
                     where gm.group_id = s.group_id and gm.user_id = auth.uid()))
    )
  );

-- Session results: readable by participants
create policy "Session participants can view results"
  on public.session_results for select
  using (
    exists (
      select 1 from public.sessions s
      where s.id = session_results.session_id
        and (s.user_id = auth.uid() or
             exists (select 1 from public.group_members gm
                     where gm.group_id = s.group_id and gm.user_id = auth.uid()))
    )
  );

create policy "Session creator can insert results"
  on public.session_results for insert
  with check (
    exists (
      select 1 from public.sessions s
      where s.id = session_results.session_id and s.user_id = auth.uid()
    )
  );
