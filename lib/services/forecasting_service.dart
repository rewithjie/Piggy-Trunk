import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/forecasting_model.dart';
import '../models/product_model.dart';
import '../models/pos_sale_model.dart';

class ForecastingService {
  final SupabaseClient _supabase;

  ForecastingService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Loads all active products, historical sales records, and computes forecasts
  /// for each product based on the chosen model and horizon.
  Future<List<ProductForecast>> calculateForecasts({
    ForecastModelType modelType = ForecastModelType.exponentialSmoothing,
    double alpha = 0.3,
    int horizonDays = 7,
    int lookbackDays = 30,
    String? categoryFilter,
    String? searchQuery,
  }) async {
    // 1. Fetch active products
    final products = await _fetchProducts();

    // 2. Fetch actual historical sales from pos_sales AND distributions from inventory_logs
    final salesList = await _fetchSales(lookbackDays);

    // 3. Group actual sales & distributions by product ID and product Name
    final Map<String, List<POSSale>> salesByProductId = {};
    final Map<String, List<POSSale>> salesByProductName = {};
    for (final sale in salesList) {
      if (sale.productId.isNotEmpty) {
        salesByProductId.putIfAbsent(sale.productId, () => []).add(sale);
      }
      if (sale.productName.isNotEmpty) {
        salesByProductName
            .putIfAbsent(sale.productName.trim().toLowerCase(), () => [])
            .add(sale);
      }
    }

    final DateTime today = DateTime.now();
    final DateTime startDate = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: lookbackDays - 1));

    final List<ProductForecast> forecasts = [];

    for (final product in products) {
      if (categoryFilter != null &&
          categoryFilter != 'All' &&
          product.category.toLowerCase() != categoryFilter.toLowerCase()) {
        continue;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchName = product.name.toLowerCase().contains(query);
        final matchCat = product.category.toLowerCase().contains(query);
        if (!matchName && !matchCat) continue;
      }

      // Collect actual sales and raiser distributions for this product
      final prodSalesById = salesByProductId[product.id] ?? [];
      final prodSalesByName =
          salesByProductName[product.name.trim().toLowerCase()] ?? [];

      final Set<String> seenSaleIds = {};
      final List<POSSale> prodSales = [];
      for (final s in [...prodSalesById, ...prodSalesByName]) {
        if (seenSaleIds.add(s.id)) {
          prodSales.add(s);
        }
      }

      // Build daily sales series for all lookbackDays (including 0-sale days)
      final List<DailySalesPoint> dailyHistory = [];
      final Map<String, int> dailyQtyMap = {};
      final Map<String, double> dailyRevMap = {};

      for (final sale in prodSales) {
        final key = _formatDateKey(sale.saleDate);
        dailyQtyMap[key] = (dailyQtyMap[key] ?? 0) + sale.quantity;
        dailyRevMap[key] = (dailyRevMap[key] ?? 0.0) + sale.totalAmount;
      }

      int totalUnitsSold = 0;
      double averageDailySales = 0.0;
      for (int i = 0; i < lookbackDays; i++) {
        final d = startDate.add(Duration(days: i));
        final key = _formatDateKey(d);
        final qty = dailyQtyMap[key] ?? 0;
        final rev = dailyRevMap[key] ?? 0.0;
        totalUnitsSold += qty;
        dailyHistory.add(DailySalesPoint(date: d, quantity: qty, revenue: rev));
      }

      // STRICTLY ACTUAL DATA:
      // If no pos_sales or distribution logs recorded for this product in lookback period:
      if (totalUnitsSold == 0) {
        if (product.sold > 0) {
          // If the product record itself has actual historical units sold counter, use it
          totalUnitsSold = product.sold;
          averageDailySales = product.sold / lookbackDays.toDouble();
        } else {
          // 100% Actual 0: No sales, no raiser distributions
          totalUnitsSold = 0;
          averageDailySales = 0.0;
        }
      } else {
        averageDailySales = totalUnitsSold / lookbackDays.toDouble();
      }

      // Compute standard deviation of daily sales
      double standardDeviation = 0.0;
      if (averageDailySales > 0) {
        double varianceSum = 0.0;
        for (final pt in dailyHistory) {
          final diff = pt.quantity - averageDailySales;
          varianceSum += diff * diff;
        }
        standardDeviation = sqrt(varianceSum / max(1, lookbackDays));
      }

      // Calculate both SES and SMA velocities for comparison
      final sesVelocity = averageDailySales > 0
          ? _calculateExponentialSmoothing(
              dailyHistory,
              alpha: alpha,
              fallbackAverage: averageDailySales,
            )
          : 0.0;
      final smaVelocity = averageDailySales > 0
          ? _calculateSimpleMovingAverage(
              dailyHistory,
              window: min(14, lookbackDays),
              fallbackAverage: averageDailySales,
            )
          : 0.0;

      final forecastedDailyVelocity = modelType == ForecastModelType.exponentialSmoothing
          ? sesVelocity
          : smaVelocity;

      // Projected demand for the horizon
      final double predictedDemand = max(0.0, forecastedDailyVelocity * horizonDays);
      final double smaPredictedDemand = max(0.0, smaVelocity * horizonDays);

      // Build projected future data points for both SES and SMA
      final List<DailySalesPoint> projectedDailySales = [];
      final List<DailySalesPoint> smaProjectedDailySales = [];
      final random = Random(product.id.hashCode);
      for (int i = 1; i <= horizonDays; i++) {
        final projDate = DateTime(today.year, today.month, today.day).add(Duration(days: i));
        final varianceFactor = 1.0 + ((random.nextDouble() - 0.45) * 0.14);
        final projQty = sesVelocity > 0
            ? max(0, (sesVelocity * varianceFactor).round())
            : 0;
        projectedDailySales.add(DailySalesPoint(
          date: projDate,
          quantity: projQty,
          revenue: projQty * product.price,
          isProjected: true,
        ));

        // SMA projection (flatter curve reflecting lagging average)
        final smaQty = smaVelocity > 0 ? max(0, smaVelocity.round()) : 0;
        smaProjectedDailySales.add(DailySalesPoint(
          date: projDate,
          quantity: smaQty,
          revenue: smaQty * product.price,
          isProjected: true,
        ));
      }

      // Inventory Reorder Planning Formula:
      final int leadTimeDays = 3;
      final double leadTimeDemand = forecastedDailyVelocity * leadTimeDays;

      // Safety stock only if there is real sales velocity
      final int calculatedSafetyStock = forecastedDailyVelocity > 0
          ? max(0, (1.65 * standardDeviation * sqrt(leadTimeDays)).round())
          : 0;

      // Reorder Point (ROP) = Lead Time Demand + Safety Stock
      final int reorderPoint = (leadTimeDemand + calculatedSafetyStock).round();

      // Recommended Reorder Quantity:
      final int suggestedReorderQty = forecastedDailyVelocity > 0
          ? max(
              0,
              ((predictedDemand + calculatedSafetyStock) - product.units).ceil(),
            )
          : 0;

      // Days of supply remaining before stockout
      final double daysOfSupply = forecastedDailyVelocity > 0.001
          ? product.units / forecastedDailyVelocity
          : 999.0;

      // Urgency Level determination for retail feed store
      UrgencyLevel urgency;
      if (forecastedDailyVelocity <= 0.001) {
        urgency = UrgencyLevel.adequate;
      } else if (product.units <= 0 || product.units <= leadTimeDemand || daysOfSupply <= leadTimeDays) {
        urgency = UrgencyLevel.critical;
      } else if (product.units <= reorderPoint) {
        urgency = UrgencyLevel.reorder;
      } else {
        urgency = UrgencyLevel.adequate;
      }

      final int monthlySoldUnits = dailyHistory.fold(0, (sum, pt) => sum + pt.quantity);
      final double monthlyRevenue = dailyHistory.fold(0.0, (sum, pt) => sum + pt.revenue);
      final int computedSoldUnits = monthlySoldUnits > 0
          ? monthlySoldUnits
          : (totalUnitsSold > 0 ? totalUnitsSold : 0);
      final double computedSalesRevenue = monthlyRevenue > 0
          ? monthlyRevenue
          : (computedSoldUnits * product.price);

      forecasts.add(ProductForecast(
        productId: product.id,
        productName: product.name,
        category: product.category,
        imageUrl: product.image,
        currentStock: product.units,
        unitPrice: product.price,
        leadTimeDays: leadTimeDays,
        safetyStock: calculatedSafetyStock,
        reorderPoint: reorderPoint,
        averageDailySales: averageDailySales,
        standardDeviation: standardDeviation,
        historicalDailySales: dailyHistory,
        projectedDailySales: projectedDailySales,
        smaProjectedDailySales: smaProjectedDailySales,
        predictedDemand: predictedDemand,
        smaPredictedDemand: smaPredictedDemand,
        recommendedReorderQty: suggestedReorderQty,
        daysOfSupply: daysOfSupply,
        urgency: urgency,
        modelType: modelType,
        alpha: alpha,
        horizonDays: horizonDays,
        totalSoldUnits: computedSoldUnits,
        totalSalesRevenue: computedSalesRevenue,
      ));
    }

    // Sort: Critical first, then Reorder needed, then highest predicted demand
    forecasts.sort((a, b) {
      final urgencyWeight = {
        UrgencyLevel.critical: 0,
        UrgencyLevel.reorder: 1,
        UrgencyLevel.adequate: 2,
        UrgencyLevel.overstocked: 3,
      };
      final cmp = urgencyWeight[a.urgency]!.compareTo(urgencyWeight[b.urgency]!);
      if (cmp != 0) return cmp;
      return b.predictedDemand.compareTo(a.predictedDemand);
    });

    return forecasts;
  }

  /// Single Exponential Smoothing (SES):
  /// F_{t+1} = \alpha * S_t + (1 - \alpha) * F_t
  double _calculateExponentialSmoothing(
    List<DailySalesPoint> history, {
    required double alpha,
    required double fallbackAverage,
  }) {
    if (history.isEmpty) return fallbackAverage;

    double f = history.first.quantity.toDouble();
    for (int i = 0; i < history.length; i++) {
      final actual = history[i].quantity.toDouble();
      f = (alpha * actual) + ((1.0 - alpha) * f);
    }
    return max(0.0, f);
  }

  /// Simple Moving Average (SMA) over the last `window` days:
  /// ADS = (1 / N) * \sum S_i
  double _calculateSimpleMovingAverage(
    List<DailySalesPoint> history, {
    required int window,
    required double fallbackAverage,
  }) {
    if (history.isEmpty) return fallbackAverage;
    final int count = min(window, history.length);
    final slice = history.sublist(history.length - count);
    final double sum = slice.fold(0.0, (prev, pt) => prev + pt.quantity);
    return max(0.0, sum / count);
  }

  /// Fetch products from inventory_products table
  Future<List<Product>> _fetchProducts() async {
    try {
      final response = await _supabase
          .from('inventory_products')
          .select()
          .eq('is_archived', false)
          .order('name', ascending: true);

      return (response as List).map((row) => Product.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Error fetching products for forecast: $e');
      try {
        final fallback = await _supabase
            .from('products')
            .select()
            .order('product_name', ascending: true);
        return (fallback as List).map((row) => Product(
              id: (row['product_id'] ?? '').toString(),
              name: (row['product_name'] ?? '').toString(),
              categoryId: '',
              category: (row['category'] ?? 'Feeds').toString(),
              image: (row['image'] ?? row['image_url'])?.toString(),
              description: '',
              price: (row['unit_price'] as num?)?.toDouble() ?? 0.0,
              units: (row['current_stock'] as num?)?.toInt() ?? 0,
              sold: 0,
              createdAt: DateTime.now(),
            )).toList();
      } catch (_) {
        return [];
      }
    }
  }

  /// Fetch actual sales from pos_sales AND distributions to hog raisers from inventory_logs
  Future<List<POSSale>> _fetchSales(int lookbackDays) async {
    final DateTime cutoff =
        DateTime.now().subtract(Duration(days: lookbackDays + 2));
    final String cutoffIso = cutoff.toIso8601String();

    final List<POSSale> combinedSales = [];
    final Set<String> seenIdentifiers = {};

    // 1. Fetch actual recorded POS sales
    try {
      final response = await _supabase
          .from('pos_sales')
          .select()
          .gte('sale_date', cutoffIso)
          .order('sale_date', ascending: true);

      final list = (response as List).map((row) => POSSale.fromJson(row)).toList();
      for (final s in list) {
        combinedSales.add(s);
        if (s.id.isNotEmpty) seenIdentifiers.add(s.id);
        if (s.orderId.isNotEmpty) seenIdentifiers.add(s.orderId);
      }
    } catch (e) {
      debugPrint('Notice: pos_sales query returned: $e');
    }

    // 2. Fetch actual sales and distributions to hog raisers from inventory_logs
    try {
      final invLogs = await _supabase
          .from('inventory_logs')
          .select()
          .gte('created_at', cutoffIso)
          .order('created_at', ascending: true);

      for (final raw in (invLogs as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final action = (map['action'] ?? '').toString().toLowerCase();
        final details = (map['details'] ?? '').toString().toLowerCase();
        final logId = (map['id'] ?? '').toString();

        final isDistribution = action == 'distributed' ||
            action == 'distribution' ||
            details.contains('distributed to') ||
            details.contains('hog raiser') ||
            details.contains('distribution');

        final isSale = action == 'sale';

        if (!isDistribution && !isSale) {
          continue;
        }

        // Avoid double-counting if this sale was already captured from pos_sales
        if (isSale && combinedSales.isNotEmpty) {
          if (seenIdentifiers.contains(logId)) continue;
          final orderIdMatch = RegExp(r'ORD-[A-Za-z0-9-]+').firstMatch(details);
          if (orderIdMatch != null && seenIdentifiers.contains(orderIdMatch.group(0))) {
            continue;
          }
        }

        final pid = (map['product_id'] ?? '').toString();
        final pName = (map['product_name'] ?? 'Product').toString();
        final qty = (map['units'] as num?)?.toInt() ?? 1;
        final total = (map['price'] as num?)?.toDouble() ?? 0.0;
        final unitPrice = qty > 0 ? total / qty : total;
        final date = DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now();

        combinedSales.add(POSSale(
          id: logId.isNotEmpty ? logId : 'LOG-${combinedSales.length + 1}',
          orderId: isDistribution ? 'DIST-RAISER' : 'ORD-LOG',
          productId: pid,
          productName: pName,
          category: 'Feeds',
          quantity: qty,
          unitPrice: unitPrice,
          totalAmount: total,
          saleDate: date,
          createdAt: date,
        ));
      }
    } catch (e) {
      debugPrint('Error loading actual sales and distributions from inventory_logs: $e');
    }

    return combinedSales;
  }

  /// Generates sample historical daily sales directly from the Flutter app
  /// to immediately populate pos_sales with 45 days of realistic data.
  Future<int> generateHistoricalDemoData({int daysBack = 45}) async {
    final products = await _fetchProducts();
    if (products.isEmpty) return 0;

    final now = DateTime.now();
    final random = Random(42);
    final List<Map<String, dynamic>> records = [];

    for (final prod in products) {
      // Create 1-3 transactions on ~80% of days
      for (int dayOffset = daysBack; dayOffset >= 1; dayOffset--) {
        final dayDate = now.subtract(Duration(days: dayOffset));

        // Feeds sell more often than medicines
        final isFeeds = prod.category.toLowerCase().contains('feed');
        final sellProbability = isFeeds ? 0.85 : 0.60;
        if (random.nextDouble() > sellProbability) continue;

        final transactionsCount = isFeeds ? (random.nextInt(3) + 1) : 1;
        for (int t = 0; t < transactionsCount; t++) {
          final qty = isFeeds ? (random.nextInt(5) + 1) : (random.nextInt(3) + 1);
          final saleHour = 8 + random.nextInt(9); // 8 AM to 5 PM
          final saleMinute = random.nextInt(60);
          final saleTime = DateTime(
            dayDate.year,
            dayDate.month,
            dayDate.day,
            saleHour,
            saleMinute,
          );

          records.add({
            'order_id': 'ORD-DEMO-${10000 + random.nextInt(90000)}',
            'product_id': prod.id,
            'product_name': prod.name,
            'category': prod.category,
            'quantity': qty,
            'unit_price': prod.price,
            'total_amount': prod.price * qty,
            'sale_date': saleTime.toIso8601String(),
            'customer_name': random.nextDouble() > 0.4 ? 'Walk-in Customer' : 'Local Hog Raiser',
            'customer_type': random.nextDouble() > 0.4 ? 'Walk-in' : 'Hog Raiser',
            'payment_method': random.nextDouble() > 0.3 ? 'Cash' : 'GCash',
            'cashier_name': 'POS System',
            'created_at': saleTime.toIso8601String(),
          });
        }
      }
    }

    if (records.isEmpty) return 0;

    // Batch insert into pos_sales in chunks of 50
    int insertedTotal = 0;
    const chunkSize = 50;
    for (int i = 0; i < records.length; i += chunkSize) {
      final end = min(i + chunkSize, records.length);
      final chunk = records.sublist(i, end);
      try {
        await _supabase.from('pos_sales').insert(chunk);
        insertedTotal += chunk.length;
      } catch (e) {
        debugPrint('Demo data chunk insert fallback: $e');
      }
    }

    return insertedTotal;
  }

  String _formatDateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
