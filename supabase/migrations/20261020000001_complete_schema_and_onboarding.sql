-- ====================================================================
-- StuDesk Supabase Migration: 20261020000001_complete_schema_and_onboarding.sql
-- Description: Extends schema with onboarding state, events, reminders,
-- library collections, academic notes, in-app notifications, and strict RLS.
-- Zero demo seed data inserted.
-- ====================================================================

-- 1. Profiles table extensions
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS preferred_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT false;

-- 2. Events table
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
DROP POLICY IF EXISTS "Users can view own events" ON public.events;
DROP POLICY IF EXISTS "Users can insert own events" ON public.events;
DROP POLICY IF EXISTS "Users can update own events" ON public.events;
DROP POLICY IF EXISTS "Users can delete own events" ON public.events;
CREATE POLICY "Users can view own events" ON public.events FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own events" ON public.events FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own events" ON public.events FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own events" ON public.events FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- 3. Reminders table
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
DROP POLICY IF EXISTS "Users can view own reminders" ON public.reminders;
DROP POLICY IF EXISTS "Users can insert own reminders" ON public.reminders;
DROP POLICY IF EXISTS "Users can update own reminders" ON public.reminders;
DROP POLICY IF EXISTS "Users can delete own reminders" ON public.reminders;
CREATE POLICY "Users can view own reminders" ON public.reminders FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own reminders" ON public.reminders FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reminders" ON public.reminders FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own reminders" ON public.reminders FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- 4. Library Collections table
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
DROP POLICY IF EXISTS "Users can view own collections" ON public.library_collections;
DROP POLICY IF EXISTS "Users can insert own collections" ON public.library_collections;
DROP POLICY IF EXISTS "Users can update own collections" ON public.library_collections;
DROP POLICY IF EXISTS "Users can delete own collections" ON public.library_collections;
CREATE POLICY "Users can view own collections" ON public.library_collections FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own collections" ON public.library_collections FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own collections" ON public.library_collections FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own collections" ON public.library_collections FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- 5. Add collection_id to library_resources if not present
ALTER TABLE public.library_resources ADD COLUMN IF NOT EXISTS collection_id UUID REFERENCES public.library_collections(id) ON DELETE SET NULL;
ALTER TABLE public.library_resources ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';

-- 6. Academic Notes & Documents table
CREATE TABLE IF NOT EXISTS public.academic_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subject_code TEXT NOT NULL DEFAULT 'General',
    file_type TEXT NOT NULL DEFAULT 'note' CHECK (file_type IN ('pdf', 'image', 'doc', 'note')),
    file_url TEXT,
    content TEXT DEFAULT '',
    file_size TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_notes_user ON public.academic_notes(user_id, subject_code);
ALTER TABLE public.academic_notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own notes" ON public.academic_notes;
DROP POLICY IF EXISTS "Users can insert own notes" ON public.academic_notes;
DROP POLICY IF EXISTS "Users can update own notes" ON public.academic_notes;
DROP POLICY IF EXISTS "Users can delete own notes" ON public.academic_notes;
CREATE POLICY "Users can view own notes" ON public.academic_notes FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own notes" ON public.academic_notes FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own notes" ON public.academic_notes FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own notes" ON public.academic_notes FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- 7. In-App Notifications table
CREATE TABLE IF NOT EXISTS public.in_app_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'system',
    record_id TEXT,
    is_read BOOLEAN NOT NULL DEFAULT false,
    is_dismissed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.in_app_notifications(user_id, is_read, created_at);
ALTER TABLE public.in_app_notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own notifications" ON public.in_app_notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON public.in_app_notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.in_app_notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.in_app_notifications;
CREATE POLICY "Users can view own notifications" ON public.in_app_notifications FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own notifications" ON public.in_app_notifications FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.in_app_notifications FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own notifications" ON public.in_app_notifications FOR DELETE TO authenticated USING (auth.uid() = user_id);
