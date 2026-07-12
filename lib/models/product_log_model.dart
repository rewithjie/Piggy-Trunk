class ProductLog {
  final String id;
  final String? productId;
  final String productName;
  final String action; // 'ADD', 'UPDATE', 'ARCHIVE', 'RESTORE'
  final String performedBy;
  final double price;
  final int units;
  final String? details;
  final DateTime createdAt;

  ProductLog({
    required this.id,
    this.productId,
    required this.productName,
    required this.action,
    required this.performedBy,
    required this.price,
    required this.units,
    this.details,
    required this.createdAt,
  });

  factory ProductLog.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final rawUnits = json['units'];

    return ProductLog(
      id: (json['id'] ?? '').toString(),
      productId: json['product_id']?.toString(),
      productName: (json['product_name'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      performedBy: (json['performed_by'] ?? '').toString(),
      price: rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0,
      units: rawUnits is num ? rawUnits.toInt() : int.tryParse(rawUnits?.toString() ?? '0') ?? 0,
      details: json['details']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'action': action,
      'performed_by': performedBy,
      'price': price,
      'units': units,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
