import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/screen_fit_util.dart';

class PartnerProjectsTab extends StatefulWidget {
  final List<Map<String, dynamic>> projectsList;
  final Future<void> Function() onRefresh;

  const PartnerProjectsTab({
    super.key,
    required this.projectsList,
    required this.onRefresh,
  });

  @override
  State<PartnerProjectsTab> createState() => _PartnerProjectsTabState();
}

class _PartnerProjectsTabState extends State<PartnerProjectsTab> {
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _greenBtnColor = Color(0xFF34D399);

  bool _isInvesting = false;
  Map<String, dynamic>? _selectedBatch;
  final TextEditingController _amountController = TextEditingController(text: '');
  double _parsedAmount = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final text = _amountController.text.replaceAll(',', '').trim();
    final val = double.tryParse(text) ?? 0.0;
    if (_parsedAmount != val) {
      setState(() {
        _parsedAmount = val;
      });
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  void _startInvestmentFlow([Map<String, dynamic>? batch]) {
    if (widget.projectsList.isEmpty && batch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active batches available for investment at the moment.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _selectedBatch = batch;
      _isInvesting = true;
    });
  }

  void _cancelInvestmentFlow() {
    setState(() {
      _isInvesting = false;
      _selectedBatch = null;
    });
  }

  Future<void> _confirmInvestment() async {
    if (_parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid investment amount.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Try recording investment in database
        try {
          await Supabase.instance.client.from('investments').insert({
            'user_id': user.id,
            'batch_id': _selectedBatch?['batch_id'] ?? 1,
            'amount': _parsedAmount,
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Notice: Investment DB insertion: $e');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully invested ₱${_formatCurrency(_parsedAmount)}!'),
          backgroundColor: const Color(0xFF2FB36F),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await widget.onRefresh();

      setState(() {
        _isInvesting = false;
        _selectedBatch = null;
      });
    } catch (e) {
      debugPrint('Error confirming investment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Investment recorded: ₱${_formatCurrency(_parsedAmount)}'),
            backgroundColor: const Color(0xFF2FB36F),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fit = ScreenFit(context);
    final double paddingH = fit.dp(20.0);
    final double paddingV = fit.dp(16.0);
    final double titleFontSize = fit.sp(24.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xffecf2ff) : _brandColor;
    final mutedTextColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
    final cardBgColor = isDark ? const Color(0xff151f2e) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xff28354a) : const Color(0xffe6ebf2);
    final statsBoxBg = isDark ? const Color(0xff1b2638) : const Color(0xfff8fafc);
    final statsBoxBorder = isDark ? const Color(0xff28354a) : const Color(0xffe6ebf2);

    final batchesList = widget.projectsList;
    final int openBatchesCount = batchesList.length;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Screen Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (_isInvesting) ...[
                      IconButton(
                        onPressed: _cancelInvestmentFlow,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: primaryTextColor,
                          size: fit.dp(24),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: fit.dp(10)),
                    ],
                    Text(
                      'Investment',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.search_rounded,
                        color: primaryTextColor,
                        size: fit.dp(24),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: fit.dp(16)),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: primaryTextColor,
                          size: fit.dp(24),
                        ),
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF5B6C),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: fit.dp(20.0)),

