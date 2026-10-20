-- ====================================================================
-- StuDesk Supabase Migration: 20261020000000_create_profiles_table.sql
-- Description: Creates the public.profiles table with strict Row Level
-- Security (RLS) policies and automatic idempotent profile creation for
-- Google OAuth authenticated students.
-- ====================================================================

-- 1. Ensure UUID extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create public.profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    institution TEXT DEFAULT 'Dept of Computer Science',
    course TEXT DEFAULT 'B.Tech Computer Science',
    academic_year TEXT DEFAULT 'Year 2',
    semester TEXT DEFAULT 'Semester 4',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure schema compatibility if columns were previously named differently
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS institution TEXT DEFAULT 'Dept of Computer Science';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS course TEXT DEFAULT 'B.Tech Computer Science';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS academic_year TEXT DEFAULT 'Year 2';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS semester TEXT DEFAULT 'Semester 4';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 4. Clean up existing policies for idempotent re-runs
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- 5. Strict RLS Policies for Authenticated Users
-- Policy: Authenticated users can view only their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Policy: Authenticated users can insert only their own profile
CREATE POLICY "Users can insert own profile"
    ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Policy: Authenticated users can update only their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 6. Safe Profile Provisioning Function for Google OAuth & Email Signups
-- Handles repeat logins and metadata sync without duplicate key errors
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    extracted_name TEXT;
    extracted_avatar TEXT;
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

    INSERT INTO public.profiles (
        id,
        full_name,
        avatar_url,
        institution,
        course,
        academic_year,
        semester,
        created_at,
        updated_at
    )
    VALUES (
        new.id,
        extracted_name,
        extracted_avatar,
        'Dept of Computer Science',
        'B.Tech Computer Science',
        'Year 2',
        'Semester 4',
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    )
    ON CONFLICT (id) DO UPDATE SET
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
        updated_at = timezone('utc'::text, now());

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Trigger on auth.users creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
