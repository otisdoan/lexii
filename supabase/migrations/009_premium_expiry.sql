-- Add premium expiry support
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS premium_expires_at TIMESTAMPTZ;

ALTER TABLE public.subscription_orders
  ADD COLUMN IF NOT EXISTS plan_duration_months INT,
  ADD COLUMN IF NOT EXISTS is_lifetime BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS granted_until TIMESTAMPTZ;
