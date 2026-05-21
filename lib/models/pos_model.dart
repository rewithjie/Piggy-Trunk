/// Order Item Model (Item in Cart)
class OrderItem {
  final int id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  OrderItem copyWith({int? quantity}) {
    return OrderItem(
      id: id,
      productId: productId,
      productName: productName,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Order Model
class Order {
  final List<OrderItem> items;

  Order({required this.items});

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  double get total => subtotal;

  void addItem(OrderItem item) {
    final existingIndex = items.indexWhere(
      (existing) => existing.productId == item.productId,
    );

    if (existingIndex != -1) {
      items[existingIndex] =
          items[existingIndex].copyWith(quantity: items[existingIndex].quantity + item.quantity);
    } else {
      items.add(item);
    }
  }

  void removeItem(String productId) {
    items.removeWhere((item) => item.productId == productId);
  }

  void clearOrder() {
    items.clear();
  }
}

/// POS Product Model
class POSProduct {
  final String id;
  final String name;
  final String categoryId;
  final String category;
  final String? image;
  final String description;
  final double price;
  final int units;
  final int sold;

  POSProduct({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.category,
    this.image,
    required this.description,
    required this.price,
    required this.units,
    required this.sold,
  });

  factory POSProduct.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final rawUnits = json['units'];
    final rawSold = json['sold'];

    return POSProduct(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      categoryId: (json['category_id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      image: json['image']?.toString(),
      description: (json['description'] ?? '').toString(),
      price: rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice?.toString() ?? '0') ?? 0,
      units: rawUnits is num ? rawUnits.toInt() : int.tryParse(rawUnits?.toString() ?? '0') ?? 0,
      sold: rawSold is num ? rawSold.toInt() : int.tryParse(rawSold?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'category': category,
      'image': image,
      'description': description,
      'price': price,
      'units': units,
      'sold': sold,
    };
  }
}
