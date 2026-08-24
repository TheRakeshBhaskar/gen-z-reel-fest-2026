create extension if not exists pgcrypto;
create sequence if not exists public.registration_seq start 1;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text,
 role text not null default 'participant' check (role in ('participant','admin','manager','judge')),
 created_at timestamptz not null default now()
);

create table if not exists public.event_settings (
 id int primary key default 1 check (id=1),
 event_title text not null default 'GEN Z REEL FEST 2026',
 event_description text default 'तुमची कल्पना. तुमची Reel. तुमचा मंच.',
 event_date text, event_time text, event_venue text default 'Bhandara × Gondia',
 event_organizer text default 'GEN Z REEL FEST 2026', event_contact text,
 registration_open boolean not null default true,
 registration_end timestamptz, voting_start timestamptz, voting_end timestamptz,
 result_date timestamptz, banner_url text, updated_at timestamptz not null default now()
);
insert into public.event_settings(id,registration_end) values(1,'2026-12-31T23:59:00+05:30') on conflict (id) do nothing;

create table if not exists public.entries (
 id uuid primary key default gen_random_uuid(),
 registration_id text unique not null default ('RB-GZR-2026-' || lpad(nextval('public.registration_seq')::text,5,'0')),
 user_id uuid references auth.users(id) on delete set null,
 name text not null, dob date, district text, taluka text, village text, mobile text, whatsapp text,
 email text not null, instagram text, youtube text, category text not null, title text not null,
 reel_url text not null, photo_url text, consent boolean not null default false,
 status text not null default 'Submitted' check (status in ('Submitted','Under Review','Approved','Shortlisted','Finalist','Rejected')),
 is_finalist boolean not null default false, public_votes int not null default 0,
 created_at timestamptz not null default now()
);

create table if not exists public.jury_scores (
 id uuid primary key default gen_random_uuid(), entry_id uuid not null references public.entries(id) on delete cascade,
 judge_id uuid not null references auth.users(id) on delete cascade,
 creativity numeric(5,2) default 0, content numeric(5,2) default 0, performance numeric(5,2) default 0,
 cinematography numeric(5,2) default 0, editing numeric(5,2) default 0, local_connect numeric(5,2) default 0,
 total numeric(6,2) generated always as (creativity+content+performance+cinematography+editing+local_connect) stored,
 created_at timestamptz not null default now(), unique(entry_id,judge_id)
);

create table if not exists public.votes (
 id uuid primary key default gen_random_uuid(), entry_id uuid not null references public.entries(id) on delete cascade,
 voter_id uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now(),
 unique(entry_id,voter_id)
);

create table if not exists public.results (
 id uuid primary key default gen_random_uuid(), registration_id text not null, name text not null,
 rank int, award text, prize text, certificate_url text, created_at timestamptz not null default now()
);

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','')) on conflict(id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.increment_vote_count() returns trigger language plpgsql security definer set search_path=public as $$
begin update public.entries set public_votes=public_votes+1 where id=new.entry_id; return new; end; $$;
drop trigger if exists after_vote on public.votes;
create trigger after_vote after insert on public.votes for each row execute procedure public.increment_vote_count();

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin') $$;
create or replace function public.is_jury_or_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role in ('admin','manager','judge')) $$;

alter table public.profiles enable row level security;
alter table public.event_settings enable row level security;
alter table public.entries enable row level security;
alter table public.jury_scores enable row level security;
alter table public.votes enable row level security;
alter table public.results enable row level security;

create policy "profiles self" on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
create policy "event public read" on public.event_settings for select to anon,authenticated using (true);
create policy "event admin update" on public.event_settings for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "entries insert auth" on public.entries for insert to authenticated with check (user_id=auth.uid());
create policy "entries own finalist jury read" on public.entries for select to authenticated using (user_id=auth.uid() or is_finalist or public.is_jury_or_admin());
create policy "entries jury update" on public.entries for update to authenticated using (public.is_jury_or_admin()) with check (public.is_jury_or_admin());
create policy "votes insert" on public.votes for insert to authenticated with check (voter_id=auth.uid() and exists(select 1 from public.entries e where e.id=entry_id and e.is_finalist=true));
create policy "votes own read" on public.votes for select to authenticated using (voter_id=auth.uid() or public.is_jury_or_admin());
create policy "jury access" on public.jury_scores for all to authenticated using (public.is_jury_or_admin()) with check (public.is_jury_or_admin());
create policy "results public read" on public.results for select to anon,authenticated using (true);
create policy "results admin write" on public.results for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- After creating your admin account in Supabase Authentication > Users:
-- update public.profiles set role='admin' where id='YOUR-USER-UUID';
