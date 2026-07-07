class InventoryRowAdapter {
  const InventoryRowAdapter();

  Map<String, dynamic> normalize(Map<String, dynamic> row, {required String sourceTable}) {
    if (sourceTable == 'inventory_products') {
      return Map<String, dynamic>.from(row);
    }

    final id = row['id'] ?? row['product_id'] ?? row['product_id'] ?? '';
    final name = row['name'] ?? row['product_name'] ?? '';
    final category = row['category'] ?? '';
    final price = row['price'] ?? row['unit_price'] ?? 0;
    final units = row['units'] ?? row['current_stock'] ?? 0;
    final sold = row['sold'] ?? 0;
    final image = row['image'];
    final description = row['description'] ?? '';
    final createdAt = row['created_at'];
    final isArchived = row['is_archived'] ?? false;

    return {
      'id': id,
      'name': name,
      'category_id': category.toString().toLowerCase().replaceAll(' ', '_'),
      'category': category,
      'description': description,
      'price': price,
      'units': units,
      'sold': sold,
      'image': image,
      'created_at': createdAt,
      'is_archived': isArchived,
    };
  }
}

List<Map<String, dynamic>> normalizeInventoryRows(
  List<dynamic> rows, {
  required String sourceTable,
}) {
  final adapter = InventoryRowAdapter();
  return rows
      .whereType<Map<String, dynamic>>()
      .map((row) => adapter.normalize(row, sourceTable: sourceTable))
      .toList();
}
