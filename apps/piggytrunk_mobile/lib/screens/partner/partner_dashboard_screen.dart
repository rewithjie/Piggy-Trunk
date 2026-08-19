import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:piggytrunk/services/notification_service.dart';

import 'tabs/partner_home_tab.dart';
import 'tabs/partner_projects_tab.dart';
import 'tabs/partner_my_projects_tab.dart';
import 'tabs/partner_activities_tab.dart';
import 'tabs/partner_profile_tab.dart';
import '../../services/auth_session_service.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;
  
  // Profile Information
  String _partnerName = "Partner Investor";
  String _partnerEmail = "";
  String _partnerPhone = "N/A";
  String _partnerAddress = "N/A";
  String? _partnerAvatarUrl;

  // Financial & Investment Data
  double _investedAmount = 0.0;
  int _activeProjectsCount = 0;
  final List<Map<String, dynamic>> _projectsList = [];
  final List<Map<String, dynamic>> _activitiesList = [];
  List<Map<String, dynamic>> _notificationsList = [];
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _fetchPartnerData();
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (image == null) return;

      if (mounted) setState(() => _isLoading = true);

      final bytes = await image.readAsBytes();
      final fileName = 'avatar-partner-${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = 'avatars/$fileName';

      try {
        await Supabase.instance.client.storage.from('profile_pictures').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        final publicUrl = Supabase.instance.client.storage.from('profile_pictures').getPublicUrl(filePath);

        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'avatar_url': publicUrl, 'picture': publicUrl}),
          );
        } catch (_) {}

        try {
          await Supabase.instance.client.from('app_users').update({
            'avatar_url': publicUrl,
          }).eq('supabase_user_id', user.id);
        } catch (_) {}

        if (mounted) {
          setState(() {
            _partnerAvatarUrl = publicUrl;
          });
        }
      } catch (uploadErr) {
        debugPrint('Storage upload error: $uploadErr');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Matagumpay na na-update ang inyong profile picture!'),
            backgroundColor: Color(0xFF2FB36F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking avatar image: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreDefaultAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'avatar_url': null, 'picture': null}),
        );
      } catch (_) {}

      try {
        await Supabase.instance.client.from('app_users').update({
          'avatar_url': null,
        }).eq('supabase_user_id', user.id);
      } catch (e) {
        debugPrint('Error clearing avatar in DB: $e');
      }
    }

    if (mounted) {
      setState(() {
        _partnerAvatarUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture restored to default PiggyTrunk logo!'),
          backgroundColor: Color(0xFF18314F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: _partnerName == 'N/A' ? '' : _partnerName);
    final phoneCtrl = TextEditingController(text: _partnerPhone == 'N/A' ? '' : _partnerPhone);
    final addrCtrl = TextEditingController(text: _partnerAddress == 'N/A' ? '' : _partnerAddress);

    final sheetBg = isDark ? const Color(0xFF151F2E) : Colors.white;
    final titleColor = isDark ? const Color(0xFFECF2FF) : const Color(0xFF18314F);
    final borderColor = isDark ? const Color(0xFF28354A) : const Color(0xFFE6EBF2);
    final hintColor = isDark ? PiggyTrunkTheme.ptMutedDark : PiggyTrunkTheme.ptMuted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle Pill
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334B68) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3352) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF18314F),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'I-edit ang Profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, color: hintColor, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 18),

                  _buildDialogInputField(
                    context,
                    controller: nameCtrl,
                    label: 'Buong Pangalan',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildDialogInputField(
                    context,
                    controller: phoneCtrl,
                    label: 'Phone Number (11 digits)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildDialogInputField(
                    context,
                    controller: addrCtrl,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Kanselahin',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: hintColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final newName = nameCtrl.text.trim();
                            final newPhone = phoneCtrl.text.trim();
                            final newAddr = addrCtrl.text.trim();

                            if (newName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mangyaring ilagay ang buong pangalan.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (newPhone.isNotEmpty && (newPhone.length != 11 || !newPhone.startsWith('09'))) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ang numero ng telepono ay dapat eksaktong 11 numero na nagsisimula sa 09 (hal. 09123456789).'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              if (newName.isNotEmpty) _partnerName = newName;
                              _partnerPhone = newPhone.isNotEmpty ? newPhone : 'N/A';
                              _partnerAddress = newAddr.isNotEmpty ? newAddr : 'N/A';
                            });

                            Navigator.pop(ctx);

                            try {
                              final user = Supabase.instance.client.auth.currentUser;
                              if (user != null && newName.isNotEmpty) {
                                await Supabase.instance.client
                                    .from('app_users')
                                    .update({'name': newName})
                                    .eq('supabase_user_id', user.id);
                              }
                            } catch (e) {
                              debugPrint('Error updating user name in DB: $e');
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Successfully updated profile information!'),
                                  backgroundColor: Color(0xFF2FB36F),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : const Color(0xFF18314F),
                            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'I-save ang Pagbabago',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
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
      ),
    );
  }

  Widget _buildDialogInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.plusJakartaSans(
        color: isDark ? const Color(0xFFECF2FF) : const Color(0xFF18314F),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, size: 20, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF18314F)),
        filled: true,
        fillColor: isDark ? const Color(0xFF1B2638) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF28354A) : const Color(0xFFE6EBF2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF18314F), width: 1.5),
        ),
      ),
    );
  }

  Future<void> _fetchPartnerData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _partnerEmail = user.email ?? "";

        // Initialize native notification listener for Partner Investor
        NotificationService().requestPermission();
        NotificationService().startRoleRealtimeListener(role: 'partner', userId: user.id);

        // 1. Fetch profile from app_users
        Map<String, dynamic>? profile = await Supabase.instance.client
            .from('app_users')
            .select('user_id, name, email')
            .eq('supabase_user_id', user.id)
            .maybeSingle();

        if (profile == null && _partnerEmail.isNotEmpty) {
          final profileByEmail = await Supabase.instance.client
              .from('app_users')
              .select('user_id, name, email')
              .eq('email', _partnerEmail)
              .maybeSingle();

          if (profileByEmail != null) {
            profile = profileByEmail;
            try {
              await Supabase.instance.client
                  .from('app_users')
                  .update({'supabase_user_id': user.id})
                  .eq('user_id', profileByEmail['user_id']);
            } catch (e) {
              debugPrint('Error linking supabase_user_id: $e');
            }
          }
        }

        String resolvedName = "";
        if (profile != null) {
          final rawName = profile['name'] as String?;
          if (rawName != null && rawName.trim().isNotEmpty) {
            resolvedName = rawName.trim();
          }
        }

        if (resolvedName.isEmpty) {
          final metaName = (user.userMetadata?['name'] as String?) ??
              (user.userMetadata?['full_name'] as String?);
          if (metaName != null && metaName.trim().isNotEmpty) {
            resolvedName = metaName.trim();
          } else if (_partnerEmail.contains('@')) {
            final prefix = _partnerEmail.split('@').first.trim();
            if (prefix.isNotEmpty) {
              resolvedName = prefix[0].toUpperCase() + prefix.substring(1);
            }
          }
        }

        if (resolvedName.isNotEmpty) {
          _partnerName = resolvedName;
        }

        // 2. Fetch investments total from DB
        try {
          final List<dynamic> investmentsResponse = await Supabase.instance.client
              .from('investments')
              .select('amount, status');

          double total = 0.0;
          int activeCount = 0;
          if (investmentsResponse.isNotEmpty) {
            for (var item in investmentsResponse) {
              final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
              total += amt;
              if (item['status'] == 'active' || item['status'] == 'In Progress') {
                activeCount++;
              }
            }
          }
          _investedAmount = total;
          _activeProjectsCount = activeCount;
        } catch (e) {
          debugPrint('Notice: Fetching investments: $e');
        }

        // 3. Fetch notifications (Strictly excluding Cashier/Admin stock notifications for Partner Investor)
        try {
          final List<dynamic> notifs = await Supabase.instance.client
              .from('admin_notifications')
              .select('*')
              .order('created_at', ascending: false)
              .limit(30);
          if (notifs.isNotEmpty) {
            final partnerNotifs = notifs.where((n) {
              final type = (n['type'] as String?)?.toLowerCase() ?? '';
              final title = (n['title'] as String?)?.toLowerCase() ?? '';
              final msg = (n['message'] as String?)?.toLowerCase() ?? '';

              if (type.contains('stock') ||
                  type.contains('cashier') ||
                  type.contains('pos') ||
                  type.contains('user') ||
                  type.contains('registration') ||
                  type.contains('signup') ||
                  title.contains('cashier') ||
                  title.contains('stock request') ||
                  title.contains('registered') ||
                  msg.contains('stock request') ||
                  msg.contains('pending approval') ||
                  msg.contains('cashier')) {
                return false;
              }
              return true;
            }).toList();

            _notificationsList = List<Map<String, dynamic>>.from(partnerNotifs);
          } else {
            _notificationsList = [];
          }
        } catch (_) {
          _notificationsList = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching partner profile data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await AuthSessionService().clearSession();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  void _markNotificationAsRead(int id) {
    setState(() {
      final index = _notificationsList.indexWhere((n) => n['notification_id'] == id);
      if (index != -1) {
        _notificationsList[index]['is_read'] = true;
      }
    });
  }

  void _markAllNotificationsRead() {
    setState(() {
      for (var n in _notificationsList) {
        n['is_read'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xff0f1724) : PiggyTrunkTheme.ptBg;
    final navBg = isDark ? const Color(0xff151f2e) : Colors.white;
    final navBorder = isDark ? const Color(0xff28354a) : const Color(0xffe6ebf2);

    final List<Widget> tabs = [
      PartnerHomeTab(
        partnerName: _partnerName,
        investedAmount: _investedAmount,
        activeProjectsCount: _activeProjectsCount,
        activitiesList: _activitiesList,
        notificationsList: _notificationsList,
        onRefresh: _fetchPartnerData,
        onSeeAllActivities: () => setState(() => _currentIndex = 3),
        onViewProjects: () => setState(() => _currentIndex = 1),
        onMarkNotificationAsRead: _markNotificationAsRead,
        onMarkAllRead: _markAllNotificationsRead,
      ),
      PartnerMyProjectsTab(
        projectsList: _projectsList,
        investedAmount: _investedAmount,
        onRefresh: _fetchPartnerData,
        onMakeInvestment: () => setState(() => _currentIndex = 2),
      ),
      PartnerProjectsTab(
        projectsList: _projectsList,
        onRefresh: _fetchPartnerData,
      ),
      PartnerActivitiesTab(
        activitiesList: _activitiesList,
        onRefresh: _fetchPartnerData,
      ),
      PartnerProfileTab(
        partnerName: _partnerName,
        partnerEmail: _partnerEmail,
        partnerPhone: _partnerPhone,
        partnerAddress: _partnerAddress,
        partnerAvatarUrl: _partnerAvatarUrl,
        onPickAndUploadAvatar: _pickAndUploadAvatar,
        onRestoreDefaultAvatar: _restoreDefaultAvatar,
        onShowEditProfileDialog: _showEditProfileDialog,
        onLogout: _handleLogout,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pindutin ulit ang Back button upang isara ang app.'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF18314F),
            ),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SafeArea(
          child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF18314F),
                ),
              )
            : IndexedStack(
                index: _currentIndex,
                children: tabs,
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(color: navBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: navBg,
          selectedItemColor: isDark ? const Color(0xffecf2ff) : const Color(0xFF18314F),
          unselectedItemColor: isDark ? const Color(0xff9cb0c9) : PiggyTrunkTheme.ptMuted,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded, color: isDark ? const Color(0xffecf2ff) : const Color(0xFF18314F)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.work_outline_rounded),
              activeIcon: Icon(Icons.work_rounded, color: isDark ? const Color(0xffecf2ff) : const Color(0xFF18314F)),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded, color: isDark ? const Color(0xffecf2ff) : const Color(0xFF18314F)),
              label: 'Investment',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article_rounded, color: isDark ? const Color(0xffecf2ff) : const Color(0xFF18314F)),
              label: 'Activities',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, color: isDark ? const Color(0xffecf2ff) : const Color(0xFF18314F)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
  );
  }
}
