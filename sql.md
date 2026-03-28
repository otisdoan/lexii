// ERD generated from prisma-editor.md and Supabase migrations.
// Note: auth.users is the canonical users table in Supabase. The Prisma AuthUser model simulates it.

Enum chat_sender_role {
user
admin
system
}

Enum practice_mode {
speaking
writing
}

Enum roadmap_status {
active
completed
dropped
}

Enum task_status {
unlocked
in_progress
completed
}

Table auth.users {
id uuid [pk]
email text [unique]
}

Table profiles {
id uuid [pk, ref: - auth.users.id]
full_name text
phone text
role text
avatar_url text
created_at timestamptz
premium_expires_at timestamptz
}

Table subscription_orders {
id uuid [pk]
user_id uuid [ref: > auth.users.id]
plan_id text
plan_name text
amount int
currency text
provider text
order_code bigint [unique]
payment_link_id text
checkout_url text
status text
provider_raw jsonb
paid_at timestamptz
created_at timestamptz
updated_at timestamptz
plan_duration_months int
is_lifetime boolean
granted_until timestamptz
}

Table notifications {
id uuid [pk]
recipient_user_id uuid [ref: > auth.users.id]
type text
title text
body text
metadata jsonb
is_read boolean
created_at timestamptz
}

Table tests {
id uuid [pk]
title text
duration int
type text
created_at timestamptz
total_questions int
is_premium boolean
}

Table test_parts {
id uuid [pk]
test_id uuid [ref: > tests.id]
part_number int
instructions text
}

Table passages {
id uuid [pk]
part_id uuid [ref: > test_parts.id]
title text
content text
}

Table questions {
id uuid [pk]
part_id uuid [ref: > test_parts.id]
passage_id uuid [ref: > passages.id]
question_text text
order_index int
}

Table question_options {
id uuid [pk]
question_id uuid [ref: > questions.id]
content text
is_correct boolean
}

Table question_media {
id uuid [pk]
question_id uuid [ref: > questions.id]
type text
url text
}

Table attempts {
id uuid [pk]
user_id uuid [ref: > auth.users.id]
test_id uuid [ref: > tests.id]
started_at timestamptz
submitted_at timestamptz
score int
}

Table answers {
id uuid [pk]
attempt_id uuid [ref: > attempts.id]
question_id uuid [ref: > questions.id]
option_id uuid [ref: > question_options.id]
is_correct boolean
}

Table listening_answer_history {
id uuid [pk]
user_id uuid [ref: > auth.users.id]
question_id uuid [ref: > questions.id]
selected_option_id uuid [ref: > question_options.id]
is_correct boolean
answered_at timestamptz
}

Table user_progress {
id uuid [pk]
user_id uuid [ref: > auth.users.id]
question_id uuid [ref: > questions.id]
accuracy decimal
last_seen timestamptz
}

Table wrong_questions {
id uuid [pk]
user_id uuid [ref: > auth.users.id]
question_id uuid [ref: > questions.id]
last_selected_option_id uuid [ref: > question_options.id]
wrong_count int
last_answered_at timestamptz
created_at timestamptz
updated_at timestamptz
}

Table speaking_prompts {
id uuid [pk]
part_number int
task_type text
title text
passage text
prompt text
image_url text
prep_seconds int
model_answer text
hint_words text[]
order_index int
created_at timestamptz
}

Table writing_prompts {
id uuid [pk]
part_number int
title text
prompt text
image_url text
passage_text text
passage_subject text
model_answer text
hint_words text
order_index int
created_at timestamptz
}

Table practice_history {
id uuid [pk]
user_id uuid [ref: > profiles.id]
mode practice_mode
part_number int
prompt_id text
prompt_title text
prompt_content text
user_answer text
ai_score int
ai_feedback text
ai_errors text[]
ai_task_scores jsonb
ai_important_words text[]
ai_suggested_answer text
created_at timestamptz
}

Table writing_submissions {
id uuid [pk]
user_id uuid [ref: > auth.users.id]
prompt_id uuid [ref: > writing_prompts.id]
part_number int
content text
submitted_at timestamptz
}

Table grammar {
id uuid [pk]
lesson int
title text
content text
formula text
examples jsonb
related_topics jsonb
sort_order int
created_at timestamptz
}

Table vocabulary {
id uuid [pk]
lesson int
word text
phonetic text
definition text
word_class text
score_level text
audio_url text
sort_order int
created_at timestamptz
}

Table user_saved_vocabulary {
id uuid [pk]
user_id uuid [ref: > auth.users.id]
vocabulary_id uuid [ref: > vocabulary.id]
created_at timestamptz
}

Table user_saved_grammar {
id uuid [pk]
user_id uuid [ref: > auth.users.id]
grammar_id uuid [ref: > grammar.id]
created_at timestamptz
}

Table roadmap_templates {
id uuid [pk]
target_score int
duration_days int
title text
created_at timestamptz
description text
}

Table roadmap_tasks {
id uuid [pk]
template_id uuid [ref: > roadmap_templates.id]
day_number int
task_type text
reference_id uuid
title text
created_at timestamptz
group_title text
skill_type text
}

Table user_roadmaps {
id uuid [pk]
user_id uuid [ref: > auth.users.id]
template_id uuid [ref: > roadmap_templates.id]
initial_score int
target_score int
current_day int
status roadmap_status
start_date timestamptz
created_at timestamptz
}

Table user_task_progress {
id uuid [pk]
user_roadmap_id uuid [ref: > user_roadmaps.id]
task_id uuid [ref: > roadmap_tasks.id]
status task_status
score_achieved int
completed_at timestamptz
created_at timestamptz
}

Table chat_conversations {
id uuid [pk]
user_id uuid [ref: - profiles.id]
admin_id uuid [ref: > profiles.id]
created_at timestamptz
last_message_at timestamptz
last_message_preview text
last_message_sender text
unread_user_count int
unread_admin_count int
is_resolved boolean
}

Table chat_messages {
id uuid [pk]
conversation_id uuid [ref: > chat_conversations.id]
sender_id uuid [ref: > profiles.id]
sender_role chat_sender_role
content text
is_read boolean
created_at timestamptz
}

Table reviews {
id uuid [pk]
user_id uuid [ref: > profiles.id]
rating int
content text
images text[]
likes_count int
created_at timestamptz
updated_at timestamptz
}

Table review_likes {
id uuid [pk]
review_id uuid [ref: > reviews.id]
user_id uuid [ref: > profiles.id]
created_at timestamptz
}
