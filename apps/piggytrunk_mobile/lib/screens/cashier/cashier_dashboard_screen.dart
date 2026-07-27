import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:piggytrunk/models/pos_model.dart';
import 'package:piggytrunk/utils/inventory_data_adapter.dart';
import 'package:image_picker/image_picker.dart';

import 'tabs/cashier_home_tab.dart';
import 'tabs/cashier_requests_tab.dart';
import 'tabs/cashier_inventory_tab.dart';
import 'tabs/cashier_pos_tab.dart';
import 'tabs/cashier_profile_tab.dart';
import 'widgets/stock_requests_modal.dart';
import 'widgets/cashier_notification_bell.dart';

class CashierDashboardScreen extends StatefulWidget {
  const CashierDashboardScreen({super.key});

  @override
  State<CashierDashboardScreen> createState() => _CashierDashboardScreenState();
}

class _CashierDashboardScreenState extends State<CashierDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  int _currentIndex = 0;
  bool _isLoading = false;

  // Realtime & Auto-Refresh State
  RealtimeChannel? _requestsChannel;
  Timer? _refreshTimer;

  // Profile State
  String _cashierName = "Cashier Staff";
  String _cashierEmail = "";
  String _cashierPhone = "N/A";
  String _cashierAddress = "N/A";
  String? _cashierAvatarUrl;
  static const Color _brandColor = Color(0xFF18314F);

  // Real Database Data
  List<POSProduct> _allProducts = [];
  List<POSProduct> _lowStockProducts = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  int _selectedInventoryTab = 0; // 0 = Fattening, 1 = Sow

  // Restock Screen State
  POSProduct? _selectedRestockProduct;
  int _restockQuantity = 1;
  final TextEditingController _priceController = TextEditingController();

  // Sales History State
  bool _showSalesHistory = false;
  List<Map<String, dynamic>> _salesLogs = [];
  bool _isLoadingSales = false;

  // POS Cart State
  final Order _currentOrder = Order(items: []);
  int _orderItemCounter = 0;

  // Search & Filter State
  String _selectedCategory = "All";
  final List<String> _categories = ["All", "Feeds", "Vitamins", "Medicines", "Others"];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _subscribeToStockRequests();
    // Auto-refresh every 10 seconds for real-time safety
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _fetchPendingRequests();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _requestsChannel?.unsubscribe();
    _priceController.dispose();
    super.dispose();
  }

  void _subscribeToStockRequests() {
    try {
      _requestsChannel = _supabase
          .channel('public:stock_requests')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'stock_requests',
            callback: (payload) {
              if (mounted) {
                _fetchPendingRequests();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error subscribing to stock_requests channel: $e');
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _fetchProfile();
    await _fetchInventory();
    await _fetchPendingRequests();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _cashierEmail = user.email ?? "";
        Map<String, dynamic>? profile = await _supabase
            .from('app_users')
            .select('user_id, name, email, phone, address, avatar_url')
            .eq('supabase_user_id', user.id)
            .maybeSingle();

        if (profile == null && user.email != null && user.email!.isNotEmpty) {
          final profileByEmail = await _supabase
              .from('app_users')
              .select('user_id, name, email, phone, address, avatar_url')
              .eq('email', user.email!)
              .maybeSingle();

          if (profileByEmail != null) {
            profile = profileByEmail;
            try {
              await _supabase
                  .from('app_users')
                  .update({'supabase_user_id': user.id})
                  .eq('user_id', profileByEmail['user_id']);
            } catch (e) {
              debugPrint('Error linking supabase_user_id: $e');
            }
          }
        }

        String resolvedName = "";
        if (profile != null) {
          final rawName = profile['name'] as String?;
          if (rawName != null && rawName.trim().isNotEmpty) {
            resolvedName = rawName.trim();
          }
        }

        if (resolvedName.isEmpty) {
          final metaName = (user.userMetadata?['name'] as String?) ??
              (user.userMetadata?['full_name'] as String?);
          if (metaName != null && metaName.trim().isNotEmpty) {
            resolvedName = metaName.trim();
          } else if (user.email != null && user.email!.contains('@')) {
            final prefix = user.email!.split('@').first.trim();
            if (prefix.isNotEmpty) {
              resolvedName = prefix[0].toUpperCase() + prefix.substring(1);
            }
          }
        }

        if (resolvedName.isEmpty) {
          resolvedName = "Cashier Staff";
        }

        if (mounted) {
          setState(() {
            _cashierName = resolvedName;
            if (profile != null) {
              _cashierEmail = (profile['email'] as String?) ?? user.email ?? "";
              _cashierPhone = (profile['phone'] as String?) ?? "N/A";
              _cashierAddress = (profile['address'] as String?) ?? "N/A";
              _cashierAvatarUrl = profile['avatar_url'] as String?;
            } else {
              _cashierEmail = user.email ?? "";
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _fetchInventory() async {
    try {
      final response = await _supabase
          .from('inventory_products')
          .select()
          .eq('is_archived', false)
          .order('name', ascending: true);

      final rows = response as List;
      final normalized = normalizeInventoryRows(rows, sourceTable: 'inventory_products');
      final productsList = normalized.map((r) => POSProduct.fromJson(r)).toList();

      if (mounted) {
        setState(() {
          _allProducts = productsList;
          _lowStockProducts = productsList.where((p) => p.units < 50).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading inventory products: $e');
      try {
        final fallbackResponse = await _supabase.from('products').select();
        final fallbackRows = fallbackResponse as List;
        final fallbackNormalized = normalizeInventoryRows(fallbackRows, sourceTable: 'products');
        final fallbackList = fallbackNormalized.map((r) => POSProduct.fromJson(r)).toList();
        if (mounted) {
          setState(() {
            _allProducts = fallbackList;
            _lowStockProducts = fallbackList.where((p) => p.units < 50).toList();
          });
        }
      } catch (err) {
        debugPrint('Fallback error: $err');
      }
    }
  }

  Future<void> _fetchPendingRequests() async {
    try {
      final requests = await _supabase
          .from('stock_requests')
          .select('request_id, status, quantity, created_at, product:products(name), raiser:hog_raisers(name)')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _pendingRequests = List<Map<String, dynamic>>.from(requests);
        });
      }
    } catch (e) {
      debugPrint('Error fetching stock requests: $e');
    }
  }

  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
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
        backgroundColor: backgroundColor ?? const Color(0xFF18314F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Profile Management Methods
  Future<void> _pickAndUploadAvatar() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final bytes = await image.readAsBytes();
      final fileName = 'avatar-cashier-${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = 'avatars/$fileName';

      await _supabase.storage.from('profile_pictures').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = _supabase.storage.from('profile_pictures').getPublicUrl(filePath);

      await _supabase.from('app_users').update({
        'avatar_url': publicUrl,
      }).eq('supabase_user_id', user.id);

      _showSnackBar('Matagumpay na na-update ang inyong profile picture!', backgroundColor: PiggyTrunkTheme.ptSuccess);
      await _fetchProfile();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      _showSnackBar('Error uploading image: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreDefaultAvatar() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await _supabase.from('app_users').update({
        'avatar_url': null,
      }).eq('supabase_user_id', user.id);

      _showSnackBar('Nabalik sa default ang inyong profile picture!', backgroundColor: PiggyTrunkTheme.ptSuccess);
      await _fetchProfile();
    } catch (e) {
      debugPrint('Error restoring image: $e');
      _showSnackBar('Error restoring image: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _cashierName);
    final phoneController = TextEditingController(text: _cashierPhone == 'N/A' ? '' : _cashierPhone);
    final addressController = TextEditingController(text: _cashierAddress == 'N/A' ? '' : _cashierAddress);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'I-edit ang Profile',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: _brandColor,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pangalan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _brandColor),
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang inyong pangalan',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: PiggyTrunkTheme.ptMuted),
                    fillColor: const Color(0xfff7f8fb),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Telepono / Phone Number',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _brandColor),
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang inyong numero',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: PiggyTrunkTheme.ptMuted),
                    fillColor: const Color(0xfff7f8fb),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Address / Branch',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _brandColor),
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang inyong address o branch',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: PiggyTrunkTheme.ptMuted),
                    fillColor: const Color(0xfff7f8fb),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Kanselahin',
                style: GoogleFonts.plusJakartaSans(
                  color: PiggyTrunkTheme.ptMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateProfile(
                  nameController.text.trim(),
                  phoneController.text.trim(),
                  addressController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'I-save',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile(String name, String phone, String address) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _supabase.from('app_users').update({
        'name': name.isNotEmpty ? name : _cashierName,
        'phone': phone.isNotEmpty ? phone : null,
        'address': address.isNotEmpty ? address : null,
      }).eq('supabase_user_id', user.id);

      _showSnackBar('Matagumpay na na-update ang inyong profile!', backgroundColor: PiggyTrunkTheme.ptSuccess);
      await _fetchProfile();
    } catch (e) {
      _showSnackBar('Pumalya ang pag-update: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // POS - Add product to order cart
  void _addToCart(POSProduct product) {
    if (product.units <= 0) {
      _showSnackBar('Pasensya na, wala nang stock ang item na ito.', backgroundColor: Colors.red);
      return;
    }

    final existingIndex = _currentOrder.items.indexWhere((i) => i.productId == product.id);
    if (existingIndex != -1) {
      final currentQty = _currentOrder.items[existingIndex].quantity;
      if (currentQty >= product.units) {
        _showSnackBar('Hindi maaaring lumampas sa ${product.units} units na stock.', backgroundColor: Colors.amber[800]);
        return;
      }
    }

    setState(() {
      _orderItemCounter++;
      _currentOrder.addItem(
        OrderItem(
          id: _orderItemCounter,
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: 1,
        ),
      );
    });
    _showSnackBar('${product.name} naidagdag sa cart!', backgroundColor: PiggyTrunkTheme.ptSuccess);
  }

  // POS - Complete supply release / purchase
  Future<void> _completeTransaction() async {
    if (_currentOrder.items.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Hindi naka-login ang user.");

      final userProfile = await _supabase
          .from('app_users')
          .select('user_id')
          .eq('supabase_user_id', user.id)
          .maybeSingle();

      final performerId = userProfile != null ? userProfile['user_id'] as int : null;

      for (final item in _currentOrder.items) {
        final dbProduct = _allProducts.firstWhere((p) => p.id == item.productId);
        final newUnits = dbProduct.units - item.quantity;

        await _supabase
            .from('inventory_products')
            .update({'units': newUnits})
            .eq('id', item.productId);

        if (performerId != null) {
          await _supabase.from('sales').insert({
            'quantity': item.quantity,
            'total_amount': item.subtotal,
            'type': 'Release',
            'product_id': int.tryParse(item.productId) ?? 1,
            'performed_by': performerId,
          });
        }
      }

      _showSnackBar('Matagumpay na na-release ang supply!', backgroundColor: PiggyTrunkTheme.ptSuccess);

      setState(() {
        _currentOrder.clearOrder();
        _orderItemCounter = 0;
      });

      await _fetchInventory();
    } catch (e) {
      debugPrint('Checkout error: $e');
      _showSnackBar('Nagka-error sa checkout: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRequestsDialog() {
    StockRequestsModal.show(
      context,
      pendingRequests: _pendingRequests,
      onProcessRequest: _processRequest,
    );
  }

  Future<void> _processRequest(int requestId, String status, {int? allocatedSacks, int? productId}) async {
    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('stock_requests')
          .update({'status': status})
          .eq('request_id', requestId);

      if (status == 'Approved' && allocatedSacks != null && allocatedSacks > 0) {
        if (productId != null && _allProducts.isNotEmpty) {
          final dbProd = _allProducts.firstWhere((p) => p.id.toString() == productId.toString(), orElse: () => _allProducts.first);
          final newUnits = (dbProd.units - allocatedSacks) < 0 ? 0 : (dbProd.units - allocatedSacks);
          try {
            await _supabase.from('inventory_products').update({'units': newUnits}).eq('id', dbProd.id);
          } catch (_) {
            await _supabase.from('products').update({'units': newUnits}).eq('id', dbProd.id);
          }

          try {
            final user = _supabase.auth.currentUser;
            await _supabase.from('inventory_logs').insert({
              'product_id': dbProd.id,
              'product_name': dbProd.name,
              'action': 'ALLOCATION',
              'performed_by': _cashierName.isNotEmpty ? _cashierName : (user?.email ?? 'Cashier Staff'),
              'price': dbProd.price,
              'units': allocatedSacks,
              'details': 'Allocated $allocatedSacks sacks to raiser request #$requestId',
            });
          } catch (e) {
            debugPrint('Error logging allocation: $e');
          }
        }
      }

      _showSnackBar('Request successfully $status!', backgroundColor: PiggyTrunkTheme.ptSuccess);
      await _fetchPendingRequests();
      await _fetchInventory();
    } catch (e) {
      _showSnackBar('Failed to update request: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openRestockScreen(POSProduct product) {
    setState(() {
      _selectedRestockProduct = product;
      _restockQuantity = 2;
      _priceController.text = product.price.toStringAsFixed(2);
    });
  }

  Future<void> _performRestockWithPrice(POSProduct product, int amount, double newPrice) async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      final newUnits = product.units + amount;

      await _supabase
          .from('inventory_products')
          .update({
            'units': newUnits,
            'price': newPrice,
          })
          .eq('id', product.id);

      await _supabase.from('inventory_logs').insert({
        'product_id': product.id,
        'product_name': product.name,
        'action': 'UPDATE',
        'performed_by': user?.email ?? 'Cashier Staff',
        'price': newPrice,
        'units': newUnits,
        'details': 'Restocked $amount bags at new price ₱${newPrice.toStringAsFixed(2)} via Cashier Mobile App',
      });

      _showSnackBar('Matagumpay na na-restock ang ${product.name} (+$amount bags)!', backgroundColor: PiggyTrunkTheme.ptSuccess);

      setState(() {
        _selectedRestockProduct = null;
      });
      await _fetchInventory();
    } catch (e) {
      debugPrint('Error performing restock: $e');
      _showSnackBar('Pumalya ang restock: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openSalesHistory() {
    setState(() {
      _showSalesHistory = true;
    });
    _fetchSalesLogs();
  }

  Future<void> _fetchSalesLogs() async {
    if (!mounted) return;
    setState(() => _isLoadingSales = true);
    try {
      final response = await _supabase
          .from('sales')
          .select('''
            id,
            quantity,
            total_amount,
            type,
            created_at,
            product:inventory_products(
              id,
              name,
              category,
              description,
              image
            )
          ''')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _salesLogs = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching sales logs: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSales = false);
      }
    }
  }

  void _showCartSummarySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PiggyTrunkTheme.ptBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Iyong Order Cart',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF18314F),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _currentOrder.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                  itemBuilder: (context, index) {
                    final item = _currentOrder.items[index];
                    final dbProd = _allProducts.firstWhere((p) => p.id == item.productId);

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF18314F))),
                              const SizedBox(height: 4),
                              Text('₱${item.price.toStringAsFixed(2)} bawat sack', style: const TextStyle(fontSize: 12, color: PiggyTrunkTheme.ptMuted)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  setState(() {
                                    _currentOrder.items[index] = item.copyWith(quantity: item.quantity - 1);
                                  });
                                  setModalState(() {});
                                } else {
                                  setState(() {
                                    _currentOrder.removeItem(item.productId);
                                  });
                                  setModalState(() {});
                                }
                              },
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                if (item.quantity < dbProd.units) {
                                  setState(() {
                                    _currentOrder.items[index] = item.copyWith(quantity: item.quantity + 1);
                                  });
                                  setModalState(() {});
                                } else {
                                  _showSnackBar('Hindi maaaring lumampas sa ${dbProd.units} units na stock.', backgroundColor: Colors.amber[800]);
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: PiggyTrunkTheme.ptBorder)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kabuuang Halaga (Total):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('₱${_currentOrder.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: PiggyTrunkTheme.ptAccent)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _completeTransaction();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF18314F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('I-release ang Supply / I-complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      CashierHomeTab(
        cashierName: _cashierName,
        lowStockProducts: _lowStockProducts,
        pendingRequests: _pendingRequests,
        onNavigateToInventory: () => setState(() => _currentIndex = 2),
        onShowRequestsDialog: () => setState(() => _currentIndex = 1),
      ),
      CashierRequestsTab(
        pendingRequests: _pendingRequests,
        allProducts: _allProducts,
        onProcessRequest: _processRequest,
      ),
      CashierInventoryTab(
        allProducts: _allProducts,
        selectedRestockProduct: _selectedRestockProduct,
        restockQuantity: _restockQuantity,
        priceController: _priceController,
        selectedInventoryTab: _selectedInventoryTab,
        onTabChanged: (tabIndex) => setState(() => _selectedInventoryTab = tabIndex),
        onOpenRestockScreen: _openRestockScreen,
        onQuantityChanged: (qty) => setState(() => _restockQuantity = qty),
        onPerformRestock: _performRestockWithPrice,
      ),
      CashierPOSTab(
        allProducts: _allProducts,
        categories: _categories,
        selectedCategory: _selectedCategory,
        currentOrder: _currentOrder,
        showSalesHistory: _showSalesHistory,
        salesLogs: _salesLogs,
        isLoadingSales: _isLoadingSales,
        onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
        onAddToCart: _addToCart,
        onShowCartSummary: _showCartSummarySheet,
      ),
      CashierProfileTab(
        cashierName: _cashierName,
        cashierEmail: _cashierEmail,
        cashierPhone: _cashierPhone,
        cashierAddress: _cashierAddress,
        cashierAvatarUrl: _cashierAvatarUrl,
        onPickAndUploadAvatar: _pickAndUploadAvatar,
        onRestoreDefaultAvatar: _restoreDefaultAvatar,
        onShowEditProfileDialog: _showEditProfileDialog,
        onHandleLogout: _handleLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: PiggyTrunkTheme.ptBg,
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              leading: (_currentIndex == 2 && _selectedRestockProduct != null)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF18314F)),
                      onPressed: () => setState(() => _selectedRestockProduct = null),
                    )
                  : (_currentIndex == 3 && _showSalesHistory)
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF18314F)),
                          onPressed: () => setState(() => _showSalesHistory = false),
                        )
                      : null,
              title: Text(
                _currentIndex == 1
                    ? 'Requests'
                    : _currentIndex == 2
                        ? (_selectedRestockProduct != null ? 'Restock' : 'Inventory')
                        : _currentIndex == 3
                            ? (_showSalesHistory ? 'New Sale' : 'POS Terminal')
                            : 'Account Profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF18314F),
                ),
              ),
              backgroundColor: PiggyTrunkTheme.ptBg,
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: (_currentIndex == 2 && _selectedRestockProduct != null)
                  ? [
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF18314F)),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                    ]
                  : (_currentIndex == 3
                      ? (_showSalesHistory
                          ? [
                              CashierNotificationBell(
                                pendingRequests: _pendingRequests,
                                onOpenRequestsModal: _showRequestsDialog,
                              ),
                              const SizedBox(width: 8),
                            ]
                          : [
                              CashierNotificationBell(
                                pendingRequests: _pendingRequests,
                                onOpenRequestsModal: _showRequestsDialog,
                              ),
                              IconButton(
                                icon: const Icon(Icons.receipt_long, color: Color(0xFF18314F)),
                                onPressed: _openSalesHistory,
                              ),
                              const SizedBox(width: 8),
                            ])
                      : [
                          CashierNotificationBell(
                            pendingRequests: _pendingRequests,
                            onOpenRequestsModal: _showRequestsDialog,
                          ),
                          const SizedBox(width: 8),
                        ]),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF18314F)))
          : tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() {
            _currentIndex = index;
            if (index != 3) {
              _showSalesHistory = false;
            }
            if (index == 3 || index == 2) {
              _selectedCategory = "All";
            }
          }),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF18314F),
          unselectedItemColor: PiggyTrunkTheme.ptMuted,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _pendingRequests.where((r) => (r['status'] as String? ?? 'Pending').toLowerCase() == 'pending').isNotEmpty
                  ? Badge(
                      label: Text('${_pendingRequests.where((r) => (r['status'] as String? ?? 'Pending').toLowerCase() == 'pending').length}'),
                      child: const Icon(Icons.assignment_outlined),
                    )
                  : const Icon(Icons.assignment_outlined),
              activeIcon: _pendingRequests.where((r) => (r['status'] as String? ?? 'Pending').toLowerCase() == 'pending').isNotEmpty
                  ? Badge(
                      label: Text('${_pendingRequests.where((r) => (r['status'] as String? ?? 'Pending').toLowerCase() == 'pending').length}'),
                      child: const Icon(Icons.assignment),
                    )
                  : const Icon(Icons.assignment),
              label: 'Requests',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventory',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calculate_outlined),
              activeIcon: Icon(Icons.calculate),
              label: 'POS',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
