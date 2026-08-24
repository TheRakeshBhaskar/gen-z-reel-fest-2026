# GEN Z REEL FEST 2026 V6.0

A Google Apps Script-free architecture using Vercel + Supabase.

## Stack
- Frontend: static HTML/CSS/JavaScript
- Hosting: Vercel
- Database/Auth/Storage: Supabase
- Custom domain: reelfest.rajkumarbadole.in

## Setup
1. Create a Supabase project.
2. Run `supabase.sql` in Supabase SQL Editor.
3. Create a Storage bucket named `public-assets`.
4. Enable Email Auth.
5. Create an admin user and change its profile role to `admin` using the SQL comment in `supabase.sql`.
6. Open `index.html` and replace the two CONFIG placeholders with the Supabase project URL and publishable key.
7. Deploy this folder to Vercel.
8. Add `reelfest.rajkumarbadole.in` as a custom domain in Vercel and follow the DNS record Vercel provides. Do not change `jansampark.rajkumarbadole.in`.

## V6.0 features
- Public home page, banner URL and event details
- Registration
- Unique registration IDs
- Participant email magic-link login
- Participant status page
- Finalist Top Reels
- Authenticated one-vote-per-user protection
- Admin/Jury dashboard
- Shortlist/finalist controls
- Event schedule fields
- Results table
- Supabase RLS security

V6.0 intentionally uses Instagram Reel URLs instead of direct MP4 uploads for the first release.
