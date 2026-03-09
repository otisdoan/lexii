-- Add detail columns to grammar table (for existing databases where 005 already ran)
ALTER TABLE grammar
  ADD COLUMN IF NOT EXISTS formula        TEXT,
  ADD COLUMN IF NOT EXISTS examples       JSONB NOT NULL DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS related_topics JSONB NOT NULL DEFAULT '[]';

-- Update existing lesson-1 grammar records with rich content
UPDATE grammar SET
  formula        = 'S + V(s/es) | S + do/does + not + V | Do/Does + S + V?',
  examples       = '["She works at a corporation.", "The company opens at 9 AM.", "He does not attend meetings on Fridays.", "Do they sign contracts every quarter?"]'::jsonb,
  related_topics = '["Thì hiện tại tiếp diễn (Present Continuous)", "Thì quá khứ đơn (Simple Past)"]'::jsonb
WHERE title = 'Thì hiện tại đơn (Simple Present)';

UPDATE grammar SET
  formula        = 'S + am/is/are + V-ing | S + am/is/are + not + V-ing | Am/Is/Are + S + V-ing?',
  examples       = '["The manager is negotiating a new contract.", "We are reviewing the proposal right now.", "Is she attending the corporate meeting?"]'::jsonb,
  related_topics = '["Thì hiện tại đơn (Simple Present)", "Thì quá khứ tiếp diễn (Past Continuous)"]'::jsonb
WHERE title = 'Thì hiện tại tiếp diễn (Present Continuous)';

UPDATE grammar SET
  formula        = 'S + V2/V-ed | S + did not + V | Did + S + V?',
  examples       = '["The company signed the proposal last week.", "She did not attend the major meeting.", "Did the senior executive negotiate the contract?"]'::jsonb,
  related_topics = '["Thì hiện tại đơn (Simple Present)", "Thì quá khứ hoàn thành (Past Perfect)"]'::jsonb
WHERE title = 'Thì quá khứ đơn (Simple Past)';

-- Insert additional lesson-1 grammar topics (ngu-phap.html style)
INSERT INTO grammar (lesson, title, content, formula, examples, related_topics, sort_order) VALUES
  (1, 'Cấu trúc chung của một câu trong tiếng Anh',
   'Một câu hoàn chỉnh trong tiếng Anh gồm các thành phần: Chủ ngữ, Động từ, Bổ ngữ và Trạng ngữ.',
   'SUBJECT + VERB + COMPLEMENT (OBJECT: DIRECT | INDIRECT) + MODIFIER',
   '["John and I ate a pizza last night.", "We studied \"present perfect\" last week.", "He runs very fast.", "I like walking."]'::jsonb,
   '["Subject (chủ ngữ)", "Verb (động từ)", "Complement (vị ngữ)", "Modifier (trạng từ)"]'::jsonb,
   0),
  (1, 'Subject (chủ ngữ)',
   'Chủ ngữ là người hoặc vật thực hiện hành động trong câu. Chủ ngữ thường là danh từ, đại từ hoặc cụm danh từ.',
   NULL,
   '["The manager submitted the report.", "She is a senior executive.", "John and his team negotiated the contract."]'::jsonb,
   '["Cấu trúc chung của một câu", "Verb (động từ)"]'::jsonb,
   10),
  (1, 'Verb (động từ)',
   'Động từ diễn tả hành động hoặc trạng thái của chủ ngữ. Động từ có thể là nội động từ (không cần tân ngữ) hoặc ngoại động từ (cần tân ngữ).',
   NULL,
   '["The company operates in 30 countries.", "She negotiated a major deal.", "The schedule was confirmed yesterday."]'::jsonb,
   '["Subject (chủ ngữ)", "Complement (vị ngữ)"]'::jsonb,
   20),
  (1, 'Complement (vị ngữ)',
   'Bổ ngữ bổ sung thông tin cho động từ hoặc chủ ngữ. Tân ngữ trực tiếp (Direct Object) và gián tiếp (Indirect Object) đều là dạng bổ ngữ.',
   NULL,
   '["She sent him the invoice.", "The manager reviewed the proposal.", "We discussed the corporate strategy."]'::jsonb,
   '["Subject (chủ ngữ)", "Modifier (trạng từ)"]'::jsonb,
   30),
  (1, 'Modifier (trạng từ)',
   'Trạng ngữ bổ sung thông tin về thời gian, địa điểm, cách thức, hoặc tần suất. Trạng ngữ có thể đứng đầu, giữa hoặc cuối câu.',
   NULL,
   '["He runs very fast.", "The meeting was held yesterday in the boardroom.", "She always arrives on time."]'::jsonb,
   '["Cấu trúc chung của một câu", "Complement (vị ngữ)"]'::jsonb,
   40),
  (1, 'Danh từ đếm được và không đếm được',
   'Danh từ đếm được (count nouns) có thể dùng với a/an và có dạng số nhiều. Danh từ không đếm được (non-count nouns) không có dạng số nhiều và không dùng với a/an.',
   'Count noun: a/an + N, Ns/Nes | Non-count noun: some/any/much + N (no plural)',
   '["She has an appointment at 3 PM. (count)", "We need more information about the contract. (non-count)", "Please send me the documents. (count)", "The advice was very helpful. (non-count)"]'::jsonb,
   '["Cách dùng quán từ không xác định ''a'' và ''an''", "Subject (chủ ngữ)"]'::jsonb,
   50),
  (1, 'Cách dùng quán từ không xác định ''a'' và ''an''',
   'Dùng "a" trước từ bắt đầu bằng âm phụ âm, dùng "an" trước từ bắt đầu bằng âm nguyên âm (a, e, i, o, u). Lưu ý: quy tắc dựa trên ÂM, không phải CHỮ CÁI.',
   'a + consonant sound | an + vowel sound',
   '["She has a meeting at noon.", "He is an executive officer.", "It was an hour-long presentation. (''h'' silent → vowel sound)", "She works for a university. (''u'' sounds like ''you'' → consonant sound)"]'::jsonb,
   '["Danh từ đếm được và không đếm được", "Subject (chủ ngữ)"]'::jsonb,
   60)
ON CONFLICT DO NOTHING;
