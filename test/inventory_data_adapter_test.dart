import 'package:flutter_test/flutter_test.dart';
import 'package:piggytrunk/utils/inventory_data_adapter.dart';

void main() {
  group('normalizeInventoryRows', () {
    test('maps product table rows into the inventory payload shape', () {
      final rows = [
        {
          'product_id': 1,
          'product_name': 'Grower Feed',
          'unit_price': 25.5,
          'current_stock': 12,
          'category': 'Feeds',
        },
      ];

      final normalized = normalizeInventoryRows(rows, sourceTable: 'products');

      expect(normalized.single['name'], 'Grower Feed');
      expect(normalized.single['price'], 25.5);
      expect(normalized.single['units'], 12);
      expect(normalized.single['category'], 'Feeds');
    });

    test('keeps inventory_products rows intact', () {
      final rows = [
        {
          'id': 'abc',
          'name': 'Vitamin Mix',
          'price': 10.0,
          'units': 4,
          'category': 'Vitamins',
        },
      ];

      final normalized = normalizeInventoryRows(rows, sourceTable: 'inventory_products');

      expect(normalized.single['id'], 'abc');
      expect(normalized.single['name'], 'Vitamin Mix');
    });
  });
}
