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
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
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
      setState(() {
        _editingProduct = existing;
        _nameCtrl.text = existing.name;
        _categoryCtrl.text = existing.category.isNotEmpty == true ? existing.category : 'Feeds';
        _descriptionCtrl.text = existing.description;
        _priceCtrl.text = existing.price.toInt().toString();
        _unitsCtrl.text = existing.units.toString();
        _imageCtrl.text = existing.image ?? '';
        _selectedImageBytes = null;
        _selectedImageName = null;
        _showAddProductForm = true;
      });
    } else {
      setState(() {
        _resetAddProductForm();
        _showAddProductForm = true;
      });
    }
  }

  Future<void> _submitAddProduct() async {
    if (_isSubmitting) return;
    final name = _nameCtrl.text.trim();
    final category = _categoryCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final image = _imageCtrl.text.trim();
    final priceInt = int.tryParse(_priceCtrl.text.trim());
    final units = int.tryParse(_unitsCtrl.text.trim());

    if (name.isEmpty || category.isEmpty || priceInt == null || units == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete all required fields.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
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
        'price': priceInt.toDouble(),
        'units': units,
        'image': imageUrl,
      };

      if (_editingProduct != null) {
        await _supabase.from(_table).update(payload).eq('id', _editingProduct!.id);
        
        List<String> changes = [];
        if (_editingProduct!.name != name) changes.add('Name: "${_editingProduct!.name}" -> "$name"');
        if (_editingProduct!.category != category) changes.add('Category: "${_editingProduct!.category}" -> "$category"');
        if (_editingProduct!.price != priceInt.toDouble()) changes.add('Price: ₱${_editingProduct!.price.toInt()} -> ₱$priceInt');
        if (_editingProduct!.units != units) changes.add('Stock: ${_editingProduct!.units} -> $units');
        if (_editingProduct!.description != description) changes.add('Description updated');
        
        final detailsStr = changes.isEmpty ? 'No field changes' : changes.join(', ');
        
        await _insertProductLog(
          productId: _editingProduct!.id,
          productName: name,
          action: 'UPDATE',
          price: priceInt.toDouble(),
          units: units,
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
          price: priceInt.toDouble(),
          units: units,
          details: 'Initial stock of $units units at ₱$priceInt.00',
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

  Future<void> _toggleArchive(Product product) async {
    try {
      final newArchivedState = !product.isArchived;
      await _supabase.from(_table).update({'is_archived': newArchivedState}).eq('id', product.id);
      
      final action = newArchivedState ? 'ARCHIVE' : 'RESTORE';
      final details = newArchivedState 
          ? 'Product moved to archives' 
          : 'Product restored to active inventory';
          
      await _insertProductLog(
        productId: product.id,
        productName: product.name,
        action: action,
        price: product.price,
        units: product.units,
        details: details,
      );

      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product.isArchived ? 'Product restored successfully.' : 'Product archived successfully.',
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
            'Update failed: $e',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInput(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    double minHeight = 0,
    bool withBottomPadding = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: withBottomPadding ? 12 : 0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.plusJakartaSans(
          color: _fieldText,
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
          fillColor: _fieldBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          constraints: minHeight > 0 ? BoxConstraints(minHeight: minHeight) : null,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: _bgDark,
      endDrawer: _buildLogsDrawer(),
      body: Row(

        children: [
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showAddProductForm) {
      return _buildAddProductForm();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
          padding: const EdgeInsets.fromLTRB(34, 28, 34, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        OutlinedButton.icon(
                          onPressed: () async {
                            setState(() => _isArchiveMode = !_isArchiveMode);
                            await _loadProducts();
                          },
                          icon: Icon(
                            _isArchiveMode ? Icons.inventory_2_outlined : Icons.archive_outlined,
                            size: 18,
                            color: _titleColor,
                          ),
                          label: Text(
                            _isArchiveMode ? 'Back to Active' : 'Archives',
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
                            minimumSize: const Size(170, 52),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _panelBorder),
                ),
                child: Row(
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
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(color: _cardBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              _isArchiveMode ? 'No archived products found.' : 'No products found.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _titleColor,
              ),
            ),
            const SizedBox(height: 20),
            if (!_isArchiveMode)
              ElevatedButton(
                onPressed: () => setState(() => _showAddProductForm = true),
                style: _whiteButtonStyle(minWidth: 220),
                child: Text(
                  'Create First Product',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
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
              final crossAxisCount = screenWidth > 1400 ? 4 : (screenWidth > 900 ? 3 : 2);
              final childAspectRatio = screenWidth > 1400 ? 0.70 : (screenWidth > 900 ? 0.76 : 0.82);

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
                  GridView.builder(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
              padding: const EdgeInsets.fromLTRB(40, 34, 40, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingProduct == null ? 'Add New Product' : 'Edit Product',
                    style: GoogleFonts.plusJakartaSans(
                      color: _titleColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.04,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                                            child: Text(
                                              'Click to upload\nPNG, JPG, WebP',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.plusJakartaSans(
                                                color: _mutedColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
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
                            _buildInput(_nameCtrl, 'e.g., Premium Hog Feed'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _formLabel('CATEGORY *'),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _categoryCtrl.text.isEmpty ? 'Feeds' : _categoryCtrl.text,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: _fieldBg,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                          isDense: false,
                                          constraints: const BoxConstraints(minHeight: 50),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: _cardBorder),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: _fieldFocus),
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
                                          setState(() => _categoryCtrl.text = value);
                                        },
                                      ),
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
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _formLabel('PRICE (PHP) *'),
                            const SizedBox(height: 8),
                            _buildInput(
                              _priceCtrl,
                              '0',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
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
                  const SizedBox(height: 24),
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
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Product Image (Full width, BoxFit.cover)
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _fieldBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: product.image != null && product.image!.isNotEmpty
                  ? Image.network(
                      product.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.broken_image_outlined, color: _mutedColor, size: 32),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image_outlined, color: _mutedColor, size: 32),
                    ),
            ),
          ),
          // Bottom: Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'PRODUCT NAME: ${product.name}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _isDark ? Colors.white : const Color(0xFF3B5B83),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildStockBadge(product),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'DESCRIPTION: ${product.description.isEmpty ? 'None' : product.description}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: _mutedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PRICE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
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
                  const SizedBox(height: 6),
                  // Stock row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _mutedColor,
                        ),
                      ),
                      Text(
                        '${product.units} units',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                   Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openProductDialog(existing: product),
                          icon: Icon(Icons.edit_outlined, size: 14, color: _mutedColor),
                          label: Text(
                            'Edit',
                            style: GoogleFonts.plusJakartaSans(
                              color: _mutedColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _panelBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _toggleArchive(product),
                          icon: Icon(
                            _isArchiveMode ? Icons.unarchive_outlined : Icons.archive_outlined,
                            size: 14,
                            color: _accentDark,
                          ),
                          label: Text(
                            _isArchiveMode ? 'Restore' : 'Archive',
                            style: GoogleFonts.plusJakartaSans(
                              color: _accentDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _panelBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) => Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            border: Border.all(color: _panelBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.history, size: 18, color: _mutedColor),
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
          ),
        ],
      ),
    );
  }


  Widget _buildStockBadge(Product product) {
    final lowStock = product.units <= 10;
    final bg = lowStock ? const Color(0x33FF758C) : const Color(0x3343CB89);
    final fg = lowStock ? const Color(0xFFFF758C) : const Color(0xFF43CB89);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        lowStock ? 'LOW STOCK' : 'IN STOCK',
        style: GoogleFonts.plusJakartaSans(
          color: fg,
          fontSize: 11,
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hourVal = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final hour = hourVal.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
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
      if (_selectedLogFilter == 'ARCHIVE') return log.action == 'ARCHIVE' || log.action == 'RESTORE';
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
                    _buildLogFilterChip('ARCHIVE', 'Archive/Restore'),
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
    final activeColor = _isDark ? PiggyTrunkTheme.ptPrimary : const Color(0xFF315C8F);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedLogFilter = filterValue;
          });
        }
      },
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isSelected ? Colors.white : _titleColor,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      backgroundColor: _fieldBg,
      selectedColor: activeColor,
      side: BorderSide(color: isSelected ? Colors.transparent : _cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      case 'ARCHIVE':
        badgeBg = const Color(0xFFFEF3C7);
        badgeFg = const Color(0xFFB45309);
        badgeText = 'ARCHIVED';
        break;
      case 'RESTORE':
        badgeBg = const Color(0xFFCCFBF1);
        badgeFg = const Color(0xFF0F766E);
        badgeText = 'RESTORED';
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

  Widget _buildTabButton(int index, String label, IconData icon) {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : _titleColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : _titleColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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
      final response = await _supabase
          .from('stock_requests')
          .select('*, hog_raisers(name)')
          .order('request_date', ascending: false);
      
      if (!mounted) return;
      setState(() {
        _stockRequests = List<Map<String, dynamic>>.from(response as List);
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
    final activeColor = _isDark ? PiggyTrunkTheme.ptPrimary : const Color(0xFF315C8F);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _requestsFilter = filterValue;
          });
        }
      },
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isSelected ? Colors.white : _titleColor,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      backgroundColor: _fieldBg,
      selectedColor: activeColor,
      side: BorderSide(color: isSelected ? Colors.transparent : _cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  TableRow _buildRequestRow(Map<String, dynamic> req) {
    final raiser = req['hog_raisers'] as Map<String, dynamic>?;
    final raiserName = raiser?['name'] ?? 'Unknown Raiser';
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

    showDialog<void>(
      context: context,
      builder: (context) {
        Product? selectedProdInDialog = selectedProduct;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final hasSufficientStock = selectedProdInDialog != null && selectedProdInDialog!.units >= requestedQuantity;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: 480,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cardBorder),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approve Stock Request',
                      style: GoogleFonts.plusJakartaSans(
                        color: _titleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Raiser: $raiserName',
                      style: GoogleFonts.plusJakartaSans(
                        color: _titleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Requesting: $requestedQuantity units of $category${feedType.isNotEmpty ? ' ($feedType)' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        color: _titleColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SELECT PRODUCT FROM INVENTORY TO RELEASE:',
                      style: GoogleFonts.plusJakartaSans(
                        color: _mutedColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (matchingProducts.isEmpty)
                      Text(
                        'No products found in the inventory under "$category" category. Please add a product first.',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      DropdownButtonFormField<Product>(
                        value: selectedProdInDialog,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _fieldBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _fieldFocus),
                          ),
                        ),
                        dropdownColor: _fieldBg,
                        style: GoogleFonts.plusJakartaSans(
                          color: _fieldText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _mutedColor),
                        items: matchingProducts
                            .map((prod) => DropdownMenuItem<Product>(
                                  value: prod,
                                  child: Text('${prod.name} (${prod.units} left)'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedProdInDialog = val;
                          });
                        },
                      ),
                    if (selectedProdInDialog != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Current Stock: ${selectedProdInDialog!.units} units',
                        style: GoogleFonts.plusJakartaSans(
                          color: hasSufficientStock ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (!hasSufficientStock) ...[
                        const SizedBox(height: 8),
                        Text(
                          'WARNING: Insufficient stock. You only have ${selectedProdInDialog!.units} units available but $requestedQuantity are requested.',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                color: _titleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (selectedProdInDialog == null || !hasSufficientStock)
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  _processApproveRequest(requestId, selectedProdInDialog!, requestedQuantity, raiserName);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PiggyTrunkTheme.ptSuccess,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Confirm Approval',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 450,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cardBorder),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reject Stock Request',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to reject the stock request from $raiserName for $quantity units of $category?',
                  style: GoogleFonts.plusJakartaSans(color: _titleColor, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            color: _titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _processRejectRequest(requestId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Confirm Rejection',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
