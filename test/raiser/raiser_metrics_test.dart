import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hog Raiser Financial & Inventory Metrics Tests', () {
    test('Calculates capital invested, deductions, and remaining balance accurately', () {
      const double initialCapital = 150000.0;
      const double stocksSpendAmount = 35400.0;

      final double remainingBalance = (initialCapital - stocksSpendAmount).clamp(0.0, double.infinity);
      final double totalCurrentInvestment = initialCapital - stocksSpendAmount;

      expect(remainingBalance, 114600.0);
      expect(totalCurrentInvestment, 114600.0);

      // Currency formatting check
      String formatCurrency(double amount) {
        return '₱${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      }

      expect(formatCurrency(initialCapital), '₱150,000');
      expect(formatCurrency(stocksSpendAmount), '₱35,400');
      expect(formatCurrency(remainingBalance), '₱114,600');
    });

    test('Identifies healthy vs sick hogs accurately', () {
      final List<Map<String, dynamic>> hogsList = [
        {'hog_id': 1, 'health_status': 'Healthy', 'weight': 25.5},
        {'hog_id': 2, 'health_status': 'Recovered', 'weight': 28.0},
        {'hog_id': 3, 'health_status': 'Sick', 'weight': 22.0},
        {'hog_id': 4, 'health_status': 'Fever', 'weight': 23.5},
        {'hog_id': 5, 'health_status': 'Diarrhea', 'weight': 21.0},
        {'hog_id': 6, 'health_status': 'Injured', 'weight': 30.0},
        {'hog_id': 7, 'health_status': 'healthy', 'current_weight': 29.5},
      ];

      final int totalHogs = hogsList.length;
      final int sickHogsCount = hogsList.where((h) {
        final s = (h['health_status'] ?? '').toString().trim().toLowerCase();
        return s == 'sick' ||
            s == 'under observation' ||
            s == 'quarantine' ||
            s == 'fever' ||
            s == 'diarrhea' ||
            s == 'food poisoning' ||
            s == 'injury' ||
            s == 'injured';
      }).length;

      final int healthyHogsCount = (totalHogs - sickHogsCount).clamp(0, totalHogs);
      final double healthPercent = totalHogs > 0 ? (healthyHogsCount / totalHogs * 100) : 0.0;

      expect(totalHogs, 7);
      expect(sickHogsCount, 4); // Sick, Fever, Diarrhea, Injured
      expect(healthyHogsCount, 3); // Healthy, Recovered, healthy
      expect(healthPercent, closeTo(42.85, 0.01));
    });

    test('Weight parsing fallback handles weight, current_weight, and string inputs', () {
      double? parseHogWeight(Map<String, dynamic> hog) {
        final rawWeight = hog['weight'] ?? hog['current_weight'];
        return rawWeight is num
            ? rawWeight.toDouble()
            : double.tryParse(rawWeight?.toString() ?? '');
      }

      expect(parseHogWeight({'weight': 45.2}), 45.2);
      expect(parseHogWeight({'current_weight': 50.8}), 50.8);
      expect(parseHogWeight({'weight': '62.5'}), 62.5);
      expect(parseHogWeight({'weight': null, 'current_weight': '70.0'}), 70.0);
      expect(parseHogWeight({}), isNull);
    });
  });
}
