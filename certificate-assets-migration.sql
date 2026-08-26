-- GEN Z REEL FEST 2026
-- Certificate asset storage migration
-- Run this once in Supabase SQL Editor before enabling cloud uploads.

-- Public read bucket for certificate visuals. Upload/delete is restricted to signed-in users.
insert into storage.buckets (id, name, public)
values ('certificate-assets', 'certificate-assets', true)
on conflict (id) do update set public = excluded.public;

-- Persistent certificate settings.
create table if not exists public.certificate_settings (
  id int primary key default 1 check (id = 1),
  design_url text,
  logo_url text,
  issuer text not null default 'GEN Z REEL FEST 2026',
  footer text not null default 'Official Final Result',
  updated_at timestamptz not null default now()
);

insert into public.certificate_settings(id)
values (1)
on conflict (id) do nothing;

create table if not exists public.certificate_jury_settings (
  judge_id uuid primary key references auth.users(id) on delete cascade,
  post text,
  signature_url text,
  updated_at timestamptz not null default now()
);

alter table public.certificate_settings enable row level security;
alter table public.certificate_jury_settings enable row level security;

-- Remove/recreate only these migration-owned policies so the script can be safely rerun.
drop policy if exists "certificate settings public read" on public.certificate_settings;
drop policy if exists "certificate settings admin write" on public.certificate_settings;
drop policy if exists "certificate jury public read" on public.certificate_jury_settings;
drop policy if exists "certificate jury admin write" on public.certificate_jury_settings;
drop policy if exists "certificate assets public read" on storage.objects;
drop policy if exists "certificate assets authenticated upload" on storage.objects;
drop policy if exists "certificate assets authenticated update" on storage.objects;
drop policy if exists "certificate assets authenticated delete" on storage.objects;

create policy "certificate settings public read"
on public.certificate_settings for select
to anon, authenticated using (true);

create policy "certificate settings admin write"
on public.certificate_settings for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "certificate jury public read"
on public.certificate_jury_settings for select
to anon, authenticated using (true);

create policy "certificate jury admin write"
on public.certificate_jury_settings for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "certificate assets public read"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'certificate-assets');

create policy "certificate assets authenticated upload"
on storage.objects for insert
to authenticated
with check (bucket_id = 'certificate-assets' and public.is_admin());

create policy "certificate assets authenticated update"
on storage.objects for update
to authenticated
using (bucket_id = 'certificate-assets' and public.is_admin())
with check (bucket_id = 'certificate-assets' and public.is_admin());

create policy "certificate assets authenticated delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'certificate-assets' and public.is_admin());

-- After running this migration, the web settings page can safely move
-- design/logo/signatures from browser localStorage to Supabase Storage.
-- No certificate asset is uploaded by this migration.