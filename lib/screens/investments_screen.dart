import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/investment_model.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';
import '../utils/responsive.dart';
import '../main.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Investment> investments = [];
  bool _isLoading = true;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _headerText => _isDark ? const Color(0xFF9EC0E8) : const Color(0xFF4B6281);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
  Color get _fieldBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC);
  Color get _fieldFocus => _isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);
  Color get _fieldText => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _hintText => _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
  Color get _successDark => _isDark ? PiggyTrunkTheme.ptSuccessDark : PiggyTrunkTheme.ptSuccess;
  Color get _inProgressDark => _isDark ? PiggyTrunkTheme.ptInProgressDark : PiggyTrunkTheme.ptInProgress;
  Color get _mutedDark => _isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

  InputDecoration _createInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: _hintText, fontSize: 14, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: _fieldBg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _fieldFocus),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    setState(() => _isLoading = true);
    try {
      // Auto-migrate: convert any old pending investments to active in the database
      try {
        await _supabase
            .from('investment_records')
            .update({'stage': 'active'})
            .eq('stage', 'pending');
      } catch (_) {
        // Ignore silent migration failures (e.g. offline/network)
      }

      final response = await _supabase
          .from('investment_records')
          .select()
          .order('investment_date', ascending: false);

      final rows = (response as List)
          .map((row) => Investment.fromJson(row as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() => investments = rows);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load investments: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  String _formatDateForDisplay(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Select date';
    }
  }

  String _formatCurrency(double amount) {
    final String fixed = amount.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String integerPart = parts[0];
    final String decimalPart = parts[1];
    
    final String formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    return '₱$formattedInteger.$decimalPart';
  }
  bool _showForm = false;
  Investment? _editingInvestment;
  final TextEditingController _capitalCtrl = TextEditingController();
  final TextEditingController _totalHogCtrl = TextEditingController();
  List<String> _selectedHogTypes = ['Fattening'];
  String? _selectedRaiserId = 'unassigned';
  List<Map<String, dynamic>> _activeRaisers = [];

  Future<void> _openInlineForm({Investment? existing}) async {
    _capitalCtrl.text = existing != null ? existing.initialCapital.toInt().toString() : '';
    _totalHogCtrl.text = existing != null ? existing.totalHog.toString() : '';

    if (existing != null && existing.hogType.isNotEmpty && existing.hogType != 'Auto-populated' && existing.hogType != 'N/A') {
      _selectedHogTypes = existing.hogType.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (_selectedHogTypes.isEmpty) _selectedHogTypes = ['Fattening'];
    } else {
      _selectedHogTypes = ['Fattening'];
    }

    _editingInvestment = existing;

    try {
      final response = await _supabase
          .from('hog_raisers')
          .select('hog_raiser_id, name, pig_type')
          .eq('status', 'Active')
          .order('name', ascending: true);

      final activeRows = (response as List).cast<Map<String, dynamic>>().map((r) {
        return {
          ...r,
          'id': (r['id'] ?? r['hog_raiser_id'] ?? '').toString(),
          'real_pk_col': r['id'] != null ? 'id' : 'hog_raiser_id',
        };
      }).toList();

      _activeRaisers = [
        {
          'id': 'unassigned',
          'name': 'Unassigned (Create Batch First)',
        },
        ...activeRows,
      ];

      if (existing == null) {
        _selectedRaiserId = 'unassigned';
      } else {
        _selectedRaiserId = (existing.hogRaiserId.isEmpty || existing.hogRaiserId == 'unassigned' || existing.raiserName.toLowerCase() == 'unassigned')
            ? 'unassigned'
            : existing.hogRaiserId;
      }
    } catch (_) {
      _activeRaisers = [
        {'id': 'unassigned', 'name': 'Unassigned (Create Batch First)'}
      ];
      _selectedRaiserId = 'unassigned';
    }

    if (!mounted) return;
    setState(() {
      _showForm = true;
    });
  }

  Widget _buildAddInvestmentView() {
    final isEdit = _editingInvestment != null;

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
              constraints: const BoxConstraints(maxWidth: 850),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF12213A) : Colors.white,
                border: Border.all(color: _cardBorder, width: 1),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.fromLTRB(40, 34, 40, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Investment' : 'Create Investment',
                        style: GoogleFonts.plusJakartaSans(
                          color: _titleColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.04,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showForm = false),
                        icon: Icon(Icons.close_rounded, color: _headerText, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 1. HOG RAISER
                  Text(
                    'HOG RAISER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _headerText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  (isEdit && _editingInvestment!.hogRaiserId.isNotEmpty && _editingInvestment!.hogRaiserId != 'unassigned' && _editingInvestment!.raiserName.toLowerCase() != 'unassigned')
                      ? Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _fieldBg.withValues(alpha: 0.5),
                            border: Border.all(color: _fieldBorder.withValues(alpha: 0.5), width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text(
                            _editingInvestment!.raiserName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _fieldText,
                            ),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: _selectedRaiserId,
                          decoration: _createInputDecoration('Select an authorized raiser'),
                          isExpanded: true,
                          menuMaxHeight: 260,
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: _fieldBg,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _hintText),
                          style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14, fontWeight: FontWeight.w500),
                          items: _activeRaisers
                              .map((raiser) => DropdownMenuItem<String>(
                                    value: raiser['id'].toString(),
                                    child: Text(
                                      (raiser['name'] ?? '').toString(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _fieldText,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRaiserId = value;
                            });
                          },
                        ),
                  const SizedBox(height: 24),

                  // 2. INITIAL CAPITAL & TOTAL HOG (2-Column Row)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INITIAL CAPITAL FIELD WITH ₱ PREFIX BOX
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INITIAL CAPITAL (PHP)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _headerText,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _capitalCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: GoogleFonts.plusJakartaSans(
                                color: _fieldText,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: _createInputDecoration('0.00').copyWith(
                                prefixIcon: Container(
                                  width: 48,
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.15),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                    ),
                                    border: Border(
                                      right: BorderSide(color: _fieldBorder),
                                    ),
                                  ),
                                  child: Text(
                                    '₱',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: PiggyTrunkTheme.ptPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // TOTAL HOG FIELD WITH HEADS SUFFIX BADGE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL HOG (HEADS)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _headerText,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _totalHogCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: GoogleFonts.plusJakartaSans(
                                color: _fieldText,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: _createInputDecoration('0').copyWith(
                                suffixIcon: Container(
                                  width: 72,
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(left: 12),
                                  decoration: BoxDecoration(
                                    color: _isDark ? const Color(0xFF1E2F47) : const Color(0xFFEEF4FD),
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    border: Border(
                                      left: BorderSide(color: _fieldBorder),
                                    ),
                                  ),
                                  child: Text(
                                    'Heads',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: _fieldText,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                suffixIconConstraints: const BoxConstraints(minWidth: 72, minHeight: 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. HOG TYPE ASSIGNMENT (CHECKBOXES)
                  Text(
                    'HOG TYPE ASSIGNMENT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _headerText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (_selectedHogTypes.contains('Fattening')) {
                                if (_selectedHogTypes.length > 1) _selectedHogTypes.remove('Fattening');
                              } else {
                                _selectedHogTypes.add('Fattening');
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: _fieldBg,
                              border: Border.all(
                                color: _selectedHogTypes.contains('Fattening') ? PiggyTrunkTheme.ptPrimary : _fieldBorder,
                                width: _selectedHogTypes.contains('Fattening') ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedHogTypes.contains('Fattening') ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  color: _selectedHogTypes.contains('Fattening') ? PiggyTrunkTheme.ptPrimary : _hintText,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Fattening',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: _selectedHogTypes.contains('Fattening') ? FontWeight.w700 : FontWeight.w500,
                                    color: _fieldText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (_selectedHogTypes.contains('Sow / Breeding')) {
                                if (_selectedHogTypes.length > 1) _selectedHogTypes.remove('Sow / Breeding');
                              } else {
                                _selectedHogTypes.add('Sow / Breeding');
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: _fieldBg,
                              border: Border.all(
                                color: _selectedHogTypes.contains('Sow / Breeding') ? PiggyTrunkTheme.ptPrimary : _fieldBorder,
                                width: _selectedHogTypes.contains('Sow / Breeding') ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedHogTypes.contains('Sow / Breeding') ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  color: _selectedHogTypes.contains('Sow / Breeding') ? PiggyTrunkTheme.ptPrimary : _hintText,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Sow / Breeding',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: _selectedHogTypes.contains('Sow / Breeding') ? FontWeight.w700 : FontWeight.w500,
                                    color: _fieldText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // 4. ACTION BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() => _showForm = false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        onPressed: _saveInlineInvestment,
                        icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                        label: Text(
                          isEdit ? 'Save Changes' : 'Create Investment',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PiggyTrunkTheme.ptPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
        ),
      ),
    );
  }

  Future<void> _saveInlineInvestment() async {
    final parsedCapital = int.tryParse(_capitalCtrl.text.trim());
    final parsedTotalHog = int.tryParse(_totalHogCtrl.text.trim());

    if (_selectedRaiserId == null ||
        parsedCapital == null ||
        parsedTotalHog == null ||
        _selectedHogTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields correctly and select at least one Hog Type.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isUnassigned = _selectedRaiserId == 'unassigned';
    final raiserName = isUnassigned
        ? 'Unassigned'
        : (_activeRaisers.firstWhere(
            (r) => r['id'].toString() == _selectedRaiserId,
            orElse: () => {'name': ''},
          )['name'] ?? 'Unassigned');

    final hogTypeStr = _selectedHogTypes.join(', ');
    final isEdit = _editingInvestment != null;

    final payload = {
      'hog_raiser_id': isUnassigned ? '' : _selectedRaiserId,
      'raiser_name': raiserName,
      'initial_capital': parsedCapital,
      'hog_type': hogTypeStr,
      'total_hog': parsedTotalHog,
      'investment_date': isEdit ? _editingInvestment!.investmentDate.toIso8601String() : DateTime.now().toIso8601String(),
      if (!isEdit) 'stage': 'active',
    };

    try {
      if (isEdit) {
        await _supabase.from('investment_records').update(payload).eq('id', _editingInvestment!.id);
      } else {
        await _supabase.from('investment_records').insert(payload);
      }

      if (!isUnassigned && int.tryParse(_selectedRaiserId!) != null) {
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
            .eq(pkCol, int.parse(_selectedRaiserId!));
      }

      setState(() {
        _showForm = false;
        _editingInvestment = null;
      });

      await _loadInvestments();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Investment updated successfully.' : 'Investment batch added successfully.',
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
            'Save failed: $e',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteInvestment(Investment investment) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'Delete Investment',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Delete investment for ${investment.raiserName}?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Cancel',
              style: AppTextStyles.button(isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF758C),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: AppTextStyles.button(Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Delete the investment record
      await _supabase.from('investment_records').delete().eq('id', investment.id);

      // 2. Reset the corresponding raiser's lifecycle_stage back to null in hog_raisers table
      final raiserIdStr = investment.hogRaiserId;
      final raiserId = int.tryParse(raiserIdStr);
      if (raiserId != null) {
        final raiserCheck = await _supabase
            .from('hog_raisers')
            .select('hog_raiser_id')
            .eq('hog_raiser_id', raiserId)
            .maybeSingle();

        if (raiserCheck != null) {
          final pkVal = raiserCheck['hog_raiser_id'];
          await _supabase
              .from('hog_raisers')
              .update({'lifecycle_stage': null})
              .eq('hog_raiser_id', pkVal);
        }
      }

      await _loadInvestments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Investment deleted successfully.',
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
            'Delete failed: $e',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmallScreen(context);

    return Scaffold(
      backgroundColor: _bgDark,
      drawer: isSmall
          ? Drawer(
              backgroundColor: _cardBg,
              child: AdminSidebar(
                currentRoute: '/investments',
                onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmall)
            AdminSidebar(
              currentRoute: '/investments',
              onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
            ),
          Expanded(
            child: Column(
              children: [
                const ScreenTopBar(),
                Expanded(child: _buildMainState(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainState(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showForm) {
      return _buildAddInvestmentView();
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
              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  border: Border.all(color: _cardBorder, width: 1),
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
                ),
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Investment Management',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _titleColor,
                              letterSpacing: -0.04,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _openInlineForm(),
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: Text(
                                'Add Investment',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: _primaryWhiteButtonStyle(minWidth: 0),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Investment Management',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: _titleColor,
                              letterSpacing: -0.04,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openInlineForm(),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(
                              'Add Investment',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: _primaryWhiteButtonStyle(minWidth: 180),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final tableWidth = constraints.maxWidth > 950 ? constraints.maxWidth : 950.0;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTableHeader(),
                                if (investments.isEmpty)
                                  Container(
                                    width: tableWidth,
                                    padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.7)),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'No investments found.',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            color: _titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        ElevatedButton(
                                          onPressed: () => _openInlineForm(),
                                          style: _primaryWhiteButtonStyle(minWidth: 240),
                                          child: Text(
                                            'Create First Investment',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ...List.generate(
                                    investments.length,
                                    (index) => _buildTableRow(context, investments[index], index),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _primaryWhiteButtonStyle({double minWidth = 0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.styleFrom(
      backgroundColor: isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
      foregroundColor: isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
      minimumSize: Size(minWidth, 52),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1B2E48) : const Color(0xFFEDF4FC),
        border: Border(bottom: BorderSide(color: _cardBorder, width: 1.2)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'HOG RAISER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _headerText,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'INITIAL CAPITAL',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _headerText,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'HOG TYPE',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _headerText,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'TOTAL HOG',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _headerText,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'INVESTMENT DATE',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _headerText,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'STAGE',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _headerText,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'ACTIONS',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _headerText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHogTypeTags(String hogType) {
    if (hogType.isEmpty || hogType == 'Auto-populated' || hogType == 'N/A') {
      return Text('N/A', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _headerText));
    }
    final types = hogType.split(',').map((e) => e.trim()).toList();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: types.map((t) {
        final isBreeding = t.toLowerCase().contains('breed') || t.toLowerCase().contains('sow');
        final bg = isBreeding ? Colors.purple.withValues(alpha: 0.18) : PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.18);
        final fg = isBreeding ? Colors.purpleAccent : PiggyTrunkTheme.ptPrimary;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: fg.withValues(alpha: 0.4)),
          ),
          child: Text(
            t,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableRow(BuildContext context, Investment investment, int index) {
    final isUnassigned = investment.hogRaiserId.isEmpty ||
        investment.hogRaiserId == 'unassigned' ||
        investment.raiserName.toLowerCase() == 'unassigned';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.5)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isUnassigned ? 'Unassigned' : investment.raiserName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isUnassigned ? Colors.orangeAccent : _titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isUnassigned) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'Unassigned',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatCurrency(investment.initialCapital),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _titleColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildHogTypeTags(investment.hogType),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${investment.totalHog} heads',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _titleColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatDateForDisplay(investment.investmentDate.toString()),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _titleColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: _buildStageBadge(investment.stage),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _openInlineForm(existing: investment),
                    icon: Icon(Icons.edit_outlined, size: 22, color: _headerText),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit Investment',
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    onPressed: () => _deleteInvestment(investment),
                    icon: const Icon(Icons.delete_outline, size: 22, color: Color(0xFFFF758C)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete Investment',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageBadge(String stage) {
    Color backgroundColor;
    Color textColor;

    switch (stage.toLowerCase()) {
      case 'active':
        backgroundColor = _successDark.withValues(alpha: 0.2);
        textColor = _successDark;
        break;
      case 'completed':
        backgroundColor = _inProgressDark.withValues(alpha: 0.2);
        textColor = _inProgressDark;
        break;
      case 'pending':
      default:
        backgroundColor = _mutedDark.withValues(alpha: 0.2);
        textColor = _mutedDark;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        stage,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
