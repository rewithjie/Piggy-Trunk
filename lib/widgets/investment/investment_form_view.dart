import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/investment_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class InvestmentFormView extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSaved;
  final Investment? existingInvestment;
  final void Function(String msg, {bool isError}) onShowSnackBar;

  const InvestmentFormView({
    super.key,
    required this.onCancel,
    required this.onSaved,
    this.existingInvestment,
    required this.onShowSnackBar,
  });

  @override
  State<InvestmentFormView> createState() => _InvestmentFormViewState();
}

class _InvestmentFormViewState extends State<InvestmentFormView> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late final TextEditingController _capitalCtrl;
  late final TextEditingController _totalHogCtrl;

  String? _selectedRaiserId;
  String? _selectedBatchId;
  List<String> _selectedHogTypes = ['Fattening'];

  List<Map<String, dynamic>> _activeBatches = [];
  List<Map<String, dynamic>> _activeRaisers = [];
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  String? _capitalError;
  String? _totalHogError;

  bool get _isEdit => widget.existingInvestment != null;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _mutedColor => _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
  Color get _fieldText => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _fieldBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC);
  Color get _fieldFocus => _isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);

  @override
  void initState() {
    super.initState();
    _capitalCtrl = TextEditingController(
      text: _isEdit ? widget.existingInvestment!.initialCapital.toInt().toString() : '',
    );
    _totalHogCtrl = TextEditingController(
      text: _isEdit ? widget.existingInvestment!.totalHog.toString() : '',
    );

    _selectedRaiserId = _isEdit
        ? (widget.existingInvestment!.hogRaiserId.isEmpty
            ? 'unassigned'
            : widget.existingInvestment!.hogRaiserId)
        : 'unassigned';

    if (_isEdit && widget.existingInvestment!.hogType.isNotEmpty) {
      final types = widget.existingInvestment!.hogType
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (types.isNotEmpty) _selectedHogTypes = types;
    }

    _selectedBatchId = 'unassigned';
    _fetchDropdownData();
  }

  @override
  void dispose() {
    _capitalCtrl.dispose();
    _totalHogCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final raisersRes = await _supabase
          .from('hog_raisers')
          .select('hog_raiser_id, name, pig_type, status, account_status, app_users!hog_raisers_user_id_fkey(name, email)')
          .order('name', ascending: true);

      final List<Map<String, dynamic>> parsedRaisers = [];
      for (var r in (raisersRes as List)) {
        final rMap = Map<String, dynamic>.from(r as Map);
        final accStatus = (rMap['account_status'] ?? '').toString().toLowerCase();
        if (accStatus == 'rejected' || accStatus == 'pending') continue;

        final appUsers = rMap['app_users'] as Map<String, dynamic>?;
        final googleOrAppName = (appUsers?['name'] ?? '').toString().trim();
        final raiserName = (rMap['name'] ?? '').toString().trim();
        final resolvedFullName = googleOrAppName.isNotEmpty && googleOrAppName.toLowerCase() != 'hog raiser'
            ? googleOrAppName
            : (raiserName.isNotEmpty ? raiserName : 'Hog Raiser');

        final idStr = (rMap['id'] ?? rMap['hog_raiser_id'] ?? '').toString();
        if (idStr.isEmpty) continue;

        parsedRaisers.add({
          'id': idStr,
          'name': resolvedFullName,
          'pig_type': rMap['pig_type'] ?? 'Fattening',
          'real_pk_col': rMap['id'] != null ? 'id' : 'hog_raiser_id',
        });
      }

      _activeRaisers = [
        {'id': 'unassigned', 'name': 'Unassigned (General Pool)'},
        ...parsedRaisers,
      ];

      final batchesRes = await _supabase
          .from('batches')
          .select('batch_id, batch_name, date_created, assignments(assignment_id, hog_raiser_id, status, hog_raisers(name, pig_type, hog_raiser_id, app_users!hog_raisers_user_id_fkey(name)), hogs(hog_id))')
          .order('date_created', ascending: false);

      final List<Map<String, dynamic>> parsedBatches = [];
      for (var b in (batchesRes as List)) {
        final bMap = Map<String, dynamic>.from(b as Map);
        final bId = bMap['batch_id']?.toString() ?? '';
        final bName = bMap['batch_name']?.toString() ?? 'Batch $bId';

        final assigns = bMap['assignments'] as List<dynamic>? ?? [];
        final activeAssign = assigns.firstWhere(
          (a) => (a['status'] ?? '').toString().toLowerCase() == 'active',
          orElse: () => assigns.isNotEmpty ? assigns.first : null,
        );

        String raiserId = '';
        String raiserName = 'Unassigned';
        String pigType = 'Fattening';
        int hogCount = 0;

        if (activeAssign != null) {
          final raiser = activeAssign['hog_raisers'] as Map<String, dynamic>?;
          raiserId = (activeAssign['hog_raiser_id'] ?? raiser?['hog_raiser_id'] ?? '').toString();
          if (raiser != null) {
            final appUsers = raiser['app_users'] as Map<String, dynamic>?;
            final appName = appUsers?['name']?.toString().trim();
            final rName = raiser['name']?.toString().trim();
            raiserName = (appName != null && appName.isNotEmpty && appName.toLowerCase() != 'hog raiser')
                ? appName
                : (rName != null && rName.isNotEmpty ? rName : 'Hog Raiser');
            pigType = raiser['pig_type']?.toString() ?? 'Fattening';
          }
          final hogs = activeAssign['hogs'] as List<dynamic>? ?? [];
          hogCount = hogs.length;
        }

        parsedBatches.add({
          'batch_id': bId,
          'batch_name': bName,
          'display_label': activeAssign != null
              ? '$bName • $raiserName ($hogCount heads)'
              : '$bName • Pool ($hogCount heads)',
          'raiser_id': raiserId,
          'raiser_name': raiserName,
          'pig_type': pigType,
          'hog_count': hogCount,
        });
      }

      _activeBatches = [
        {
          'batch_id': 'unassigned',
          'batch_name': 'No Specific Batch (General Pool)',
          'display_label': 'General Investment Pool (No Batch Assigned)',
          'raiser_id': '',
          'raiser_name': 'Unassigned',
          'pig_type': 'Fattening',
          'hog_count': 0,
        },
        ...parsedBatches,
      ];

      if (!_isEdit) {
        _selectedBatchId = _activeBatches.length > 1 ? _activeBatches[1]['batch_id'] : 'unassigned';
        if (_selectedBatchId != null && _selectedBatchId != 'unassigned') {
          final matched = _activeBatches.firstWhere(
            (b) => b['batch_id'] == _selectedBatchId,
            orElse: () => {},
          );
          _selectedRaiserId = (matched['raiser_id'] ?? '').toString();
          final count = matched['hog_count'];
          if (count != null && count > 0) _totalHogCtrl.text = count.toString();
          final pt = (matched['pig_type'] ?? 'Fattening').toString();
          if (pt.isNotEmpty) _selectedHogTypes = [pt];
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingData = false);
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    final parsedCapital = int.tryParse(_capitalCtrl.text.trim());
    final parsedTotalHog = int.tryParse(_totalHogCtrl.text.trim());

    if (parsedCapital == null || parsedCapital <= 0) {
      setState(() => _capitalError = 'Please enter a valid capital greater than ₱0.');
      return;
    }
    if (parsedTotalHog == null || parsedTotalHog <= 0) {
      setState(() => _totalHogError = 'Please enter total number of heads (min 1).');
      return;
    }

    setState(() {
      _capitalError = null;
      _totalHogError = null;
      _isSubmitting = true;
    });

    try {
      final isUnassigned = _selectedRaiserId == 'unassigned' || _selectedRaiserId == null || _selectedRaiserId!.isEmpty;
      final raiserName = isUnassigned
          ? 'Unassigned'
          : (_activeRaisers.firstWhere(
              (r) => r['id'].toString() == _selectedRaiserId,
              orElse: () => {'name': ''},
            )['name'] ?? 'Unassigned');

      final hogTypeStr = _selectedHogTypes.join(', ');
      final payload = {
        'hog_raiser_id': isUnassigned ? '' : _selectedRaiserId,
        'raiser_name': raiserName,
        'initial_capital': parsedCapital,
        'hog_type': hogTypeStr,
        'total_hog': parsedTotalHog,
        'investment_date': _isEdit
            ? widget.existingInvestment!.investmentDate.toIso8601String()
            : DateTime.now().toIso8601String(),
        if (!_isEdit) 'stage': 'active',
      };

      if (_isEdit) {
        await _supabase.from('investment_records').update(payload).eq('id', widget.existingInvestment!.id);
      } else {
        await _supabase.from('investment_records').insert(payload);
      }

      if (!isUnassigned && int.tryParse(_selectedRaiserId!) != null) {
        final parsedRaiserId = int.parse(_selectedRaiserId!);
        final raiserRow = _activeRaisers.firstWhere(
          (r) => r['id'].toString() == _selectedRaiserId,
          orElse: () => {},
        );
        final pkCol = raiserRow['real_pk_col'] ?? (raiserRow['id'] != null ? 'id' : 'hog_raiser_id');
        await _supabase
            .from('hog_raisers')
            .update({
              'lifecycle_stage': 'Booster',
              'pig_type': hogTypeStr,
            })
            .eq(pkCol, parsedRaiserId);
      }

      if (!mounted) return;
      widget.onShowSnackBar(_isEdit ? 'Investment updated successfully.' : 'Investment created successfully.');
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      widget.onShowSnackBar('Operation failed: $e', isError: true);
    }
  }

  Widget _buildCheckbox({
    required String title,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: onChanged,
              activeColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
              checkColor: _isDark ? const Color(0xFF132238) : Colors.white,
              side: BorderSide(
                color: _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _isDark ? Colors.white : const Color(0xFF18314F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (_isLoadingData) {
      return Center(
        child: CircularProgressIndicator(
          color: _isDark ? const Color(0xFF60A5FA) : PiggyTrunkTheme.ptPrimary,
        ),
      );
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
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
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Investment' : 'Add New Investment',
                          style: GoogleFonts.plusJakartaSans(
                            color: _titleColor,
                            fontSize: isMobile ? 22 : 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEdit
                              ? 'Update investment details and capital allocation.'
                              : 'Assign capital to an active farm batch or general pool.',
                          style: GoogleFonts.plusJakartaSans(
                            color: _mutedColor,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: Icon(Icons.close_rounded, color: _titleColor, size: isMobile ? 24 : 28),
                    tooltip: 'Back to investments',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Card Container
              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                  border: Border.all(color: _cardBorder),
                ),
                padding: EdgeInsets.all(isMobile ? 16 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Select Batch to Fund
                    Text(
                      'SELECT BATCH TO FUND *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBatchId,
                      isExpanded: true,
                      hint: Text(
                        'Select a batch to fund',
                        style: GoogleFonts.plusJakartaSans(
                          color: _mutedColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _fieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _fieldFocus, width: 1.5),
                        ),
                      ),
                      dropdownColor: _fieldBg,
                      style: GoogleFonts.plusJakartaSans(
                        color: _fieldText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      items: _activeBatches.map((b) {
                        final isUnassigned = b['batch_id'] == 'unassigned';
                        return DropdownMenuItem<String>(
                          value: b['batch_id'].toString(),
                          child: Row(
                            children: [
                              Icon(
                                isUnassigned ? Icons.layers_clear_outlined : Icons.layers_outlined,
                                size: 16,
                                color: isUnassigned
                                    ? _mutedColor
                                    : (_isDark ? Colors.white : PiggyTrunkTheme.ptPrimary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  b['display_label'].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isUnassigned ? _mutedColor : _fieldText,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedBatchId = val;
                          if (val != 'unassigned') {
                            final matched = _activeBatches.firstWhere(
                              (b) => b['batch_id'] == val,
                              orElse: () => {},
                            );
                            _selectedRaiserId = (matched['raiser_id'] ?? '').toString();
                            final count = matched['hog_count'];
                            if (count != null && count > 0) _totalHogCtrl.text = count.toString();
                            final pt = (matched['pig_type'] ?? 'Fattening').toString();
                            if (pt.isNotEmpty) _selectedHogTypes = [pt];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 22),

                    // Initial Capital
                    Text(
                      'INITIAL CAPITAL (PHP) *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _capitalCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) {
                        if (_capitalError != null) setState(() => _capitalError = null);
                      },
                      style: GoogleFonts.plusJakartaSans(
                        color: _fieldText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.plusJakartaSans(color: _mutedColor, fontSize: 14),
                        prefixIcon: Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '₱',
                            style: GoogleFonts.plusJakartaSans(
                              color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: _fieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _capitalError != null ? const Color(0xFFE53E3E) : _fieldBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _capitalError != null ? const Color(0xFFE53E3E) : _fieldFocus,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (_capitalError != null) ...[
                      const SizedBox(height: 4),
                      Text(_capitalError!, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 11.5)),
                    ],
                    const SizedBox(height: 22),

                    // Total Heads
                    Text(
                      'TOTAL HEADS *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _totalHogCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) {
                        if (_totalHogError != null) setState(() => _totalHogError = null);
                      },
                      style: GoogleFonts.plusJakartaSans(
                        color: _fieldText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.plusJakartaSans(color: _mutedColor, fontSize: 14),
                        filled: true,
                        fillColor: _fieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _totalHogError != null ? const Color(0xFFE53E3E) : _fieldBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _totalHogError != null ? const Color(0xFFE53E3E) : _fieldFocus,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (_totalHogError != null) ...[
                      const SizedBox(height: 4),
                      Text(_totalHogError!, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 11.5)),
                    ],
                    const SizedBox(height: 22),

                    // Hog Types
                    Text(
                      'HOG TYPE *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _mutedColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCheckbox(
                          title: 'Fattening',
                          isSelected: _selectedHogTypes.contains('Fattening'),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                if (!_selectedHogTypes.contains('Fattening')) _selectedHogTypes.add('Fattening');
                              } else {
                                if (_selectedHogTypes.length > 1) _selectedHogTypes.remove('Fattening');
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCheckbox(
                          title: 'Sow / Breeding',
                          isSelected: _selectedHogTypes.contains('Sow / Breeding'),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                if (!_selectedHogTypes.contains('Sow / Breeding')) _selectedHogTypes.add('Sow / Breeding');
                              } else {
                                if (_selectedHogTypes.length > 1) _selectedHogTypes.remove('Sow / Breeding');
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Responsive Action Buttons
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitForm,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                          label: Text(
                            _isSubmitting ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Save Investment'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                            foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _isSubmitting ? null : widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: _fieldBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              color: _fieldText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isSubmitting ? null : widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            side: BorderSide(color: _fieldBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              color: _fieldText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitForm,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                          label: Text(
                            _isSubmitting ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Save Investment'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                            foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
