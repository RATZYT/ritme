# RITME — Flutter Android MVP starter

This repository contains the first functional MVP foundation:
- Supabase email/password sign up and sign in
- Session-aware authentication gate
- Dashboard task summary
- Task create, filter, complete/reopen, delete
- Habit create and daily check-in
- Profile and sign out
- Material 3 light/dark system theme
- GitHub Actions workflow that builds a release APK in the cloud

## 1. Create a GitHub repository

Create an empty repository named `ritme`. Upload the contents of this folder to the repository root (not the parent folder).

## 2. Add GitHub Actions secrets

Repository → Settings → Secrets and variables → Actions → New repository secret:

- `SUPABASE_URL` = your Supabase project URL
- `SUPABASE_PUBLISHABLE_KEY` = your Supabase publishable key

Do not add a `service_role` key or secret key. Never commit credentials into source files.

## 3. Check Supabase

The app expects the six tables created by the RITME SQL setup:
`profiles`, `user_settings`, `tasks`, `habits`, `habit_checkins`, `daily_goals`.

Ensure the Data API exposes the required tables and that RLS policies are enabled and tested. The `tasks` and `habits` tables must allow authenticated users to access only their own rows.

If email confirmation is enabled, users may need to confirm their email before signing in.

## 4. Build the APK using your phone

Open the repository on GitHub:
1. Open the Actions tab.
2. Select `Build RITME APK`.
3. Tap `Run workflow`.
4. Wait for the run to finish.
5. Open the successful run and download `ritme-release-apk` from Artifacts.
6. Extract the ZIP and install `app-release.apk` on your Android phone.

The workflow generates the Android platform folder in the cloud, runs `flutter analyze` and `flutter test`, then builds the APK. A failed check stops the release build.

## Current scope

This is an initial MVP foundation, not the finished RITME product. Analytics, daily-goal management, notification scheduling, password reset UI, profile editing, and more complete automated tests are not implemented yet. Do not describe the app as production-ready until these are implemented and tested.
