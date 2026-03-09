-- ============================================
-- WRITING PRACTICE TABLES
-- Run this in Supabase SQL Editor
-- ============================================

-- Writing prompts — standalone prompts for Practice > Writing
-- Part 1: Describe the image (1–2 sentences)
-- Part 2: Respond to a written request (email / notice)
-- Part 3: Write an opinion essay

CREATE TABLE IF NOT EXISTS public.writing_prompts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  part_number     INT  NOT NULL CHECK (part_number IN (1, 2, 3)),
  title           TEXT,
  prompt          TEXT NOT NULL,           -- instruction shown to user
  image_url       TEXT,                    -- Part 1: image to describe
  passage_text    TEXT,                    -- Part 2: email / notice body
  passage_subject TEXT,                    -- Part 2: subject / heading
  model_answer    TEXT,                    -- sample reference answer
  hint_words      TEXT,                    -- comma-separated vocabulary hints
  order_index     INT  NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.writing_prompts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view writing prompts"
  ON public.writing_prompts FOR SELECT
  USING (true);

-- User writing submissions
CREATE TABLE IF NOT EXISTS public.writing_submissions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prompt_id   UUID NOT NULL REFERENCES public.writing_prompts(id) ON DELETE CASCADE,
  part_number INT  NOT NULL,
  content     TEXT NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.writing_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own writing submissions"
  ON public.writing_submissions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own writing submissions"
  ON public.writing_submissions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ── Sample data ──────────────────────────────────────────────────────────────

-- Part 1: Image description
INSERT INTO public.writing_prompts
  (part_number, title, prompt, image_url, model_answer, hint_words, order_index)
VALUES
(1, 'Đàn guitar trong hộp',
 'Mô tả những gì bạn thấy trong bức ảnh bằng 1–2 câu.',
 'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=600',
 'A guitar is resting in its open black case on a wooden floor. The case is lined with soft velvet fabric to protect the instrument.',
 'guitar, case, wooden, open, resting, fabric', 1),

(1, 'Cuộc họp văn phòng',
 'Mô tả những gì bạn thấy trong bức ảnh bằng 1–2 câu.',
 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=600',
 'Several people are sitting around a conference table in a bright office room. They appear to be engaged in a discussion.',
 'conference, meeting, sitting, discussing, office, table', 2),

(1, 'Bãi biển buổi sáng',
 'Mô tả những gì bạn thấy trong bức ảnh bằng 1–2 câu.',
 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
 'A calm beach is shown in the early morning with gentle waves washing onto the sandy shore. There are no people visible and the sky is clear.',
 'beach, waves, sand, calm, morning, shore', 3);

-- Part 2: Respond to an email / request
INSERT INTO public.writing_prompts
  (part_number, title, prompt, passage_text, passage_subject, model_answer, hint_words, order_index)
VALUES
(2, 'Phản hồi yêu cầu thông tin sản phẩm',
 'Bạn là nhân viên chăm sóc khách hàng. Đọc email bên dưới và viết một phản hồi phù hợp.',
 'I am interested in purchasing your language learning application. Could you please provide me with information about the available pricing plans and whether a free trial is offered?',
 'Subject: Language App Inquiry',
 'Dear Customer,\n\nThank you for your interest in our application. We offer three plans: Basic ($9.99/month), Premium ($19.99/month), and Annual ($99/year). All plans include a 7-day free trial with full access to all features.\n\nPlease feel free to contact us if you have further questions.\n\nBest regards,\nCustomer Service',
 'pricing, plan, trial, available, monthly, annual', 1),

(2, 'Phản hồi đặt phòng khách sạn',
 'Bạn là nhân viên lễ tân khách sạn. Đọc email bên dưới và viết một phản hồi ngắn.',
 'I would like to book a double room for two nights from March 15 to March 17. Could you confirm the availability and the room rate?',
 'Subject: Room Reservation Request',
 'Dear Guest,\n\nThank you for your reservation request. We are pleased to confirm that a double room is available from March 15 to March 17 at a rate of $120 per night. A total of $240 is required.\n\nPlease reply with your contact details to complete the booking.\n\nWarm regards,\nFront Desk',
 'available, confirmation, rate, nights, booking, contact', 2);

-- Verify:
-- SELECT part_number, title, order_index FROM writing_prompts ORDER BY part_number, order_index;
