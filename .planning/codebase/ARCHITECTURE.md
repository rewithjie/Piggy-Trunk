<!-- refreshed: 2026-10-09 -->
# Architecture

**Analysis Date:** 2026-10-09

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                      Client Layer (Flutter Multi-Role UI)               │
├───────────────────────┬──────────────────────────┬──────────────────────┤
│    Admin Web Portal   │     Mobile Responsive    │   Native Mobile App  │
│      `lib/screens/`   │    `lib/mobile_app/`     │ `apps/piggytrunk_...`│
└───────────┬───────────┴────────────┬─────────────┴──────────┬───────────┘
            │                        │                        │
            ▼                        ▼                        ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                 State & Business Logic Layer (Riverpod)                 │
│      `lib/providers/` (Auth, Dashboard, AdminNotifications, Profiles)   │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            Service Layer                                │
│   `lib/services/` (AuthService, NotificationService, EmailService, ...) │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│            Backend & Data Persistence (Supabase / PostgreSQL)           │
│   Auth / Realtime / Storage / Tables & RPC Functions (`sql/erd_...`)    │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| App Entry & Routing | Initializes Supabase, configures URL strategy, binds themes, routes roles | `lib/main.dart` |
| Theme System | Defines design tokens, Plus Jakarta Sans typography, dual light/dark modes | `lib/theme/app_theme.dart` |
| Auth Service | Handles user sign-in, signup, session restoration, and role resolution | `lib/services/auth_service.dart` |
| Notification Service | Realtime channels, sound triggers, and in-app alerts for all roles | `lib/services/notification_service.dart` |
| Admin Web Portal | Dashboard, inventory, batches, approvals, forecasting, POS, and raisers | `lib/screens/` |
| Mobile Unified App | Role-specific mobile dashboards for Raiser, Partner/Investor, Cashier, Admin | `lib/mobile_app/` |
| Database & Security | PostgreSQL schemas, triggers, seed data, and Row Level Security policies | `sql/erd_supabase/` |

## Pattern Overview

**Overall:** Feature-Layered Architecture with Provider/Service Separation

**Key Characteristics:**
- **Role Isolation:** Dispatches users to specific screens depending on their assigned `app_users.role` (admin, raiser, partner, cashier).
- **Responsive Dual-Targeting:** Supports full-screen desktop/web administrative interfaces alongside mobile-optimized responsive shells.
- **Reactive Realtime:** Integrates Supabase Realtime channels with Riverpod state notifiers to deliver live updates without manual polling.

## Layers

**UI Layer (`lib/screens/`, `lib/mobile_app/screens/`):**
- Purpose: Render interfaces, capture user events, display data models.
- Depends on: Providers and Models.

**State Management Layer (`lib/providers/`):**
- Purpose: Expose reactive state to widgets using Riverpod (`ChangeNotifierProvider`, `StateProvider`).
- Depends on: Services and Models.

**Service Layer (`lib/services/`):**
- Purpose: Encapsulate asynchronous operations, Supabase client queries, hardware APIs, and email dispatch.
- Depends on: External SDKs and database endpoints.

**Data & Models Layer (`lib/models/`, `sql/erd_supabase/`):**
- Purpose: Strongly-typed data definitions and database schema integrity.

## Data Flow

### Primary Request Path (Authentication & Role Redirection)

1. User submits credentials (`lib/mobile_app/screens/login_screen.dart:120`)
2. `AuthService.signIn` authenticates against Supabase GoTrue (`lib/services/auth_service.dart`)
3. Fetches user metadata and role from `public.app_users`
4. App router switches to appropriate role screen (e.g. `RaiserDashboardScreen` or `DashboardScreen`)

### Realtime Notifications Flow

1. Database trigger executes on table insert (`sql/erd_supabase/18_admin_notifications.sql`)
2. Supabase Realtime emits event across websocket
3. `NotificationService` captures change and updates `AdminNotificationsProvider` (`lib/services/notification_service.dart`)
4. App bar badge and notification drawers update reactively in UI

## Architectural Constraints

- **Single Supabase Instance:** All database calls route through `Supabase.instance.client`.
- **Role Boundaries:** Hog raisers and partner investors cannot view admin-restricted metrics. Enforced both by client navigation checks and Supabase Row Level Security (RLS).
- **Offline Resilience:** Auth tokens and critical settings cached in `flutter_secure_storage` and `shared_preferences`.

## Error Handling

**Strategy:** Try-catch wrappers in service calls surfacing user-friendly SnackBar / Toast alerts.

---

*Architecture analysis: 2026-10-09*
