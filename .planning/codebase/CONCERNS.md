# Codebase Concerns

**Analysis Date:** 2026-10-09

## Tech Debt

**Hardcoded Fallback Supabase Credentials:**
- Issue: `lib/main.dart` includes default fallback Supabase URL and anon key strings if `.env` fails to load.
- Files: `lib/main.dart` (lines 39-41)
- Impact: Hardcoded project keys baked directly into production client binaries.
- Fix approach: Inject via compile-time `--dart-define` environment parameters or ensure secure `.env` bundling.

**WebAssembly (WASM) Incompatibilities:**
- Issue: `flutter_secure_storage_web` relies on legacy `dart:html` and `dart:js_util` which are unsupported under Flutter WebAssembly (WASM) builds.
- Files: `build/web/`
- Impact: Prevents compiling Flutter Web with the high-performance `--wasm` target.
- Fix approach: Upgrade or abstract storage dependencies using modern JS interop (`dart:js_interop`) or conditional imports.

## Known Bugs & Edge Cases

**Offline Token Invalidation:**
- Symptoms: If network disconnects while renewing Supabase tokens, session state in Riverpod can become desynchronized from `flutter_secure_storage`.
- Files: `lib/services/auth_service.dart`, `lib/providers/auth_provider.dart`
- Workaround: Force sign-out and prompt user to re-authenticate.

**Mobile App Dual Structure:**
- Symptoms: Both `lib/mobile_app/` and `apps/piggytrunk_mobile/` exist with overlapping responsibilities.
- Files: `lib/mobile_app/`, `apps/piggytrunk_mobile/`
- Impact: Risk of code drift or editing the wrong mobile entry point when building Android APK vs Web release.
- Fix approach: Formalize `packages/` workspace as described in `apps/README.md` or unify client code.

## Security Considerations

**Row Level Security (RLS) Policy Coverage:**
- Risk: Direct Supabase client calls can bypass client-side checks if RLS policies are misconfigured.
- Files: `sql/erd_supabase/28_rls_policies.sql`, `sql/erd_supabase/34_fix_investments_and_notifications_rls.sql`
- Current mitigation: RLS enabled on all sensitive tables (`app_users`, `investments`, `pos_sales`).
- Recommendations: Maintain exhaustive unit/integration tests verifying unauthorized roles receive empty query sets.

**Client-Side Email Delivery:**
- Risk: SMTP credentials could be exposed if `email_service.dart` is invoked client-side without edge function encapsulation.
- Files: `lib/services/email_service.dart`, `server.js`
- Current mitigation: Server microservice available in `server.js`.
- Recommendations: Route all email triggers through Supabase Edge Functions or the Node microservice.

## Performance Bottlenecks

**Large Bundle Size on Flutter Web:**
- Problem: Flutter web assets require initial downloads of CanvasKit/Skwasm and engine runtime (~15-25 MB uncompressed).
- Files: `build/web/main.dart.js`, `build/web/canvaskit/`
- Cause: Full Flutter runtime engine for CanvasKit rendering.
- Improvement path: Enable gzip/brotli compression on Vercel and tree-shake unused icons and font weights.

## Test Coverage Gaps

**Zero Automated Tests in `test/`:**
- What's not tested: All business logic, forecasting equations, batch turnover validations, and investment ROI calculations.
- Files: Entire `lib/` directory.
- Risk: Regressions can go unnoticed until runtime in production builds.

---

*Concerns analysis: 2026-10-09*
