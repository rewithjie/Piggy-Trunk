# External Integrations

**Analysis Date:** 2026-10-09

## APIs & External Services

**Backend-as-a-Service:**
- Supabase Cloud - Central database, authentication, realtime, and storage
  - SDK/Client: `supabase_flutter` (^2.12.4), `@supabase/supabase-js` (^2.105.4)
  - Connection Config: `SUPABASE_URL`, `SUPABASE_ANON_KEY` in `.env` / fallback in `lib/main.dart`
  - Auth: JWT sessions via Supabase GoTrue

**Email Delivery:**
- Direct SMTP / NodeMailer
  - Client: `mailer` (^7.2.0) in Dart (`lib/services/email_service.dart`), `nodemailer` (^6.9.16) in `server.js`
  - Purpose: Password resets, admin approval notices, raiser assignment alerts

**Push & Local Notifications:**
- Local Notifications Engine
  - SDK: `flutter_local_notifications` (^17.0.0)
  - Implementation: `lib/services/notification_service.dart`

**Location Services:**
- Geolocation & Geocoding
  - SDK: `geolocator` (^14.0.2), `geocoding` (^5.0.0)
  - Purpose: Farm and delivery tracking for hog raisers

## Data Storage

**Databases:**
- PostgreSQL (Supabase Hosted)
  - Client: `SupabaseClient` (`Supabase.instance.client`)
  - Schema: Managed by 35 SQL migrations in `sql/erd_supabase/`
  - Key Tables: `app_users`, `batches`, `hogs`, `hog_raisers`, `partner_investors`, `cashiers`, `investments`, `investment_records`, `inventory_products`, `pos_sales`, `admin_notifications`, `raiser_notifications`, `partner_notifications`

**File Storage:**
- Supabase Storage Buckets
  - Purpose: Hog weight/health proof images, user avatars, verification IDs
  - Client: `SupabaseStorageClient`

**Caching:**
- SharedPreferences & FlutterSecureStorage
  - Purpose: Local offline credentials, theme preference, and session metadata

## Authentication & Identity

**Auth Provider:**
- Supabase Auth (GoTrue)
  - Implementation: `lib/services/auth_service.dart`
  - Role-based routing: Admin, Hog Raiser, Partner/Investor, Cashier
  - Trigger sync: `sql/erd_supabase/22_auth_signup_trigger.sql` maps `auth.users` to `public.app_users`

## Monitoring & Observability

**Error Tracking:**
- Flutter Framework Error Catcher (`FlutterError.onError`, `kDebugMode` logging)

**Logs:**
- `debugPrint` and console logging across service layers
- In-database audit trails: `sql/erd_supabase/12_inventory_logs.sql`

## CI/CD & Deployment

**Hosting:**
- Web: Vercel Static Hosting (`vercel.json`, `build/web`)
- Mobile: Android APK direct builds (`PiggyTrunkMobile.apk`)

**CI Pipeline:**
- Local build pipeline via PowerShell: `flutter build web --release`
- Automated Git release push workflow

## Environment Configuration

**Required env vars:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

**Secrets location:**
- Root `.env` (excluded via `.gitignore`)

## Webhooks & Callbacks

**Incoming:**
- Supabase Realtime subscriptions in `lib/services/notification_service.dart` (Postgres Changes channel listening to `admin_notifications`, `raiser_notifications`, `partner_notifications`)

**Outgoing:**
- None detected

---

*Integration audit: 2026-10-09*
