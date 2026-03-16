-- ============================================
-- ROADMAP (Learning Path) TABLES
-- ============================================

-- 1. roadmap_templates: Admin-created template (target_score + duration_days)
CREATE TABLE IF NOT EXISTS public.roadmap_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_score INT NOT NULL,
  duration_days INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(target_score, duration_days)
);

ALTER TABLE public.roadmap_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view roadmap templates"
  ON public.roadmap_templates FOR SELECT
  USING (true);


-- 2. roadmap_tasks: Tasks per day for each template
CREATE TABLE IF NOT EXISTS public.roadmap_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES public.roadmap_templates(id) ON DELETE CASCADE,
  day_number INT NOT NULL,
  task_type VARCHAR(50) NOT NULL CHECK (task_type IN ('theory', 'practice', 'test')),
  reference_id UUID,
  title VARCHAR(500) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_roadmap_tasks_template_day ON public.roadmap_tasks (template_id, day_number);

ALTER TABLE public.roadmap_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view roadmap tasks"
  ON public.roadmap_tasks FOR SELECT
  USING (true);


-- 3. user_roadmaps: User's active roadmap (one per user when they complete MH4)
CREATE TABLE IF NOT EXISTS public.user_roadmaps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  template_id UUID NOT NULL REFERENCES public.roadmap_templates(id) ON DELETE RESTRICT,
  initial_score INT NOT NULL,
  target_score INT NOT NULL,
  current_day INT NOT NULL DEFAULT 1,
  status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'dropped')),
  start_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_roadmaps_user_status ON public.user_roadmaps (user_id, status);

ALTER TABLE public.user_roadmaps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own roadmaps"
  ON public.user_roadmaps FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own roadmaps"
  ON public.user_roadmaps FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own roadmaps"
  ON public.user_roadmaps FOR UPDATE
  USING (auth.uid() = user_id);


-- 4. user_task_progress: Progress per task (unlocked / in_progress / completed)
CREATE TABLE IF NOT EXISTS public.user_task_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_roadmap_id UUID NOT NULL REFERENCES public.user_roadmaps(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES public.roadmap_tasks(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL DEFAULT 'unlocked' CHECK (status IN ('unlocked', 'in_progress', 'completed')),
  score_achieved INT,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_roadmap_id, task_id)
);

CREATE INDEX IF NOT EXISTS idx_user_task_progress_roadmap ON public.user_task_progress (user_roadmap_id);

ALTER TABLE public.user_task_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own task progress"
  ON public.user_task_progress FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roadmaps ur
      WHERE ur.id = user_task_progress.user_roadmap_id AND ur.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own task progress"
  ON public.user_task_progress FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_roadmaps ur
      WHERE ur.id = user_task_progress.user_roadmap_id AND ur.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own task progress"
  ON public.user_task_progress FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roadmaps ur
      WHERE ur.id = user_task_progress.user_roadmap_id AND ur.user_id = auth.uid()
    )
  );

-- Seed default roadmap templates (target_score, duration_days combinations)
INSERT INTO public.roadmap_templates (target_score, duration_days, title) VALUES
  (500, 30, 'Lộ trình TOEIC 500+ trong 30 ngày'),
  (500, 60, 'Lộ trình TOEIC 500+ trong 60 ngày'),
  (500, 90, 'Lộ trình TOEIC 500+ trong 90 ngày'),
  (500, 180, 'Lộ trình TOEIC 500+ trong 180 ngày'),
  (700, 30, 'Lộ trình TOEIC 700+ trong 30 ngày'),
  (700, 60, 'Lộ trình TOEIC 700+ trong 60 ngày'),
  (700, 90, 'Lộ trình TOEIC 700+ trong 90 ngày'),
  (700, 180, 'Lộ trình TOEIC 700+ trong 180 ngày'),
  (900, 30, 'Lộ trình TOEIC 900+ trong 30 ngày'),
  (900, 60, 'Lộ trình TOEIC 900+ trong 60 ngày'),
  (900, 90, 'Lộ trình TOEIC 900+ trong 90 ngày'),
  (900, 180, 'Lộ trình TOEIC 900+ trong 180 ngày')
ON CONFLICT (target_score, duration_days) DO NOTHING;