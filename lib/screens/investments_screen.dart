import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/investment_model.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Investment> investments = [];
  List<Map<String, dynamic>> _raisers = [];
  bool _isLoading = true;
  bool _isCreatingInvestment = false;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFC9D8EC);
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _headerBg => _isDark ? const Color(0xFF0C1628) : const Color(0xFFEFF4FC);
  Color get _headerText => _isDark ? const Color(0xFF9EC0E8) : const Color(0xFF4B6281);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE);
  Color get _fieldBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC);
  Color get _fieldFocus => _isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);
  Color get _fieldText => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _hintText => _isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096);
  Color get _successDark => _isDark ? PiggyTrunkTheme.ptSuccessDark : PiggyTrunkTheme.ptSuccess;
  Color get _inProgressDark => _isDark ? PiggyTrunkTheme.ptInProgressDark : PiggyTrunkTheme.ptInProgress;
  Color get _mutedDark => _isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;
  final TextEditingController _capitalCtrl = TextEditingController();
  final TextEditingController _totalHogCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showInlineCalendar = false;
  String? _selectedRaiserId;
  String _selectedRaiserName = '';
  String _selectedHogType = '';
  int _calendarViewSeed = 0;

  void _shiftSelectedMonth(int delta) {
    final current = _selectedDate;
    final target = DateTime(current.year, current.month + delta, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    final clampedDay = current.day > lastDay ? lastDay : current.day;
    setState(() {
      _selectedDate = DateTime(target.year, target.month, clampedDay);
      _calendarViewSeed++;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadInvestments(), _loadRaisers()]);
  }

  Future<void> _loadInvestments() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('investments')
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

  Future<void> _loadRaisers() async {
    try {
      final response = await _supabase
          .from('hog_raisers')
          .select('id,name,pig_type')
          .eq('status', 'Active')
          .order('name', ascending: true);
      if (!mounted) return;
      setState(() => _raisers = (response as List).cast<Map<String, dynamic>>());
    } catch (_) {}
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

  Future<void> _openInvestmentDialog({Investment? existing}) async {
    final isEdit = existing != null;
    List<Map<String, dynamic>> raisers = [];
    String? selectedRaiserId;
    String selectedHogType = 'Auto-populated';

    final initialCapitalCtrl = TextEditingController(
      text: existing != null ? existing.initialCapital.toInt().toString() : '',
    );

    final totalHogCtrl = TextEditingController(
      text: existing?.totalHog.toString() ?? '',
    );

    final investmentDateCtrl = TextEditingController(
      text: existing != null
          ? '${existing.investmentDate.year.toString().padLeft(4, '0')}-${existing.investmentDate.month.toString().padLeft(2, '0')}-${existing.investmentDate.day.toString().padLeft(2, '0')}'
          : DateTime.now().toIso8601String().split('T').first,
    );

    // Load authorized raisers
    try {
      final response = await _supabase
          .from('hog_raisers')
          .select('id, name, pig_type')
          .eq('status', 'Active')
          .order('name', ascending: true);
      raisers = List<Map<String, dynamic>>.from(response as List);
      if (raisers.isNotEmpty && existing == null) {
        selectedRaiserId = raisers[0]['id'].toString();
        selectedHogType = (raisers[0]['pig_type'] ?? 'Auto-populated').toString();
      } else if (existing != null) {
        selectedRaiserId = existing.hogRaiserId;
        final selectedRow = raisers.where((r) => r['id'].toString() == selectedRaiserId).toList();
        if (selectedRow.isNotEmpty) {
          selectedHogType = (selectedRow.first['pig_type'] ?? 'Auto-populated').toString();
        } else {
          selectedHogType = existing.hogType;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load raisers: $e')),
        );
      }
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            return Dialog(
              backgroundColor: _cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          isEdit ? 'Edit Investment' : 'Create Investment',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _titleColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // HOG RAISER Section
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.pets, size: 16, color: _headerText),
                              const SizedBox(width: 6),
                              Text(
                                'HOG RAISER',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _headerText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRaiserId,
                          decoration: _createInputDecoration('Select an authorized raiser'),
                          isExpanded: true,
                          menuMaxHeight: 260,
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: _fieldBg,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _hintText),
                          style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14, fontWeight: FontWeight.w500),
                          items: raisers
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
                            final selectedRow = raisers.where((r) => r['id'].toString() == value).toList();
                            setDialogState(() {
                              selectedRaiserId = value;
                              if (selectedRow.isNotEmpty) {
                                selectedHogType = (selectedRow.first['pig_type'] ?? 'Auto-populated').toString();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // INITIAL CAPITAL & HOG TYPE Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.attach_money, size: 14, color: _headerText),
                                        const SizedBox(width: 6),
                                        Text(
                                          'INITIAL CAPITAL',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _headerText,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _fieldBg,
                                      border: Border.all(color: _fieldBorder, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: TextField(
                                      controller: initialCapitalCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: _fieldText,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '0',
                                        hintStyle: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: _hintText,
                                        ),
                                        prefixText: '₱ ',
                                        prefixStyle: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: _fieldText,
                                        ),
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 14, color: _headerText),
                                        const SizedBox(width: 6),
                                        Text(
                                          'HOG TYPE',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _headerText,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _fieldBg.withValues(alpha: 0.5),
                                      border: Border.all(color: _fieldBorder.withValues(alpha: 0.5), width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Text(
                                      'Auto-populated',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: _hintText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // TOTAL HOG & INVESTMENT DATE Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calculate, size: 14, color: _headerText),
                                        const SizedBox(width: 6),
                                        Text(
                                          'TOTAL HOG',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _headerText,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _fieldBg,
                                      border: Border.all(color: _fieldBorder, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: TextField(
                                      controller: totalHogCtrl,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: _fieldText,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Heads',
                                        hintStyle: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: _hintText,
                                        ),
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: _headerText),
                                        const SizedBox(width: 6),
                                        Text(
                                          'INVESTMENT DATE',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _headerText,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _fieldBg,
                                      border: Border.all(color: _fieldBorder, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDateForDisplay(investmentDateCtrl.text),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            color: _fieldText,
                                          ),
                                        ),
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () async {
                                              final picked = await showDatePicker(
                                                context: statefulContext,
                                                initialDate: DateTime.tryParse(investmentDateCtrl.text) ?? DateTime.now(),
                                                firstDate: DateTime(2020),
                                                lastDate: DateTime(2050),
                                              );
                                              if (picked != null) {
                                                setDialogState(() {
                                                  investmentDateCtrl.text =
                                                      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                                });
                                              }
                                            },
                                            child: Icon(
                                              Icons.calendar_today,
                                              size: 18,
                                              color: _fieldBorder,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final parsedCapital = int.tryParse(initialCapitalCtrl.text.trim());
                                final parsedTotalHog = int.tryParse(totalHogCtrl.text.trim());
                                final parsedDate = DateTime.tryParse(investmentDateCtrl.text.trim());

                                if (selectedRaiserId == null ||
                                    parsedCapital == null ||
                                    parsedTotalHog == null ||
                                    parsedDate == null) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    const SnackBar(content: Text('Please fill all fields correctly.')),
                                  );
                                  return;
                                }

                                final raiserName = raisers
                                    .firstWhere(
                                      (r) => r['id'].toString() == selectedRaiserId,
                                      orElse: () => {'name': ''},
                                    )['name'];

                                final payload = {
                                  'hog_raiser_id': selectedRaiserId,
                                  'raiser_name': raiserName,
                                  'initial_capital': parsedCapital,
                                  'hog_type': selectedHogType,
                                  'total_hog': parsedTotalHog,
                                  'investment_date': parsedDate.toIso8601String(),
                                  'stage': 'pending',
                                };

                                try {
                                  if (isEdit) {
                                    await _supabase.from('investments').update(payload).eq('id', existing.id);
                                  } else {
                                    await _supabase.from('investments').insert(payload);
                                  }
                                  await _supabase
                                      .from('hog_raisers')
                                      .update({'lifecycle_stage': 'Booster'})
                                      .eq('id', int.parse(selectedRaiserId!));

                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);
                                  await _loadInvestments();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEdit ? 'Investment updated.' : 'Investment added.'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Save failed: $e')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(
                                isEdit ? 'Save Changes' : 'Create Investment',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F1C2F),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                side: BorderSide(color: _fieldBorder, width: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _fieldText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteInvestment(Investment investment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Investment'),
        content: Text('Delete investment for ${investment.raiserName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('investments').delete().eq('id', investment.id);
      await _loadInvestments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Investment deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: _bgDark,
      body: Row(

        children: [
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
              if (_isCreatingInvestment)
                _buildCreateInvestmentForm()
              else
                Container(
                  decoration: BoxDecoration(
                    color: _cardBg,
                    border: Border.all(color: _cardBorder, width: 1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Investment',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                          letterSpacing: -0.04,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTableHeader(),
                      if (investments.isEmpty)
                        Container(
                          width: double.infinity,
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
                                onPressed: () => setState(() => _isCreatingInvestment = true),
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

  Widget _buildCreateInvestmentForm() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF12213A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Investment',
            style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w800, color: _titleColor),
          ),
          const SizedBox(height: 18),
          _fieldLabel('HOG RAISER', Icons.person_outline),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedRaiserId,
            decoration: _createInputDecoration('Select an authorized raiser'),
            isExpanded: true,
            menuMaxHeight: 260,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: _hintText),
            dropdownColor: _fieldBg,
            style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14, fontWeight: FontWeight.w500),
            items: _raisers
                .map((r) => DropdownMenuItem<String>(
                      value: (r['id'] ?? '').toString(),
                      child: Text(
                        (r['name'] ?? '').toString(),
                        style: GoogleFonts.plusJakartaSans(
                          color: _fieldText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              final row = _raisers.firstWhere(
                (r) => (r['id'] ?? '').toString() == value,
                orElse: () => {},
              );
              setState(() {
                _selectedRaiserId = value;
                _selectedRaiserName = (row['name'] ?? '').toString();
                _selectedHogType = (row['pig_type'] ?? '').toString();
              });
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('INITIAL CAPITAL', Icons.attach_money),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _capitalCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14),
                      decoration: _createInputDecoration('0').copyWith(
                        prefixIcon: Container(
                          width: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: _fieldBorder),
                            ),
                          ),
                          child: Text(
                            '₱',
                            style: GoogleFonts.plusJakartaSans(
                              color: _fieldText,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('HOG TYPE', Icons.category_outlined),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: _selectedHogType),
                      readOnly: true,
                      style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14),
                      decoration: _createInputDecoration('Auto-populated'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('TOTAL HOG', Icons.tag),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _totalHogCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14),
                      decoration: _createInputDecoration('Heads'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('INVESTMENT DATE', Icons.calendar_today_outlined),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setState(() => _showInlineCalendar = !_showInlineCalendar),
                      child: InputDecorator(
                        decoration: _createInputDecoration('Investment Date').copyWith(
                          suffixIcon: Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: _fieldText.withValues(alpha: 0.9),
                          ),
                        ),
                        child: Text(
                          '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                          style: GoogleFonts.plusJakartaSans(color: _fieldText, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showInlineCalendar) ...[
            const SizedBox(height: 6),
            _buildInlineDatePickerCard(),
          ],
          const SizedBox(height: 26),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _submitCreateInvestment,
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Create Investment',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _isDark ? const Color(0xFF0F1C2F) : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                  foregroundColor: _isDark ? const Color(0xFF0F1C2F) : Colors.white,
                  minimumSize: const Size(220, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => setState(() => _isCreatingInvestment = false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(110, 52),
                  side: BorderSide(
                    color: _isDark ? const Color(0xFF7F94B2) : PiggyTrunkTheme.ptPrimary,
                    width: 1,
                  ),
                  foregroundColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  Widget _fieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _headerText),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _titleColor,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildInlineDatePickerCard() {
    final primary = _isDark ? const Color(0xFF8FB7E6) : const Color(0xFF1F5FAF);
    final onPrimary = _isDark ? const Color(0xFF0B1A2B) : Colors.white;
    final pickerBg = _fieldBg;
    final pickerText = _fieldText;
    final pickerBorder = _fieldBorder;
    final pickerWeekday = _hintText;
    final pickerShadow = Colors.black.withValues(alpha: _isDark ? 0.24 : 0.08);

    return Container(
      decoration: BoxDecoration(
        color: pickerBg,
        border: Border.all(color: pickerBorder),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: pickerShadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: primary,
                onPrimary: onPrimary,
                onSurface: pickerText,
                surface: pickerBg,
              ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: pickerBg,
            surfaceTintColor: Colors.transparent,
            dayStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: pickerText,
              fontSize: 13,
            ),
            weekdayStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: pickerWeekday,
              fontSize: 11,
            ),
            yearStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: pickerText,
              fontSize: 13,
            ),
            headerForegroundColor: pickerText,
            subHeaderForegroundColor: pickerWeekday,
            dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) return onPrimary;
              return pickerText;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) return primary;
              return null;
            }),
            yearForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) return onPrimary;
              return pickerText;
            }),
            yearBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) return primary;
              return null;
            }),
          ),
        ),
        child: Stack(
          children: [
            CalendarDatePicker(
              key: ValueKey('calendar_${_selectedDate.year}_${_selectedDate.month}_$_calendarViewSeed'),
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              initialCalendarMode: DatePickerMode.day,
              onDateChanged: (picked) => setState(() {
                _selectedDate = picked;
                _showInlineCalendar = false;
              }),
            ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: 56,
              child: Container(
                color: pickerBg,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Text(
                      '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: GoogleFonts.plusJakartaSans(
                        color: pickerText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _shiftSelectedMonth(-1),
                      icon: Icon(Icons.chevron_left_rounded, color: pickerText),
                      splashRadius: 18,
                      tooltip: 'Previous month',
                    ),
                    IconButton(
                      onPressed: () => _shiftSelectedMonth(1),
                      icon: Icon(Icons.chevron_right_rounded, color: pickerText),
                      splashRadius: 18,
                      tooltip: 'Next month',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _submitCreateInvestment() async {
    final capital = int.tryParse(_capitalCtrl.text.trim());
    final totalHog = int.tryParse(_totalHogCtrl.text.trim());
    if (_selectedRaiserId == null || capital == null || totalHog == null || _selectedHogType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }
    try {
      await _supabase.from('investments').insert({
        'hog_raiser_id': _selectedRaiserId,
        'raiser_name': _selectedRaiserName,
        'initial_capital': capital,
        'hog_type': _selectedHogType,
        'total_hog': totalHog,
        'investment_date': _selectedDate.toIso8601String(),
        'stage': 'pending',
      });
      await _supabase
          .from('hog_raisers')
          .update({'lifecycle_stage': 'Booster'})
          .eq('id', int.parse(_selectedRaiserId!));
      if (!mounted) return;
      setState(() {
        _isCreatingInvestment = false;
        _capitalCtrl.clear();
        _totalHogCtrl.clear();
        _selectedRaiserId = null;
        _selectedRaiserName = '';
        _selectedHogType = '';
        _selectedDate = DateTime.now();
      });
      await _loadInvestments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Investment added.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    }
  }

  Widget _buildTableHeader() {
    const headers = [
      'HOG RAISER',
      'INITIAL CAPITAL',
      'HOG TYPE',
      'TOTAL HOG',
      'INVESTMENT DATE',
      'STAGE',
      'ACTIONS',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cardBorder))),
      child: Row(
        children: headers
            .map(
              (h) => Expanded(
                child: Text(
                  h,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.03,
                    color: _headerText,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Investment investment, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.5)))),
      child: Row(
        children: [
          Expanded(
            child: Text(
              investment.raiserName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _titleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '₱${investment.initialCapital.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _titleColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              investment.hogType,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _titleColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${investment.totalHog} heads',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _titleColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatDateForDisplay(investment.investmentDate.toString()),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _titleColor,
              ),
            ),
          ),
          Expanded(
            child: _buildStageBadge(investment.stage),
          ),
          Expanded(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _openInvestmentDialog(existing: investment),
                  icon: Icon(Icons.edit_outlined, size: 16, color: _headerText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _deleteInvestment(investment),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFFF758C)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
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
