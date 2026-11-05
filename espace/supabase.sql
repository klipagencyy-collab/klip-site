-- Klip Agency · Espace créateurs & clippeurs
-- À coller une seule fois dans Supabase → SQL Editor → New query → Run (relançable sans risque).

-- 1) Profils : admin, créateur ou clippeur
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null default '',
  role text not null default 'creator',
  approved boolean not null default false,     -- seuls les comptes créés par l'agence sont activés
  created_at timestamptz not null default now()
);
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check (role in ('creator', 'clipper', 'admin'));

-- 2) Clips (un clip = un TikTok publié sur un créateur, éventuellement déposé par un clippeur)
create table if not exists public.clips (
  id bigint generated always as identity primary key,
  creator_id uuid not null references public.profiles on delete cascade,
  clipper_id uuid references public.profiles on delete set null,
  url text not null unique check (url ~* '^https://([a-z]+\.)?tiktok\.com/'),
  status text not null default 'valide' check (status in ('en_attente', 'valide', 'refuse')),
  bonus numeric(10, 2) not null default 0,
  title text default '', author text default '', cover_url text default '',
  posted_at timestamptz,
  views bigint not null default 0, likes bigint not null default 0,
  comments bigint not null default 0, shares bigint not null default 0,
  updated_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists clips_creator on public.clips (creator_id);
create index if not exists clips_clipper on public.clips (clipper_id);

-- 3) Historique des stats (courbes)
create table if not exists public.clip_stats (
  id bigint generated always as identity primary key,
  clip_id bigint not null references public.clips on delete cascade,
  views bigint not null default 0, likes bigint not null default 0,
  comments bigint not null default 0, shares bigint not null default 0,
  captured_at timestamptz not null default now()
);
create index if not exists clip_stats_clip on public.clip_stats (clip_id, captured_at);

-- 4) Liens des lives envoyés par les créateurs (WeTransfer, Google Drive…)
create table if not exists public.transfers (
  id bigint generated always as identity primary key,
  creator_id uuid not null references public.profiles on delete cascade,
  url text not null,
  provider text not null default 'wetransfer',
  note text default '' check (char_length(note) <= 500),
  status text not null default 'recu' check (status in ('recu', 'en_cours', 'clipe')),
  created_at timestamptz not null default now()
);

-- Liens : WeTransfer, Google Drive, Dropbox ou autre (au choix du créateur)
alter table public.transfers add column if not exists provider text not null default 'wetransfer';
alter table public.transfers drop constraint if exists transfers_url_check;
alter table public.transfers add constraint transfers_url_check check (url ~* '^https://[^ ]+$' and char_length(url) <= 1000);
alter table public.transfers drop constraint if exists transfers_provider_check;
alter table public.transfers add constraint transfers_provider_check check (provider in ('wetransfer', 'drive', 'dropbox', 'autre'));

-- Profil créé automatiquement à chaque nouveau compte
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name) values (new.id, coalesce(new.raw_user_meta_data ->> 'name', '')) on conflict do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.my_role() returns text
language sql stable security definer set search_path = public as $$
  select case when approved or role = 'admin' then role end from public.profiles where id = auth.uid();
$$;
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$ select coalesce(public.my_role() = 'admin', false); $$;

-- Liste des créateurs (nom seulement) pour le menu des clippeurs
create or replace function public.list_creators() returns table (id uuid, name text)
language sql stable security definer set search_path = public as $$
  select p.id, p.name from public.profiles p
  where p.role = 'creator' and p.approved and public.my_role() in ('clipper', 'admin') order by p.name;
$$;

-- Sécurité : chacun ne voit que ses données, l'admin voit tout
alter table public.profiles enable row level security;
alter table public.clips enable row level security;
alter table public.clip_stats enable row level security;
alter table public.transfers enable row level security;

drop policy if exists p_read on public.profiles;
create policy p_read on public.profiles for select using (id = auth.uid() or public.is_admin());
drop policy if exists p_admin on public.profiles;
create policy p_admin on public.profiles for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists c_read on public.clips;
create policy c_read on public.clips for select using (
  public.is_admin()
  or (public.my_role() = 'creator' and creator_id = auth.uid() and status = 'valide')
  or (public.my_role() = 'clipper' and clipper_id = auth.uid()));
drop policy if exists c_clipper_insert on public.clips;
create policy c_clipper_insert on public.clips for insert with check (
  public.my_role() = 'clipper' and clipper_id = auth.uid() and status = 'en_attente' and bonus = 0 and views = 0
  and exists (select 1 from public.profiles p where p.id = creator_id and p.role = 'creator' and p.approved));
drop policy if exists c_admin on public.clips;
create policy c_admin on public.clips for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists s_read on public.clip_stats;
create policy s_read on public.clip_stats for select using (
  public.is_admin() or exists (select 1 from public.clips c where c.id = clip_id and (
    (public.my_role() = 'creator' and c.creator_id = auth.uid() and c.status = 'valide')
    or (public.my_role() = 'clipper' and c.clipper_id = auth.uid()))));
drop policy if exists s_admin on public.clip_stats;
create policy s_admin on public.clip_stats for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists t_read on public.transfers;
create policy t_read on public.transfers for select using ((public.my_role() = 'creator' and creator_id = auth.uid()) or public.is_admin());
drop policy if exists t_insert on public.transfers;
create policy t_insert on public.transfers for insert with check (public.my_role() = 'creator' and creator_id = auth.uid());
drop policy if exists t_admin on public.transfers;
create policy t_admin on public.transfers for all using (public.is_admin()) with check (public.is_admin());

-- Temps réel : les pages se mettent à jour seules
do $$ begin alter publication supabase_realtime add table public.clips; exception when others then null; end $$;
do $$ begin alter publication supabase_realtime add table public.transfers; exception when others then null; end $$;

-- 5) Compte admin : crée ton utilisateur dans Authentication → Users → Add user
--    (klip.agencyy@gmail.com, ton mot de passe, « Auto Confirm User » coché), puis lance :
-- update public.profiles set role = 'admin', approved = true, name = 'Klip Agency'
--   where id = (select id from auth.users where email = 'klip.agencyy@gmail.com');

-- 6) Espace commun : tous les clips validés avec clippeur, créateur et courbe
create or replace function public.shared_feed() returns table (
  id bigint, url text, title text, cover_url text, views bigint, likes bigint, posted_at timestamptz, created_at timestamptz,
  creator_name text, clipper_name text, points jsonb)
language sql stable security definer set search_path = public as $$
  select c.id, c.url, c.title, c.cover_url, c.views, c.likes, c.posted_at, c.created_at, pc.name, coalesce(pk.name, 'Klip'),
    (select coalesce(jsonb_agg(jsonb_build_array(extract(epoch from s.captured_at)::bigint, s.views) order by s.captured_at), '[]'::jsonb)
       from (select captured_at, views from public.clip_stats where clip_id = c.id order by captured_at desc limit 30) s)
  from public.clips c join public.profiles pc on pc.id = c.creator_id left join public.profiles pk on pk.id = c.clipper_id
  where c.status = 'valide' and (public.my_role() in ('admin', 'clipper') or (public.my_role() = 'creator' and c.creator_id = auth.uid()))
  order by c.views desc limit 300;
$$;
