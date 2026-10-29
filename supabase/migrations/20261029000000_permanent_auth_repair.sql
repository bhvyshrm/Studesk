-- ====================================================================
-- StuDesk Supabase Permanent Authentication & Schema Repair Migration
-- File: supabase/migrations/20261029000000_permanent_auth_repair.sql
--
-- This migration is completely idempotent and safe to run multiple times.
-- It resolves:
-- 1. Missing columns on public.profiles (preferred_name, bio, onboarding_completed)
-- 2. Clean out fake academic defaults ('Dept of Computer Science', etc.)
-- 3. Username format validation constraint & lower(username) unique index
-- 4. Complete Row Level Security (RLS) policies: SELECT, INSERT, UPDATE
-- 5. Exception-safe public.handle_new_user() trigger on auth.users
-- 6. RPC: public.check_username_available (supporting requested_username & p_username)
-- 7. RPC: public.get_auth_email_for_username (supporting p_username, requested_username, username)
-- 8. RPC: public.claim_username (supporting BOTH p_username & new_username)
-- 9. Idempotent creation of core application tables & RLS to eliminate sync crashes
-- ====================================================================

-- 1. Ensure required extensions exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Ensure public.profiles table exists with all required columns
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT,
    full_name TEXT,
    preferred_name TEXT DEFAULT '',
    avatar_url TEXT DEFAULT '',
    institution TEXT DEFAULT '',
    course TEXT DEFAULT '',
    academic_year TEXT DEFAULT '',
    semester TEXT DEFAULT '',
    bio TEXT DEFAULT '',
    onboarding_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure all columns exist on profiles if table was created in an older schema
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS username TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS preferred_name TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS institution TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS course TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS academic_year TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS semester TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());

-- Clear out any legacy fake academic defaults
ALTER TABLE public.profiles ALTER COLUMN institution SET DEFAULT '';
ALTER TABLE public.profiles ALTER COLUMN course SET DEFAULT '';
ALTER TABLE public.profiles ALTER COLUMN academic_year SET DEFAULT '';
ALTER TABLE public.profiles ALTER COLUMN semester SET DEFAULT '';

-- Format constraint for username: 3-20 characters, lowercase alphanumeric and underscore
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_profiles_username_format'
    ) THEN
        ALTER TABLE public.profiles
        ADD CONSTRAINT chk_profiles_username_format
        CHECK (username IS NULL OR username ~ '^[a-z0-9_]{3,20}$');
    END IF;
END $$;

-- Case-insensitive unique index on username
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_unique_lower
ON public.profiles (lower(username))
WHERE username IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(id);

-- 3. Row Level Security on public.profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT TO authenticated
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 4. Exception-safe public.handle_new_user() trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    extracted_name TEXT;
    extracted_avatar TEXT;
    extracted_username TEXT;
    extracted_preferred TEXT;
