-- ====================================================================
-- STUDESK COMPREHENSIVE POSTGRESQL SCHEMA WITH ROW LEVEL SECURITY (RLS)
-- ====================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. PROFILES TABLE (Linked directly to Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'Alex Chen',
    email TEXT,
    college TEXT NOT NULL DEFAULT 'Dept of Computer Science',
    course TEXT NOT NULL DEFAULT 'B.Tech Computer Science',
    semester TEXT NOT NULL DEFAULT 'Semester 4',
    roll_no TEXT NOT NULL DEFAULT '22CS1049',
    academic_year TEXT NOT NULL DEFAULT 'Year 2',
    streak_days INTEGER NOT NULL DEFAULT 14,
    last_active_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    target_attendance_percent NUMERIC(5, 2) NOT NULL DEFAULT 85.0,
    weekly_study_goal_hours INTEGER NOT NULL DEFAULT 20,
    is_dark_mode BOOLEAN NOT NULL DEFAULT true,
    notifications_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. COURSES TABLE
CREATE TABLE IF NOT EXISTS public.courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    title TEXT NOT NULL,
    professor TEXT NOT NULL,
    department TEXT NOT NULL,
    schedule TEXT NOT NULL,
    location TEXT NOT NULL,
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

-- 4. COURSE UNITS TABLE
CREATE TABLE IF NOT EXISTS public.course_units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    course_code TEXT NOT NULL,
    unit_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'upcoming' CHECK (status IN ('completed', 'current', 'upcoming')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_user_course_unit UNIQUE (user_id, course_code, unit_number)
);

-- 5. UNIT TOPICS TABLE
CREATE TABLE IF NOT EXISTS public.unit_topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES public.course_units(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    date_str TEXT DEFAULT '',
    subtitle TEXT DEFAULT '',
    is_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 6. SUBJECT ATTENDANCE RECORDS (Per-lecture records)
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

-- 7. COLLEGE ATTENDANCE RECORDS (Daily college calendar - separate from subject attendance)
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

-- 8. TASKS TABLE
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('high', 'academic', 'review', 'normal')),
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

-- 9. LIBRARY RESOURCES & NOTES TABLE
CREATE TABLE IF NOT EXISTS public.library_resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'note' CHECK (type IN ('video', 'pdf', 'note', 'bookmark')),
    subject_tag TEXT NOT NULL DEFAULT 'General',
    url TEXT,
    note_content TEXT,
    duration TEXT,
    meta_info TEXT,
    channel TEXT,
    is_bookmarked BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 10. JOURNAL ENTRIES TABLE
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

-- 11. TIMETABLE ENTRIES TABLE
CREATE TABLE IF NOT EXISTS public.timetable_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    course_code TEXT NOT NULL,
    title TEXT NOT NULL,
    room TEXT NOT NULL,
    professor TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 12. EXAMS TABLE
CREATE TABLE IF NOT EXISTS public.exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    course_code TEXT NOT NULL,
    title TEXT NOT NULL,
    exam_date TIMESTAMPTZ NOT NULL,
    room TEXT NOT NULL,
    syllabus_cutoff TEXT NOT NULL,
    weightage_percent INTEGER NOT NULL DEFAULT 30,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 13. INDEXES FOR HIGH-PERFORMANCE QUERYING
CREATE INDEX IF NOT EXISTS idx_courses_user ON public.courses(user_id);
CREATE INDEX IF NOT EXISTS idx_course_units_user ON public.course_units(user_id, course_code);
CREATE INDEX IF NOT EXISTS idx_unit_topics_unit ON public.unit_topics(unit_id);
CREATE INDEX IF NOT EXISTS idx_subject_attendance_user ON public.subject_attendance(user_id, course_code);
CREATE INDEX IF NOT EXISTS idx_college_attendance_user ON public.college_attendance(user_id, date);
CREATE INDEX IF NOT EXISTS idx_tasks_user ON public.tasks(user_id, is_completed);
CREATE INDEX IF NOT EXISTS idx_resources_user ON public.library_resources(user_id, type);
CREATE INDEX IF NOT EXISTS idx_journals_user ON public.journal_entries(user_id, date);
CREATE INDEX IF NOT EXISTS idx_timetable_user ON public.timetable_entries(user_id, day_of_week);
CREATE INDEX IF NOT EXISTS idx_exams_user ON public.exams(user_id, exam_date);

-- ====================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Strict isolation: Users can ONLY access and modify their own data.
-- ====================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unit_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subject_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.library_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetable_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;

-- 1. PROFILES POLICIES
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 2. COURSES POLICIES
CREATE POLICY "Users can view own courses" ON public.courses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own courses" ON public.courses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own courses" ON public.courses FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own courses" ON public.courses FOR DELETE USING (auth.uid() = user_id);

-- 3. COURSE UNITS POLICIES
CREATE POLICY "Users can view own units" ON public.course_units FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own units" ON public.course_units FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own units" ON public.course_units FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own units" ON public.course_units FOR DELETE USING (auth.uid() = user_id);

-- 4. UNIT TOPICS POLICIES
CREATE POLICY "Users can view own topics" ON public.unit_topics FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own topics" ON public.unit_topics FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own topics" ON public.unit_topics FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own topics" ON public.unit_topics FOR DELETE USING (auth.uid() = user_id);

-- 5. SUBJECT ATTENDANCE POLICIES
CREATE POLICY "Users can view own subject attendance" ON public.subject_attendance FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own subject attendance" ON public.subject_attendance FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own subject attendance" ON public.subject_attendance FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own subject attendance" ON public.subject_attendance FOR DELETE USING (auth.uid() = user_id);

-- 6. COLLEGE ATTENDANCE POLICIES
CREATE POLICY "Users can view own college attendance" ON public.college_attendance FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own college attendance" ON public.college_attendance FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own college attendance" ON public.college_attendance FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own college attendance" ON public.college_attendance FOR DELETE USING (auth.uid() = user_id);

-- 7. TASKS POLICIES
CREATE POLICY "Users can view own tasks" ON public.tasks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own tasks" ON public.tasks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own tasks" ON public.tasks FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own tasks" ON public.tasks FOR DELETE USING (auth.uid() = user_id);

-- 8. LIBRARY RESOURCES POLICIES
CREATE POLICY "Users can view own resources" ON public.library_resources FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own resources" ON public.library_resources FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own resources" ON public.library_resources FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own resources" ON public.library_resources FOR DELETE USING (auth.uid() = user_id);

-- 9. JOURNAL ENTRIES POLICIES
CREATE POLICY "Users can view own journals" ON public.journal_entries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own journals" ON public.journal_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own journals" ON public.journal_entries FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own journals" ON public.journal_entries FOR DELETE USING (auth.uid() = user_id);

-- 10. TIMETABLE POLICIES
CREATE POLICY "Users can view own timetable" ON public.timetable_entries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own timetable" ON public.timetable_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own timetable" ON public.timetable_entries FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own timetable" ON public.timetable_entries FOR DELETE USING (auth.uid() = user_id);

-- 11. EXAMS POLICIES
CREATE POLICY "Users can view own exams" ON public.exams FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own exams" ON public.exams FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own exams" ON public.exams FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own exams" ON public.exams FOR DELETE USING (auth.uid() = user_id);

-- ====================================================================
-- AUTOMATIC PROFILE CREATION TRIGGER ON AUTH SIGNUP
-- ====================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'StuDesk Student'),
        new.email
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
