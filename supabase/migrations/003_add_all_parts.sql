-- ============================================
-- ADD MISSING PARTS (2-7) TO EXISTING TESTS
-- Run this in Supabase SQL Editor
-- ============================================

-- First, check what tests and parts exist:
-- SELECT t.id, t.title, tp.part_number 
-- FROM tests t LEFT JOIN test_parts tp ON tp.test_id = t.id ORDER BY t.title, tp.part_number;

-- Insert missing parts for ALL existing full tests
-- (this inserts rows only if they don't already exist via ON CONFLICT DO NOTHING)

DO $$
DECLARE
  test_rec RECORD;
BEGIN
  FOR test_rec IN SELECT id FROM public.tests WHERE type = 'full_test' LOOP
    -- Part 1: Photographs (6 questions)
    INSERT INTO public.test_parts (test_id, part_number, instructions)
    VALUES (
      test_rec.id, 1,
      'For each question, you will see a picture and hear four statements. Select the best description of the picture.'
    ) ON CONFLICT (test_id, part_number) DO NOTHING;

    -- Part 2: Question-Response (25 questions)
    INSERT INTO public.test_parts (test_id, part_number, instructions)
    VALUES (
      test_rec.id, 2,
      'You will hear a question or statement and three responses. Select the best response.'
    ) ON CONFLICT (test_id, part_number) DO NOTHING;

    -- Part 3: Conversations (39 questions)
    INSERT INTO public.test_parts (test_id, part_number, instructions)
    VALUES (
      test_rec.id, 3,
      'You will hear conversations between two or more people. Answer the questions about each conversation.'
    ) ON CONFLICT (test_id, part_number) DO NOTHING;

    -- Part 4: Talks (30 questions)
    INSERT INTO public.test_parts (test_id, part_number, instructions)
    VALUES (
      test_rec.id, 4,
      'You will hear talks given by a single speaker. Answer the questions about each talk.'
    ) ON CONFLICT (test_id, part_number) DO NOTHING;

    -- Part 5: Incomplete Sentences (30 questions)
    INSERT INTO public.test_parts (test_id, part_number, instructions)
    VALUES (
      test_rec.id, 5,
      'A word or phrase is missing in each sentence. Select the best answer to complete the sentence.'
    ) ON CONFLICT (test_id, part_number) DO NOTHING;

    -- Part 6: Text Completion (16 questions)
    INSERT INTO public.test_parts (test_id, part_number, instructions)
    VALUES (
      test_rec.id, 6,
      'Read the texts below. A word or phrase is missing in parts of each text. Select the best answer.'
    ) ON CONFLICT (test_id, part_number) DO NOTHING;

    -- Part 7: Reading Comprehension (54 questions)
    INSERT INTO public.test_parts (test_id, part_number, instructions)
    VALUES (
      test_rec.id, 7,
      'Read the texts and select the best answer to each question based on what is stated or implied.'
    ) ON CONFLICT (test_id, part_number) DO NOTHING;

  END LOOP;
END $$;

-- Verify result:
SELECT t.title, tp.part_number, tp.instructions
FROM tests t 
JOIN test_parts tp ON tp.test_id = t.id 
ORDER BY t.title, tp.part_number;
