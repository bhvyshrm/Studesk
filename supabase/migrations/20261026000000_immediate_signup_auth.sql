-- ====================================================================
-- StuDesk Supabase Migration: 20261026000000_immediate_signup_auth.sql
-- Description: Server-side infrastructure for immediate signup with Supabase:
-- 1. Ensure public.profiles table has all columns with safe, non-fake defaults
-- 2. Clean out fake academic defaults ('Dept of Computer Science', etc.)
-- 3. Enforce username format constraint & unique index on lower(username)
-- 4. Fault-tolerant public.handle_new_user() trigger function:
--    - Zero fake academic details (defaults to empty strings)
--    - Robust exception handling so schema mismatches or missing columns NEVER break signup
--    - Normalizes username and populates profile id as auth user UUID
--    - Safe handling for username uniqueness collisions
-- 5. RPC functions (check_username_available, get_auth_email_for_username, claim_username)
-- 6. Strict least-privilege Row Level Security (RLS) on public.profiles
-- ====================================================================

-- 1. Ensure public.profiles columns exist safely
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS username TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS preferred_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS institution TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS course TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS academic_year TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS semester TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());

-- 2. Clear out fake academic default values on existing columns
ALTER TABLE public.profiles ALTER COLUMN institution SET DEFAULT '';
ALTER TABLE public.profiles ALTER COLUMN course SET DEFAULT '';
ALTER TABLE public.profiles ALTER COLUMN academic_year SET DEFAULT '';
ALTER TABLE public.profiles ALTER COLUMN semester SET DEFAULT '';

-- 3. Format constraint and case-insensitive unique index on lower(username)
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

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_unique_lower
ON public.profiles (lower(username))
WHERE username IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(id);

-- 4. Enable Row Level Security (RLS)
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

-- 5. Robust, exception-safe public.handle_new_user() trigger
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

    -- Nested block to catch any schema mismatches or collisions without failing user creation
    BEGIN
        -- Primary attempt with full schema and zero fake academic details
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
            -- In case the requested username collides with an existing profile, insert without username
            -- so that the authenticated account is still created and user can claim a unique username
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
                    NULL,
                    extracted_name,
                    extracted_preferred,
                    extracted_avatar,
                    '',
                    '',
                    '',
                    '',
                    '',
                    false,
                    timezone('utc'::text, now()),
                    timezone('utc'::text, now())
                )
                ON CONFLICT (id) DO NOTHING;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'handle_new_user fallback after unique_violation: %', SQLERRM;
            END;

        WHEN OTHERS THEN
            -- Fallback attempt for older schemas that may lack extended columns (e.g. preferred_name, bio, onboarding_completed)
            BEGIN
                INSERT INTO public.profiles (
                    id,
                    username,
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
                    extracted_username,
                    extracted_name,
                    extracted_avatar,
                    '',
                    '',
                    '',
                    '',
                    timezone('utc'::text, now()),
                    timezone('utc'::text, now())
                )
                ON CONFLICT (id) DO UPDATE SET
                    username = COALESCE(public.profiles.username, EXCLUDED.username),
                    full_name = EXCLUDED.full_name,
                    updated_at = timezone('utc'::text, now());
            EXCEPTION
                WHEN OTHERS THEN
                    -- Last-ditch safeguard: Never fail auth.users insertion
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

-- 6. RPC: check_username_available
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

REVOKE ALL ON FUNCTION public.check_username_available(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_username_available(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_username_available(TEXT) TO anon;

-- 7. RPC: get_auth_email_for_username
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

    SELECT u.email INTO found_email
    FROM auth.users u
    INNER JOIN public.profiles p ON p.id = u.id
    WHERE lower(p.username) = normalized
    LIMIT 1;

    RETURN found_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.get_auth_email_for_username(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_auth_email_for_username(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_auth_email_for_username(TEXT) TO authenticated;

-- 8. RPC: claim_username
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

REVOKE ALL ON FUNCTION public.claim_username(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_username(TEXT) TO authenticated;
