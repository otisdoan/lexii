-- ============================================
-- Admin RLS policy for subscription_orders
-- ============================================

-- Admins can read all subscription orders for transaction management.
CREATE POLICY "Admins can view all subscription orders"
  ON public.subscription_orders
  FOR SELECT
  USING (public.is_admin());
