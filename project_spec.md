PROJECT SPEC – TOEIC LEARNING APP (Flutter + Supabase)
1. Project Overview

Build a production-ready TOEIC learning mobile application using:

Flutter (clean architecture, enterprise structure)

Backend: Supabase

UI source: HTML exported from Google Stitch UI (stored in /html-ui)

The system must support:

TOEIC practice tests

Listening audio playback

Reading passages

User progress tracking

Score analytics

Authentication (email + Google)

The generated source code must follow enterprise-level clean architecture.
2. SOURCE CODE ARCHITECTURE (REQUIRED)

Use feature-first clean architecture with separation of:

presentation

domain

data

core/shared

Root structure
lib/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── config/
│   ├── routes/
│   ├── env/
│   └── supabase_config.dart
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── test/
│   ├── practice/
│   ├── result/
│   ├── profile/
│   └── vocabulary/
│
└── main.dart
Feature structure pattern

Each feature must follow:
feature_name/
│
├── data/
│   ├── datasources/
│   ├── models/
│   ├── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   ├── usecases/
│
├── presentation/
│   ├── pages/
│   ├── widgets/
│   ├── controllers/
│
└── feature_routes.dart
Use this structure consistently across ALL features.
3. STATE MANAGEMENT RULE

Use:

Riverpod OR Bloc

Repository pattern mandatory

No direct Supabase calls inside UI layer

Flow:
UI → Controller → UseCase → Repository → Supabase datasource
4. HTML → FLUTTER CONVERSION RULES

All HTML files are stored in:
/html-ui/
Agent must convert each HTML screen into Flutter UI.

Conversion guidelines
Layout

Map Tailwind spacing → EdgeInsets

Flex → Row/Column

Grid → GridView

Container classes → BoxDecoration

Typography

Tailwind font sizes → TextStyle

Use centralized theme file

Icons

Convert material symbols → Flutter Icons

Colors

Extract colors into:
core/theme/app_colors.dart
Components to extract

Every screen must split into:

page

reusable widgets

form widgets

buttons
5. DATABASE DESIGN (SUPABASE)
5.1 AUTH TABLES

Use Supabase default:

auth.users

Create custom:

profiles
id uuid pk (fk auth.users)
full_name text
phone text
role text default 'user'
avatar_url text
created_at timestamptz

5.2 TEST SYSTEM TABLES

tests
id uuid pk
title text
duration int
type text
created_at timestamptz

test_parts
id uuid pk
test_id uuid fk
part_number int
instructions text

questions
id uuid pk
part_id uuid fk
passage_id uuid fk nullable
question_text text nullable
order_index int

question_options
id uuid pk
question_id uuid fk
content text
is_correct boolean

question_media
id uuid pk
question_id uuid fk
type text (audio/image/text)
url text


passages
id uuid pk
part_id uuid fk
title text
content text

5.3 USER PRACTICE DATA
attempts
id uuid pk
user_id uuid fk
test_id uuid fk
started_at timestamptz
submitted_at timestamptz
score int

answers
id uuid pk
attempt_id uuid fk
question_id uuid fk
option_id uuid
is_correct boolean

5.4 LEARNING FEATURES
vocabulary
id uuid pk
word text
meaning text
example text


user_progress
id uuid pk
user_id uuid fk
question_id uuid fk
accuracy numeric
last_seen timestamptz

6. STORAGE BUCKETS

Create Supabase storage:

audio/
images/
avatars/
documents/
7. ROUTING STRUCTURE

Use named routes grouped by feature:

/auth/login
/auth/register
/home
/test/list
/test/start
/test/result
/profile

Routing config must be centralized.

8. CODING STANDARDS

Mandatory:

null safety everywhere

repository pattern

DTO → entity mapping

no business logic inside widgets

error handling via custom Failure classes

dependency injection required

9. OUTPUT EXPECTATION

Agent must generate:

Full Flutter project

Supabase SQL migration file

Folder structure as specified

Theme + routing setup

At least one full feature implemented (Auth or Test)