import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pos_model.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Order currentOrder = Order(items: []);

  List<POSProduct> _products = [];
  bool _isLoading = true;
  int _orderItemCounter = 0;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? PiggyTrunkTheme.ptBgDark : const Color(0xFFF4F7FB);
  Color get _surface => _isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
  Color get _surfaceSoft => _isDark ? PiggyTrunkTheme.ptSurfaceDark.withValues(alpha: 0.5) : const Color(0xFFF8FBFF);
  Color get _border => _isDark ? PiggyTrunkTheme.ptBorderDark : const Color(0xFFD7E3F3);
  Color get _text => _isDark ? PiggyTrunkTheme.ptTextDark : const Color(0xFF18314F);
  Color get _muted => _isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xFF6F8096);

  @override
  void initState() {
    super.initState();
    _loadProductsFromInventory();
  }

  Future<void> _loadProductsFromInventory() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('inventory_products')
          .select()
          .eq('is_archived', false)
          .order('created_at', ascending: false);

      final rows = (response as List)
          .map((row) => POSProduct.fromJson(row as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() => _products = rows);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load POS products: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get _categories {
    final categorySet = _products.map((p) => p.category.trim()).where((c) => c.isNotEmpty).toSet();
    final sorted = categorySet.toList()..sort();
    return sorted;
  }

  List<POSProduct> _productsByCategory(String category) {
    return _products.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
  }

  void _clearOrder() {
    if (currentOrder.items.isEmpty) return;
    setState(() {
      currentOrder.clearOrder();
      _orderItemCounter = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order cleared.')),
    );
  }

  void _completeTransaction() {
    if (currentOrder.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items in the order yet.')),
      );
      return;
    }

    final itemCount = currentOrder.totalItems;
    final total = currentOrder.total;

    setState(() {
      currentOrder.clearOrder();
      _orderItemCounter = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction completed: $itemCount item(s), PHP ${total.toStringAsFixed(2)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(

        children: [
          AdminSidebar(
            currentRoute: '/pos',
            onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
          ),
          Expanded(
            child: Column(
              children: [
                const ScreenTopBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 1200;

                            if (isNarrow) {
                              return SingleChildScrollView(
                                child: Column(

                                  children: [
                                    _buildProductsPanel(const EdgeInsets.fromLTRB(16, 16, 16, 12)),
                                    SizedBox(
                                      height: 500,
                                      child: _buildCurrentOrderPanel(context, stacked: true),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildProductsPanel(const EdgeInsets.fromLTRB(16, 16, 16, 16)),
                                ),
                                Container(width: 1, color: _border),
                                Expanded(flex: 1, child: _buildCurrentOrderPanel(context)),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsPanel(EdgeInsets padding) {
    return SingleChildScrollView(
      padding: padding,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _surfaceSoft,
          border: Border.all(
            color: _border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'POS',
                  style: AppTextStyles.sectionTitle(_text),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAllCategoryProducts(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCategoryProducts() {
    final categories = _categories;

    if (categories.isEmpty) {
      return Text(
        'No available products from Inventory yet.',
        style: AppTextStyles.body(_muted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(categories.length, (index) {
        final category = categories[index];
        final products = _productsByCategory(category);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: AppTextStyles.jakarta(
                size: 16,
                weight: FontWeight.w800,
                letterSpacing: -0.02,
                color: _text,
              ),
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No available products.',
                  style: AppTextStyles.body(_muted),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(products.length, (idx) {
                    return Padding(
                      padding: EdgeInsets.only(right: idx == products.length - 1 ? 0 : 16),
                      child: _buildPOSProductCard(products[idx]),
                    );
                  }),
                ),
              ),
            if (index != categories.length - 1) const SizedBox(height: 48),
          ],
        );
      }),
    );
  }

  Widget _buildPOSProductCard(POSProduct product) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _orderItemCounter++;
            currentOrder.addItem(
              OrderItem(
                id: _orderItemCounter,
                productId: product.id,
                productName: product.name,
                price: product.price,
                quantity: 1,
              ),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} added to order'),
              duration: const Duration(milliseconds: 800),
            ),
          );
        },
        child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _border, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: product.image != null
                  ? Image.network(product.image!, fit: BoxFit.cover)
                  : Icon(
                      Icons.image_not_supported_outlined,
                      color: _muted,
                      size: 48,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PRODUCT NAME: ${product.name}',
                    style: AppTextStyles.jakarta(
                      size: 11,
                      weight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: _muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DESCRIPTION: ${product.description.isEmpty ? 'No description available.' : product.description}',
                    style: AppTextStyles.jakarta(size: 10, weight: FontWeight.w500, color: _muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PRICE',
                        style: AppTextStyles.jakarta(size: 11, weight: FontWeight.w700, color: _muted),
                      ),
                      Text(
                        'PHP ${product.price.toStringAsFixed(2)}',
                        style: AppTextStyles.jakarta(size: 12, weight: FontWeight.w700, color: _text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock:',
                        style: AppTextStyles.jakarta(size: 11, weight: FontWeight.w700, color: _muted),
                      ),
                      Text(
                        '${product.units} units',
                        style: AppTextStyles.jakarta(size: 12, weight: FontWeight.w700, color: _text),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCurrentOrderPanel(BuildContext context, {bool stacked = false}) {
    return Container(
      decoration: BoxDecoration(
        border: stacked
            ? Border(top: BorderSide(color: _border, width: 1))
            : Border(left: BorderSide(color: _border, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current order',
                  style: AppTextStyles.cardTitle(_text),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${currentOrder.totalItems} ITEMS',
                    style: AppTextStyles.jakarta(
                      size: 11,
                      weight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: currentOrder.items.isEmpty
                ? Center(
                    child: Text(
                      'No products added yet.',
                      style: AppTextStyles.caption(PiggyTrunkTheme.ptMutedDark),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: List.generate(
                        currentOrder.items.length,
                        (index) => _buildOrderItemRow(currentOrder.items[index], index),
                      ),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _border, width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: AppTextStyles.caption(PiggyTrunkTheme.ptMutedDark),
                    ),
                    Text(
                      'PHP ${currentOrder.subtotal.toStringAsFixed(2)}',
                      style: AppTextStyles.jakarta(size: 13, weight: FontWeight.w700, color: _text),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyles.bodyStrong(_text),
                    ),
                    Text(
                      'PHP ${currentOrder.total.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyStrong(_text),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight = constraints.maxWidth < 360;

                    if (isTight) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _completeTransaction,
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: Text(
                              'Complete Transaction',
                              style: AppTextStyles.jakarta(
                                size: 14,
                                weight: FontWeight.w700,
                                color: _isDark ? const Color(0xFF0F1C2F) : Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                              foregroundColor: _isDark ? const Color(0xFF0F1C2F) : Colors.white,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _clearOrder,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              side: BorderSide(
                                color: _isDark ? const Color(0xFF7F94B2) : PiggyTrunkTheme.ptPrimary,
                                width: 1,
                              ),
                              foregroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Clear Order',
                              style: AppTextStyles.jakarta(
                                size: 14,
                                weight: FontWeight.w700,
                                color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _completeTransaction,
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: Text(
                              'Complete Transaction',
                              style: AppTextStyles.jakarta(
                                size: 14,
                                weight: FontWeight.w700,
                                color: _isDark ? const Color(0xFF0F1C2F) : Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                              foregroundColor: _isDark ? const Color(0xFF0F1C2F) : Colors.white,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearOrder,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              side: BorderSide(
                                color: _isDark ? const Color(0xFF7F94B2) : PiggyTrunkTheme.ptPrimary,
                                width: 1,
                              ),
                              foregroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Clear Order',
                              style: AppTextStyles.jakarta(
                                size: 14,
                                weight: FontWeight.w700,
                                color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(OrderItem item, int index) {
    return Padding(
      padding: EdgeInsets.only(bottom: index == currentOrder.items.length - 1 ? 0 : 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bg,
          border: Border.all(color: _border, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: AppTextStyles.jakarta(size: 13, weight: FontWeight.w600, color: _text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: _muted),
                  onPressed: () {
                    setState(() {
                      currentOrder.removeItem(item.productId);
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.quantity}x PHP ${item.price.toStringAsFixed(2)}',
                  style: AppTextStyles.jakarta(size: 12, weight: FontWeight.w500, color: _muted),
                ),
                Text(
                  'PHP ${item.subtotal.toStringAsFixed(2)}',
                  style: AppTextStyles.jakarta(size: 13, weight: FontWeight.w700, color: _text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
