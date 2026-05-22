import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import '../models/product_model.dart';
import '../theme/app_theme.dart';
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
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('is_archived', _isArchiveMode)
          .order('created_at', ascending: false);

      final rows = (response as List)
          .map((row) => Product.fromJson(row as Map<String, dynamic>))
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

  Future<void> _openProductDialog({Product? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category.isNotEmpty == true ? existing!.category : 'Feeds');
    final descriptionCtrl = TextEditingController(text: existing?.description ?? '');
    final priceCtrl = TextEditingController(text: existing?.price.toString() ?? '');
    final unitsCtrl = TextEditingController(text: existing?.units.toString() ?? '');
    final imageCtrl = TextEditingController(text: existing?.image ?? '');
    final soldCtrl = TextEditingController(text: existing?.sold.toString() ?? '0');

    final isEdit = existing != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardBg,
          title: Text(
            isEdit ? 'Edit Product' : 'Add Product',
            style: GoogleFonts.plusJakartaSans(
              color: _titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 430,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInput(nameCtrl, 'Product Name'),
                  _buildInput(categoryCtrl, 'Category'),
                  _buildInput(descriptionCtrl, 'Description'),
                  _buildInput(priceCtrl, 'Price', keyboardType: TextInputType.number),
                  _buildInput(unitsCtrl, 'Units', keyboardType: TextInputType.number),
                  _buildInput(soldCtrl, 'Sold', keyboardType: TextInputType.number),
                  _buildInput(imageCtrl, 'Image URL (optional)'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final category = categoryCtrl.text.trim();
                final description = descriptionCtrl.text.trim();
                final image = imageCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim());
                final units = int.tryParse(unitsCtrl.text.trim());
                final sold = int.tryParse(soldCtrl.text.trim());

                if (name.isEmpty || category.isEmpty || price == null || units == null || sold == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please complete all required fields.')),
                  );
                  return;
                }

                final payload = {
                  'name': name,
                  'category_id': category.toLowerCase().replaceAll(' ', '_'),
                  'category': category,
                  'description': description,
                  'price': price,
                  'units': units,
                  'sold': sold,
                  'image': image.isEmpty ? null : image,
                  'is_archived': existing?.isArchived ?? false,
                };

                try {
                  if (isEdit) {
                    await _supabase.from(_table).update(payload).eq('id', existing.id);
                  } else {
                    await _supabase.from(_table).insert(payload);
                  }

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  await _loadProducts();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Product updated.' : 'Product added.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Save failed: $e')),
                  );
                }
              },
              style: _whiteButtonStyle(),
              child: Text(isEdit ? 'Save Changes' : 'Create Product'),
            ),
          ],
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

    if (name.isEmpty || category.isEmpty || priceInt == null || units == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? imageUrl = image.isEmpty ? null : image;
      if (_selectedImageBytes != null && _selectedImageName != null) {
        imageUrl = await _uploadProductImage(_selectedImageBytes!, _selectedImageName!);
      }

      await _supabase.from(_table).insert({
        'name': name,
        'category_id': category.toLowerCase().replaceAll(' ', '_'),
        'category': category,
        'description': description,
        'price': priceInt.toDouble(),
        'units': units,
        'sold': 0,
        'image': imageUrl,
        'is_archived': false,
      });

      if (!mounted) return;
      _nameCtrl.clear();
      _resetAddProductForm();
      setState(() => _showAddProductForm = false);
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
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
        SnackBar(content: Text('Could not open image picker: $e')),
      );
    }
  }

  Future<String> _uploadProductImage(Uint8List bytes, String fileName) async {
    const bucket = 'product-images';
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'inventory/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await _supabase.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> _toggleArchive(Product product) async {
    try {
      await _supabase.from(_table).update({'is_archived': !product.isArchived}).eq('id', product.id);
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(product.isArchived ? 'Product restored.' : 'Product archived.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
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
              else
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.35,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  itemBuilder: (context, index) => _buildProductCard(_products[index]),
                ),
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
                    'Add New Product',
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
                                child: _selectedImageBytes == null
                                    ? Center(
                                        child: Text(
                                          'Click to upload\nPNG, JPG, WebP',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: _mutedColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : ClipRRect(
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
                                      ),
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
                          _isSubmitting ? 'Adding...' : 'Add Product',
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStockBadge(product),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Category: ${product.category}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description.isEmpty ? 'No description available.' : product.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _fieldText,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _buildMetric('Price', 'PHP ${product.price.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildMetric('Units', '${product.units}'),
              ),
              Expanded(
                child: _buildMetric('Sold', '${product.sold}'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openProductDialog(existing: product),
                  icon: Icon(Icons.edit_outlined, size: 16, color: _mutedColor),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.plusJakartaSans(
                      color: _mutedColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _panelBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleArchive(product),
                  icon: Icon(
                    _isArchiveMode ? Icons.unarchive_outlined : Icons.archive_outlined,
                    size: 16,
                    color: _accentDark,
                  ),
                  label: Text(
                    _isArchiveMode ? 'Restore' : 'Archive',
                    style: GoogleFonts.plusJakartaSans(
                      color: _accentDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _panelBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
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
