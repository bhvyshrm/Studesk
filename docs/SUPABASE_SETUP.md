# StuDesk Backend & Google Authentication Setup Guide

This document provides instructions for setting up the Supabase PostgreSQL backend and Google OAuth for StuDesk.

---

## 1. Quick Start (Offline / Local Student Mode)

By default, StuDesk runs in **Local Student Mode** without requiring any external credentials.
- All student data (courses, attendance, tasks, notes, journals, streaks) persists locally via encrypted SharedPreferences.
- Full UI and features are completely testable and functional offline.

---

## 2. Supabase Backend Setup

### Step 1: Create a Supabase Project
1. Log in to [Supabase Console](https://supabase.com).
2. Click **New Project**, choose your organization, and name your database `studesk`.
3. Choose your closest region and set a strong database password.

### Step 2: Apply the Database Schema & RLS Policies
1. In your Supabase dashboard, navigate to the **SQL Editor**.
2. Open the migration file: `supabase/migrations/20261019000000_studesk_initial_schema.sql`.
3. Paste the contents into the SQL Editor and click **Run**.
4. This sets up all tables:
   - `profiles`
   - `courses`
   - `course_units`
   - `unit_topics`
   - `subject_attendance`
   - `college_attendance`
   - `tasks`
   - `library_resources`
   - `journal_entries`
   - `timetable_entries`
   - `exams`
5. **Row Level Security (RLS)** is enabled on all tables, ensuring each student can only read, write, update, and delete their own private academic records.

---

## 3. Google OAuth Configuration

### Step 1: Google Cloud Console Credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com).
2. Create an OAuth 2.0 Client ID:
   - **Application type**: Web application (for Supabase callback)
   - **Authorized redirect URIs**: `https://<YOUR-PROJECT-ID>.supabase.co/auth/v1/callback`
3. Copy the **Client ID** and **Client Secret**.

### Step 2: Configure Supabase Auth Provider
1. In Supabase Dashboard, navigate to **Authentication -> Providers -> Google**.
2. Enable Google.
3. Paste your Google **Client ID** and **Client Secret**.
4. Save changes.

### Step 3: Platform Deep Linking (Android & iOS)

#### Android Deep Linking
In `android/app/src/main/AndroidManifest.xml`, inside `<activity android:name=".MainActivity">`:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="studesk" android:host="login-callback" />
</intent-filter>
```

#### iOS Deep Linking
In `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>studesk</string>
        </array>
    </dict>
</array>
```

---

## 4. Running the Flutter App with Supabase Credentials

Pass the environment variables securely at compile/run time via `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Or for release build:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

> [!SECURITY] Never commit service-role keys or private API secrets to the repository. The client application only requires the public Anonymous Key (`anonKey`), protected by Row Level Security on the PostgreSQL database.
