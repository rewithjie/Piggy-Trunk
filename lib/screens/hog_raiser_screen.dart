import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/screen_top_bar.dart';

class HogRaiserScreen extends StatefulWidget {
  const HogRaiserScreen({super.key});

  @override
  State<HogRaiserScreen> createState() => _HogRaiserScreenState();
}

class _HogRaiserScreenState extends State<HogRaiserScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GlobalKey<FormState> _createFormKey = GlobalKey<FormState>();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  List<Map<String, dynamic>> _raisers = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showCreateForm = false;
  String? _selectedPigType;
  String _selectedStatus = 'Active';
  static const List<String> _lifecycleStages = <String>[
    'Booster',
    'Pre-Starter',
    'Starter',
    'Grower',
    'Finisher',
    'Selling',
  ];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDark => _isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
  Color get _accentDark => _isDark ? PiggyTrunkTheme.ptAccentDark : PiggyTrunkTheme.ptAccent;
  Color get _panelStart => _isDark ? const Color(0xFF1A2940) : Colors.white;
  Color get _panelEnd => _isDark ? const Color(0xFF0F1C2F) : Colors.white;
  Color get _panelBorder => _isDark ? const Color(0xFF2A3E5B) : const Color(0xFFE3EAF3);
  Color get _cardBg => _isDark ? const Color(0xFF132238) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF27405F) : const Color(0xFFC6D8EF);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF18314F);
  Color get _fieldBg => _isDark ? const Color(0xFF1A2B44) : const Color(0xFFEEF4FD);
  Color get _fieldBorder => _isDark ? const Color(0xFF28405D) : const Color(0xFFB4C9E6);
  Color get _fieldFocus => _isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F);
  Color get _fieldText => _isDark ? const Color(0xFFE6F1FF) : const Color(0xFF18314F);
  Color get _hintText => _isDark ? const Color(0xFF8FA7C4) : const Color(0xFF5D7391);

  @override
  void initState() {
    super.initState();
    _loadRaisers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRaisers({String keyword = ''}) async {
    setState(() => _isLoading = true);
    try {
      dynamic query = _supabase.from('hog_raisers').select();
      if (keyword.trim().isNotEmpty) {
        query = query.or('name.ilike.%$keyword%,address.ilike.%$keyword%,phone.ilike.%$keyword%');
      }
      final response = await query.order('name', ascending: true);

      if (!mounted) return;
      setState(() {
        _raisers = (response as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load raisers: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _parseId(dynamic rawId) {
    if (rawId == null) return null;
    if (rawId is int) return rawId;
    return int.tryParse(rawId.toString());
  }

  void _resetCreateForm() {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();
    _addressCtrl.clear();
    _createFormKey.currentState?.reset();
    _selectedPigType = null;
    _selectedStatus = 'Active';
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _validateRequired(value, 'Email');
    if (requiredError != null) return requiredError;
    final email = value!.trim();
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return isValid ? null : 'Please enter a valid email address';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Row(
        children: [
          AdminSidebar(
            currentRoute: '/raisers',
            onLogout: () => Navigator.of(context).pushReplacementNamed('/login'),
          ),
          Expanded(
            child: Column(
              children: [
                const ScreenTopBar(adminName: 'Admin', adminRole: 'SYSTEM ADMINISTRATOR'),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 1340),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_panelStart, _panelEnd]),
                                border: Border.all(color: _panelBorder, width: 1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
                              child: _showCreateForm ? _buildCreateForm() : _buildListView(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hog Raiser',
          style: AppTextStyles.pageTitle(_titleColor),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _cardBorder),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showCreateForm = true),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: Text(
                    'Create New Account',
                    style: AppTextStyles.button(_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
                    foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: AppTextStyles.body(_fieldText),
                      decoration: InputDecoration(
                        hintText: 'Search raisers...',
                        hintStyle: AppTextStyles.body(_hintText),
                        prefixIcon: Icon(Icons.search, color: _hintText),
                        filled: true,
                        fillColor: _fieldBg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _fieldFocus),
                        ),
                      ),
                      onSubmitted: (value) => _loadRaisers(keyword: value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _loadRaisers(keyword: _searchCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
                      foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                      minimumSize: const Size(100, 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Search',
                      style: AppTextStyles.button(_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _tableHeader(),
              const SizedBox(height: 8),
              if (_raisers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: Text(
                      'No raiser found',
                      style: AppTextStyles.jakarta(size: 24, weight: FontWeight.w700, color: _titleColor),
                    ),
                  ),
                )
              else
                ..._raisers.map(_tableRow),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableHeader() {
    final headers = ['HOG RAISER', 'ADDRESS', 'PHONE NUMBER', 'PIG TYPE', 'STATUS', 'ACTIONS'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cardBorder))),
      child: Row(
        children: headers
            .map(
              (h) => Expanded(
                child: Text(
                  h,
                  style: AppTextStyles.tableHeader(_hintText),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> row) {
    final currentStage = row['lifecycle_stage']?.toString().trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cardBorder.withValues(alpha: 0.5)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text((row['name'] ?? '').toString(), style: AppTextStyles.body(_titleColor))),
              Expanded(child: Text((row['address'] ?? '').toString(), style: AppTextStyles.body(_titleColor))),
              Expanded(child: Text((row['phone'] ?? '').toString(), style: AppTextStyles.body(_titleColor))),
              Expanded(child: Text((row['pig_type'] ?? '').toString(), style: AppTextStyles.body(_titleColor))),
              Expanded(child: Text((row['status'] ?? '').toString(), style: AppTextStyles.body(_titleColor))),
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _openEditRaiserDialog(row),
                      icon: Icon(Icons.edit_outlined, size: 16, color: _hintText),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => _deleteRaiser(row),
                      icon: Icon(Icons.delete_outline, size: 16, color: _accentDark),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (currentStage != null && currentStage.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildLifecycleMap(currentStage),
          ],
        ],
      ),
    );
  }

  Widget _buildLifecycleMap(String currentStage) {
    final activeIndex = _lifecycleStages.indexWhere((stage) => stage.toLowerCase() == currentStage.toLowerCase());
    final normalizedIndex = activeIndex < 0 ? 0 : activeIndex;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_lifecycleStages.length, (index) {
          final stage = _lifecycleStages[index];
          final isDone = index < normalizedIndex;
          final isCurrent = index == normalizedIndex;

          Color bgColor;
          Color fgColor;
          IconData icon;
          if (isDone) {
            bgColor = const Color(0xFF10B981);
            fgColor = Colors.white;
            icon = Icons.check;
          } else if (isCurrent) {
            bgColor = const Color(0xFFF97316);
            fgColor = Colors.white;
            icon = Icons.priority_high_rounded;
          } else {
            bgColor = _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
            fgColor = Colors.white;
            icon = Icons.radio_button_unchecked;
          }

          return Padding(
            padding: EdgeInsets.only(right: index == _lifecycleStages.length - 1 ? 0 : 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: bgColor,
                  child: Icon(icon, size: 14, color: fgColor),
                ),
                const SizedBox(height: 6),
                Text(
                  stage,
                  style: AppTextStyles.jakarta(size: 11, weight: FontWeight.w700, color: _titleColor),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Center(
        child: Form(
          key: _createFormKey,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 920),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF12213A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Raiser',
              style: AppTextStyles.jakarta(
                size: 30,
                weight: FontWeight.w800,
                color: _titleColor,
                letterSpacing: -0.04,
              ),
            ),
            const SizedBox(height: 18),
            _buildLabel(Icons.person_2_outlined, 'HOG RAISER NAME', fontSize: 14),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameCtrl,
              hint: 'Enter name',
              fontSize: 14,
              hintSize: 14,
              validator: (value) => _validateRequired(value, 'Name'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel(Icons.phone_outlined, 'PHONE', fontSize: 14),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneCtrl,
                    hint: '+63 XXX XXX XXXX',
                    fontSize: 14,
                    hintSize: 14,
                    validator: (value) => _validateRequired(value, 'Phone'),
                  ),
                ])),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel(Icons.email_outlined, 'EMAIL', fontSize: 14),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailCtrl,
                    hint: 'official@raiser-domain.com',
                    fontSize: 14,
                    hintSize: 14,
                    validator: _validateEmail,
                  ),
                ])),
              ],
            ),
            const SizedBox(height: 14),
            _buildLabel(Icons.location_on_outlined, 'ADDRESS', fontSize: 14),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _addressCtrl,
              hint: 'e.g., Malasiqui, San Carlos',
              fontSize: 14,
              hintSize: 14,
              validator: (value) => _validateRequired(value, 'Address'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel(Icons.view_module_outlined, 'SELECT PIG', fontSize: 14),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedPigType,
                    hint: 'Select breed type',
                    items: const ['Fattening', 'Sow'],
                    fontSize: 14,
                    onChanged: (v) => setState(() => _selectedPigType = v),
                  ),
                ])),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel(Icons.verified_outlined, 'STATUS', fontSize: 14),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedStatus,
                    hint: 'Select status',
                    items: const ['Active', 'Inactive'],
                    fontSize: 14,
                    onChanged: (v) => setState(() => _selectedStatus = v ?? 'Active'),
                  ),
                ])),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _createRaiser,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    _isSubmitting ? 'Creating...' : 'Create New Account',
                    style: AppTextStyles.button(_isDark ? PiggyTrunkTheme.ptPrimary : Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDark ? PiggyTrunkTheme.ptSurface : PiggyTrunkTheme.ptPrimary,
                    foregroundColor: _isDark ? PiggyTrunkTheme.ptPrimary : Colors.white,
                    minimumSize: const Size(230, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _resetCreateForm();
                    _showCreateForm = false;
                  }),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(108, 52),
                    side: BorderSide(color: _fieldBorder, width: 1),
                  ),
                  child: Text('Cancel', style: AppTextStyles.body(_titleColor)),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildLabel(IconData icon, String label, {double fontSize = 23}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _titleColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.jakarta(size: fontSize, weight: FontWeight.w800, color: _titleColor),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required double fontSize,
    required double hintSize,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: 64,
      child: TextFormField(
        controller: controller,
        validator: validator,
        cursorColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
        style: AppTextStyles.jakarta(size: fontSize, weight: FontWeight.w500, color: _fieldText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.jakarta(size: hintSize, weight: FontWeight.w500, color: _hintText),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required double fontSize,
  }) {
    return SizedBox(
      height: 66,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        isDense: true,
        borderRadius: BorderRadius.circular(12),
        menuMaxHeight: 220,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _hintText),
        dropdownColor: _fieldBg,
        style: AppTextStyles.jakarta(size: fontSize, weight: FontWeight.w500, color: _fieldText),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
        ),
        hint: Text(
          hint,
          style: AppTextStyles.jakarta(size: fontSize, weight: FontWeight.w600, color: _hintText),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    item,
                    style: AppTextStyles.jakarta(size: fontSize, weight: FontWeight.w600, color: _fieldText),
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        selectedItemBuilder: (context) => items
            .map(
              (item) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  style: AppTextStyles.jakarta(size: fontSize, weight: FontWeight.w600, color: _fieldText),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _createRaiser() async {
    if (_isSubmitting) return;
    final form = _createFormKey.currentState;
    if (form == null || !form.validate()) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final pigType = _selectedPigType?.trim() ?? '';
    final status = _selectedStatus.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || address.isEmpty || pigType.isEmpty || status.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _supabase.from('hog_raisers').insert({
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'pig_type': pigType,
        'status': status,
      });

      if (!mounted) return;
      setState(() {
        _resetCreateForm();
        _showCreateForm = false;
      });
      await _loadRaisers(keyword: _searchCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Raiser account created successfully.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openEditRaiserDialog(Map<String, dynamic> row) async {
    final id = _parseId(row['id']);
    if (id == null) return;

    final nameCtrl = TextEditingController(text: (row['name'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (row['phone'] ?? '').toString());
    final emailCtrl = TextEditingController(text: (row['email'] ?? '').toString());
    final addressCtrl = TextEditingController(text: (row['address'] ?? '').toString());
    String pigType = (row['pig_type'] ?? 'Fattening').toString();
    String status = (row['status'] ?? 'Active').toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardBg,
          title: Text(
            'Edit Raiser',
            style: AppTextStyles.jakarta(size: 18, weight: FontWeight.w700, color: _titleColor),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogInput(nameCtrl, 'Name'),
                  _buildDialogInput(phoneCtrl, 'Phone'),
                  _buildDialogInput(emailCtrl, 'Email'),
                  _buildDialogInput(addressCtrl, 'Address'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: pigType,
                    decoration: _dialogDecoration('Pig Type'),
                    items: const ['Fattening', 'Sow']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => pigType = v ?? pigType,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: _dialogDecoration('Status'),
                    items: const ['Active', 'Inactive']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => status = v ?? status,
                  ),
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
                final phone = phoneCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final address = addressCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty || email.isEmpty || address.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please complete all required fields.')),
                  );
                  return;
                }
                try {
                  await _supabase.from('hog_raisers').update({
                    'name': name,
                    'phone': phone,
                    'email': email,
                    'address': address,
                    'pig_type': pigType,
                    'status': status,
                  }).eq('id', id);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  await _loadRaisers(keyword: _searchCtrl.text);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Raiser updated successfully.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update failed: $e')),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRaiser(Map<String, dynamic> row) async {
    final id = _parseId(row['id']);
    if (id == null) return;
    final name = (row['name'] ?? '').toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Raiser'),
        content: Text('Delete raiser "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _supabase.from('hog_raisers').delete().eq('id', id);
      await _loadRaisers(keyword: _searchCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Raiser deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildDialogInput(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        cursorColor: _isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
        style: AppTextStyles.body(_fieldText),
        decoration: _dialogDecoration(label),
      ),
    );
  }

  InputDecoration _dialogDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.body(_hintText),
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
    );
  }
}
