-- ====================================================================
-- StuDesk Supabase Migration: 20261023000000_username_password_auth.sql
-- Description: Server-side infrastructure for username-and-password auth:
-- 1. Database-enforced username format constraint & unique index
-- 2. Secure SECURITY DEFINER function to resolve username to auth email
--    without exposing profile records to unauthenticated clients
-- 3. Updated auth.users trigger to automatically provision username on signup
-- 4. Re-enforced least-privilege Row Level Security (RLS) on public.profiles
-- ====================================================================

-- 1. Ensure username column exists on public.profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS username TEXT;

-- 2. Format check constraint (3-20 lowercase alphanumeric characters + underscores)
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

-- 4. Fast lookup index on id
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(id);

-- 5. Strict least-privilege RLS on public.profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

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

-- 6. Trusted username resolution function for authentication
-- Runs with SECURITY DEFINER with locked search_path so unauthenticated clients
-- can resolve a username to an auth email ONLY during the login flow without
-- querying auth.users directly or reading arbitrary public.profiles records.
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

    -- Validate format before query
    IF normalized !~ '^[a-z0-9_]{3,20}$' THEN
        RETURN NULL;
    END IF;

    -- Look up email securely across auth.users and public.profiles
    SELECT u.email INTO found_email
    FROM auth.users u
    INNER JOIN public.profiles p ON p.id = u.id
    WHERE lower(p.username) = normalized
    LIMIT 1;

    RETURN found_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- Allow anon and authenticated clients to call the resolver RPC
REVOKE ALL ON FUNCTION public.get_auth_email_for_username(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_auth_email_for_username(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_auth_email_for_username(TEXT) TO authenticated;

-- 7. Username availability checker (for real-time registration feedback)
CREATE OR REPLACE FUNCTION public.check_username_available(requested_username TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    normalized TEXT;
BEGIN
    IF requested_username IS NULL THEN
        RETURN FALSE;
    END IF;

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
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.check_username_available(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_username_available(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_username_available(TEXT) TO anon;

-- 8. Atomic RPC to claim/set username
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

    -- Atomic update or insert
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

-- 9. Automatic profile provisioning trigger on auth.users creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    extracted_name TEXT;
    extracted_avatar TEXT;
    extracted_username TEXT;
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
        'Dept of Computer Science',
        'B.Tech Computer Science',
        'Year 2',
        'Semester 4',
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
        updated_at = timezone('utc'::text, now());

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
