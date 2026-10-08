# Codebase Structure

**Analysis Date:** 2026-10-09

## Directory Layout

```text
Piggy-Trunk/
├── .agents/                 # GSD skills, agents, workflows, hooks, rules, and settings
├── apps/
│   └── piggytrunk_mobile/   # Dedicated mobile client project and standalone mobile tree
├── assets/                  # Images, SVGs, audio effects, and UI brand assets
├── build/
│   └── web/                 # Flutter web compiled release bundle deployed to Vercel
├── docs/                    # Architecture diagrams, ERD visualizers, DBML schemas
├── lib/                     # Main shared Flutter application codebase
│   ├── config/              # App configuration constants
│   ├── data/                # Static seed data and mock adapters
│   ├── mobile_app/          # Role-based mobile client screens, tabs, and widgets
│   │   ├── screens/         # Role dashboards (admin, cashier, partner, raiser)
│   │   ├── services/        # Mobile-specific utilities and providers
│   │   ├── utils/           # Helper functions and string definitions
│   │   └── widgets/         # Responsive wrappers, side drawers, modals
│   ├── models/              # Strongly-typed Dart data transfer objects
│   ├── providers/           # Riverpod state providers and controllers
│   ├── screens/             # Web/Desktop admin portal pages
│   ├── services/            # API clients, Supabase services, notification handlers
│   ├── styles/              # Screen-specific styles and aesthetic overrides
│   ├── theme/               # Global PiggyTrunkTheme and typography definitions
│   ├── utils/               # Formatting, currency helpers, and data adapters
│   └── widgets/             # Reusable UI components (tables, dialogs, charts)
├── sql/
│   └── erd_supabase/        # 35 ordered SQL migrations for Supabase Postgres & RLS
├── test/                    # Unit and widget test files
├── web/                     # Web entry index.html, manifest.json, favicon
└── vercel.json              # Vercel deployment routing configuration
```

## Directory Purposes

**`lib/screens/`:**
- Purpose: Contains full-featured administrative views for web and desktop.
- Contains: `dashboard_screen.dart`, `hog_raiser_screen.dart`, `investments_screen.dart`, `inventory_screen.dart`, `pos_screen.dart`, `batch_management_screen.dart`, `demand_forecasting_screen.dart`, `best_sellers_screen.dart`, `landing_screen.dart`.

**`lib/mobile_app/`:**
- Purpose: Self-contained mobile experience partitioned by role.
- Contains:
  - `raiser/`: Pig status, health reporting, feeding logs, weight entry.
  - `partner/`: Investment cycles, ROI metrics, project catalogs, portfolio.
  - `cashier/`: POS terminal, daily sales, invoice printing.
  - `admin/`: Quick mobile management and approval flows.

**`lib/services/`:**
- Purpose: Centralized business logic and external integrations.
- Key files: `auth_service.dart`, `notification_service.dart`, `forecasting_service.dart`, `email_service.dart`.

**`sql/erd_supabase/`:**
- Purpose: Complete source-controlled database migrations, security policies, triggers, and views.

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Primary Flutter application bootstrap.
- `lib/mobile_app/main.dart`: Mobile standalone bootstrap.
- `web/index.html`: Web hosting entrypoint.

**Configuration:**
- `pubspec.yaml`: Flutter dependencies and asset registrations.
- `vercel.json`: Hosting rewrite rules for single-page routing.
- `analysis_options.yaml`: Dart analysis and linter rules.

**Theme & Brand:**
- `lib/theme/app_theme.dart`: Color tokens, dark/light themes, typography.

## Naming Conventions

**Files:**
- Dart files: `lower_snake_case.dart` (e.g., `batch_management_screen.dart`, `auth_service.dart`).
- SQL migrations: `NN_description.sql` (e.g., `18_admin_notifications.sql`).

**Directories:**
- `lower_snake_case` (e.g., `mobile_app`, `erd_supabase`).

**Classes & Widgets:**
- `PascalCase` (e.g., `PiggyTrunkTheme`, `RaiserDashboardScreen`, `InvestmentsScreen`).

## Where to Add New Code

**New Role Screen / Feature:**
- Admin Web: Add screen under `lib/screens/` and register navigation route in `lib/widgets/sidebar.dart` / `lib/main.dart`.
- Mobile Feature: Add screen under `lib/mobile_app/screens/<role>/` and update relevant tab/drawer under `lib/mobile_app/screens/<role>/tabs/`.

**New Database Table / Migration:**
- Add migration under `sql/erd_supabase/NN_<feature_name>.sql`.
- Create corresponding Dart model under `lib/models/`.

**New Service / Business Logic:**
- Add under `lib/services/` and expose via Riverpod provider in `lib/providers/`.

---

*Structure analysis: 2026-10-09*
