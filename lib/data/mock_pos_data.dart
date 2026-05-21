import '../models/pos_model.dart';

class MockPOSData {
  static List<String> getCategories() {
    return ['Feeds', 'Vitamins', 'Medicines', 'Other'];
  }

  static List<POSProduct> getProductsByCategory(String category) {
    // Empty list - no products yet
    return [];
  }

  static List<POSProduct> getAllProducts() {
    return [];
  }
}
