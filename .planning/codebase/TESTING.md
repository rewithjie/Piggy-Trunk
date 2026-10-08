# Testing Patterns

**Analysis Date:** 2026-10-09

## Test Framework

**Runner:**
- Flutter Test Runner (`flutter_test` from Flutter SDK)
- Config: `pubspec.yaml` under `dev_dependencies`

**Assertion Library:**
- `package:flutter_test/flutter_test.dart` assertions (`expect`, `findsOneWidget`, `equals`)

**Run Commands:**
```powershell
flutter test                           # Run all tests in test/ directory
flutter test test/unit/sample_test.dart # Run single test file
flutter test --coverage                # Generate lcov coverage profile
```

## Test File Organization

**Location:**
- Located in dedicated root `test/` directory.

**Naming:**
- Files must end with `_test.dart` (e.g. `auth_service_test.dart`, `dashboard_screen_test.dart`).

**Current Codebase State:**
- The root `test/` directory is currently empty.
- Previous test suites were kept in temporary or reverted branches; establishing an automated test harness for core services and calculations (forecasting, POS total calculations, and batch management) is recommended.

## Standard Test Patterns

**Unit Test Structure:**
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForecastingService Calculation Tests', () {
    test('calculates correct growth trajectory given weight and feed metrics', () {
      // Setup
      final initialWeight = 20.0;
      final dailyGain = 0.75;
      final days = 30;

      // Execute
      final projected = initialWeight + (dailyGain * days);

      // Verify
      expect(projected, equals(42.5));
    });
  });
}
```

**Widget Test Structure:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Renders Login Screen with email and password fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Sign In'), findsOneWidget);
  });
}
```

## Mocking & Isolation

**Mocking Recommendation:**
- Use `mockito` or `mocktail` for mocking `SupabaseClient` and `NotificationService`.
- Wrap API calls in interface boundaries or pass mock instances via Riverpod provider overrides:
```dart
final container = ProviderContainer(
  overrides: [
    authServiceProvider.overrideWithValue(MockAuthService()),
  ],
);
```

## Coverage Gaps

- Critical business logic in `lib/services/forecasting_service.dart` and `lib/services/auth_service.dart` currently has 0% automated test coverage.
- Priority areas for future testing phases:
  1. `ForecastingService` math calculations
  2. Inventory deduction & stock request flows
  3. Investment ROI and distribution logic
  4. Role permission guards

---

*Testing analysis: 2026-10-09*
