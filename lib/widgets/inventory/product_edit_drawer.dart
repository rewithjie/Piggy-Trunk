import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../utils/capitalization_formatters.dart';

class ProductEditDrawer {
  static const List<String> categoryOptions = <String>[
    'Feeds',
    'Vitamins',
    'Medicines',
    'Others',
  ];

  static void show({
    required BuildContext context,
    required Product existing,
    required Future<String?> Function(Uint8List bytes, String filename) onUploadImage,
    required Future<void> Function({
      required String? productId,
      required String productName,
      required String action,
      required double price,
      required int units,
      String? details,
    }) onInsertLog,
    required VoidCallback onProductUpdated,
    required void Function(String msg, {Color? backgroundColor}) onShowSnackBar,
  }) {
    final nameCtrl = TextEditingController(text: existing.name);
    String selectedCategory = existing.category.isNotEmpty ? existing.category : 'Feeds';
    final unitsCtrl = TextEditingController(text: existing.units.toString());
    final descriptionCtrl = TextEditingController(text: existing.description);
    Uint8List? localImageBytes;
    String? localImageName;
    final ImagePicker imagePicker = ImagePicker();

    String? nameError;
    String? stockError;
    bool isSaving = false;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Product Details',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogCtx, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final isMobile = Responsive.isMobile(dialogCtx);
        final screenHeight = MediaQuery.of(dialogCtx).size.height;
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark || Theme.of(context).brightness == Brightness.dark;
        final drawerBg = isDark ? const Color(0xFF132238) : Colors.white;
        final borderColor = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
        final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
        final mutedColor = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
        final fieldBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
        final fieldBorder = isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);

