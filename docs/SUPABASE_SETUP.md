# StuDesk Backend & Authentication Setup Guide

This document provides instructions for setting up the Supabase PostgreSQL backend, username-and-password authentication, Row Level Security (RLS) policies, and database functions for StuDesk.

---

## 1. Quick Start (Offline / Local Student Mode)

By default, StuDesk runs in **Local Student Mode** without requiring external credentials:
- All student records (courses, timetable, syllabus topics, attendance, tasks, academic notes, library resources) persist locally via encrypted storage.
- Full UI and features are completely testable and functional offline.

---

## 2. Supabase Backend Setup

### Step 1: Create a Supabase Project
1. Log in to [Supabase Console](https://supabase.com).
2. Click **New Project**, choose your organization, and name your database `studesk`.
3. Choose your closest region and set a strong database password.

### Step 2: Apply Database Migrations (in Order)
In your Supabase dashboard, navigate to the **SQL Editor**:
1. Run `supabase/migrations/20261019000000_studesk_initial_schema.sql` (Creates core tables: `courses`, `tasks`, `exams`, `attendance`, etc.).
2. Run `supabase/migrations/20261020000000_create_profiles_table.sql` (Creates `public.profiles` table and trigger).
3. Run `supabase/migrations/20261020000001_complete_schema_and_onboarding.sql` (Adds events, reminders, library collections, notes).
4. Run `supabase/migrations/20261022000000_add_username_onboarding_and_security.sql` (Adds username constraints, `check_username_available` and `claim_username` RPCs).
5. Run `supabase/migrations/20261023000000_username_password_auth.sql` (Adds `get_auth_email_for_username` RPC resolver and updates user signup trigger).

---

## 3. Username and Password Authentication Architecture

StuDesk uses Supabase Auth with a backend-safe username lookup mechanism:

### Security Principles:
- **Client Least-Privilege**: The Flutter client never queries `auth.users` directly and never holds a service-role key. Only the public Anonymous Key (`anonKey`) is used.
- **Data Protection**: Unauthenticated clients cannot browse or read arbitrary records from `public.profiles`. RLS is strictly enforced (`auth.uid() = id`).
- **Trusted Username Resolution**: When a student enters their username and password, the app calls the trusted PostgreSQL `SECURITY DEFINER` function `public.get_auth_email_for_username(p_username TEXT)`. This function checks the username format and returns the internal auth email exclusively for authentication with Supabase Auth (`signInWithPassword`).
- **Enumeration Defense**: If a username does not exist or password fails, generic error messaging and consistent handling ensure attackers cannot easily enumerate usernames.
- **Username Uniqueness & Constraints**: Enforced at the database level with a case-insensitive unique index (`lower(username)`) and format check (`^[a-z0-9_]{3,20}$`).

---

## 4. Auth Provider Settings & Deep Link Configuration in Supabase Dashboard

### Why `localhost:5001` Was Occurring (Root Cause)
1. **Missing `emailRedirectTo` parameter**: During user signup (`signUpWithUsernameAndPassword`), the Supabase Flutter client did not pass an explicit `emailRedirectTo` parameter.
2. **GoTrue Fallback to Site URL**: When `emailRedirectTo` is omitted, Supabase Auth defaults the confirmation email's `redirect_to` target to the project's configured **Site URL** (which was set to `http://localhost:5001` during web development).
3. **Supabase Redirect Whitelist**: Even when `emailRedirectTo` is supplied by the app, Supabase checks it against the **Redirect URLs** allowlist in the dashboard. If `studesk://login-callback` is not explicitly whitelisted, Supabase discards it and falls back to the Site URL (`http://localhost:5001`).
4. Clicking the link on an Android device redirected the browser to port 5001 on `localhost` (which has no web server on Android), failing with `ERR_CONNECTION_REFUSED` and never opening StuDesk.

### Required Supabase Dashboard Configuration

Follow these exact steps in your [Supabase Dashboard](https://supabase.com/dashboard):

#### Step 1: Whitelist Deep Link Redirect URLs
1. Navigate to **Authentication** -> **URL Configuration**.
2. Under **Redirect URLs**, click **Add URL**.
3. Add the following redirect URLs:
   - `studesk://login-callback` (Required for native Android deep link)
   - `studesk://**` (Recommended wildcard for all native callbacks)
   - `http://localhost:5001` (For local Flutter web development)
4. Under **Site URL**, you can keep `http://localhost:5001` or your production domain.
5. Click **Save**.

#### Step 2: Verify the Signup Confirmation Email Template
1. Navigate to **Authentication** -> **Email Templates** -> **Confirm signup**.
2. Ensure the template body uses `{{ .ConfirmationURL }}` for the confirmation button/link:
   ```html
   <h2>Confirm your signup</h2>
   <p>Follow this link to confirm your account:</p>
   <p><a href="{{ .ConfirmationURL }}">Confirm your mail</a></p>
   ```
   > **Note**: Do not hardcode `http://localhost:5001` or any static URL inside the email template. `{{ .ConfirmationURL }}` automatically attaches the client-supplied `redirect_to=studesk://login-callback` query parameter and authentication token.

#### Step 3: Provider Settings
1. Navigate to **Authentication** -> **Providers** -> **Email**:
   - Ensure **Enable Email provider** is turned **ON**.
   - **Confirm email**:
     - *If enabled*: Users must click the confirmation link sent to their email before their account is fully active. StuDesk presents a dedicated "Verify Your Email Address" screen until the link is clicked.
     - *If disabled*: Users are immediately authenticated upon form submission.
   - **Secure email change** and **Mailer OTP expiry**: Set as desired (default: 3600 seconds / 1 hour).

---

## 5. Google OAuth (Preserved for Future Re-Enablement)

Google OAuth configuration is preserved in code and can be re-enabled if needed:
- Credentials in Google Cloud Console redirect to `https://<YOUR-PROJECT-ID>.supabase.co/auth/v1/callback`.
- Deep links are configured in `android/app/src/main/AndroidManifest.xml` (`studesk://login-callback`).

---

## 6. Running and Building the Flutter App

Pass the environment variables securely at compile or run time via `--dart-define`:

### Run in Debug / Development
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Build Production Release APK
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```
