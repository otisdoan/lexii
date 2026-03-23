-- Safety patch for profile visibility used by reviews + premium checks.
-- Ensures users can always read their own profile,
-- and authenticated users can read profiles of users who posted reviews.

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

DROP POLICY IF EXISTS "Authenticated can view reviewer profiles" ON public.profiles;

CREATE POLICY "Authenticated can view reviewer profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    auth.uid() = id
    OR EXISTS (
      SELECT 1
      FROM public.reviews r
      WHERE r.user_id = profiles.id
    )
  );
