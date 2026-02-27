-- ============================================
-- LEXII IELTS - SUPABASE DATABASE MIGRATION
-- ============================================

-- 1. PROFILES TABLE (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT,
  role TEXT DEFAULT 'user',
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 2. TESTS TABLE
CREATE TABLE IF NOT EXISTS public.tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  duration INT NOT NULL DEFAULT 120,
  type TEXT NOT NULL DEFAULT 'full_test',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.tests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view tests"
  ON public.tests FOR SELECT
  USING (true);


-- 3. TEST PARTS TABLE
CREATE TABLE IF NOT EXISTS public.test_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_id UUID NOT NULL REFERENCES public.tests(id) ON DELETE CASCADE,
  part_number INT NOT NULL,
  instructions TEXT,
  UNIQUE(test_id, part_number)
);

ALTER TABLE public.test_parts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view test parts"
  ON public.test_parts FOR SELECT
  USING (true);


-- 4. PASSAGES TABLE
CREATE TABLE IF NOT EXISTS public.passages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id UUID NOT NULL REFERENCES public.test_parts(id) ON DELETE CASCADE,
  title TEXT,
  content TEXT NOT NULL
);

ALTER TABLE public.passages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view passages"
  ON public.passages FOR SELECT
  USING (true);


-- 5. QUESTIONS TABLE
CREATE TABLE IF NOT EXISTS public.questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id UUID NOT NULL REFERENCES public.test_parts(id) ON DELETE CASCADE,
  passage_id UUID REFERENCES public.passages(id) ON DELETE SET NULL,
  question_text TEXT,
  order_index INT NOT NULL DEFAULT 0
);

ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view questions"
  ON public.questions FOR SELECT
  USING (true);


-- 6. QUESTION OPTIONS TABLE
CREATE TABLE IF NOT EXISTS public.question_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT FALSE
);

ALTER TABLE public.question_options ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view options"
  ON public.question_options FOR SELECT
  USING (true);


-- 7. QUESTION MEDIA TABLE
CREATE TABLE IF NOT EXISTS public.question_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('audio', 'image', 'text')),
  url TEXT NOT NULL
);

ALTER TABLE public.question_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view media"
  ON public.question_media FOR SELECT
  USING (true);


-- 8. ATTEMPTS TABLE
CREATE TABLE IF NOT EXISTS public.attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  test_id UUID NOT NULL REFERENCES public.tests(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  submitted_at TIMESTAMPTZ,
  score INT
);

ALTER TABLE public.attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own attempts"
  ON public.attempts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own attempts"
  ON public.attempts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own attempts"
  ON public.attempts FOR UPDATE
  USING (auth.uid() = user_id);


-- 9. ANSWERS TABLE
CREATE TABLE IF NOT EXISTS public.answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id UUID NOT NULL REFERENCES public.attempts(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  option_id UUID REFERENCES public.question_options(id),
  is_correct BOOLEAN
);

ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own answers"
  ON public.answers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.attempts
      WHERE attempts.id = answers.attempt_id
      AND attempts.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own answers"
  ON public.answers FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.attempts
      WHERE attempts.id = attempt_id
      AND attempts.user_id = auth.uid()
    )
  );


-- 10. VOCABULARY TABLE
CREATE TABLE IF NOT EXISTS public.vocabulary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  word TEXT NOT NULL,
  meaning TEXT NOT NULL,
  example TEXT
);

ALTER TABLE public.vocabulary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view vocabulary"
  ON public.vocabulary FOR SELECT
  USING (true);


-- 11. USER PROGRESS TABLE
CREATE TABLE IF NOT EXISTS public.user_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  accuracy NUMERIC DEFAULT 0,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, question_id)
);

ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress"
  ON public.user_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert own progress"
  ON public.user_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
  ON public.user_progress FOR UPDATE
  USING (auth.uid() = user_id);


-- ============================================
-- STORAGE BUCKETS
-- ============================================
INSERT INTO storage.buckets (id, name, public) VALUES ('audio', 'audio', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('images', 'images', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('documents', 'documents', false) ON CONFLICT DO NOTHING;

-- Storage policies
CREATE POLICY "Public audio access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'audio');

CREATE POLICY "Public images access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'images');

CREATE POLICY "Public avatars access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Authenticated users can upload avatars"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