        return SlideTransition(
          position: Tween<Offset>(
            begin: isMobile ? const Offset(0.0, 1.0) : const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: Align(
            alignment: isMobile ? Alignment.bottomCenter : Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (stfCtx, setDrawerState) {
                  return Container(
                    width: isMobile ? double.infinity : 440,
                    height: isMobile ? screenHeight * 0.88 : double.infinity,
                    decoration: BoxDecoration(
                      color: drawerBg,
                      borderRadius: isMobile
                          ? const BorderRadius.vertical(top: Radius.circular(24))
                          : const BorderRadius.horizontal(left: Radius.circular(20)),
                      border: isMobile
                          ? Border(top: BorderSide(color: borderColor, width: 1.2))
                          : Border(left: BorderSide(color: borderColor, width: 1.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                          blurRadius: 24,
                          offset: isMobile ? const Offset(0, -4) : const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: !isMobile,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMobile) ...[
                            // Top Drag Handle for mobile only
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 12, bottom: 6),
                                width: 44,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],

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
                                    color: isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
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

                          // Form Content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Photo Avatar with picker
                                  Center(
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: fieldBg,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: borderColor, width: 1.5),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: localImageBytes != null
                                                ? Image.memory(
                                                    localImageBytes!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : (existing.image != null && existing.image!.isNotEmpty
                                                    ? Image.network(
                                                        existing.image!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) => Center(
                                                          child: Icon(Icons.broken_image_outlined, color: mutedColor, size: 32),
                                                        ),
                                                      )
                                                    : Center(
                                                        child: Icon(Icons.image_outlined, color: mutedColor, size: 36),
                                                      )),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: InkWell(
                                            onTap: () async {
                                              try {
                                                final XFile? file = await imagePicker.pickImage(
                                                  source: ImageSource.gallery,
                                                  maxWidth: 800,
                                                  maxHeight: 800,
                                                  imageQuality: 85,
                                                );
                                                if (file != null) {
                                                  final bytes = await file.readAsBytes();
                                                  setDrawerState(() {
                                                    localImageBytes = bytes;
                                                    localImageName = file.name;
                                                  });
                                                }
                                              } catch (e) {
                                                onShowSnackBar('Failed to select image: $e', backgroundColor: Colors.redAccent);
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: isDark ? const Color(0xFF132238) : Colors.white, width: 2),
                                              ),
                                              child: Icon(
                                                Icons.camera_alt_rounded,
                                                color: isDark ? const Color(0xFF132238) : Colors.white,
                                                size: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
                                    textCapitalization: TextCapitalization.words,
                                    inputFormatters: const [CapitalizeWordsInputFormatter()],
                                    onChanged: (_) {
                                      if (nameError != null) setDrawerState(() => nameError = null);
                                    },
                                    style: GoogleFonts.plusJakartaSans(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Premium Booster Feeds',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: mutedColor, fontSize: 14),
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
                                          color: nameError != null ? const Color(0xFFE53E3E) : PiggyTrunkTheme.ptPrimary,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (nameError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      nameError!,
                                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFFE53E3E), fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                  const SizedBox(height: 16),

                                  // Row: Category & Stock
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
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
                                              initialValue: selectedCategory,
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: fieldBg,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(color: fieldBorder),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(color: PiggyTrunkTheme.ptPrimary, width: 1.5),
                                                ),
                                              ),
                                              dropdownColor: fieldBg,
                                              borderRadius: BorderRadius.circular(12),
                                              style: GoogleFonts.plusJakartaSans(
                                                color: titleColor,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              items: categoryOptions.map((c) {
                                                return DropdownMenuItem<String>(
                                                  value: c,
                                                  child: Text(c),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setDrawerState(() => selectedCategory = val);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'STOCK (UNITS) *',
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
                                                    color: stockError != null ? const Color(0xFFE53E3E) : PiggyTrunkTheme.ptPrimary,
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (stockError != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                stockError!,
                                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFFE53E3E), fontSize: 11.5, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Locked Unit Price Box
                                  Text(
                                    'UNIT PRICE (PHP) – LOCKED',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: mutedColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF162338) : const Color(0xFFEDF2F7),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: fieldBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '₱ ${existing.price.toStringAsFixed(2)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: titleColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(Icons.lock_outline_rounded, size: 16, color: mutedColor),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Price is locked after initial product creation.',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: mutedColor, fontStyle: FontStyle.italic),
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
                                    textCapitalization: TextCapitalization.sentences,
                                    inputFormatters: const [CapitalizeSentencesInputFormatter()],
                                    style: GoogleFonts.plusJakartaSans(color: titleColor, fontSize: 13.5),
                                    decoration: InputDecoration(
                                      hintText: 'Enter optional product description...',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: mutedColor, fontSize: 13),
                                      filled: true,
                                      fillColor: fieldBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: fieldBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: PiggyTrunkTheme.ptPrimary, width: 1.5),
                                      ),
                                    ),
                                  ),
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
                                    onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide(color: borderColor, width: 1.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: mutedColor,
                                        fontWeight: FontWeight.w600,
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
                                                imageUrl = await onUploadImage(localImageBytes!, localImageName!);
                                              }

                                              final payload = {
                                                'name': name,
                                                'category_id': selectedCategory.toLowerCase().replaceAll(' ', '_'),
                                                'category': selectedCategory,
                                                'description': descriptionCtrl.text.trim(),
                                                'units': units,
                                                'image': imageUrl,
                                              };

                                              await Supabase.instance.client
                                                  .from('inventory_products')
                                                  .update(payload)
                                                  .eq('id', existing.id);

                                              List<String> changes = [];
                                              if (existing.name != name) changes.add('Name: "${existing.name}" -> "$name"');
                                              if (existing.category != selectedCategory) changes.add('Category: "${existing.category}" -> "$selectedCategory"');
                                              if (existing.units != units) changes.add('Stock: ${existing.units} -> $units');
                                              if (existing.description != descriptionCtrl.text.trim()) changes.add('Description updated');

                                              final detailsStr = changes.isEmpty ? 'No field changes' : changes.join(', ');

                                              await onInsertLog(
                                                productId: existing.id,
                                                productName: name,
                                                action: 'UPDATE',
                                                price: existing.price,
                                                units: units,
                                                details: detailsStr,
                                              );

                                              if (!dialogCtx.mounted) return;
                                              Navigator.of(dialogCtx).pop();
                                              onProductUpdated();

                                              onShowSnackBar(
                                                'Product "$name" updated successfully.',
                                                backgroundColor: PiggyTrunkTheme.ptSuccess,
                                              );
                                            } catch (e) {
                                              setDrawerState(() {
                                                isSaving = false;
                                                nameError = 'Update failed: $e';
                                              });
                                            }
                                          },
                                    icon: isSaving
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                                          ),
                                    label: Text(
                                      isSaving ? 'Saving...' : 'Save Changes',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                                      foregroundColor: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
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
}
