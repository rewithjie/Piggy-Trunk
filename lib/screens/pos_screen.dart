import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pos_model.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../utils/inventory_data_adapter.dart';
import '../utils/responsive.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../main.dart';

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
    final session = _supabase.auth.currentSession;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    if (isInitialLaunch) {
      isInitialLaunch = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
      return;
    }
    _loadProductsFromInventory();
  }

  void _showThemedSnackBar(String message, {Color? backgroundColor, Duration? duration}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF315C8F),
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
      ),
    );
  }

  Future<void> _loadProductsFromInventory() async {
    setState(() => _isLoading = true);
    try {
      final response = await _loadInventoryRows();
      final rows = response
          .map((row) => POSProduct.fromJson(row))
          .toList();

      if (!mounted) return;
      setState(() => _products = rows);
    } catch (e) {
      if (!mounted) return;
      _showThemedSnackBar('Failed to load POS products: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadInventoryRows() async {
    try {
      final response = await _supabase
          .from('inventory_products')
          .select()
          .order('created_at', ascending: false);

      final rows = (response as List).where((row) {
        final isArchived = row['is_archived'] == true;
        return !isArchived;
      }).toList();
      return normalizeInventoryRows(rows, sourceTable: 'inventory_products');
    } catch (e) {
      final fallbackResponse = await _supabase.from('products').select();
      final fallbackRows = (fallbackResponse as List).where((row) {
        final isArchived = row['is_archived'] == true;
        return !isArchived;
      }).toList();
      return normalizeInventoryRows(fallbackRows, sourceTable: 'products');
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
    _showThemedSnackBar('Order cleared.', backgroundColor: Colors.orange);
  }

  Future<void> _completeTransaction() async {
    if (currentOrder.items.isEmpty) {
      _showThemedSnackBar('No items in the order yet.', backgroundColor: Colors.red);
      return;
    }

    final itemCount = currentOrder.totalItems;
    final total = currentOrder.total;
    final itemsToDeduct = List<OrderItem>.from(currentOrder.items);

    setState(() {
      _isLoading = true;
    });

    try {
      for (final item in itemsToDeduct) {
        final product = _products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => POSProduct(
            id: item.productId,
            name: item.productName,
            categoryId: '',
            category: '',
            description: '',
            price: item.price,
            units: 0,
            sold: 0,
          ),
        );

        final newUnits = (product.units - item.quantity).clamp(0, 999999);
        final newSold = product.sold + item.quantity;

        try {
          await _supabase.from('inventory_products').update({
            'units': newUnits,
            'sold': newSold,
          }).eq('id', product.id);
        } catch (_) {
          await _supabase.from('products').update({
            'units': newUnits,
            'sold': newSold,
          }).eq('id', product.id);
        }

        try {
          await _supabase.from('inventory_logs').insert({
            'product_id': product.id,
            'product_name': product.name,
            'action': 'UPDATE',
            'performed_by': _supabase.auth.currentUser?.email ?? 'Cashier Admin',
            'price': product.price,
            'units': newUnits,
            'details': 'POS Sale: Sold ${item.quantity} unit(s). Remaining: $newUnits.',
          });
        } catch (_) {}
      }

      setState(() {
        currentOrder.clearOrder();
        _orderItemCounter = 0;
      });

      await _loadProductsFromInventory();

      if (!mounted) return;
      _showThemedSnackBar(
        'Transaction completed! Deducted stock for $itemCount item(s). Total: PHP ${total.toStringAsFixed(2)}',
        backgroundColor: PiggyTrunkTheme.ptSuccess,
      );
    } catch (e) {
      if (!mounted) return;
      _showThemedSnackBar('Error completing transaction: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);

    return Scaffold(
      backgroundColor: _bg,
      drawer: isSmall
          ? Drawer(
              backgroundColor: _surface,
              child: AdminSidebar(
                currentRoute: '/pos',
                onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmall)
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
                                    _buildProductsPanel(EdgeInsets.all(Responsive.isMobile(context) ? 10 : 16)),
                                    Container(
                                      constraints: const BoxConstraints(minHeight: 480),
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
    final isMobile = Responsive.isMobile(context);
    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _surfaceSoft,
          border: Border.all(
            color: _border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
        ),
        padding: EdgeInsets.all(isMobile ? 12 : 24),
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
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: AppTextStyles.jakarta(
                    size: 18,
                    weight: FontWeight.w800,
                    letterSpacing: -0.02,
                    color: _text,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${products.length})',
                  style: AppTextStyles.jakarta(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No available products.',
                  style: AppTextStyles.body(_muted),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final isNarrow = constraints.maxWidth <= 700;
                  final crossAxisCount = isWide ? 2 : 1;
                  final childAspectRatio = isWide ? 2.3 : 2.0;

                  if (isNarrow) {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, idx) => _buildPOSProductCard(products[idx]),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, idx) => _buildPOSProductCard(products[idx]),
                  );
                },
              ),
            if (index != categories.length - 1) const SizedBox(height: 32),
          ],
        );
      }),
    );
  }

  Widget _buildPOSProductCard(POSProduct product) {
    final isOutOfStock = product.units <= 0;
    final isMobile = Responsive.isMobile(context);
    final double imgSize = isMobile ? 95.0 : 135.0;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Square Product Image (1:1 Ratio)
          Container(
            width: imgSize,
            height: imgSize,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border.withValues(alpha: 0.8)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: product.image != null && product.image!.isNotEmpty
                  ? Image.network(
                      product.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.broken_image_outlined, color: _muted, size: 28),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image_outlined, color: _muted, size: 28),
                    ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          // Right Column: Product Details & Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Title + Stock Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: AppTextStyles.jakarta(
                          size: isMobile ? 13 : 14,
                          weight: FontWeight.w800,
                          color: _text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 3 : 4),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Colors.red.withValues(alpha: 0.18)
                            : (product.units <= 5
                                ? Colors.orange.withValues(alpha: 0.18)
                                : const Color(0x3343CB89)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOutOfStock
                            ? 'OUT OF STOCK'
                            : (product.units <= 5 ? 'LOW STOCK' : 'IN STOCK'),
                        style: AppTextStyles.jakarta(
                          size: isMobile ? 9 : 10,
                          weight: FontWeight.w800,
                          color: isOutOfStock
                              ? Colors.redAccent
                              : (product.units <= 5 ? Colors.orangeAccent : const Color(0xFF43CB89)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Description
                Text(
                  product.description.isEmpty ? 'No description' : product.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.jakarta(
                    size: isMobile ? 11 : 12,
                    weight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
                SizedBox(height: isMobile ? 5 : 6),
                // Price & Stock Row
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 5 : 6),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('PRICE:', style: AppTextStyles.jakarta(size: 10, weight: FontWeight.w700, color: _muted)),
                                Text('₱${product.price.toStringAsFixed(2)}', style: AppTextStyles.jakarta(size: 12, weight: FontWeight.w800, color: _text)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Stock:', style: AppTextStyles.jakarta(size: 10, weight: FontWeight.w700, color: _muted)),
                                Text('${product.units} units', style: AppTextStyles.jakarta(size: 12, weight: FontWeight.w700, color: _text)),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'PRICE: ',
                                  style: AppTextStyles.jakarta(size: 11, weight: FontWeight.w700, color: _muted),
                                ),
                                Text(
                                  '₱${product.price.toStringAsFixed(2)}',
                                  style: AppTextStyles.jakarta(size: 13, weight: FontWeight.w800, color: _text),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'Stock: ',
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
                SizedBox(height: isMobile ? 6 : 8),
                // Action Button: Add to Cart
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isOutOfStock
                        ? null
                        : () {
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
                            _showThemedSnackBar(
                              '${product.name} added to order',
                              backgroundColor: const Color(0xFF315C8F),
                              duration: const Duration(milliseconds: 800),
                            );
                          },
                    icon: const Icon(Icons.add_shopping_cart, size: 14),
                    label: Text(
                      isOutOfStock ? 'Out of Stock' : '+ Add to Order',
                      style: AppTextStyles.jakarta(
                        size: 12,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOutOfStock ? Colors.grey : PiggyTrunkTheme.ptPrimary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentOrderPanel(BuildContext context, {bool stacked = false}) {
    final isMobile = Responsive.isMobile(context);

    Widget orderItemsContent;
    if (currentOrder.items.isEmpty) {
      orderItemsContent = Padding(
        padding: EdgeInsets.symmetric(vertical: stacked ? 32 : 60, horizontal: 16),
        child: Center(
          child: Text(
            'No products added yet.',
            style: AppTextStyles.caption(PiggyTrunkTheme.ptMutedDark),
          ),
        ),
      );
    } else {
      orderItemsContent = Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          children: List.generate(
            currentOrder.items.length,
            (index) => _buildOrderItemRow(currentOrder.items[index], index),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: stacked
            ? Border(top: BorderSide(color: _border, width: 1))
            : Border(left: BorderSide(color: _border, width: 1)),
      ),
      child: Column(
        mainAxisSize: stacked ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          if (stacked)
            orderItemsContent
          else
            Expanded(
              child: SingleChildScrollView(
                child: orderItemsContent,
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
