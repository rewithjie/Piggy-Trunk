import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piggytrunk/theme/app_theme.dart';

class RequestFormScreen extends StatefulWidget {
  final List<Map<String, dynamic>> activeAssignments;
  final Map<String, dynamic> raiserData;
  final VoidCallback onBack;
  final VoidCallback onSuccess;
  final VoidCallback onViewHistory;

  const RequestFormScreen({
    super.key,
    required this.activeAssignments,
    required this.raiserData,
    required this.onBack,
    required this.onSuccess,
    required this.onViewHistory,
  });

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  String _selectedCategory = 'Feeds';
  int _quantity = 0;
  String? _selectedFeedType = 'Booster';
  final TextEditingController _notesController = TextEditingController();
  BigInt? _selectedAssignmentId;
  bool _isSubmitting = false;

  String? _assignmentError;
  String? _quantityError;

  static const Color _brandColor = Color(0xFF18314F);

  @override
  void initState() {
    super.initState();
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Matagumpay na naipadala ang Stock Request!'),
            backgroundColor: PiggyTrunkTheme.ptSuccess,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: _brandColor,
          ),
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
    required String imagePath,
    required bool isSelected,
  }) {
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _brandColor : PiggyTrunkTheme.ptBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _brandColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _brandColor.withValues(alpha: 0.1)
                      : const Color(0xfff7f8fb),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                  color: isSelected ? _brandColor : const Color(0xffa0aec0),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? _brandColor : const Color(0xff5d6a7b),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedChip(String label) {
    final isSelected = _selectedFeedType == label;
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
          color: isSelected ? _brandColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _brandColor : PiggyTrunkTheme.ptBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xff5d6a7b),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PiggyTrunkTheme.ptBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _brandColor, size: 20),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Mag-request ng Supplies',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _brandColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: _brandColor),
            onPressed: widget.onViewHistory,
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
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
                        color: _brandColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    widget.activeAssignments.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: PiggyTrunkTheme.ptBorder),
                            ),
                            child: Text(
                              'Walang aktibong batch na nakatalaga.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: PiggyTrunkTheme.ptMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : DropdownButtonFormField<BigInt>(
                            initialValue: _selectedAssignmentId,
                            isExpanded: true,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: _brandColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: PiggyTrunkTheme.ptBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: PiggyTrunkTheme.ptBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _brandColor, width: 1.5),
                              ),
                            ),
                            items: widget.activeAssignments.map((a) {
                              final rawBatchName = a['batches']?['batch_name'] ?? 'Assignment #${a['assignment_id']}';
                              // Clean up the UUID suffix from the display batch name
                              String displayBatchName = rawBatchName;
                              if (rawBatchName.contains(' (')) {
                                final parts = rawBatchName.split(' (');
                                if (parts.last.endsWith(')')) {
                                  displayBatchName = parts.sublist(0, parts.length - 1).join(' (');
                                }
                              }
                              final hogType = a['hog_types']?['type_name'] ?? 'N/A';
                              return DropdownMenuItem<BigInt>(
                                value: BigInt.from(a['assignment_id'] as num),
                                child: Text(
                                  '$displayBatchName ($hogType)',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: _brandColor,
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
                        color: _brandColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCategoryCard(
                          name: 'Feeds',
                          label: 'Feeds (Pagkain)',
                          imagePath: 'assets/feeds_icon.png',
                          isSelected: _selectedCategory == 'Feeds',
                        ),
                        const SizedBox(width: 12),
                        _buildCategoryCard(
                          name: 'Vitamins',
                          label: 'Vitamins (Bitamina)',
                          imagePath: 'assets/vitamins_icon.png',
                          isSelected: _selectedCategory == 'Vitamins',
                        ),
                        const SizedBox(width: 12),
                        _buildCategoryCard(
                          name: 'Medicine',
                          label: 'Medicine (Gamot)',
                          imagePath: 'assets/medicine_icon.png',
                          isSelected: _selectedCategory == 'Medicine',
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
                        color: _quantityError != null ? const Color(0xFFE53935) : _brandColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _quantityError != null ? const Color(0xFFFFEBEE) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _quantityError != null ? const Color(0xFFE53935) : PiggyTrunkTheme.ptBorder,
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
                            icon: const Icon(Icons.remove, color: _brandColor),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xfff7f8fb),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          Text(
                            _quantity.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _brandColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _quantity++;
                                _quantityError = null;
                              });
                            },
                            icon: const Icon(Icons.add, color: _brandColor),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xfff7f8fb),
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
                          color: _brandColor,
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
                        color: _brandColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: _brandColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ipaliwanag kung para saan ito...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xffa0aec0),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: PiggyTrunkTheme.ptBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: PiggyTrunkTheme.ptBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _brandColor, width: 1.5),
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