BEGIN
    extracted_name := COALESCE(
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'name',
        split_part(new.email, '@', 1),
        'StuDesk Student'
    );
    extracted_avatar := COALESCE(
        new.raw_user_meta_data->>'avatar_url',
        new.raw_user_meta_data->>'picture',
        ''
    );
    extracted_username := lower(trim(COALESCE(new.raw_user_meta_data->>'username', '')));
    IF extracted_username = '' THEN
        extracted_username := NULL;
    END IF;

    extracted_preferred := COALESCE(
        new.raw_user_meta_data->>'preferred_name',
        split_part(extracted_name, ' ', 1),
        ''
    );

    BEGIN
        INSERT INTO public.profiles (
            id,
            username,
            full_name,
            preferred_name,
            avatar_url,
            institution,
            course,
            academic_year,
            semester,
            bio,
            onboarding_completed,
            created_at,
            updated_at
        )
        VALUES (
            new.id,
            extracted_username,
            extracted_name,
            extracted_preferred,
            extracted_avatar,
            COALESCE(new.raw_user_meta_data->>'institution', ''),
            COALESCE(new.raw_user_meta_data->>'course', ''),
            COALESCE(new.raw_user_meta_data->>'academic_year', ''),
            COALESCE(new.raw_user_meta_data->>'semester', ''),
            COALESCE(new.raw_user_meta_data->>'bio', ''),
            (extracted_username IS NOT NULL),
            timezone('utc'::text, now()),
            timezone('utc'::text, now())
        )
        ON CONFLICT (id) DO UPDATE SET
            username = COALESCE(public.profiles.username, EXCLUDED.username),
            full_name = CASE
                WHEN public.profiles.full_name IS NULL OR public.profiles.full_name = '' OR public.profiles.full_name = 'StuDesk Student'
                THEN EXCLUDED.full_name
                ELSE public.profiles.full_name
            END,
            avatar_url = CASE
                WHEN EXCLUDED.avatar_url IS NOT NULL AND EXCLUDED.avatar_url <> ''
                THEN EXCLUDED.avatar_url
                ELSE public.profiles.avatar_url
            END,
            onboarding_completed = CASE
                WHEN EXCLUDED.username IS NOT NULL THEN true
                ELSE public.profiles.onboarding_completed
            END,
            updated_at = timezone('utc'::text, now());

    EXCEPTION
        WHEN unique_violation THEN
            -- In case of username collision, provision profile without username so user can select an available one
            BEGIN
                INSERT INTO public.profiles (
                    id, username, full_name, preferred_name, avatar_url,
                    institution, course, academic_year, semester, bio,
                    onboarding_completed, created_at, updated_at
                ) VALUES (
                    new.id, NULL, extracted_name, extracted_preferred, extracted_avatar,
                    '', '', '', '', '',
                    false, timezone('utc'::text, now()), timezone('utc'::text, now())
                )
                ON CONFLICT (id) DO UPDATE SET
                    full_name = EXCLUDED.full_name,
                    updated_at = timezone('utc'::text, now());
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'handle_new_user fallback after unique_violation: %', SQLERRM;
            END;

        WHEN OTHERS THEN
            BEGIN
                INSERT INTO public.profiles (
                    id, username, full_name, avatar_url,
                    institution, course, academic_year, semester,
                    created_at, updated_at
                ) VALUES (
                    new.id, extracted_username, extracted_name, extracted_avatar,
                    '', '', '', '',
                    timezone('utc'::text, now()), timezone('utc'::text, now())
                )
                ON CONFLICT (id) DO UPDATE SET
                    username = COALESCE(public.profiles.username, EXCLUDED.username),
                    full_name = EXCLUDED.full_name,
                    updated_at = timezone('utc'::text, now());
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'handle_new_user base insert error: %', SQLERRM;
            END;
    END;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. RPC: check_username_available (both requested_username and p_username signatures)
