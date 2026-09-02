import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../../widgets/piggy_toast.dart';

class RequestFormScreen extends StatefulWidget {
  final List<Map<String, dynamic>> activeAssignments;
  final Map<String, dynamic> raiserData;
  final String initialCategory;
  final VoidCallback onBack;
  final VoidCallback onSuccess;
  final VoidCallback onViewHistory;

  const RequestFormScreen({
    super.key,
    required this.activeAssignments,
    required this.raiserData,
    this.initialCategory = 'Feeds',
    required this.onBack,
    required this.onSuccess,
    required this.onViewHistory,
  });

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  late String _selectedCategory;
  int _quantity = 0;
  String? _selectedFeedType;
  final TextEditingController _notesController = TextEditingController();
  BigInt? _selectedAssignmentId;
  bool _isSubmitting = false;

  String? _assignmentError;
  String? _quantityError;

  static const Color _brandColor = Color(0xFF18314F);

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (_selectedCategory == 'Feeds') {
      _selectedFeedType = 'Booster';
    } else {
      _selectedFeedType = null;
    }
    if (widget.activeAssignments.isNotEmpty) {
      _selectedAssignmentId = BigInt.from(widget.activeAssignments[0]['assignment_id'] as num);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    setState(() {
      _assignmentError = null;
      _quantityError = null;
    });

    bool hasError = false;

    if (_selectedAssignmentId == null) {
      _assignmentError = 'Paki-pili ang assignment batch para sa request.';
      hasError = true;
    }

    if (_quantity <= 0) {
      _quantityError = 'Paki-lagay ang dami ng item na ire-request (dapat higit sa 0).';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final raiserId = widget.raiserData['hog_raiser_id'] ?? widget.raiserData['id'];
      if (raiserId == null) throw Exception('Raiser profile is not available.');

      await Supabase.instance.client.from('stock_requests').insert({
        'assignment_id': _selectedAssignmentId!.toInt(),
        'hog_raiser_id': raiserId,
        'status': 'pending',
        'request_date': DateTime.now().toIso8601String().split('T').first,
        'category': _selectedCategory,
        'quantity': _quantity,
        'feed_type': _selectedCategory == 'Feeds' ? _selectedFeedType : null,
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      });

      final notesText = _notesController.text.trim();
      final itemDesc = _selectedCategory == 'Feeds'
          ? '$_quantity sako ng ${_selectedFeedType ?? "Feeds"}'
          : '$_quantity pcs ng $_selectedCategory';
      final raiserName = widget.raiserData['name'] ?? 'Hog Raiser';
      final notifMessage = notesText.isNotEmpty
          ? '$raiserName requested $itemDesc.\nNotes: "$notesText"'
          : '$raiserName requested $itemDesc.';

      try {
        await Supabase.instance.client.from('admin_notifications').insert({
          'title': 'New Stock Request',
          'message': notifMessage,
          'type': 'stock_request',
          'is_read': false,
        });
      } catch (_) {}

      if (mounted) {
        PiggyToast.showSuccess(
          context,
          'Matagumpay na naipadala ang Stock Request!',
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        PiggyToast.showError(
          context,
          'Error: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildCategoryCard({
    required String name,
    required String label,
    required String sublabel,
    required String imagePath,
    required Color accentColor,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final cardBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final selectedBorderColor = isDark ? const Color(0xFF38BDF8) : _brandColor;
    final textColor = isDark ? PiggyTrunkTheme.ptTextDark : (isSelected ? _brandColor : const Color(0xFF1E293B));
    final mutedColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = name;
            if (name != 'Feeds') {
              _selectedFeedType = null;
            } else {
              _selectedFeedType = 'Booster';
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? selectedBorderColor : cardBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.2) : _brandColor.withValues(alpha: 0.12))
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  imagePath,
                  width: 22,
                  height: 22,
                  color: accentColor,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    name == 'Feeds'
                        ? Icons.grass_rounded
                        : (name == 'Vitamins'
                            ? Icons.medication_liquid_rounded
                            : Icons.medical_services_rounded),
                    size: 22,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedChip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedFeedType == label;
    final selectedBg = isDark ? Colors.white : _brandColor;
    final selectedText = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inactiveBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final inactiveBorder = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final inactiveText = isDark ? PiggyTrunkTheme.ptTextDark : const Color(0xff5d6a7b);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeedType = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedBg : inactiveBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? selectedText : inactiveText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
    final surfaceBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
    final borderColor = isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder;
    final textColor = isDark ? PiggyTrunkTheme.ptTextDark : _brandColor;
    final mutedColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: surfaceBg,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Mag-request ng Supplies',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: textColor),
            onPressed: widget.onViewHistory,
          ),
        ],
      ),
      body: _isSubmitting
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : _brandColor),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Batch Selection dropdown
                    Text(
                      'Piliin ang Batch / Alagang Baboy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    widget.activeAssignments.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              'Walang aktibong batch na nakatalaga.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: mutedColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : DropdownButtonFormField<BigInt>(
                            initialValue: _selectedAssignmentId,
                            dropdownColor: surfaceBg,
                            isExpanded: true,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              fillColor: surfaceBg,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : _brandColor, width: 1.5),
                              ),
                            ),
                            items: widget.activeAssignments.map((a) {
                              final rawBatchName = a['batches']?['batch_name'] ?? 'Assignment #${a['assignment_id']}';
                              String displayBatchName = rawBatchName;
                              if (rawBatchName.contains(' (')) {
                                final parts = rawBatchName.split(' (');
                                if (parts.last.endsWith(')')) {
                                  displayBatchName = parts.sublist(0, parts.length - 1).join(' (');
                                }
                              }
                              final rawHogType = a['hog_types']?['type_name']?.toString() ??
                                  a['pig_type']?.toString() ??
                                  widget.raiserData['pig_type']?.toString() ??
                                  'Unassigned';
                              final hogType = (rawHogType.isEmpty || rawHogType == 'N/A' || rawHogType.toLowerCase() == 'unassigned')
                                  ? 'Unassigned'
                                  : rawHogType;
                              return DropdownMenuItem<BigInt>(
                                value: BigInt.from(a['assignment_id'] as num),
                                child: Text(
                                  '$displayBatchName ($hogType)',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedAssignmentId = val;
                                _assignmentError = null;
                              });
                            },
                          ),
                    if (_assignmentError != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFE53935)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _assignmentError!,
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Select Category Group
                    Text(
                      'Piliin ang Kategorya',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCategoryCard(
                          name: 'Feeds',
                          label: 'Feeds',
                          sublabel: 'Pagkain',
                          imagePath: 'assets/feeds_icon.png',
                          accentColor: const Color(0xFF10B981),
                          isSelected: _selectedCategory == 'Feeds',
                        ),
                        const SizedBox(width: 10),
                        _buildCategoryCard(
                          name: 'Medicine',
                          label: 'Medicine',
                          sublabel: 'Gamot',
                          imagePath: 'assets/medicine_icon.png',
                          accentColor: const Color(0xFFEF4444),
                          isSelected: _selectedCategory == 'Medicine',
                        ),
                        const SizedBox(width: 10),
                        _buildCategoryCard(
                          name: 'Vitamins',
                          label: 'Vitamins',
                          sublabel: 'Bitamina',
                          imagePath: 'assets/vitamins_icon.png',
                          accentColor: const Color(0xFF8B5CF6),
                          isSelected: _selectedCategory == 'Vitamins',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quantity Counter
                    Text(
                      'Dami (Sako / Piraso)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _quantityError != null ? const Color(0xFFE53935) : textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _quantityError != null
                            ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE))
                            : surfaceBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _quantityError != null ? const Color(0xFFE53935) : borderColor,
                          width: _quantityError != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_quantity > 0) {
                                setState(() {
                                  _quantity--;
                                  _quantityError = null;
                                });
                              }
                            },
                            icon: Icon(Icons.remove, color: textColor),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xfff7f8fb),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          Text(
                            _quantity.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _quantity++;
                                _quantityError = null;
                              });
                            },
                            icon: Icon(Icons.add, color: textColor),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xfff7f8fb),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_quantityError != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFE53935)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _quantityError!,
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Feeds Category Selection (only show if category is Feeds)
                    if (_selectedCategory == 'Feeds') ...[
                      Text(
                        'Uri ng Feeds',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildFeedChip('Booster'),
                          _buildFeedChip('Pre-Starter'),
                          _buildFeedChip('Starter'),
                          _buildFeedChip('Grower'),
                          _buildFeedChip('Finisher'),
                          _buildFeedChip('Lactation'),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Notes/Explanation field
                    Text(
                      'Karagdagang Impormasyon / Notes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [
                        SentenceCapitalizationFormatter(),
                      ],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ipaliwanag kung para saan ito...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: mutedColor,
                        ),
                        fillColor: surfaceBg,
                        filled: true,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : _brandColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Confirm Request Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: widget.activeAssignments.isEmpty ? null : _submitRequest,
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                        label: Text(
                          'Kumpirmahin ang Request',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PiggyTrunkTheme.ptSuccess,
                          disabledBackgroundColor: PiggyTrunkTheme.ptSuccess.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Auto-capitalizes the first letter of each sentence
class SentenceCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final text = newValue.text;
    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (capitalizeNext && RegExp(r'[a-zA-Z]').hasMatch(char)) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
        if (char == '.' || char == '?' || char == '!' || char == '\n') {
          capitalizeNext = true;
        } else if (char.trim().isNotEmpty) {
          capitalizeNext = false;
        }
      }
    }

    final newText = buffer.toString();
    return newValue.copyWith(
      text: newText,
      selection: newValue.selection,
    );
  }
}
