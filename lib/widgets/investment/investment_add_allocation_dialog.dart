import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/investment_model.dart';
import '../../utils/app_toast.dart';

class InvestmentAddAllocationDialog extends StatefulWidget {
  final Investment investment;
  final VoidCallback onSuccess;

  const InvestmentAddAllocationDialog({
    super.key,
    required this.investment,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required Investment investment,
    required VoidCallback onSuccess,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => InvestmentAddAllocationDialog(
          investment: investment,
          onSuccess: onSuccess,
        ),
      );
    }

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: InvestmentAddAllocationDialog(
            investment: investment,
            onSuccess: onSuccess,
          ),
        ),
      ),
    );
  }

  @override
  State<InvestmentAddAllocationDialog> createState() => _InvestmentAddAllocationDialogState();
}

class _InvestmentAddAllocationDialogState extends State<InvestmentAddAllocationDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;

  int _selectedTab = 0; // 0 = Stocks/Feeds, 1 = Capital/Heads
  bool _isSaving = false;

  // Stocks Form Controllers
  final TextEditingController _feedTypeCtrl = TextEditingController(text: 'Grower Feeds');
  final TextEditingController _qtyCtrl = TextEditingController(text: '5');
  final TextEditingController _unitPriceCtrl = TextEditingController(text: '1650');
  final TextEditingController _notesCtrl = TextEditingController();
  String _selectedCategory = 'Feeds';

  // Capital/Heads Form Controllers
  final TextEditingController _additionalCapitalCtrl = TextEditingController();
  final TextEditingController _additionalHeadsCtrl = TextEditingController();

  final List<String> _commonCategories = ['Feeds', 'Medicine', 'Supplies', 'Biologics'];
  final List<String> _quickFeeds = [
    'Starter Feeds',
    'Grower Feeds',
    'Finisher Feeds',
    'Booster Feeds',
    'Sow Feeds',
    'Vitamins & Minerals',
    'Iron Supplement',
    'Dewormer',
  ];

  @override
  void dispose() {
    _feedTypeCtrl.dispose();
    _qtyCtrl.dispose();
    _unitPriceCtrl.dispose();
    _notesCtrl.dispose();
    _additionalCapitalCtrl.dispose();
    _additionalHeadsCtrl.dispose();
    super.dispose();
  }

  double get _calculatedTotalStocks {
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    final price = double.tryParse(_unitPriceCtrl.text.trim()) ?? 0.0;
    return qty * price;
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(0);
    final formatted = parts.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₱$formatted';
  }

  Future<void> _submitStocksAllocation() async {
    final feedType = _feedTypeCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final unitPrice = double.tryParse(_unitPriceCtrl.text.trim()) ?? 0.0;

    if (feedType.isEmpty) {
      AppToast.error(context, 'Please specify the item or feed name.');
      return;
    }
    if (qty <= 0) {
      AppToast.error(context, 'Quantity must be at least 1 unit.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final nowStr = DateTime.now().toIso8601String();
      final payload = <String, dynamic>{
        'hog_raiser_id': widget.investment.hogRaiserId,
        'category': _selectedCategory,
        'feed_type': feedType,
        'quantity': qty,
        'status': 'approved',
        'request_date': nowStr,
        'decision_date': nowStr,
        'notes': _notesCtrl.text.trim().isNotEmpty
            ? _notesCtrl.text.trim()
            : 'Direct allocation added via Admin Investment Management',
      };

      // Link assignment_id if available
      try {
        final assignRes = await _supabase
            .from('assignments')
            .select('assignment_id')
            .eq('hog_raiser_id', widget.investment.hogRaiserId)
            .limit(1);
        if (assignRes.isNotEmpty) {
          payload['assignment_id'] = assignRes.first['assignment_id'];
        }
      } catch (_) {}

      await _supabase.from('stock_requests').insert(payload);

      // Also record inventory log if inventory_logs exists
      try {
        await _supabase.from('inventory_logs').insert({
          'action': 'Allocated to Raiser',
          'product_name': feedType,
          'category': _selectedCategory,
          'quantity': qty,
          'unit_price': unitPrice,
          'total_amount': qty * unitPrice,
          'notes': 'Allocated to raiser: ${widget.investment.raiserName}',
          'created_at': nowStr,
        });
      } catch (_) {}

      if (!mounted) return;
      AppToast.success(context, 'Stock allocation of $qty units added successfully!');
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to add stock allocation: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitCapitalTopUp() async {
    final addCapital = double.tryParse(_additionalCapitalCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
    final addHeads = int.tryParse(_additionalHeadsCtrl.text.trim()) ?? 0;

    if (addCapital <= 0 && addHeads <= 0) {
      AppToast.error(context, 'Please enter additional capital amount or additional heads count.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final newCapital = widget.investment.initialCapital + addCapital;
      final newTotalHog = widget.investment.totalHog + addHeads;

      final updatePayload = <String, dynamic>{};
      if (addCapital > 0) updatePayload['initial_capital'] = newCapital;
      if (addHeads > 0) updatePayload['total_hog'] = newTotalHog;

      await _supabase.from('investment_records').update(updatePayload).eq('id', widget.investment.id);

      if (!mounted) return;
      AppToast.success(context, 'Investment allocation updated successfully!');
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to update capital: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
    final titleColor = isDark ? Colors.white : const Color(0xFF18314F);
    final fieldBg = isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
    final fieldBorder = isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC);
    final fieldText = isDark ? Colors.white : const Color(0xFF18314F);
    final hintText = isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 18,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Allocation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.investment.raiserName} • ${widget.investment.batchName ?? "Unassigned"}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hintText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: hintText, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          Divider(color: cardBorder.withValues(alpha: 0.6), height: 1),

          // Tab Selector: Stocks Allocation vs Capital/Heads Top-up
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16253B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF28405D) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSubTab(
                      label: 'Feeds & Supplies',
                      icon: Icons.inventory_2_outlined,
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildSubTab(
                      label: 'Capital & Heads',
                      icon: Icons.monetization_on_outlined,
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _selectedTab == 0
                  ? _buildStocksTab(isDark, fieldBg, fieldBorder, fieldText, hintText, titleColor)
                  : _buildCapitalTab(isDark, fieldBg, fieldBorder, fieldText, hintText, titleColor),
            ),
          ),

          // Footer
          Divider(color: cardBorder.withValues(alpha: 0.6), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hintText,
                    side: BorderSide(color: fieldBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : (_selectedTab == 0 ? _submitStocksAllocation : _submitCapitalTopUp),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    _selectedTab == 0 ? 'Allocate Stock' : 'Update Investment',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF243B5B) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF18314F))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStocksTab(
    bool isDark,
    Color fieldBg,
    Color fieldBorder,
    Color fieldText,
    Color hintText,
    Color titleColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Selector Chips
        Text(
          'Category',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: hintText),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _commonCategories.map((cat) {
            final isSel = _selectedCategory == cat;
            return InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF8B5CF6) : fieldBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSel ? const Color(0xFF8B5CF6) : fieldBorder,
                  ),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel ? Colors.white : fieldText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Quick Preset Suggestions
        Text(
          'Quick Selection',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: hintText),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _quickFeeds.map((feed) {
            final isSel = _feedTypeCtrl.text.trim() == feed;
            return InkWell(
              onTap: () => setState(() => _feedTypeCtrl.text = feed),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSel
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                      : fieldBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSel ? const Color(0xFF8B5CF6) : fieldBorder.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  feed,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel ? const Color(0xFF8B5CF6) : hintText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Item / Feed Name Field
        Text(
          'Item / Product Name *',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: hintText),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _feedTypeCtrl,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: fieldText, fontWeight: FontWeight.w600),
          decoration: _inputDecoration('e.g. Grower Feeds, Vitamins', fieldBg, fieldBorder, hintText),
        ),
        const SizedBox(height: 12),

        // Quantity & Unit Price in 2 columns
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantity (units/sacks) *',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: hintText),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: fieldText, fontWeight: FontWeight.w700),
                    decoration: _inputDecoration('Qty', fieldBg, fieldBorder, hintText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unit Price (₱)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: hintText),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _unitPriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: fieldText, fontWeight: FontWeight.w700),
                    decoration: _inputDecoration('Unit Price', fieldBg, fieldBorder, hintText, prefixText: '₱ '),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Total Stocks Spend Summary Callout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Spend Value:',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: hintText),
              ),
              Text(
                _formatCurrency(_calculatedTotalStocks),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Notes
        Text(
          'Notes (Optional)',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: hintText),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: fieldText),
          decoration: _inputDecoration('e.g. Batch week 4 feed replenishment', fieldBg, fieldBorder, hintText),
        ),
      ],
    );
  }

  Widget _buildCapitalTab(
    bool isDark,
    Color fieldBg,
    Color fieldBorder,
    Color fieldText,
    Color hintText,
    Color titleColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Allocation Status Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16253B) : const Color(0xFFF1F6FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT CAPITAL', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: hintText)),
                    const SizedBox(height: 2),
                    Text(_formatCurrency(widget.investment.initialCapital), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF43CB89))),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: fieldBorder),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT HEADS', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: hintText)),
                    const SizedBox(height: 2),
                    Text('${widget.investment.totalHog} heads', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: titleColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Additional Capital Field
        Text(
          'Add Capital (₱)',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: hintText),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _additionalCapitalCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: fieldText, fontWeight: FontWeight.w700),
          decoration: _inputDecoration('e.g. 5000', fieldBg, fieldBorder, hintText, prefixText: '₱ '),
        ),
        const SizedBox(height: 14),

        // Additional Heads Field
        Text(
          'Add Heads Count (Optional)',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: hintText),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _additionalHeadsCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: fieldText, fontWeight: FontWeight.w700),
          decoration: _inputDecoration('e.g. 2', fieldBg, fieldBorder, hintText, suffixText: 'heads'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    Color bg,
    Color border,
    Color hintColor, {
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: hintColor),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
      suffixText: suffixText,
      suffixStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
      ),
    );
  }
}
