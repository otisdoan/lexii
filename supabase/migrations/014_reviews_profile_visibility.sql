-- ============================================
-- Allow authenticated users to read profile info
-- of users who have posted reviews.
-- This enables review list to show reviewer name/avatar.
-- ============================================

CREATE OR REPLACE FUNCTION public.can_view_profile_safely(profile_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  IF auth.uid() = profile_id THEN
    RETURN true;
  END IF;

  BEGIN
    RETURN EXISTS (
      SELECT 1
      FROM public.reviews r
      WHERE r.user_id = profile_id
    );
  EXCEPTION
    WHEN undefined_table THEN
      RETURN false;
    WHEN insufficient_privilege THEN
      RETURN false;
    WHEN others THEN
      RETURN false;
  END;
END;
$$;

REVOKE ALL ON FUNCTION public.can_view_profile_safely(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_view_profile_safely(uuid) TO authenticated;

DROP POLICY IF EXISTS "Authenticated can view reviewer profiles" ON public.profiles;

CREATE POLICY "Authenticated can view reviewer profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (public.can_view_profile_safely(id));
