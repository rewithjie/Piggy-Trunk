import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../utils/inventory_data_adapter.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

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
  static const List<String> _categoryOptions = <String>[
    'Feeds',
    'Vitamins',
    'Medicines',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
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
      } else {
        payload['sold'] = 0;
        payload['is_archived'] = false;
        await _supabase.from(_table).insert(payload);
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
      await _supabase.from(_table).update({'is_archived': !product.isArchived}).eq('id', product.id);
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
                  Row(
                    children: [
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
              const SizedBox(height: 24),
              if (_products.isEmpty)
                Container(
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
                )
              else ...[
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
            ],
          ),
        ),
      ),
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

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: _mutedColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: _titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
}
