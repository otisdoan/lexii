-- Hotfix: prevent 500 errors from profiles SELECT policy that references reviews.
-- Root issue: direct EXISTS on public.reviews inside profiles policy can fail
-- in some environments (permission/RLS recursion/table mismatch), breaking all
-- APIs that read profiles.

-- 1) Safety helper that never throws; fallback to own-profile access.
CREATE OR REPLACE FUNCTION public.can_view_profile_safely(profile_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  -- Always allow reading own profile.
  IF auth.uid() = profile_id THEN
    RETURN true;
  END IF;

  -- Allow reading profiles of users who posted reviews.
  BEGIN
    RETURN EXISTS (
      SELECT 1
      FROM public.reviews r
      WHERE r.user_id = profile_id
    );
  EXCEPTION
    WHEN undefined_table THEN
      -- If reviews table is missing in this environment, do not fail APIs.
      RETURN false;
    WHEN insufficient_privilege THEN
      -- If permissions are insufficient, do not fail APIs.
      RETURN false;
    WHEN others THEN
      -- Never propagate policy-time errors to client APIs.
      RETURN false;
  END;
END;
$$;

REVOKE ALL ON FUNCTION public.can_view_profile_safely(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_view_profile_safely(uuid) TO authenticated;

-- 2) Replace risky policy with safe policy.
DROP POLICY IF EXISTS "Authenticated can view reviewer profiles" ON public.profiles;

CREATE POLICY "Authenticated can view reviewer profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (public.can_view_profile_safely(id));

-- 3) Ensure own-profile policy always exists.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'profiles'
      AND policyname = 'Users can view own profile'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Users can view own profile"
        ON public.profiles FOR SELECT
        USING (auth.uid() = id)
    $policy$;
  END IF;
END
$$;