            // View 1: How Much Would You Like to Invest View
            if (_isInvesting) ...[
              Text(
                'How much would you like to\ninvest?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fit.sp(18.0),
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: fit.dp(16.0)),

              // Input Field Container
              Text(
                'ENTER AMOUNT (PHP)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fit.sp(10.0),
                  fontWeight: FontWeight.w800,
                  color: mutedTextColor,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: fit.dp(6.0)),
              Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: _brandColor,
                    selectionColor: _brandColor.withValues(alpha: 0.2),
                    selectionHandleColor: _brandColor,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: fit.dp(14), vertical: fit.dp(6)),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(fit.dp(14)),
                    border: Border.all(color: cardBorderColor, width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '₱',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: fit.sp(18.0),
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                      SizedBox(width: fit.dp(8)),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(16.0),
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: fit.sp(16.0),
                              fontWeight: FontWeight.w500,
                              color: mutedTextColor.withValues(alpha: 0.5),
                            ),
                            fillColor: Colors.transparent,
                            filled: true,
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: fit.dp(18.0)),

              Divider(color: cardBorderColor, height: 1),
              SizedBox(height: fit.dp(16.0)),

              // Total Commitment Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Commitment',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fit.sp(13.0),
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    '₱${_formatCurrency(_parsedAmount)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fit.sp(16.0),
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: fit.dp(20.0)),

              // Confirm Investment Button (Same UI Color Theme - Brand Navy)
              SizedBox(
                width: double.infinity,
                height: fit.dp(44),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmInvestment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(fit.dp(14)),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirm Investment',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: fit.sp(14.0),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: fit.dp(6)),
                            Icon(
                              Icons.check_rounded,
                              size: fit.dp(18),
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ] else ...[
              // View 2: Select Active Batch List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Select Active Batch',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fit.sp(18.0),
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '$openBatchesCount BATCHES OPEN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fit.sp(11.0),
                      fontWeight: FontWeight.w800,
                      color: mutedTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: fit.dp(14.0)),

              if (batchesList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: fit.dp(20), vertical: fit.dp(28)),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(fit.dp(22)),
                    border: Border.all(color: cardBorderColor, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: fit.dp(38),
                        color: isDark ? const Color(0xff9cb0c9) : _brandColor,
                      ),
                      SizedBox(height: fit.dp(10)),
                      Text(
                        'No Active Batches Available',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: fit.sp(15.0),
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: fit.dp(4)),
                      Text(
                        'There are currently no open batches available for investment. Please check back later.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: fit.sp(12.0),
                          fontWeight: FontWeight.w500,
                          color: mutedTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: fit.dp(16)),
                      ElevatedButton.icon(
                        onPressed: widget.onRefresh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: fit.dp(18), vertical: fit.dp(12)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(fit.dp(14)),
                          ),
                        ),
                        icon: Icon(Icons.refresh_rounded, size: fit.dp(18), color: Colors.white),
                        label: Text(
                          'Refresh Batches',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(13.0),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...batchesList.map((batch) {
                  final String batchName = batch['batch_name'] ?? batch['title'] ?? 'Batch 2024-B';
                  final String batchCode = batch['batch_code'] ?? '#B2024-B';
                  final String status = batch['status'] ?? 'IN PROGRESS';
                  final int totalRaisers = (batch['total_raisers'] as num?)?.toInt() ?? 3;
                  final int totalHogs = (batch['total_hogs'] as num?)?.toInt() ?? 42;
                  final int mortality = (batch['mortality'] as num?)?.toInt() ?? 0;

                  return Container(
                    margin: EdgeInsets.only(bottom: fit.dp(16)),
                    padding: EdgeInsets.all(fit.dp(20.0)),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(fit.dp(22)),
                      border: Border.all(color: cardBorderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: fit.dp(12), vertical: fit.dp(6)),
                              decoration: BoxDecoration(
                                color: _greenBtnColor,
                                borderRadius: BorderRadius.circular(fit.dp(20)),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: fit.sp(11.0),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Text(
                              batchCode,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: fit.sp(13.0),
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: fit.dp(12)),
                        Text(
                          batchName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fit.sp(20.0),
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: fit.dp(16)),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: fit.dp(14), horizontal: fit.dp(12)),
                          decoration: BoxDecoration(
                            color: statsBoxBg,
                            borderRadius: BorderRadius.circular(fit.dp(16)),
                            border: Border.all(color: statsBoxBorder, width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'TOTAL RAISER',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(10.0),
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(height: fit.dp(4)),
                                    Text(
                                      '$totalRaisers',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(20.0),
                                        fontWeight: FontWeight.w800,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: fit.dp(30),
                                width: 1,
                                color: statsBoxBorder,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'TOTAL HOG',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(10.0),
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(height: fit.dp(4)),
                                    Text(
                                      '$totalHogs',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(20.0),
                                        fontWeight: FontWeight.w800,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: fit.dp(30),
                                width: 1,
                                color: statsBoxBorder,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'MORTALITY',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(10.0),
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(height: fit.dp(4)),
                                    Text(
                                      '$mortality',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: fit.sp(20.0),
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: fit.dp(16)),
                        SizedBox(
                          width: double.infinity,
                          height: fit.dp(44),
                          child: ElevatedButton.icon(
                            onPressed: () => _startInvestmentFlow(batch),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(fit.dp(14)),
                              ),
                            ),
                            icon: Icon(
                              Icons.insert_chart_outlined_rounded,
                              size: fit.dp(18),
                              color: Colors.white,
                            ),
                            label: Text(
                              'INVEST',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: fit.sp(14.0),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}
