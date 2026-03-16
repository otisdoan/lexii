-- Track per-question listening practice history
CREATE TABLE IF NOT EXISTS public.listening_answer_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  selected_option_id UUID REFERENCES public.question_options(id) ON DELETE SET NULL,
  is_correct BOOLEAN NOT NULL DEFAULT FALSE,
  answered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_listening_answer_history_user_answered_at
  ON public.listening_answer_history(user_id, answered_at DESC);

CREATE INDEX IF NOT EXISTS idx_listening_answer_history_user_question
  ON public.listening_answer_history(user_id, question_id);

ALTER TABLE public.listening_answer_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own listening answer history"
  ON public.listening_answer_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own listening answer history"
  ON public.listening_answer_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Track deduplicated wrong questions for retry practice
CREATE TABLE IF NOT EXISTS public.wrong_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  last_selected_option_id UUID REFERENCES public.question_options(id) ON DELETE SET NULL,
  wrong_count INT NOT NULL DEFAULT 1,
  last_answered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_wrong_questions_user_last_answered
  ON public.wrong_questions(user_id, last_answered_at DESC);

ALTER TABLE public.wrong_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wrong questions"
  ON public.wrong_questions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wrong questions"
  ON public.wrong_questions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wrong questions"
  ON public.wrong_questions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.set_wrong_questions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_wrong_questions_updated_at_trigger ON public.wrong_questions;
CREATE TRIGGER set_wrong_questions_updated_at_trigger
  BEFORE UPDATE ON public.wrong_questions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_wrong_questions_updated_at();
