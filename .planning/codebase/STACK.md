# Technology Stack

**Analysis Date:** 2026-10-09

## Languages

**Primary:**
- Dart 3.11+ (`^3.11.1`) - Core client applications (Web, Android, iOS, Desktop) in `lib/` and `apps/piggytrunk_mobile/`

**Secondary:**
- JavaScript / Node.js (ES6+ / CommonJS) - Auxiliary utility scripts and backend microservice in `server.js`
- SQL (PostgreSQL / PL/pgSQL) - Database schema, RPC functions, triggers, and RLS policies in `sql/erd_supabase/`
- HTML / CSS - Flutter web shell and canvas rendering in `web/`

## Runtime

**Environment:**
- Flutter SDK (Web, Android, Windows, macOS, Linux)
- Node.js 18+ / 20+ runtime for local backend helper tools and MCP services

**Package Manager:**
- Flutter / Dart Pub (`pubspec.yaml`, `pubspec.lock`)
- npm (`package.json`, `package-lock.json`)
- Lockfiles: Present (`pubspec.lock` and `package-lock.json`)

## Frameworks

**Core:**
- Flutter SDK (`flutter`) - Cross-platform UI toolkit targeting Web and Mobile
- Riverpod (`flutter_riverpod` ^2.4.0) - Reactive state management and dependency injection

**UI & Styling:**
- Google Fonts (`google_fonts` ^6.1.0) - Plus Jakarta Sans typography
- SVG Engine (`flutter_svg` ^2.0.0) - Vector rendering
- Cupertino Icons (`cupertino_icons` ^1.0.8) & Material Icons

**Testing:**
- `flutter_test` (Flutter SDK) - Unit and widget testing runner

**Build/Dev:**
- `build_runner` (^2.4.0) & `json_serializable` (^6.7.0) - Code generation for JSON models
- `flutter_lints` (^6.0.0) - Dart static analysis rules
- `flutter_launcher_icons` (^0.13.1) - Icon generator

## Key Dependencies

**Critical:**
- `supabase_flutter` (^2.12.4) - Primary backend client handling Auth, PostgreSQL query builder, Realtime events, and Storage
- `flutter_riverpod` (^2.4.0) - Global and scoped reactive state management
- `flutter_secure_storage` (^9.0.0) - Secure local token storage for persistent credentials
- `shared_preferences` (^2.2.2) - Key-value persistent preferences (theme mode, session caching)
- `flutter_dotenv` (^5.2.1) - Environment variable loading (.env)

**Infrastructure:**
- `http` (^1.1.0) - HTTP request client
- `flutter_local_notifications` (^17.0.0) - Native platform notifications
- `mailer` (^7.2.0) - Direct SMTP email dispatch
- `geolocator` (^14.0.2) & `geocoding` (^5.0.0) - Location and geocoding services
- `image_picker` (^1.1.2) & `file_picker` (^10.3.2) - Attachment and image upload handling
- `url_launcher` (^6.3.0) - External URL handling

## Configuration

**Environment:**
- Configured via `.env` file containing `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- Fallback hardcoded defaults configured in `lib/main.dart` for web environments
- Secrets must never be committed to source control

**Build:**
- `pubspec.yaml` - Core Flutter dependencies and asset registrations
- `analysis_options.yaml` - Linter and analyzer configuration
- `vercel.json` - Single-page app routing rules for Web deployments

## Platform Requirements

**Development:**
- Flutter SDK 3.x+ (Dart 3.11.1+)
- Chrome / Edge for Flutter Web debugging
- Android SDK & Gradle for APK compilation
- Node.js for CLI tools

**Production:**
- Vercel hosting for Flutter Web release (`build/web`)
- Android ARM64 Release APK (`PiggyTrunkMobile.apk`)
- Supabase Cloud PostgreSQL database with RLS policies

---

*Stack analysis: 2026-10-09*
