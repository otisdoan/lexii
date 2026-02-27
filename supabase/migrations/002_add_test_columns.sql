-- ============================================
-- ADD total_questions AND is_premium TO tests
-- ============================================

ALTER TABLE public.tests
  ADD COLUMN IF NOT EXISTS total_questions INT NOT NULL DEFAULT 200;

ALTER TABLE public.tests
  ADD COLUMN IF NOT EXISTS is_premium BOOLEAN NOT NULL DEFAULT FALSE;