CREATE OR REPLACE FUNCTION public.check_username_available(requested_username TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    normalized TEXT;
BEGIN
    IF requested_username IS NULL THEN
        RETURN FALSE;
    END IF;

    normalized := lower(trim(requested_username));

    IF normalized !~ '^[a-z0-9_]{3,20}$' THEN
        RETURN FALSE;
    END IF;

    IF normalized IN (
        'admin', 'administrator', 'studesk', 'support', 'root',
        'system', 'help', 'api', 'null', 'undefined', 'moderator',
        'staff', 'security', 'guest', 'user', 'official'
    ) THEN
        RETURN FALSE;
    END IF;

    RETURN NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE lower(username) = normalized
          AND id != COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public, auth;

CREATE OR REPLACE FUNCTION public.check_username_available(p_username TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.check_username_available(requested_username := p_username);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.check_username_available(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_username_available(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_username_available(TEXT) TO anon;

-- 6. RPC: get_auth_email_for_username (supporting p_username, requested_username, username)
CREATE OR REPLACE FUNCTION public.get_auth_email_for_username(p_username TEXT)
RETURNS TEXT AS $$
DECLARE
    found_email TEXT;
    normalized TEXT;
BEGIN
    IF p_username IS NULL THEN
        RETURN NULL;
    END IF;

    normalized := lower(trim(p_username));

    IF normalized !~ '^[a-z0-9_]{3,20}$' THEN
        RETURN NULL;
    END IF;

    -- Lookup email securely across auth.users and public.profiles
    SELECT u.email INTO found_email
    FROM auth.users u
    LEFT JOIN public.profiles p ON p.id = u.id
    WHERE lower(p.username) = normalized
       OR lower(trim(COALESCE(u.raw_user_meta_data->>'username', ''))) = normalized
    LIMIT 1;

    RETURN found_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.get_auth_email_for_username(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_auth_email_for_username(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_auth_email_for_username(TEXT) TO authenticated;

-- 7. RPC: claim_username (supporting BOTH new_username and p_username argument names)
CREATE OR REPLACE FUNCTION public.claim_username(new_username TEXT)
RETURNS JSONB AS $$
DECLARE
    normalized TEXT;
    caller_id UUID;
    updated_row public.profiles%ROWTYPE;
BEGIN
    caller_id := auth.uid();
    IF caller_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    normalized := lower(trim(new_username));

    IF normalized !~ '^[a-z0-9_]{3,20}$' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Username must be 3-20 characters using only lowercase letters, numbers, and underscores.'
        );
    END IF;

    IF normalized IN (
        'admin', 'administrator', 'studesk', 'support', 'root',
        'system', 'help', 'api', 'null', 'undefined', 'moderator',
        'staff', 'security', 'guest', 'user', 'official'
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'This username is reserved. Please pick a different one.'
        );
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.profiles
        WHERE lower(username) = normalized
          AND id != caller_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Username is already taken by another student.'
        );
    END IF;

    BEGIN
        UPDATE public.profiles
        SET username = normalized,
            onboarding_completed = true,
            updated_at = timezone('utc'::text, now())
        WHERE id = caller_id
        RETURNING * INTO updated_row;

        IF NOT FOUND THEN
            INSERT INTO public.profiles (
                id,
                username,
                onboarding_completed,
                created_at,
                updated_at
            ) VALUES (
                caller_id,
                normalized,
                true,
                timezone('utc'::text, now()),
                timezone('utc'::text, now())
            )
            RETURNING * INTO updated_row;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            UPDATE public.profiles
            SET username = normalized,
                updated_at = timezone('utc'::text, now())
            WHERE id = caller_id;

            IF NOT FOUND THEN
                INSERT INTO public.profiles (id, username, created_at, updated_at)
                VALUES (caller_id, normalized, timezone('utc'::text, now()), timezone('utc'::text, now()));
            END IF;
    END;

    RETURN jsonb_build_object(
        'success', true,
        'username', normalized
    );
EXCEPTION
    WHEN unique_violation THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Username was just claimed by another student. Please pick a different one.'
        );
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- Overload with p_username parameter name so both callers succeed
CREATE OR REPLACE FUNCTION public.claim_username(p_username TEXT)
RETURNS JSONB AS $$
BEGIN
    RETURN public.claim_username(new_username := p_username);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.claim_username(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_username(TEXT) TO authenticated;

-- 8. Core Application Tables (Courses, Tasks, Exams, Events, Reminders, Notes, Timetable, Attendance)
-- Creates missing tables if not yet created so client sync never throws 404/PGRST205

CREATE TABLE IF NOT EXISTS public.courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    title TEXT NOT NULL,
    professor TEXT NOT NULL DEFAULT '',
    department TEXT NOT NULL DEFAULT '',
    schedule TEXT NOT NULL DEFAULT '',
    location TEXT NOT NULL DEFAULT '',
    credits INTEGER NOT NULL DEFAULT 3,
    attended_lectures INTEGER NOT NULL DEFAULT 0,
    total_lectures INTEGER NOT NULL DEFAULT 0,
    grade TEXT NOT NULL DEFAULT 'A',
    standing TEXT NOT NULL DEFAULT 'Safe',
    last_topic TEXT DEFAULT '',
    is_warning BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_user_course_code UNIQUE (user_id, code)
);
CREATE INDEX IF NOT EXISTS idx_courses_user ON public.courses(user_id);
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own courses" ON public.courses;
CREATE POLICY "Users can manage own courses" ON public.courses FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'normal',
    due_time TEXT,
    due_date TIMESTAMPTZ,
    category_tag TEXT NOT NULL DEFAULT 'General',
    detail TEXT,
    course_code TEXT,
    is_recurring BOOLEAN NOT NULL DEFAULT false,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_tasks_user ON public.tasks(user_id, is_completed);
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own tasks" ON public.tasks;
CREATE POLICY "Users can manage own tasks" ON public.tasks FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    event_date TIMESTAMPTZ NOT NULL,
    start_time TEXT,
    end_time TEXT,
    location TEXT,
    notes TEXT,
    has_reminder BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_events_user ON public.events(user_id, event_date);
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own events" ON public.events;
CREATE POLICY "Users can manage own events" ON public.events FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    reminder_time TIMESTAMPTZ NOT NULL,
    repeat_rule TEXT,
    linked_id TEXT,
    linked_type TEXT,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_reminders_user ON public.reminders(user_id, reminder_time);
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own reminders" ON public.reminders;
CREATE POLICY "Users can manage own reminders" ON public.reminders FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    course_code TEXT NOT NULL,
    title TEXT NOT NULL,
    exam_date TIMESTAMPTZ NOT NULL,
    room TEXT NOT NULL DEFAULT '',
    syllabus_cutoff TEXT NOT NULL DEFAULT '',
    weightage_percent INTEGER NOT NULL DEFAULT 30,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_exams_user ON public.exams(user_id, exam_date);
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own exams" ON public.exams;
CREATE POLICY "Users can manage own exams" ON public.exams FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.library_collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    color_hex TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_collections_user ON public.library_collections(user_id);
ALTER TABLE public.library_collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own collections" ON public.library_collections;
CREATE POLICY "Users can manage own collections" ON public.library_collections FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.library_resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    collection_id UUID REFERENCES public.library_collections(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'note',
    subject_tag TEXT NOT NULL DEFAULT 'General',
    url TEXT,
    note_content TEXT,
    duration TEXT,
    meta_info TEXT,
    channel TEXT,
    description TEXT DEFAULT '',
    is_bookmarked BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_resources_user ON public.library_resources(user_id, type);
ALTER TABLE public.library_resources ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own resources" ON public.library_resources;
CREATE POLICY "Users can manage own resources" ON public.library_resources FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.academic_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subject_code TEXT NOT NULL DEFAULT 'General',
    file_type TEXT NOT NULL DEFAULT 'note',
    file_url TEXT,
    content TEXT DEFAULT '',
    file_size TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_notes_user ON public.academic_notes(user_id, subject_code);
ALTER TABLE public.academic_notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own notes" ON public.academic_notes;
CREATE POLICY "Users can manage own notes" ON public.academic_notes FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.timetable_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    course_code TEXT NOT NULL,
    title TEXT NOT NULL,
    room TEXT NOT NULL DEFAULT '',
    professor TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_timetable_user ON public.timetable_entries(user_id, day_of_week);
ALTER TABLE public.timetable_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own timetable" ON public.timetable_entries;
CREATE POLICY "Users can manage own timetable" ON public.timetable_entries FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.subject_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    course_code TEXT NOT NULL,
    date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    is_present BOOLEAN NOT NULL DEFAULT true,
    lecture_slot TEXT,
    topic_discussed TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_sub_att_user ON public.subject_attendance(user_id, course_code);
ALTER TABLE public.subject_attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own subject attendance" ON public.subject_attendance;
CREATE POLICY "Users can manage own subject attendance" ON public.subject_attendance FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.college_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    is_present BOOLEAN NOT NULL DEFAULT true,
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_user_college_day UNIQUE (user_id, date)
);
CREATE INDEX IF NOT EXISTS idx_col_att_user ON public.college_attendance(user_id, date);
ALTER TABLE public.college_attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own college attendance" ON public.college_attendance;
CREATE POLICY "Users can manage own college attendance" ON public.college_attendance FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    mood TEXT NOT NULL DEFAULT 'Deep Focus',
    streak TEXT NOT NULL DEFAULT '14 Days',
    tasks_completed INTEGER NOT NULL DEFAULT 0,
    total_tasks INTEGER NOT NULL DEFAULT 0,
    linked_courses JSONB NOT NULL DEFAULT '[]'::jsonb,
    learned_text TEXT NOT NULL DEFAULT '',
    code_snippet TEXT,
    accomplishments JSONB NOT NULL DEFAULT '[]'::jsonb,
    blocker TEXT,
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    word_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_journals_user ON public.journal_entries(user_id, date);
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own journals" ON public.journal_entries;
CREATE POLICY "Users can manage own journals" ON public.journal_entries FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
