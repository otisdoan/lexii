-- Subscription orders for PayOS checkout flow
CREATE TABLE IF NOT EXISTS public.subscription_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id TEXT NOT NULL,
  plan_name TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'VND',
  provider TEXT NOT NULL DEFAULT 'payos',
  order_code BIGINT NOT NULL UNIQUE,
  payment_link_id TEXT,
  checkout_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  provider_raw JSONB,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.subscription_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription orders"
  ON public.subscription_orders
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscription orders"
  ON public.subscription_orders
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.touch_subscription_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_subscription_orders_updated_at ON public.subscription_orders;
CREATE TRIGGER set_subscription_orders_updated_at
  BEFORE UPDATE ON public.subscription_orders
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_subscription_orders_updated_at();
