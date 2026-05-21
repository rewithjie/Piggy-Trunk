import '../models/product_model.dart';

class MockInventoryData {
  static List<ProductCategory> getCategories() {
    return [
      ProductCategory(id: 'feeds', name: 'Feeds', icon: 'F'),
      ProductCategory(id: 'vitamins', name: 'Vitamins', icon: 'V'),
      ProductCategory(id: 'medicines', name: 'Medicines', icon: 'M'),
      ProductCategory(id: 'other', name: 'Other', icon: 'O'),
    ];
  }

  static List<Product> getProductsByCategory(String categoryId) {
    return [];
  }

  static List<Product> getAllProducts() {
    return [];
  }

  static List<Product> getArchivedProducts() {
    return [];
  }
}
