-- ====================================================================
-- StuDesk Supabase Migration: 20261022000000_add_username_onboarding_and_security.sql
-- Description: Adds secure username field to public.profiles with:
-- 1. Format check constraint (3-20 lowercase alphanumeric + underscores)
-- 2. Case-insensitive unique constraint index
-- 3. Strict least-privilege Row Level Security (RLS) policies
-- 4. Secure RPC function to check username availability without data leaks
-- 5. Atomic RPC function to claim/save username with concurrency protection
-- ====================================================================

-- 1. Add username column if not exists
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS username TEXT;

-- 2. Enforce format constraint on username (3-20 chars: a-z, 0-9, _)
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

-- 3. Case-insensitive unique index on lower(username)
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_unique_lower
ON public.profiles (lower(username))
WHERE username IS NOT NULL;

-- 4. Fast lookup index on profile id
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(id);

-- 5. Ensure Row Level Security (RLS) is enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 6. Clean and re-assert strict least-privilege RLS policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
    ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 7. Secure username availability check function
-- Runs with SECURITY DEFINER so it can check existence across public.profiles
-- without leaking other students' personal records (email, full name, etc.)
CREATE OR REPLACE FUNCTION public.check_username_available(requested_username TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    normalized TEXT;
BEGIN
    normalized := lower(trim(requested_username));

    -- Enforce format: 3-20 lowercase alphanumeric or underscore
    IF normalized !~ '^[a-z0-9_]{3,20}$' THEN
        RETURN FALSE;
    END IF;

    -- Block reserved words
    IF normalized IN (
        'admin', 'administrator', 'studesk', 'support', 'root',
        'system', 'help', 'api', 'null', 'undefined', 'moderator',
        'staff', 'security', 'guest', 'user', 'official'
    ) THEN
        RETURN FALSE;
    END IF;

    -- Return TRUE if not already taken by another user
    RETURN NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE lower(username) = normalized
          AND id != COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION public.check_username_available(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_username_available(TEXT) TO anon;

-- 8. Atomic RPC function to claim/save username with concurrency protection
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

    -- Concurrency check: does another user own this username?
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

    -- Atomic update
    UPDATE public.profiles
    SET username = normalized,
        onboarding_completed = true,
        updated_at = timezone('utc'::text, now())
    WHERE id = caller_id
    RETURNING * INTO updated_row;

    IF NOT FOUND THEN
        -- If profile does not exist yet, insert with authenticated caller id
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.claim_username(TEXT) TO authenticated;
