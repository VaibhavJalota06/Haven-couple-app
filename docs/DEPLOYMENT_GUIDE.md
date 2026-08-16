# Haven - Production Deployment & Setup Guide

## 1. Supabase Backend Setup

1. Create a project at [https://supabase.com](https://supabase.com).
2. Open the **SQL Editor** in the Supabase Dashboard.
3. Run the SQL migration scripts in sequence:
   - `supabase/migrations/01_initial_schema.sql`
   - `supabase/migrations/02_rls_policies.sql`
   - `supabase/migrations/03_storage_buckets.sql`
   - `supabase/migrations/04_functions_and_triggers.sql`
4. Under **Project Settings -> API**, copy:
   - `Project URL`
   - `anon public key`
5. Enable Email Auth under **Authentication -> Providers**.

## 2. Client Configuration

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Update `.env` with your Supabase credentials:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-public-key
   ```

## 3. Running & Building the Flutter App

### Local Development
```bash
# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

### Running Test Suite
```bash
flutter test
```

### Production Builds

**Android APK / App Bundle:**
```bash
flutter build appbundle --release
```

**iOS Release Build:**
```bash
flutter build ipa --release
```
