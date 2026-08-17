import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import '../models/product_model.dart';
import '../models/product_log_model.dart';
import '../theme/app_theme.dart';
import '../utils/inventory_data_adapter.dart';
import '../utils/responsive.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../widgets/slide_over_confirmation_drawer.dart';
import '../main.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const String _table = 'inventory_products';
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Product> _products = [];
  bool _isArchiveMode = false;
  bool _isLoading = true;
  bool _showAddProductForm = false;
  bool _isSubmitting = false;
  Product? _editingProduct;
  String? _productNameError;
  String? _productCategoryError;
  String? _productStockError;
  String? _productPriceError;
  int _activeTab = 0; // 0 = Inventory Products, 1 = Raiser Stock Requests
  List<Map<String, dynamic>> _stockRequests = [];
  bool _isLoadingRequests = false;
  String _requestsFilter = 'All'; // 'All', 'Pending', 'Approved', 'Rejected'
  bool _isProcessingRequest = false;
  bool _hasCheckedArgs = false;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _accentDark => _isDark ? PiggyTrunkTheme.ptAccentDark : PiggyTrunkTheme.ptAccent;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _mutedColor => _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
  Color get _fieldText => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _fieldFocus => _isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController(text: 'Feeds');
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _unitsCtrl = TextEditingController();
  final TextEditingController _imageCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  List<ProductLog> _logs = [];
  bool _isLoadingLogs = false;
  String? _selectedLogFilter; 
  String? _filterProductId;
  String? _filterProductName;
  String? _logsErrorMessage;

  static const List<String> _categoryOptions = <String>[
    'Feeds',
    'Vitamins',
    'Medicines',
    'Others',
  ];

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
    _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'stock_request') {
        setState(() {
          _activeTab = 1;
        });
        _loadStockRequests();
      }
      _hasCheckedArgs = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _unitsCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _resetAddProductForm() {
    _nameCtrl.clear();
    _categoryCtrl.text = 'Feeds';
    _descriptionCtrl.clear();
    _priceCtrl.clear();
    _unitsCtrl.clear();
    _imageCtrl.clear();
    _selectedImageBytes = null;
    _selectedImageName = null;
    _editingProduct = null;
    _productNameError = null;
    _productCategoryError = null;
    _productStockError = null;
    _productPriceError = null;
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _loadInventoryRows();
      final rows = response
          .map((row) => Product.fromJson(row))
          .toList();

      if (!mounted) return;
      setState(() => _products = rows);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load inventory: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadInventoryRows() async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('is_archived', _isArchiveMode)
          .order('created_at', ascending: false);

      final rows = response as List;
      return normalizeInventoryRows(rows, sourceTable: _table);
    } catch (e) {
      final fallbackResponse = await _supabase.from('products').select();
      final fallbackRows = fallbackResponse as List;
      return normalizeInventoryRows(fallbackRows, sourceTable: 'products');
    }
  }

  void _openProductDialog({Product? existing}) {
    if (existing != null) {
      _openEditProductDrawer(existing);
    } else {
      setState(() {
        _resetAddProductForm();
        _showAddProductForm = true;
      });
    }
  }

  void _openEditProductDrawer(Product existing) {
    final nameCtrl = TextEditingController(text: existing.name);
    String selectedCategory = existing.category.isNotEmpty ? existing.category : 'Feeds';
    final unitsCtrl = TextEditingController(text: existing.units.toString());
    final descriptionCtrl = TextEditingController(text: existing.description);
    Uint8List? localImageBytes;
    String? localImageName;
    String? nameError;
    String? stockError;
    bool isSaving = false;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Product Drawer',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogCtx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim1, anim2, child) {
        final curvedValue = Curves.easeOutCubic.transform(anim1.value);
        final screenWidth = MediaQuery.of(dialogCtx).size.width;
        final isMobile = screenWidth < 600;
        final drawerWidth = isMobile ? screenWidth : 440.0;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final drawerBg = isDark ? const Color(0xFF0F172A) : Colors.white;
        final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final fieldBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
        final fieldBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

        return Transform.translate(
          offset: Offset((1.0 - curvedValue) * drawerWidth, 0.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (stfCtx, setDrawerState) {
                  return Container(
                    width: drawerWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: drawerBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                          blurRadius: 24,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF3B82F6),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Edit Product Details',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: titleColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Update photo, stock & details',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                                  splashRadius: 20,
                                  onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                                ),
                              ],
                            ),
                          ),

                          // Scrollable Body
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Photo Section
                                  Text(
                                    'PRODUCT PHOTO',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mutedColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: isSaving
                                        ? null
                                        : () async {
                                            try {
                                              final fileResult = await FilePicker.platform.pickFiles(
                                                type: FileType.custom,
                                                allowMultiple: false,
                                                withData: true,
                                                allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
                                              );
                                              if (fileResult != null && fileResult.files.isNotEmpty) {
                                                final file = fileResult.files.first;
                                                if (file.bytes != null) {
                                                  setDrawerState(() {
                                                    localImageBytes = file.bytes;
                                                    localImageName = file.name;
                                                  });
                                                }
                                              }
                                            } catch (e) {
                                              debugPrint('Pick file error: $e');
                                            }
                                          },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 150,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: fieldBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: fieldBorder),
                                      ),
                                      child: localImageBytes != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(11),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.memory(localImageBytes!, fit: BoxFit.cover),
                                                  Positioned(
                                                    right: 8,
                                                    top: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withValues(alpha: 0.65),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        'Change',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : (existing.image != null && existing.image!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(11),
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      Image.network(
                                                        existing.image!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) => Center(
                                                          child: Icon(Icons.broken_image_outlined, color: mutedColor, size: 32),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        right: 8,
                                                        top: 8,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.black.withValues(alpha: 0.65),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            'Change',
                                                            style: GoogleFonts.plusJakartaSans(
                                                              color: Colors.white,
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.add_photo_alternate_outlined, color: mutedColor, size: 36),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Upload Product Image',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          color: mutedColor,
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Product Name
                                  Text(
                                    'PRODUCT NAME *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mutedColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: nameCtrl,
                                    onChanged: (_) {
                                      if (nameError != null) setDrawerState(() => nameError = null);
                                    },
                                    style: GoogleFonts.plusJakartaSans(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      hintText: 'e.g., Premium Hog Feed',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: mutedColor, fontSize: 14),
                                      prefixIcon: Icon(Icons.inventory_2_outlined, size: 18, color: mutedColor),
                                      filled: true,
                                      fillColor: fieldBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: nameError != null ? const Color(0xFFE53E3E) : fieldBorder,
                                          width: nameError != null ? 1.5 : 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: nameError != null ? const Color(0xFFE53E3E) : const Color(0xFF2563EB),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (nameError != null) _buildInlineError(nameError!),
                                  const SizedBox(height: 16),

                                  // Category & Stock Row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Category
                                      Expanded(
                                        flex: 6,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'CATEGORY *',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: mutedColor,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              initialValue: _categoryOptions.contains(selectedCategory) ? selectedCategory : 'Feeds',
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: fieldBg,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(color: fieldBorder),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                                ),
                                              ),
                                              dropdownColor: fieldBg,
                                              borderRadius: BorderRadius.circular(12),
                                              style: GoogleFonts.plusJakartaSans(
                                                color: titleColor,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: mutedColor),
                                              items: _categoryOptions.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                                              onChanged: (val) {
                                                if (val != null) setDrawerState(() => selectedCategory = val);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Stock
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'STOCK *',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: mutedColor,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: unitsCtrl,
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                              onChanged: (_) {
                                                if (stockError != null) setDrawerState(() => stockError = null);
                                              },
                                              style: GoogleFonts.plusJakartaSans(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600),
                                              decoration: InputDecoration(
                                                hintText: '0',
                                                hintStyle: GoogleFonts.plusJakartaSans(color: mutedColor, fontSize: 14),
                                                filled: true,
                                                fillColor: fieldBg,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: stockError != null ? const Color(0xFFE53E3E) : fieldBorder,
                                                    width: stockError != null ? 1.5 : 1,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: stockError != null ? const Color(0xFFE53E3E) : const Color(0xFF2563EB),
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (stockError != null) _buildInlineError(stockError!),
                                  const SizedBox(height: 16),

                                  // Price (PHP) Locked
                                  Text(
                                    'PRICE (PHP) (Locked)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mutedColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: TextEditingController(text: existing.price.toStringAsFixed(2)),
                                    enabled: false,
                                    style: GoogleFonts.plusJakartaSans(color: mutedColor, fontSize: 14, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      prefixText: '₱ ',
                                      prefixStyle: GoogleFonts.plusJakartaSans(color: mutedColor, fontSize: 14, fontWeight: FontWeight.bold),
                                      filled: true,
                                      fillColor: fieldBg.withAlpha(120),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: fieldBorder.withAlpha(100)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Price is locked after initial product creation.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.orangeAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Description
                                  Text(
                                    'DESCRIPTION',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mutedColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: descriptionCtrl,
                                    maxLines: 3,
                                    style: GoogleFonts.plusJakartaSans(color: titleColor, fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: 'Add product details, usage instructions, or benefits...',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: mutedColor, fontSize: 14),
                                      filled: true,
                                      fillColor: fieldBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: fieldBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Docked Footer
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: drawerBg,
                              border: Border(top: BorderSide(color: borderColor, width: 1)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide(color: fieldBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: titleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: isSaving
                                        ? null
                                        : () async {
                                            final name = nameCtrl.text.trim();
                                            final units = int.tryParse(unitsCtrl.text.trim());
                                            if (name.isEmpty) {
                                              setDrawerState(() => nameError = 'Product name is required.');
                                              return;
                                            }
                                            if (units == null || units < 0) {
                                              setDrawerState(() => stockError = 'Please enter valid stock units.');
                                              return;
                                            }

                                            setDrawerState(() {
                                              nameError = null;
                                              stockError = null;
                                              isSaving = true;
                                            });

                                            try {
                                              String? imageUrl = existing.image;
                                              if (localImageBytes != null && localImageName != null) {
                                                imageUrl = await _uploadProductImage(localImageBytes!, localImageName!);
                                              }

                                              final payload = {
                                                'name': name,
                                                'category_id': selectedCategory.toLowerCase().replaceAll(' ', '_'),
                                                'category': selectedCategory,
                                                'description': descriptionCtrl.text.trim(),
                                                'units': units,
                                                'image': imageUrl,
                                              };

                                              await _supabase.from(_table).update(payload).eq('id', existing.id);

                                              List<String> changes = [];
                                              if (existing.name != name) changes.add('Name: "${existing.name}" -> "$name"');
                                              if (existing.category != selectedCategory) changes.add('Category: "${existing.category}" -> "$selectedCategory"');
                                              if (existing.units != units) changes.add('Stock: ${existing.units} -> $units');
                                              if (existing.description != descriptionCtrl.text.trim()) changes.add('Description updated');

                                              final detailsStr = changes.isEmpty ? 'No field changes' : changes.join(', ');

                                              await _insertProductLog(
                                                productId: existing.id,
                                                productName: name,
                                                action: 'UPDATE',
                                                price: existing.price,
                                                units: units,
                                                details: detailsStr,
                                              );

                                              if (!dialogCtx.mounted) return;
                                              Navigator.of(dialogCtx).pop();
                                              await _loadProducts();

                                              _showThemedSnackBar(
                                                'Product "$name" updated successfully.',
                                                backgroundColor: PiggyTrunkTheme.ptSuccess,
                                              );
                                            } catch (e) {
                                              setDrawerState(() {
                                                isSaving = false;
                                                nameError = 'Failed to update product: $e';
                                              });
                                            }
                                          },
                                    icon: isSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.check_rounded, size: 18),
                                    label: Text(
                                      isSaving ? 'Saving...' : 'Save Changes',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitAddProduct() async {
    if (_isSubmitting) return;
    final name = _nameCtrl.text.trim();
    final category = _categoryCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final image = _imageCtrl.text.trim();
    final priceInt = int.tryParse(_priceCtrl.text.trim());
    final units = int.tryParse(_unitsCtrl.text.trim());

    String? nameErr;
    String? categoryErr;
    String? priceErr;
    String? stockErr;

    if (name.isEmpty) {
      nameErr = 'Product name is required.';
    }
    if (category.isEmpty) {
      categoryErr = 'Please select a category.';
    }
    if (units == null) {
      stockErr = 'Please enter stock quantity.';
    } else if (units < 0) {
      stockErr = 'Stock cannot be negative.';
    }
    if (priceInt == null) {
      priceErr = 'Please enter product price.';
    } else if (priceInt <= 0) {
      priceErr = 'Price must be greater than 0.';
    }

    if (nameErr != null || categoryErr != null || priceErr != null || stockErr != null) {
      setState(() {
        _productNameError = nameErr;
        _productCategoryError = categoryErr;
        _productPriceError = priceErr;
        _productStockError = stockErr;
      });
      return;
    }

    final validatedPrice = priceInt!;
    final validatedUnits = units!;

    setState(() {
      _productNameError = null;
      _productCategoryError = null;
      _productPriceError = null;
      _productStockError = null;
      _isSubmitting = true;
    });
    try {
      String? imageUrl = image.isEmpty ? null : image;
      if (_selectedImageBytes != null && _selectedImageName != null) {
        imageUrl = await _uploadProductImage(_selectedImageBytes!, _selectedImageName!);
      } else if (_editingProduct != null) {
        imageUrl = _editingProduct!.image;
      }

      final payload = {
        'name': name,
        'category_id': category.toLowerCase().replaceAll(' ', '_'),
        'category': category,
        'description': description,
        'price': validatedPrice.toDouble(),
        'units': validatedUnits,
        'image': imageUrl,
      };

      if (_editingProduct != null) {
        await _supabase.from(_table).update(payload).eq('id', _editingProduct!.id);
        
        List<String> changes = [];
        if (_editingProduct!.name != name) changes.add('Name: "${_editingProduct!.name}" -> "$name"');
        if (_editingProduct!.category != category) changes.add('Category: "${_editingProduct!.category}" -> "$category"');
        if (_editingProduct!.price != validatedPrice.toDouble()) changes.add('Price: ₱${_editingProduct!.price.toInt()} -> ₱$validatedPrice');
        if (_editingProduct!.units != validatedUnits) changes.add('Stock: ${_editingProduct!.units} -> $validatedUnits');
        if (_editingProduct!.description != description) changes.add('Description updated');
        
        final detailsStr = changes.isEmpty ? 'No field changes' : changes.join(', ');
        
        await _insertProductLog(
          productId: _editingProduct!.id,
          productName: name,
          action: 'UPDATE',
          price: validatedPrice.toDouble(),
          units: validatedUnits,
          details: detailsStr,
        );
      } else {
        payload['sold'] = 0;
        payload['is_archived'] = false;
        final inserted = await _supabase.from(_table).insert(payload).select().single();
        final insertedId = inserted['id']?.toString();
        
        await _insertProductLog(
          productId: insertedId,
          productName: name,
          action: 'ADD',
          price: validatedPrice.toDouble(),
          units: validatedUnits,
          details: 'Initial stock of $validatedUnits units at ₱$validatedPrice.00',
        );
      }

      if (!mounted) return;
      final wasEditing = _editingProduct != null;
      _resetAddProductForm();
      setState(() => _showAddProductForm = false);
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEditing ? 'Product updated successfully.' : 'Product added successfully.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingProduct != null ? 'Update failed: $e' : 'Create failed: $e',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickProductImage() async {
    try {
      final fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );

      if (fileResult != null && fileResult.files.isNotEmpty) {
        final file = fileResult.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          if (!mounted) return;
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = file.name;
          });
          return;
        }
      }

      // Fallback for environments where file_picker may not return bytes.
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (picked == null) return;
      final fallbackBytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = fallbackBytes;
        _selectedImageName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open image picker: $e',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _uploadProductImage(Uint8List bytes, String fileName) async {
    const bucket = 'product-images';
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'inventory/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    try {
      await _supabase.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Bucket not found')) {
        throw 'Supabase storage bucket "product-images" is missing. Please create a public storage bucket named "product-images" in your Supabase dashboard.';
      }
      rethrow;
    }
  }

  void _openRestockDialog({Product? initialProduct}) {
    if (_products.isEmpty) {
      _showThemedSnackBar(
        'No products available in inventory to restock.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    Product selectedProduct = initialProduct != null && _products.any((p) => p.id == initialProduct.id)
        ? _products.firstWhere((p) => p.id == initialProduct.id)
        : _products.first;

    final isSpecificProduct = initialProduct != null;
    final quantityCtrl = TextEditingController();
    bool isSubmittingRestock = false;
    String? restockError;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Restock Drawer',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogCtx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim1, anim2, child) {
        final curvedValue = Curves.easeOutCubic.transform(anim1.value);
        final screenWidth = MediaQuery.of(dialogCtx).size.width;
        final isMobile = screenWidth < 600;
        final drawerWidth = isMobile ? screenWidth : 420.0;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final drawerBg = isDark ? const Color(0xFF0F172A) : Colors.white;
        final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final fieldBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
        final fieldBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
        final cardBg = isDark ? const Color(0xFF16243A) : const Color(0xFFEFF6FF);
        final cardBorder = isDark ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFFBFDBFE);

        return Transform.translate(
          offset: Offset((1.0 - curvedValue) * drawerWidth, 0.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (stfCtx, setDialogState) {
                  final addUnits = int.tryParse(quantityCtrl.text.trim()) ?? 0;
                  final projectedStock = selectedProduct.units + addUnits;

                  return Container(
                    width: drawerWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: drawerBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                          blurRadius: 24,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_shopping_cart_rounded,
                                    color: Color(0xFF3B82F6),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isSpecificProduct ? 'Restock Product' : 'Restock Inventory',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: titleColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Add stock units to warehouse',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                                  splashRadius: 20,
                                  onPressed: isSubmittingRestock ? null : () => Navigator.of(dialogCtx).pop(),
                                ),
                              ],
                            ),
                          ),

                          // Drawer Body
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Selected Product Details Card
                                  if (isSpecificProduct) ...[
                                    Text(
                                      'TARGET PRODUCT',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: mutedColor,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: cardBorder),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  selectedProduct.category.toUpperCase(),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(0xFF3B82F6),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFDBEAFE),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Stock: ${selectedProduct.units} units',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            selectedProduct.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: titleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₱${selectedProduct.price.toStringAsFixed(2)} / unit',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: mutedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'SELECT PRODUCT *',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: mutedColor,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<Product>(
                                      initialValue: selectedProduct,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: fieldBg,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: fieldBorder),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                        ),
                                      ),
                                      dropdownColor: fieldBg,
                                      borderRadius: BorderRadius.circular(12),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: titleColor,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      items: _products.map((prod) {
                                        return DropdownMenuItem<Product>(
                                          value: prod,
                                          child: Text(
                                            '[${prod.category}] ${prod.name} (${prod.units} units)',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() => selectedProduct = val);
                                        }
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 20),

                                  // Add Quantity
                                  Text(
                                    'ADD QUANTITY (UNITS) *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mutedColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: quantityCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (_) {
                                      setDialogState(() {
                                        if (restockError != null) restockError = null;
                                      });
                                    },
                                    style: GoogleFonts.plusJakartaSans(
                                      color: titleColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'e.g., 50',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: mutedColor, fontSize: 14),
                                      prefixIcon: Icon(Icons.add_circle_outline_rounded, size: 18, color: mutedColor),
                                      filled: true,
                                      fillColor: fieldBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: restockError != null ? const Color(0xFFE53E3E) : fieldBorder,
                                          width: restockError != null ? 1.5 : 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: restockError != null ? const Color(0xFFE53E3E) : const Color(0xFF2563EB),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (restockError != null) _buildInlineError(restockError!),
                                  const SizedBox(height: 20),

                                  // Live Projection Card
                                  if (addUnits > 0) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Current: ${selectedProduct.units}  →  New Total: $projectedStock units',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Docked Footer Buttons
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: drawerBg,
                              border: Border(top: BorderSide(color: borderColor, width: 1)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSubmittingRestock ? null : () => Navigator.of(dialogCtx).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide(color: fieldBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: titleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: isSubmittingRestock
                                        ? null
                                        : () async {
                                            final units = int.tryParse(quantityCtrl.text.trim());
                                            if (units == null || units <= 0) {
                                              setDialogState(() {
                                                restockError = 'Please enter a valid quantity greater than 0.';
                                              });
                                              return;
                                            }

                                            setDialogState(() {
                                              restockError = null;
                                              isSubmittingRestock = true;
                                            });
                                            final newUnits = selectedProduct.units + units;

                                            try {
                                              await _supabase.from(_table).update({
                                                'units': newUnits,
                                              }).eq('id', selectedProduct.id);

                                              await _insertProductLog(
                                                productId: selectedProduct.id,
                                                productName: selectedProduct.name,
                                                action: 'RESTOCK',
                                                price: selectedProduct.price,
                                                units: newUnits,
                                                details: 'Restocked +$units units. Previous: ${selectedProduct.units}, New: $newUnits.',
                                              );

                                              if (!dialogCtx.mounted) return;
                                              Navigator.of(dialogCtx).pop();
                                              await _loadProducts();

                                              _showThemedSnackBar(
                                                'Successfully restocked +$units units to ${selectedProduct.name}.',
                                                backgroundColor: PiggyTrunkTheme.ptSuccess,
                                              );
                                            } catch (e) {
                                              setDialogState(() {
                                                isSubmittingRestock = false;
                                                restockError = 'Restock failed: $e';
                                              });
                                            }
                                          },
                                    icon: isSubmittingRestock
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.check_rounded, size: 18),
                                    label: Text(
                                      isSubmittingRestock ? 'Saving...' : 'Confirm Restock',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInlineError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1.5),
            child: Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFE53E3E)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE53E3E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    double minHeight = 0,
    bool withBottomPadding = true,
    bool enabled = true,
    bool hasError = false,
    ValueChanged<String>? onChanged,
  }) {
    final borderSide = hasError
        ? const BorderSide(color: Color(0xFFE53E3E), width: 1.5)
        : BorderSide(color: _cardBorder);
    final focusedBorderSide = hasError
        ? const BorderSide(color: Color(0xFFE53E3E), width: 1.5)
        : BorderSide(color: _fieldFocus);

    return Padding(
      padding: EdgeInsets.only(bottom: withBottomPadding ? 12 : 0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: GoogleFonts.plusJakartaSans(
          color: enabled ? _fieldText : _mutedColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: _mutedColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: enabled ? _fieldBg : _fieldBg.withAlpha(100),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          constraints: minHeight > 0 ? BoxConstraints(minHeight: minHeight) : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: borderSide,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _cardBorder.withAlpha(80)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: focusedBorderSide,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);

    return Scaffold(
      backgroundColor: _bgDark,
      drawer: isSmall
          ? Drawer(
              backgroundColor: _panelStart,
              child: AdminSidebar(
                currentRoute: '/inventory',
                onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                isDrawer: true,
              ),
            )
          : null,
      endDrawer: _buildLogsDrawer(),
      body: Row(
        children: [
          if (!isSmall)
            AdminSidebar(
              currentRoute: '/inventory',
              onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
            ),
          Expanded(
            child: Column(
              children: [
                const ScreenTopBar(),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final isMobile = Responsive.isMobile(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showAddProductForm) {
      return _buildAddProductForm();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1350),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_panelStart, _panelEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: _panelBorder, width: 1),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 34),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 34,
            vertical: isMobile ? 16 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _titleColor,
                        letterSpacing: -0.04,
                      ),
                    ),
                    if (_activeTab == 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) => OutlinedButton.icon(
                                onPressed: () async {
                                  setState(() {
                                    _filterProductId = null;
                                    _filterProductName = null;
                                    _selectedLogFilter = null;
                                  });
                                  _loadLogs();
                                  Scaffold.of(context).openEndDrawer();
                                },
                                icon: Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 16,
                                  color: _titleColor,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Activity Logs',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: _titleColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _fieldBg,
                                  side: BorderSide(color: _panelBorder),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() => _showAddProductForm = true),
                              icon: const Icon(Icons.add, size: 18),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Add Product',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              style: _whiteButtonStyle(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Inventory',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _titleColor,
                        letterSpacing: -0.04,
                      ),
                    ),
                    if (_activeTab == 0)
                      Row(
                        children: [
                          Builder(
                            builder: (context) => OutlinedButton.icon(
                              onPressed: () async {
                                setState(() {
                                  _filterProductId = null;
                                  _filterProductName = null;
                                  _selectedLogFilter = null;
                                });
                                _loadLogs();
                                Scaffold.of(context).openEndDrawer();
                              },
                              icon: Icon(
                                Icons.history_toggle_off_rounded,
                                size: 18,
                                color: _titleColor,
                              ),
                              label: Text(
                                'Activity Logs',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _titleColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _fieldBg,
                                side: BorderSide(
                                  color: _panelBorder,
                                ),
                                minimumSize: const Size(160, 52),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _showAddProductForm = true),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(
                              'Add Product',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: _whiteButtonStyle(),
                          ),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              // Tab Toggle Container
              Container(
                width: isMobile ? double.infinity : null,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _panelBorder),
                ),
                child: isMobile
                    ? Row(
                        children: [
                          Expanded(child: _buildTabButton(0, 'Products', Icons.inventory_2_outlined, isMobile: true)),
                          const SizedBox(width: 4),
                          Expanded(child: _buildTabButton(1, 'Stock Requests', Icons.assignment_outlined, isMobile: true)),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTabButton(0, 'Inventory Products', Icons.description_outlined),
                          _buildTabButton(1, 'Raiser Stock Requests', Icons.assignment_outlined),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              _activeTab == 0 ? _buildProductsSection() : _buildStockRequestsContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    if (_products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(color: _cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            _isArchiveMode ? 'No archived products found.' : 'No products found.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _titleColor,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cat in _categoryOptions) ...[
          Builder(
            builder: (context) {
              final catProducts = _products.where((p) => p.category.toLowerCase() == cat.toLowerCase()).toList();
              if (catProducts.isEmpty) return const SizedBox.shrink();
              
              final screenWidth = MediaQuery.of(context).size.width;
              final isNarrow = screenWidth <= 700;
              final crossAxisCount = screenWidth > 1200 ? 2 : 1;
              final childAspectRatio = screenWidth > 1400 ? 2.6 : (screenWidth > 1100 ? 2.35 : 2.1);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          cat,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _titleColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${catProducts.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  isNarrow
                      ? ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: catProducts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) => _buildProductCard(catProducts[index]),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: catProducts.length,
                          itemBuilder: (context, index) => _buildProductCard(catProducts[index]),
                        ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAddProductForm() {
    final isMobile = Responsive.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1350),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_panelStart, _panelEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: _panelBorder, width: 1),
            borderRadius: BorderRadius.circular(34),
          ),
          padding: const EdgeInsets.fromLTRB(30, 26, 30, 26),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF12213A) : Colors.white,
                border: Border.all(color: _cardBorder, width: 1),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: EdgeInsets.all(isMobile ? 16 : 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingProduct == null ? 'Add New Product' : 'Edit Product',
                    style: GoogleFonts.plusJakartaSans(
                      color: _titleColor,
                      fontSize: isMobile ? 22 : 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.04,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isMobile) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _formLabel('PRODUCT PHOTO'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _isSubmitting ? null : _pickProductImage,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _fieldBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _cardBorder,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: _selectedImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.memory(
                                          _selectedImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.55),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Change',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : (_editingProduct?.image != null && _editingProduct!.image!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              _editingProduct!.image!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Center(
                                                child: Icon(Icons.broken_image_outlined, color: _mutedColor, size: 32),
                                              ),
                                            ),
                                            Positioned(
                                              right: 8,
                                              top: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.55),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Change',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_outlined, color: _mutedColor, size: 38),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Upload Image',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: _mutedColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                          ),
                        ),
                        if (_selectedImageName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _selectedImageName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: _mutedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _formLabel('PRODUCT NAME *'),
                        const SizedBox(height: 8),
                        _buildInput(
                          _nameCtrl,
                          'e.g., Premium Hog Feed',
                          hasError: _productNameError != null,
                          onChanged: (_) {
                            if (_productNameError != null) setState(() => _productNameError = null);
                          },
                        ),
                        if (_productNameError != null) _buildInlineError(_productNameError!),
                        const SizedBox(height: 12),
                        _formLabel('CATEGORY *'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _categoryCtrl.text.isEmpty ? 'Feeds' : _categoryCtrl.text,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _fieldBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            isDense: false,
                            constraints: const BoxConstraints(minHeight: 50),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _productCategoryError != null ? const Color(0xFFE53E3E) : _cardBorder,
                                width: _productCategoryError != null ? 1.5 : 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _productCategoryError != null ? const Color(0xFFE53E3E) : _fieldFocus,
                                width: _productCategoryError != null ? 1.5 : 1,
                              ),
                            ),
                          ),
                          dropdownColor: _fieldBg,
                          borderRadius: BorderRadius.circular(12),
                          style: GoogleFonts.plusJakartaSans(
                            color: _fieldText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          iconSize: 20,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _mutedColor),
                          items: _categoryOptions
                              .map(
                                (category) => DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _categoryCtrl.text = value;
                              _productCategoryError = null;
                            });
                          },
                        ),
                        if (_productCategoryError != null) _buildInlineError(_productCategoryError!),
                        const SizedBox(height: 12),
                        _formLabel('STOCK *'),
                        const SizedBox(height: 8),
                        _buildInput(
                          _unitsCtrl,
                          '0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          minHeight: 50,
                          withBottomPadding: false,
                          hasError: _productStockError != null,
                          onChanged: (_) {
                            if (_productStockError != null) setState(() => _productStockError = null);
                          },
                        ),
                        if (_productStockError != null) _buildInlineError(_productStockError!),
                        const SizedBox(height: 12),
                        _formLabel(_editingProduct != null ? 'PRICE (PHP) (Locked)' : 'PRICE (PHP) *'),
                        const SizedBox(height: 8),
                        _buildInput(
                          _priceCtrl,
                          '0',
                          enabled: _editingProduct == null,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          hasError: _productPriceError != null,
                          onChanged: (_) {
                            if (_productPriceError != null) setState(() => _productPriceError = null);
                          },
                        ),
                        if (_productPriceError != null) _buildInlineError(_productPriceError!),
                        if (_editingProduct != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Price is non-editable after product creation.',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.orangeAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _formLabel('DESCRIPTION'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionCtrl,
                          maxLines: 3,
                          style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Add product details, usage instructions, or benefits...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: _mutedColor,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: _fieldBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _fieldFocus),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formLabel('PRODUCT PHOTO'),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _isSubmitting ? null : _pickProductImage,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 170,
                                  decoration: BoxDecoration(
                                    color: _fieldBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _cardBorder,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: _selectedImageBytes != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(11),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.memory(
                                                _selectedImageBytes!,
                                                fit: BoxFit.cover,
                                              ),
                                              Positioned(
                                                right: 8,
                                                top: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.55),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'Change',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : (_editingProduct?.image != null && _editingProduct!.image!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(11),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.network(
                                                    _editingProduct!.image!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Center(
                                                      child: Icon(Icons.broken_image_outlined, color: _mutedColor, size: 32),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    right: 8,
                                                    top: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withValues(alpha: 0.55),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        'Change',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add_photo_alternate_outlined, color: _mutedColor, size: 38),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Upload Image',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      color: _mutedColor,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                ),
                              ),
                              if (_selectedImageName != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _selectedImageName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _mutedColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formLabel('PRODUCT NAME *'),
                              const SizedBox(height: 8),
                              _buildInput(
                                _nameCtrl,
                                'e.g., Premium Hog Feed',
                                hasError: _productNameError != null,
                                onChanged: (_) {
                                  if (_productNameError != null) setState(() => _productNameError = null);
                                },
                              ),
                              if (_productNameError != null) _buildInlineError(_productNameError!),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _formLabel('CATEGORY *'),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<String>(
                                          initialValue: _categoryCtrl.text.isEmpty ? 'Feeds' : _categoryCtrl.text,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: _fieldBg,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                            isDense: false,
                                            constraints: const BoxConstraints(minHeight: 50),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: _productCategoryError != null ? const Color(0xFFE53E3E) : _cardBorder,
                                                width: _productCategoryError != null ? 1.5 : 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: _productCategoryError != null ? const Color(0xFFE53E3E) : _fieldFocus,
                                                width: _productCategoryError != null ? 1.5 : 1,
                                              ),
                                            ),
                                          ),
                                          dropdownColor: _fieldBg,
                                          borderRadius: BorderRadius.circular(12),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: _fieldText,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          iconSize: 20,
                                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _mutedColor),
                                          items: _categoryOptions
                                              .map(
                                                (category) => DropdownMenuItem<String>(
                                                  value: category,
                                                  child: Text(category),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setState(() {
                                              _categoryCtrl.text = value;
                                              _productCategoryError = null;
                                            });
                                          },
                                        ),
                                        if (_productCategoryError != null) _buildInlineError(_productCategoryError!),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _formLabel('STOCK *'),
                                        const SizedBox(height: 8),
                                        _buildInput(
                                          _unitsCtrl,
                                          '0',
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          minHeight: 50,
                                          withBottomPadding: false,
                                          hasError: _productStockError != null,
                                          onChanged: (_) {
                                            if (_productStockError != null) setState(() => _productStockError = null);
                                          },
                                        ),
                                        if (_productStockError != null) _buildInlineError(_productStockError!),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _formLabel(_editingProduct != null ? 'PRICE (PHP) (Locked)' : 'PRICE (PHP) *'),
                              const SizedBox(height: 8),
                              _buildInput(
                                _priceCtrl,
                                '0',
                                enabled: _editingProduct == null,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                hasError: _productPriceError != null,
                                onChanged: (_) {
                                  if (_productPriceError != null) setState(() => _productPriceError = null);
                                },
                              ),
                              if (_productPriceError != null) _buildInlineError(_productPriceError!),
                              if (_editingProduct != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Price is non-editable after product creation.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.orangeAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _formLabel('DESCRIPTION'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _descriptionCtrl,
                                maxLines: 3,
                                style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Add product details, usage instructions, or benefits...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: _mutedColor,
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: _fieldBg,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _cardBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _fieldFocus),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${_descriptionCtrl.text.length}/1000',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _mutedColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (isMobile) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitAddProduct,
                          style: _whiteButtonStyle(minWidth: double.infinity),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            _isSubmitting
                                ? (_editingProduct == null ? 'Adding...' : 'Saving...')
                                : (_editingProduct == null ? 'Add Product' : 'Save Changes'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() {
                                    _resetAddProductForm();
                                    _showAddProductForm = false;
                                  }),
                          icon: Icon(Icons.close, color: _titleColor),
                          label: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              color: _titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: _cardBorder, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitAddProduct,
                          style: _whiteButtonStyle(minWidth: 190),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            _isSubmitting
                                ? (_editingProduct == null ? 'Adding...' : 'Saving...')
                                : (_editingProduct == null ? 'Add Product' : 'Save Changes'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() {
                                    _resetAddProductForm();
                                    _showAddProductForm = false;
                                  }),
                          icon: Icon(Icons.close, color: _titleColor),
                          label: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              color: _titleColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(170, 54),
                            side: BorderSide(color: _cardBorder, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: _titleColor,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isMobile = Responsive.isMobile(context);
    final imageSize = isMobile ? 110.0 : 155.0;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(isMobile ? 10 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Square Product Image (1:1 Ratio)
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              color: _fieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder.withAlpha(80)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: product.image != null && product.image!.isNotEmpty
                  ? Image.network(
                      product.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.broken_image_outlined, color: _mutedColor, size: 28),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image_outlined, color: _mutedColor, size: 28),
                    ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 14),
          // Right Column: Product Details & Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Title + Stock Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.w800,
                          color: _isDark ? Colors.white : const Color(0xFF3B5B83),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildStockBadge(product, isMobile: isMobile),
                  ],
                ),
                const SizedBox(height: 2),
                // Description
                Text(
                  product.description.isEmpty ? 'No description' : product.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 11 : 12,
                    color: _mutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                // Price & Stock Row Container
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: _fieldBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PRICE:',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _mutedColor,
                                  ),
                                ),
                                Text(
                                  '₱${product.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _titleColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Stock:',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _mutedColor,
                                  ),
                                ),
                                Text(
                                  '${product.units} units',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _titleColor,
                                  ),
                                ),
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
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _mutedColor,
                                  ),
                                ),
                                Text(
                                  '₱${product.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _titleColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'Stock: ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _mutedColor,
                                  ),
                                ),
                                Text(
                                  '${product.units} units',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _titleColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                SizedBox(height: isMobile ? 8 : 10),
                // Action Buttons Row (Edit, Restock, Logs)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openProductDialog(existing: product),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _panelBorder, width: 1.2),
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12, horizontal: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined, size: isMobile ? 13 : 15, color: _mutedColor),
                            const SizedBox(width: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Edit',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _mutedColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isMobile ? 11 : 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openRestockDialog(initialProduct: product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PiggyTrunkTheme.ptPrimary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12, horizontal: 2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_shopping_cart, size: isMobile ? 13 : 15),
                            const SizedBox(width: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Restock',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isMobile ? 11 : 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Builder(
                      builder: (context) => Container(
                        width: isMobile ? 36 : 42,
                        height: isMobile ? 36 : 42,
                        decoration: BoxDecoration(
                          border: Border.all(color: _panelBorder, width: 1.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.history, size: isMobile ? 16 : 18, color: _mutedColor),
                          tooltip: 'View Product Logs',
                          onPressed: () {
                            setState(() {
                              _filterProductId = product.id;
                              _filterProductName = product.name;
                              _selectedLogFilter = null;
                            });
                            _loadLogs();
                            Scaffold.of(context).openEndDrawer();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(Product product, {bool isMobile = false}) {
    final lowStock = product.units <= 10;
    final bg = lowStock ? const Color(0x33FF758C) : const Color(0x3343CB89);
    final fg = lowStock ? const Color(0xFFFF758C) : const Color(0xFF43CB89);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10, vertical: isMobile ? 3 : 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        lowStock ? 'LOW STOCK' : 'IN STOCK',
        style: GoogleFonts.plusJakartaSans(
          color: fg,
          fontSize: isMobile ? 9 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  ButtonStyle _whiteButtonStyle({double minWidth = 0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.styleFrom(
      backgroundColor: isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
      foregroundColor: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
      minimumSize: Size(minWidth, 52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    );
  }

  Future<void> _insertProductLog({
    required String? productId,
    required String productName,
    required String action, 
    required double price,
    required int units,
    String? details,
  }) async {
    try {
      final userEmail = _supabase.auth.currentUser?.email ?? 'Unknown Admin';
      await _supabase.from('inventory_logs').insert({
        'product_id': productId,
        'product_name': productName,
        'action': action,
        'performed_by': userEmail,
        'price': price,
        'units': units,
        'details': details,
      });
    } catch (e) {
      debugPrint('Failed to insert product log to Supabase: $e');
    }
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLogs = true;
      _logsErrorMessage = null;
    });
    try {
      var query = _supabase.from('inventory_logs').select();
      if (_filterProductId != null) {
        query = query.eq('product_id', _filterProductId!);
      }
      final response = await query.order('created_at', ascending: false);
      final list = response as List;
      final parsed = list.map((e) => ProductLog.fromJson(e)).toList();
      
      if (!mounted) return;
      setState(() {
        _logs = parsed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logsErrorMessage = 'Could not load activity logs.\nMake sure the database table is created: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingLogs = false);
      }
    }
  }

  String _formatDate(DateTime dt) {
    final localDt = dt.toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[localDt.month - 1];
    final day = localDt.day.toString().padLeft(2, '0');
    final year = localDt.year;
    final hourVal = localDt.hour > 12 ? localDt.hour - 12 : (localDt.hour == 0 ? 12 : localDt.hour);
    final hour = hourVal.toString().padLeft(2, '0');
    final minute = localDt.minute.toString().padLeft(2, '0');
    final ampm = localDt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year $hour:$minute $ampm';
  }

  Widget _buildLogsDrawer() {
    final title = _filterProductName != null 
        ? 'History: $_filterProductName' 
        : 'Inventory Activity Logs';

    final filteredList = _logs.where((log) {
      if (_selectedLogFilter == null) return true;
      if (_selectedLogFilter == 'ADD') return log.action == 'ADD';
      if (_selectedLogFilter == 'UPDATE') return log.action == 'UPDATE';
      if (_selectedLogFilter == 'RESTOCK') return log.action == 'RESTOCK';
      return true;
    }).toList();

    return Drawer(
      width: MediaQuery.of(context).size.width > 600 ? 550 : double.infinity,
      backgroundColor: _cardBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _titleColor,
                          ),
                        ),
                        if (_filterProductName != null) ...[
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _filterProductId = null;
                                _filterProductName = null;
                              });
                              _loadLogs();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Showing only this product. Click to clear.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: _accentDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.clear, size: 12, color: _accentDark),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            'Real-time log of product addition & updates.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: _mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: _mutedColor),
                    onPressed: _loadLogs,
                    tooltip: 'Refresh Logs',
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _mutedColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLogFilterChip(null, 'All Actions'),
                    const SizedBox(width: 8),
                    _buildLogFilterChip('ADD', 'Creations'),
                    const SizedBox(width: 8),
                    _buildLogFilterChip('UPDATE', 'Updates'),
                    const SizedBox(width: 8),
                    _buildLogFilterChip('RESTOCK', 'Restocks'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: _isLoadingLogs
                  ? const Center(child: CircularProgressIndicator())
                  : _logsErrorMessage != null
                      ? _buildLogsErrorState()
                      : filteredList.isEmpty
                          ? _buildLogsEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                return _buildLogItem(filteredList[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogFilterChip(String? filterValue, String label) {
    final isSelected = _selectedLogFilter == filterValue;
    final activeBg = _isDark ? const Color(0xFF2563EB) : const Color(0xFF18314F);
    final unselectedBg = _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final unselectedBorder = _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final unselectedTextColor = _isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return InkWell(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedLogFilter = filterValue;
          });
        }
      },
      borderRadius: BorderRadius.circular(18),
      splashColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      hoverColor: const Color(0xFF2563EB).withValues(alpha: 0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : unselectedBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? activeBg : unselectedBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: _isDark ? 0.35 : 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLogsErrorState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0x11FF758C) : const Color(0xFFFFF0F2),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Database Setup Required',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'To view and record real-time product logs, the database table must be created in your Supabase project.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _titleColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Instruction:',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Run the SQL script 24_inventory_logs.sql in the Supabase SQL Editor.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: _mutedColor,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF1C2D44) : const Color(0xFFEDF2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'sql/erd_supabase/24_inventory_logs.sql',
                style: GoogleFonts.firaCode(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadLogs,
              style: _whiteButtonStyle(minWidth: 150),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_outlined, size: 48, color: _mutedColor),
          const SizedBox(height: 16),
          Text(
            'No Activity Logs Found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedLogFilter != null
                ? 'No activities found matching this filter.'
                : 'Activities will appear here when products are modified.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(ProductLog log) {
    Color badgeBg;
    Color badgeFg;
    String badgeText = log.action;

    switch (log.action) {
      case 'ADD':
        badgeBg = const Color(0xFFDCFCE7);
        badgeFg = const Color(0xFF15803D);
        badgeText = 'CREATED';
        break;
      case 'UPDATE':
        badgeBg = const Color(0xFFDBEAFE);
        badgeFg = const Color(0xFF1D4ED8);
        badgeText = 'UPDATED';
        break;
      case 'RESTOCK':
        badgeBg = const Color(0xFFE0E7FF);
        badgeFg = const Color(0xFF4338CA);
        badgeText = 'RESTOCKED';
        break;
      default:
        badgeBg = _fieldBg;
        badgeFg = _mutedColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF15263F) : Colors.white,
        border: Border.all(color: _cardBorder),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    color: badgeFg,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              Text(
                _formatDate(log.createdAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: _mutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            log.productName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: _mutedColor),
              const SizedBox(width: 4),
              Text(
                'By: ${log.performedBy}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (log.details != null && log.details!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cardBorder.withValues(alpha: 0.5)),
              ),
              child: Text(
                log.details!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: _titleColor,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price: ₱${log.price.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _mutedColor,
                ),
              ),
              Text(
                'Stock: ${log.units} units',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _mutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, {bool isMobile = false}) {
    final isSelected = _activeTab == index;
    final activeColor = _isDark ? PiggyTrunkTheme.ptPrimary : const Color(0xFF315C8F);
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
        if (index == 1) {
          _loadStockRequests();
        } else {
          _loadProducts();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isMobile ? 14 : 16,
              color: isSelected ? Colors.white : _titleColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? Colors.white : _titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadStockRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingRequests = true);
    try {
      dynamic response;
      try {
        response = await _supabase
            .from('stock_requests')
            .select('*, hog_raisers(name)')
            .order('request_date', ascending: false);
      } catch (relErr) {
        // Fallback if foreign key relationship is not in PostgREST schema cache
        debugPrint('Foreign key relation fallback: $relErr');
        response = await _supabase
            .from('stock_requests')
            .select('*')
            .order('request_date', ascending: false);
      }

      final rawList = List<Map<String, dynamic>>.from(response as List);

      // Extract raiser IDs to fetch names if missing
      final hogRaiserIds = rawList
          .map((r) => (r['hog_raiser_id'] ?? r['raiser_id'] ?? r['user_id'])?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      Map<String, String> raiserNameMap = {};
      if (hogRaiserIds.isNotEmpty) {
        try {
          final raisersRes = await _supabase
              .from('hog_raisers')
              .select('id, name')
              .filter('id', 'in', hogRaiserIds.toList());
          for (final raiser in raisersRes as List) {
            raiserNameMap[raiser['id'].toString()] = raiser['name']?.toString() ?? 'Unknown Raiser';
          }
        } catch (_) {}
      }

      for (var req in rawList) {
        final raiserId = (req['hog_raiser_id'] ?? req['raiser_id'] ?? req['user_id'])?.toString();
        if (raiserId != null && raiserNameMap.containsKey(raiserId)) {
          req['fetched_raiser_name'] = raiserNameMap[raiserId];
        }
      }

      if (!mounted) return;
      setState(() {
        _stockRequests = rawList;
      });
    } catch (e) {
      debugPrint('Error loading stock requests: $e');
      _showThemedSnackBar('Failed to load stock requests: $e', backgroundColor: Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isLoadingRequests = false);
      }
    }
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
      ),
    );
  }

  Widget _buildStockRequestsContent() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredRequests = _stockRequests.where((req) {
      if (_requestsFilter == 'All') return true;
      return (req['status'] as String).toLowerCase() == _requestsFilter.toLowerCase();
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRequestFilterChip('All', 'All Requests'),
                    const SizedBox(width: 8),
                    _buildRequestFilterChip('Pending', 'Pending'),
                    const SizedBox(width: 8),
                    _buildRequestFilterChip('Approved', 'Approved'),
                    const SizedBox(width: 8),
                    _buildRequestFilterChip('Rejected', 'Rejected'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: _titleColor),
              onPressed: _loadStockRequests,
              tooltip: 'Refresh Requests',
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (filteredRequests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: _cardBorder),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                'No requests found.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _titleColor,
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: _cardBorder),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth > 1000 ? constraints.maxWidth : 1000.0;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2), // Raiser
                          1: FlexColumnWidth(1.0), // Date
                          2: FlexColumnWidth(1.0), // Category
                          3: FlexColumnWidth(1.0), // Detail
                          4: FlexColumnWidth(0.8), // Quantity
                          5: FlexColumnWidth(1.0), // Status
                          6: FlexColumnWidth(1.8), // Actions
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC),
                              border: Border(bottom: BorderSide(color: _cardBorder)),
                            ),
                            children: [
                              _tableHeaderCell('RAISER NAME'),
                              _tableHeaderCell('REQUEST DATE'),
                              _tableHeaderCell('CATEGORY'),
                              _tableHeaderCell('FEED TYPE'),
                              _tableHeaderCell('QUANTITY'),
                              _tableHeaderCell('STATUS'),
                              _tableHeaderCell('ACTIONS'),
                            ],
                          ),
                          ...filteredRequests.map((req) => _buildRequestRow(req)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _tableHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: _titleColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRequestFilterChip(String filterValue, String label) {
    final isSelected = _requestsFilter == filterValue;
    final activeBg = _isDark ? const Color(0xFF2563EB) : const Color(0xFF18314F);
    final unselectedBg = _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final unselectedBorder = _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final unselectedTextColor = _isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return InkWell(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _requestsFilter = filterValue;
          });
        }
      },
      borderRadius: BorderRadius.circular(20),
      splashColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      hoverColor: const Color(0xFF2563EB).withValues(alpha: 0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBg : unselectedBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: _isDark ? 0.35 : 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  TableRow _buildRequestRow(Map<String, dynamic> req) {
    final raiser = req['hog_raisers'] as Map<String, dynamic>?;
    final raiserName = req['fetched_raiser_name'] ??
        req['raiser_name'] ??
        req['hog_raiser_name'] ??
        req['user_name'] ??
        raiser?['name'] ??
        'Unknown Raiser';
    final requestDate = req['request_date']?.toString() ?? 'N/A';
    final category = req['category']?.toString() ?? 'Feeds';
    final feedType = req['feed_type']?.toString() ?? 'N/A';
    final quantity = req['quantity']?.toString() ?? '0';
    final status = req['status']?.toString().toUpperCase() ?? 'PENDING';

    Color statusBg;
    Color statusFg;
    if (status == 'APPROVED') {
      statusBg = const Color(0x3343CB89);
      statusFg = const Color(0xFF43CB89);
    } else if (status == 'REJECTED') {
      statusBg = const Color(0x33FF758C);
      statusFg = const Color(0xFFFF758C);
    } else {
      statusBg = const Color(0x33FFAA00);
      statusFg = const Color(0xFFFFAA00);
    }

    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.5))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            raiserName,
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            requestDate,
            style: GoogleFonts.plusJakartaSans(
              color: _mutedColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            category,
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            feedType,
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '$quantity units',
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: statusFg,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: status == 'PENDING'
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _isProcessingRequest ? null : () => _showApproveDialog(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PiggyTrunkTheme.ptSuccess,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: _isProcessingRequest ? null : () => _confirmRejectRequest(req),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PiggyTrunkTheme.ptMuted,
                        side: BorderSide(color: _panelBorder),
                        minimumSize: const Size(70, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  'No Actions',
                  style: GoogleFonts.plusJakartaSans(
                    color: _mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showApproveDialog(Map<String, dynamic> req) async {
    final category = req['category']?.toString() ?? 'Feeds';
    final feedType = req['feed_type']?.toString() ?? '';
    final requestedQuantity = (req['quantity'] as num?)?.toInt() ?? 1;
    final raiser = req['hog_raisers'] as Map<String, dynamic>?;
    final raiserName = raiser?['name'] ?? 'Unknown Raiser';
    final requestId = req['request_id'];

    List<Product> matchingProducts = _products.where((p) {
      return p.category.toLowerCase() == category.toLowerCase();
    }).toList();

    Product? selectedProduct;
    if (matchingProducts.isNotEmpty) {
      if (category.toLowerCase() == 'feeds' && feedType.isNotEmpty) {
        selectedProduct = matchingProducts.firstWhere(
          (p) => p.name.toLowerCase().contains(feedType.toLowerCase()),
          orElse: () => matchingProducts.first,
        );
      } else {
        selectedProduct = matchingProducts.first;
      }
    }

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Approve Request Drawer',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogCtx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim1, anim2, child) {
        final curvedValue = Curves.easeOutCubic.transform(anim1.value);
        final screenWidth = MediaQuery.of(dialogCtx).size.width;
        final isMobile = screenWidth < 600;
        final drawerWidth = isMobile ? screenWidth : 420.0;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final drawerBg = isDark ? const Color(0xFF0F172A) : Colors.white;
        final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final fieldBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
        final fieldBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
        final cardBg = isDark ? const Color(0xFF16243A) : const Color(0xFFEFF6FF);
        final cardBorder = isDark ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFFBFDBFE);

        return Transform.translate(
          offset: Offset((1.0 - curvedValue) * drawerWidth, 0.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (stfCtx, setStateDialog) {
                  Product? selectedProdInDialog = selectedProduct;
                  final hasSufficientStock = selectedProdInDialog != null && selectedProdInDialog.units >= requestedQuantity;

                  return Container(
                    width: drawerWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: drawerBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                          blurRadius: 24,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.task_alt_rounded,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Approve Request',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Release stock from inventory',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: mutedColor, size: 20),
                                  splashRadius: 20,
                                  onPressed: () => Navigator.of(dialogCtx).pop(),
                                ),
                              ],
                            ),
                          ),

                          // Body
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Raiser Request Card
                                  Text(
                                    'REQUEST DETAILS',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mutedColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: cardBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              raiserName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: titleColor,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                'HOG RAISER',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF3B82F6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Requested: $requestedQuantity units of $category${feedType.isNotEmpty ? ' ($feedType)' : ''}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Product selection
                                  Text(
                                    'SELECT PRODUCT TO RELEASE *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mutedColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (matchingProducts.isEmpty)
                                    Text(
                                      'No products found in the inventory under "$category" category.',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  else
                                    DropdownButtonFormField<Product>(
                                      initialValue: selectedProdInDialog,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: fieldBg,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: fieldBorder),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                        ),
                                      ),
                                      dropdownColor: fieldBg,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: titleColor,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: mutedColor),
                                      items: matchingProducts
                                          .map((prod) => DropdownMenuItem<Product>(
                                                value: prod,
                                                child: Text('${prod.name} (${prod.units} left)'),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        setStateDialog(() {
                                          selectedProduct = val;
                                        });
                                      },
                                    ),
                                  if (selectedProdInDialog != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: hasSufficientStock
                                            ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08)
                                            : Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: hasSufficientStock
                                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                              : Colors.red.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Current Stock: ${selectedProdInDialog.units} units',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: hasSufficientStock
                                                  ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                                                  : Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (!hasSufficientStock) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Insufficient stock. You need $requestedQuantity units but only have ${selectedProdInDialog.units}.',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.redAccent,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Footer
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: drawerBg,
                              border: Border(top: BorderSide(color: borderColor, width: 1)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(dialogCtx).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide(color: fieldBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: titleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: (selectedProdInDialog == null || !hasSufficientStock)
                                        ? null
                                        : () {
                                            Navigator.of(dialogCtx).pop();
                                            _processApproveRequest(requestId, selectedProdInDialog, requestedQuantity, raiserName);
                                          },
                                    icon: const Icon(Icons.check_rounded, size: 18),
                                    label: Text(
                                      'Confirm Approval',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _processApproveRequest(
    dynamic requestId,
    Product product,
    int quantity,
    String raiserName,
  ) async {
    setState(() => _isProcessingRequest = true);
    try {
      final finalUnits = product.units - quantity;

      await _supabase.from('stock_requests').update({
        'status': 'approved',
        'decision_date': DateTime.now().toIso8601String().split('T').first,
      }).eq('request_id', requestId);

      await _supabase.from(_table).update({
        'units': finalUnits,
      }).eq('id', product.id);

      await _insertProductLog(
        productId: product.id,
        productName: product.name,
        action: 'UPDATE',
        price: product.price,
        units: finalUnits,
        details: 'Approved stock request for $raiserName: Released $quantity units of ${product.category}. New stock: $finalUnits.',
      );

      _showThemedSnackBar(
        'Stock request approved successfully.',
        backgroundColor: PiggyTrunkTheme.ptSuccess,
      );

      await Future.wait([_loadProducts(), _loadStockRequests()]);
    } catch (e) {
      debugPrint('Error approving stock request: $e');
      _showThemedSnackBar(
        'Failed to approve request: $e',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      setState(() => _isProcessingRequest = false);
    }
  }

  Future<void> _confirmRejectRequest(Map<String, dynamic> req) async {
    final requestId = req['request_id'];
    final category = req['category']?.toString() ?? 'Feeds';
    final quantity = (req['quantity'] as num?)?.toInt() ?? 1;
    final raiser = req['hog_raisers'] as Map<String, dynamic>?;
    final raiserName = raiser?['name'] ?? 'Unknown Raiser';

    final confirmed = await SlideOverConfirmationDrawer.show(
      context: context,
      actionType: SlideOverActionType.danger,
      title: 'Reject Stock Request',
      userName: raiserName,
      userRole: 'HOG RAISER',
      confirmButtonText: 'Confirm Rejection',
      message: 'Are you sure you want to reject the stock request from $raiserName for $quantity units of $category? This will cancel this pending stock request.',
    );

    if (confirmed == true) {
      await _processRejectRequest(requestId);
    }
  }

  Future<void> _processRejectRequest(dynamic requestId) async {
    setState(() => _isProcessingRequest = true);
    try {
      await _supabase.from('stock_requests').update({
        'status': 'rejected',
        'decision_date': DateTime.now().toIso8601String().split('T').first,
      }).eq('request_id', requestId);

      _showThemedSnackBar(
        'Stock request rejected.',
        backgroundColor: Colors.orange,
      );

      await _loadStockRequests();
    } catch (e) {
      debugPrint('Error rejecting stock request: $e');
      _showThemedSnackBar(
        'Failed to reject request: $e',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      setState(() => _isProcessingRequest = false);
    }
  }
}
