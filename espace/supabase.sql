-- Klip Agency · Espace créateur
-- À coller une seule fois dans Supabase → SQL Editor → New query → Run.

-- 1) Profils (un par compte : créateur ou admin)
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null default '',
  handle text default '',
  role text not null default 'creator' check (role in ('creator', 'admin')),
  approved boolean not null default false,     -- seuls les comptes créés par l'agence sont activés
  created_at timestamptz not null default now()
);

-- 2) Clips publiés sur un créateur
create table if not exists public.clips (
  id bigint generated always as identity primary key,
  creator_id uuid not null references public.profiles on delete cascade,
  url text not null unique,
  title text default '',
  author text default '',
  cover_url text default '',
  posted_at timestamptz,
  views bigint not null default 0,
  likes bigint not null default 0,
  comments bigint not null default 0,
  shares bigint not null default 0,
  updated_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists clips_creator on public.clips (creator_id);

-- 3) Historique des stats (pour les courbes)
create table if not exists public.clip_stats (
  id bigint generated always as identity primary key,
  clip_id bigint not null references public.clips on delete cascade,
  views bigint not null default 0,
  likes bigint not null default 0,
  comments bigint not null default 0,
  shares bigint not null default 0,
  captured_at timestamptz not null default now()
);
create index if not exists clip_stats_clip on public.clip_stats (clip_id, captured_at);

-- 4) Liens WeTransfer envoyés par les créateurs
create table if not exists public.transfers (
  id bigint generated always as identity primary key,
  creator_id uuid not null references public.profiles on delete cascade,
  url text not null check (url ~* '^https://([a-z0-9-]+\.)?(we\.tl|wetransfer\.com)/'),
  note text default '' check (char_length(note) <= 500),
  status text not null default 'recu' check (status in ('recu', 'en_cours', 'clipe')),
  created_at timestamptz not null default now()
);

-- Profil créé automatiquement à l'inscription
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name) values (new.id, coalesce(new.raw_user_meta_data ->> 'name', ''));
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;
create or replace function public.is_approved() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and approved);
$$;

-- Sécurité : chaque créateur ne voit que ses données, l'admin voit tout
alter table public.profiles enable row level security;
alter table public.clips enable row level security;
alter table public.clip_stats enable row level security;
alter table public.transfers enable row level security;

drop policy if exists p_read on public.profiles;
create policy p_read on public.profiles for select using (id = auth.uid() or public.is_admin());
drop policy if exists p_admin on public.profiles;
create policy p_admin on public.profiles for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists c_read on public.clips;
create policy c_read on public.clips for select using ((creator_id = auth.uid() and public.is_approved()) or public.is_admin());
drop policy if exists c_admin on public.clips;
create policy c_admin on public.clips for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists s_read on public.clip_stats;
create policy s_read on public.clip_stats for select using (
  public.is_admin() or (public.is_approved() and exists (select 1 from public.clips c where c.id = clip_id and c.creator_id = auth.uid())));
drop policy if exists s_admin on public.clip_stats;
create policy s_admin on public.clip_stats for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists t_read on public.transfers;
create policy t_read on public.transfers for select using ((creator_id = auth.uid() and public.is_approved()) or public.is_admin());
drop policy if exists t_insert on public.transfers;
create policy t_insert on public.transfers for insert with check (creator_id = auth.uid() and public.is_approved());
drop policy if exists t_admin on public.transfers;
create policy t_admin on public.transfers for all using (public.is_admin()) with check (public.is_admin());

-- Temps réel : la page se met à jour seule quand les stats changent
do $$ begin
  alter publication supabase_realtime add table public.clips;
exception when others then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.transfers;
exception when others then null; end $$;

-- 5) Ton compte admin : crée d'abord ton utilisateur dans Authentication → Users → Add user
--    (klip.agencyy@gmail.com + ton mot de passe, coche « Auto Confirm User »), puis lance :
-- update public.profiles set role = 'admin', approved = true, name = 'Klip Agency'
--   where id = (select id from auth.users where email = 'klip.agencyy@gmail.com');
