# Coding Conventions

**Analysis Date:** 2026-10-09

## Naming Patterns

**Files:**
- Dart source files use lowercase with underscores: `lower_snake_case.dart` (e.g., `dashboard_screen.dart`, `app_theme.dart`).
- Screen widgets append `Screen` (e.g., `InventoryScreen`, `AdminLoginScreen`).
- Tab widgets append `Tab` (e.g., `PartnerHomeTab`, `RaiserProfileTab`).
- Dialog / Sheet widgets append `Dialog`, `Sheet`, or `Drawer` (e.g., `BatchRaiserDetailsDrawer`).

**Classes & Types:**
- PascalCase for all classes, enums, mixins, and typedefs (e.g., `PiggyTrunkTheme`, `NotificationService`).

**Variables & Functions:**
- camelCase for functions, methods, local variables, and parameters (e.g., `fetchDashboardData()`, `currentBatchId`).
- Private members prefixed with `_` (e.g., `_supabaseUrl`, `_defaultSupabaseAnonKey`).

## Code Style

**Formatting:**
- Official Dart formatting standard via `dart format` (120/80 column wrap standard).
- Trailing commas are consistently applied on multi-line parameter lists to enable clean Dart formatting.

**Linting:**
- Configured via `analysis_options.yaml` extending `package:flutter_lints/flutter.yaml`.
- Analyzer options enforce `prefer_const_constructors`, `prefer_final_fields`, and `use_key_in_widget_constructors`.

## Import Organization

**Order:**
1. Flutter / Dart SDK imports: `import 'package:flutter/material.dart';`
2. Third-party packages: `import 'package:supabase_flutter/supabase_flutter.dart';`
3. Relative workspace imports: `import '../models/product_model.dart';`

**Path Style:**
- Relative imports within the `lib/` directory or package-qualified `package:piggytrunk/...` imports.

## Error Handling

**Patterns:**
- Asynchronous service calls are wrapped in `try/catch` blocks:
```dart
try {
  final response = await Supabase.instance.client.from('batches').select();
  return response.map((data) => BatchModel.fromJson(data)).toList();
} catch (e, stack) {
  debugPrint('Error fetching batches: $e\n$stack');
  rethrow;
}
```
- In UI widgets, errors trigger an error SnackBar:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Failed to perform operation: $e'),
    backgroundColor: PiggyTrunkTheme.ptAccent,
  ),
);
```

## Logging

**Framework:**
- `debugPrint(...)` and `kDebugMode` checks for development logging.
- Avoid raw `print(...)` in production code.

## Theme & UI Tokens

**Consistency Guidelines:**
- Avoid hardcoding arbitrary hex colors directly inside widgets.
- Always reference `PiggyTrunkTheme` color tokens from `lib/theme/app_theme.dart`:
  - Primary Navy: `PiggyTrunkTheme.ptPrimary` (`#243b53`)
  - Accent / Danger Coral: `PiggyTrunkTheme.ptAccent` (`#ef5b6c`)
  - Success Emerald: `PiggyTrunkTheme.ptSuccess` (`#2fb36f`)
  - In Progress Amber: `PiggyTrunkTheme.ptInProgress` (`#ffa566`)
  - Surface & Background: `PiggyTrunkTheme.ptSurface`, `PiggyTrunkTheme.ptBg`
- Typography: Standardize on `GoogleFonts.plusJakartaSans` via `Theme.of(context).textTheme`.

## Git Commit Rules (Workspace Enforced)

- Always run `flutter build web --release` before commits that modify web/client behavior.
- Commit messages must be simple, direct, concise, and explicitly mention the edited section (e.g. `Update mobile raiser drawer`, `Align admin sidebar active tabs`).
- Do NOT use conventional commit prefixes (`feat:`, `chore:`, `refactor:`) in workspace commits.

---

*Convention analysis: 2026-10-09*
