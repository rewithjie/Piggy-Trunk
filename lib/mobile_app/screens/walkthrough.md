# Walkthrough - Redesigned Stock/Supply Request Flow, Hogs Tab, Editable Profile & Avatar Edit

Fully implemented the redesigned Stock/Supply request flow, added a dedicated Request History screen, localized labels to friendly Tagalog, redesigned the Hogs tab, resolved dialog visibility bugs, and implemented interactive Profile Picture editing.

## Changes Made

### 1. Database Schema Update

#### [NEW] [26_hog_reports.sql](file:///c:/Users/rewithjie/Piggy-Trunk/sql/erd_supabase/26_hog_reports.sql)
- Created the new `hog_reports` table to store logs of health issues, disease outbreaks, or deaths reported by raisers.

#### [NEW] [27_hog_raisers_avatar.sql](file:///c:/Users/rewithjie/Piggy-Trunk/sql/erd_supabase/27_hog_raisers_avatar.sql)
- Added an `avatar_url` text column to the `public.hog_raisers` table.

#### [MODIFY] [00_run_order.md](file:///c:/Users/rewithjie/Piggy-Trunk/sql/erd_supabase/00_run_order.md)
- Documented `27_hog_raisers_avatar.sql` in the run order sequence.

### 2. Tab Navigation & Hogs Tab Redesign

#### [MODIFY] [dashboard_screen.dart](file:///c:/Users/rewithjie/Piggy-Trunk/apps/hog_raiser_mobile/lib/screens/dashboard_screen.dart)
- **Nested Tab Navigation**:
  - Embedded `RequestFormScreen` and `RequestHistoryScreen` directly within the Request tab view state machine.
- **Hogs Tab Redesign**:
  - Rewrote the `_buildHogsTab` screen to match the mockup.

### 3. Profile & Dialog Visibility Fixes

#### [MODIFY] [dashboard_screen.dart](file:///c:/Users/rewithjie/Piggy-Trunk/apps/hog_raiser_mobile/lib/screens/dashboard_screen.dart)
- **Dialog Button Visibility**: Resolved invisible/microscopic text issues on TextButtons in both the **Add Report** and **Edit Profile** dialogs by explicitly defining `fontSize: 14` on the Text widget properties.
- **Profile Picture Upload**:
  - Tapping on the profile image now triggers `_pickAndUploadAvatar()`.
  - Integrates `image_picker` to select photos from the mobile gallery, uploads them directly to the Supabase Storage `'profile_pictures'` bucket, and updates the `avatar_url` column in the database.
  - Implemented a circular profile image loader that displays the chosen picture with a pink camera overlay icon, falling back to `PiggyTrunkLogo` when none is set.

---

## Verification Results

### Automated Checks
- Ran `flutter analyze`. The entire project builds successfully with **zero compile errors**.
