class POSSale {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String category;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime saleDate;
  final String customerName;
  final String customerType;
  final String paymentMethod;
  final String? cashierName;
  final DateTime createdAt;

  POSSale({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.category = 'Feeds',
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.saleDate,
    this.customerName = 'Walk-in Customer',
    this.customerType = 'Walk-in',
    this.paymentMethod = 'Cash',
    this.cashierName,
    required this.createdAt,
  });

  factory POSSale.fromJson(Map<String, dynamic> json) {
    final rawQty = json['quantity'];
    final rawUnit = json['unit_price'];
    final rawTotal = json['total_amount'];

    final parsedSaleDate = json['sale_date'] != null
        ? DateTime.tryParse(json['sale_date'].toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final parsedCreatedAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? parsedSaleDate
        : parsedSaleDate;

    return POSSale(
      id: (json['id'] ?? '').toString(),
      orderId: (json['order_id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? 'Product').toString(),
      category: (json['category'] ?? 'Feeds').toString(),
      quantity: rawQty is num ? rawQty.toInt() : int.tryParse(rawQty?.toString() ?? '1') ?? 1,
      unitPrice: rawUnit is num ? rawUnit.toDouble() : double.tryParse(rawUnit?.toString() ?? '0') ?? 0.0,
      totalAmount: rawTotal is num ? rawTotal.toDouble() : double.tryParse(rawTotal?.toString() ?? '0') ?? 0.0,
      saleDate: parsedSaleDate,
      customerName: (json['customer_name'] ?? 'Walk-in Customer').toString(),
      customerType: (json['customer_type'] ?? 'Walk-in').toString(),
      paymentMethod: (json['payment_method'] ?? 'Cash').toString(),
      cashierName: json['cashier_name']?.toString(),
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'sale_date': saleDate.toIso8601String(),
      'customer_name': customerName,
      'customer_type': customerType,
      'payment_method': paymentMethod,
      'cashier_name': cashierName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
