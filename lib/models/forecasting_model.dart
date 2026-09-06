import 'package:flutter/material.dart';

enum ForecastModelType {
  exponentialSmoothing,
  simpleMovingAverage,
}

enum UrgencyLevel {
  critical,
  reorder,
  adequate,
  overstocked,
}

class DailySalesPoint {
  final DateTime date;
  final int quantity;
  final double revenue;
  final bool isProjected;

  DailySalesPoint({
    required this.date,
    required this.quantity,
    this.revenue = 0.0,
    this.isProjected = false,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'quantity': quantity,
        'revenue': revenue,
        'isProjected': isProjected,
      };
}

class ProductForecast {
  final String productId;
  final String productName;
  final String category;
  final String? imageUrl;
  final int currentStock;
  final double unitPrice;
  final int leadTimeDays;
  final int safetyStock;
  final int reorderPoint;
  final double averageDailySales;
  final double standardDeviation;
  final List<DailySalesPoint> historicalDailySales;
  final List<DailySalesPoint> projectedDailySales;
  final double predictedDemand;
  final int recommendedReorderQty;
  final double daysOfSupply;
  final UrgencyLevel urgency;
  final ForecastModelType modelType;
  final double alpha;
  final int horizonDays;

  ProductForecast({
    required this.productId,
    required this.productName,
    required this.category,
    this.imageUrl,
    required this.currentStock,
    required this.unitPrice,
    required this.leadTimeDays,
    required this.safetyStock,
    required this.reorderPoint,
    required this.averageDailySales,
    required this.standardDeviation,
    required this.historicalDailySales,
    required this.projectedDailySales,
    required this.predictedDemand,
    required this.recommendedReorderQty,
    required this.daysOfSupply,
    required this.urgency,
    required this.modelType,
    required this.alpha,
    required this.horizonDays,
  });

  String get urgencyLabel {
    if (currentStock <= 0) return 'OUT OF STOCK';
    switch (urgency) {
      case UrgencyLevel.critical:
        return 'CRITICAL RUNOUT';
      case UrgencyLevel.reorder:
        return 'REORDER NEEDED';
      case UrgencyLevel.adequate:
      case UrgencyLevel.overstocked:
        return 'IN STOCK';
    }
  }

  Color get urgencyColor {
    if (currentStock <= 0) return const Color(0xFFFFAA00);
    switch (urgency) {
      case UrgencyLevel.critical:
        return const Color(0xFFFF758C);
      case UrgencyLevel.reorder:
        return const Color(0xFFFFAA00);
      case UrgencyLevel.adequate:
      case UrgencyLevel.overstocked:
        return const Color(0xFF43CB89);
    }
  }

  String get modelName {
    switch (modelType) {
      case ForecastModelType.exponentialSmoothing:
        return 'Adaptive Exponential Smoothing (α = ${alpha.toStringAsFixed(2)})';
      case ForecastModelType.simpleMovingAverage:
        return 'Simple Moving Average (SMA)';
    }
  }
}
