-- GEN Z REEL FEST 2026 - Jury Management V22 FIX
-- Run this entire SQL once in Supabase SQL Editor.

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';

CREATE UNIQUE INDEX IF NOT EXISTS profiles_email_unique_idx
ON public.profiles (lower(email))
WHERE email IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.jury_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  full_name text NOT NULL,
  phone text,
  role text NOT NULL DEFAULT 'judge' CHECK (role IN ('judge','manager')),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  accepted_at timestamptz
);

ALTER TABLE public.jury_invites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin can manage jury invites" ON public.jury_invites;
CREATE POLICY "admin can manage jury invites"
ON public.jury_invites
FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

CREATE OR REPLACE FUNCTION public.handle_new_jury_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE inv public.jury_invites%ROWTYPE;
BEGIN
  SELECT * INTO inv FROM public.jury_invites
  WHERE lower(email)=lower(new.email) AND accepted_at IS NULL
  LIMIT 1;

  IF FOUND THEN
    INSERT INTO public.profiles (id, full_name, email, phone, role, status)
    VALUES (new.id, inv.full_name, new.email, inv.phone, inv.role, 'active')
    ON CONFLICT (id) DO UPDATE SET
      full_name=EXCLUDED.full_name,
      email=EXCLUDED.email,
      phone=EXCLUDED.phone,
      role=EXCLUDED.role,
      status='active';

    UPDATE public.jury_invites SET accepted_at=now() WHERE id=inv.id;
  END IF;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_jury ON auth.users;
CREATE TRIGGER on_auth_user_created_jury
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_jury_user();

-- Verify the required columns exist:
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema='public' AND table_name='profiles'
AND column_name IN ('id','role','full_name','email','phone','status')
ORDER BY ordinal_position;
