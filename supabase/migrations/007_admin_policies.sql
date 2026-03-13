-- ============================================
-- Admin RLS policies for profiles table
-- ============================================

-- Helper function that checks if the current user is an admin.
-- SECURITY DEFINER lets it bypass RLS when doing the self-lookup,
-- avoiding infinite recursion.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Admins can read all profiles
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (public.is_admin());

-- Admins can update any profile (e.g. role changes)
CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE
  USING (public.is_admin());

-- Admins can delete any profile
CREATE POLICY "Admins can delete all profiles"
  ON public.profiles FOR DELETE
  USING (public.is_admin());
