-- GEN Z REEL FEST 2026 - Jury Scoring V3
-- Run this once in Supabase > SQL Editor.

alter table public.entries
  add column if not exists jury_creativity integer,
  add column if not exists jury_content integer,
  add column if not exists jury_editing integer,
  add column if not exists jury_presentation integer,
  add column if not exists jury_local_connect integer,
  add column if not exists jury_total integer;

-- Keep scores within the intended 0-20 range.
alter table public.entries
  drop constraint if exists entries_jury_scores_check;

alter table public.entries
  add constraint entries_jury_scores_check check (
    (jury_creativity is null or jury_creativity between 0 and 20) and
    (jury_content is null or jury_content between 0 and 20) and
    (jury_editing is null or jury_editing between 0 and 20) and
    (jury_presentation is null or jury_presentation between 0 and 20) and
    (jury_local_connect is null or jury_local_connect between 0 and 20) and
    (jury_total is null or jury_total between 0 and 100)
  );

-- Refresh PostgREST schema cache.
notify pgrst, 'reload schema';