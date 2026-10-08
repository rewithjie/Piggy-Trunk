---
trigger: always_on
description: Piggy Trunk UI/UX Design System, brand tokens, typography, and styling rules.
---

# Piggy Trunk Design System & UI Rules

When developing, refactoring, or generating UI components, screens, or assets for Piggy Trunk, adhere strictly to these established design specifications.

## 1. Brand Color Palette (`lib/theme/app_theme.dart`)

Always reference tokens from `PiggyTrunkTheme` instead of arbitrary hex colors:

### Light Theme
- **Primary Navy:** `PiggyTrunkTheme.ptPrimary` (`#243b53`) — Primary brand headers, sidebars, active badges, and main action buttons.
- **Accent Coral:** `PiggyTrunkTheme.ptAccent` (`#ef5b6c`) — Highlights, key interactive CTAs, warnings, and vital alerts.
- **Success Emerald:** `PiggyTrunkTheme.ptSuccess` (`#2fb36f`) — Completed batches, positive investments, healthy reports.
- **In-Progress Amber:** `PiggyTrunkTheme.ptInProgress` (`#ffa566`) — Active hog batches, pending approvals, ongoing cycles.
- **Text Primary:** `PiggyTrunkTheme.ptText` (`#18314f`) — Main headings and body copy.
- **Text Muted:** `PiggyTrunkTheme.ptMuted` (`#6f8096`) — Subtitles, metadata, and timestamps.
- **Surface / Cards:** `PiggyTrunkTheme.ptSurface` (`#ffffff`) and `PiggyTrunkTheme.ptSurfaceSoft` (`#f8fafc`).
- **Border:** `PiggyTrunkTheme.ptBorder` (`#e6ebf2`).
- **Scaffold Background:** `PiggyTrunkTheme.ptBg` (`#f4f7fb`).

### Dark Theme
- **Scaffold Background:** `PiggyTrunkTheme.ptBgDark` (`#0f1724`).
- **Surface / Cards:** `PiggyTrunkTheme.ptSurfaceDark` (`#151f2e`) and `ptSurfaceSoftDark` (`#1b2638`).
- **Border:** `PiggyTrunkTheme.ptBorderDark` (`#28354a`).
- **Text Primary:** `PiggyTrunkTheme.ptTextDark` (`#ecf2ff`).
- **Text Muted:** `PiggyTrunkTheme.ptMutedDark` (`#9cb0c9`).
- **Accent Coral:** `PiggyTrunkTheme.ptAccentDark` (`#ff758c`).
- **Success Emerald:** `PiggyTrunkTheme.ptSuccessDark` (`#43cb89`).

## 2. Typography

- **Font Family:** `GoogleFonts.plusJakartaSans` across all platforms (Web and Mobile).
- **Scale:**
  - `displayLarge`: 32px, `FontWeight.w800`, letterSpacing `-0.04`
  - `displayMedium`: 28px, `FontWeight.w800`, letterSpacing `-0.04`
  - `headlineMedium`: 20px, `FontWeight.w800`, letterSpacing `-0.04`
  - `titleMedium`: 16px, `FontWeight.w600`
  - `bodyMedium`: 14px, `FontWeight.w400`
  - `bodySmall`: 12px, `FontWeight.w500`

## 3. Component Standards & Aesthetics

- **Card Styling:** Standardize card borders with `BorderRadius.circular(12)` or `BorderRadius.circular(16)` with subtle borders (`Border.all(color: PiggyTrunkTheme.ptBorder)`).
- **Elevation:** Avoid heavy material drop shadows. Use subtle modern shadows:
  ```dart
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ]
  ```
- **Dual Form Factor:**
  - **Desktop / Admin Web:** Persistent navigation sidebar, responsive multi-column metric grids, data tables with pagination.
  - **Mobile Shell (`ResponsiveMobileWrapper`):** Clean bottom navigation bar or drawer, card-based lists, floating status indicators, mobile-friendly forms.
- **States & Micro-interactions:** Use smooth transitions, clear disabled button states, and shimmer loading skeletons (`ShimmerLoading`).
