-- Drop and recreate to ensure correct schema
DROP TABLE IF EXISTS grammar CASCADE;
DROP TABLE IF EXISTS vocabulary CASCADE;

-- Theory: Vocabulary table
CREATE TABLE vocabulary (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson      INTEGER NOT NULL DEFAULT 1,
  word        TEXT    NOT NULL,
  phonetic    TEXT,
  definition  TEXT    NOT NULL,
  word_class  TEXT,                           -- n, adj, v, adv, prep ...
  score_level TEXT    NOT NULL DEFAULT '450+', -- '450+' | '600+' | '800+' | '990+'
  audio_url   TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Theory: Grammar table
CREATE TABLE grammar (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson         INTEGER NOT NULL DEFAULT 1,
  title          TEXT    NOT NULL,
  content        TEXT    NOT NULL DEFAULT '',  -- markdown / plain text explanation
  formula        TEXT,                         -- e.g. "S + V(s/es)"
  examples       JSONB   NOT NULL DEFAULT '[]',
  related_topics JSONB   NOT NULL DEFAULT '[]',
  sort_order     INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS vocabulary_lesson_idx       ON vocabulary (lesson);
CREATE INDEX IF NOT EXISTS vocabulary_score_level_idx  ON vocabulary (score_level);
CREATE INDEX IF NOT EXISTS grammar_lesson_idx          ON grammar (lesson);

-- Sample vocabulary data (Lesson 1 – Business / Corporate)
INSERT INTO vocabulary (lesson, word, phonetic, definition, word_class, score_level, sort_order) VALUES
  (1, 'Inc',         '/ɪŋk/',           'Tập đoàn',                     'n',   '800+', 1),
  (1, 'Corporate',   '/ˈkɔːrpərət/',    'Thuộc về tập đoàn',            'adj', '800+', 2),
  (1, 'Senior',      '/ˈsiːniər/',      'Cấp cao',                      'adj', '800+', 3),
  (1, 'Major',       '/ˈmeɪdʒər/',      'Chủ yếu, quan trọng',          'adj', '800+', 4),
  (1, 'Executive',   '/ɪɡˈzekjətɪv/',   'Giám đốc điều hành',           'n',   '800+', 5),
  (1, 'Appointment', '/əˈpɔɪntmənt/',   'Cuộc hẹn, buổi gặp mặt',       'n',   '600+', 6),
  (1, 'Schedule',    '/ˈskedʒuːl/',     'Lịch trình, thời gian biểu',   'n/v', '600+', 7),
  (1, 'Negotiate',   '/nɪˈɡoʊʃieɪt/',  'Đàm phán',                     'v',   '800+', 8),
  (1, 'Contract',    '/ˈkɒntrækt/',     'Hợp đồng',                     'n',   '600+', 9),
  (1, 'Proposal',    '/prəˈpoʊzəl/',    'Đề xuất, dự thảo',             'n',   '600+', 10),
  (2, 'Invoice',     '/ˈɪnvɔɪs/',       'Hóa đơn',                      'n',   '600+', 1),
  (2, 'Budget',      '/ˈbʌdʒɪt/',       'Ngân sách',                    'n',   '450+', 2),
  (2, 'Revenue',     '/ˈrevənjuː/',     'Doanh thu',                    'n',   '800+', 3),
  (2, 'Expenses',    '/ɪkˈspensɪz/',    'Chi phí',                      'n',   '600+', 4),
  (2, 'Profit',      '/ˈprɒfɪt/',       'Lợi nhuận',                    'n',   '450+', 5);

-- Sample grammar data
INSERT INTO grammar (lesson, title, content, formula, examples, related_topics, sort_order) VALUES
  (1, 'Cấu trúc chung của một câu trong tiếng Anh',
   'Một câu hoàn chỉnh trong tiếng Anh gồm các thành phần: Chủ ngữ, Động từ, Bổ ngữ và Trạng ngữ.',
   'SUBJECT + VERB + COMPLEMENT (OBJECT: DIRECT | INDIRECT) + MODIFIER',
   '["John and I ate a pizza last night.", "We studied \"present perfect\" last week.", "He runs very fast.", "I like walking."]'::jsonb,
   '["Subject (chủ ngữ)", "Verb (động từ)", "Complement (vị ngữ)", "Modifier (trạng từ)"]'::jsonb,
   0),
  (1, 'Subject (chủ ngữ)',
   'Chủ ngữ là người hoặc vật thực hiện hành động trong câu.',
   NULL,
   '["The manager submitted the report.", "She is a senior executive.", "John and his team negotiated the contract."]'::jsonb,
   '["Cấu trúc chung của một câu trong tiếng Anh", "Verb (động từ)"]'::jsonb,
   10),
  (1, 'Verb (động từ)',
   'Động từ diễn tả hành động hoặc trạng thái của chủ ngữ.',
   NULL,
   '["The company operates in 30 countries.", "She negotiated a major deal.", "The schedule was confirmed yesterday."]'::jsonb,
   '["Subject (chủ ngữ)", "Complement (vị ngữ)"]'::jsonb,
   20),
  (1, 'Complement (vị ngữ)',
   'Bổ ngữ bổ sung thông tin cho động từ hoặc chủ ngữ.',
   NULL,
   '["She sent him the invoice.", "The manager reviewed the proposal.", "We discussed the corporate strategy."]'::jsonb,
   '["Subject (chủ ngữ)", "Modifier (trạng từ)"]'::jsonb,
   30),
  (1, 'Modifier (trạng từ)',
   'Trạng ngữ bổ sung thông tin về thời gian, địa điểm, cách thức hoặc tần suất.',
   NULL,
   '["He runs very fast.", "The meeting was held yesterday in the boardroom.", "She always arrives on time."]'::jsonb,
   '["Cấu trúc chung của một câu trong tiếng Anh", "Complement (vị ngữ)"]'::jsonb,
   40),
  (1, 'Thì hiện tại đơn (Simple Present)',
   'Dùng để diễn đạt các hành động lặp đi lặp lại, thói quen, hoặc sự thật chung.',
   'S + V(s/es) | S + do/does + not + V | Do/Does + S + V?',
   '["She works at a corporation.", "The company opens at 9 AM.", "He does not attend meetings on Fridays.", "Do they sign contracts every quarter?"]'::jsonb,
   '["Thì hiện tại tiếp diễn (Present Continuous)", "Thì quá khứ đơn (Simple Past)"]'::jsonb,
   50),
  (1, 'Thì hiện tại tiếp diễn (Present Continuous)',
   'Dùng để diễn đạt hành động đang xảy ra tại thời điểm nói.',
   'S + am/is/are + V-ing | S + am/is/are + not + V-ing | Am/Is/Are + S + V-ing?',
   '["The manager is negotiating a new contract.", "We are reviewing the proposal right now.", "Is she attending the corporate meeting?"]'::jsonb,
   '["Thì hiện tại đơn (Simple Present)", "Thì quá khứ tiếp diễn (Past Continuous)"]'::jsonb,
   60),
  (1, 'Danh từ đếm được và không đếm được',
   'Danh từ đếm được (count nouns) có thể dùng với a/an và có dạng số nhiều. Danh từ không đếm được (non-count nouns) không có dạng số nhiều.',
   'Count noun: a/an + N, N-s/es | Non-count noun: some/any/much + N (no plural)',
   '["She has an appointment at 3 PM. (count)", "We need more information about the contract. (non-count)", "Please send me the documents. (count)", "The advice was very helpful. (non-count)"]'::jsonb,
   '["Cách dùng quán từ không xác định ''a'' và ''an''", "Subject (chủ ngữ)"]'::jsonb,
   70),
  (1, 'Cách dùng quán từ không xác định ''a'' và ''an''',
   'Dùng "a" trước từ bắt đầu bằng âm phụ âm, "an" trước từ bắt đầu bằng âm nguyên âm.',
   'a + consonant sound | an + vowel sound',
   '["She has a meeting at noon.", "He is an executive officer.", "It was an hour-long presentation.", "She works for a university."]'::jsonb,
   '["Danh từ đếm được và không đếm được", "Subject (chủ ngữ)"]'::jsonb,
   80),
  (2, 'Thì quá khứ đơn (Simple Past)',
   'Dùng để diễn đạt hành động đã xảy ra và kết thúc trong quá khứ.',
   'S + V2/V-ed | S + did not + V | Did + S + V?',
   '["The company signed the proposal last week.", "She did not attend the major meeting.", "Did the senior executive negotiate the contract?"]'::jsonb,
   '["Thì hiện tại đơn (Simple Present)", "Thì quá khứ hoàn thành (Past Perfect)"]'::jsonb,
   1);
