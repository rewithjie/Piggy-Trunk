import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:piggytrunk/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_session_service.dart';

import 'tabs/raiser_home_tab.dart';
import 'tabs/raiser_request_tab.dart';
import 'tabs/raiser_hogs_tab.dart';
import 'tabs/raiser_profile_tab.dart';

class MobileDashboardScreen extends StatefulWidget {
  const MobileDashboardScreen({super.key});

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic> _raiserData = {};
  double _investedAmount = 0.0;
  List<Map<String, dynamic>> _hogsList = [];
  List<Map<String, dynamic>> _requestsList = [];
  List<Map<String, dynamic>> _activeAssignments = [];
  List<Map<String, dynamic>> _reportsList = [];
  List<Map<String, dynamic>> _notificationsList = [];

  BigInt? _selectedAssignmentId;
  String? _errorMessage;
  DateTime? _lastBackPressTime;

  static const Color _brandColor = Color(0xFF18314F);

  @override
  void initState() {
    super.initState();
    _fetchRaiserData();
  }

  Future<void> _fetchRaiserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('DEBUG ERROR: No logged in Supabase Auth user.');
        return;
      }
      debugPrint('DEBUG INFO: Logged in user Auth ID: ${user.id}, Email: ${user.email}');

      // Initialize native notification listener for Hog Raiser
      NotificationService().requestPermission();
      NotificationService().startRoleRealtimeListener(role: 'raiser', userId: user.id);

      // 1. Fetch user profile from app_users
      var appUser = await Supabase.instance.client
          .from('app_users')
          .select('user_id, name, email')
          .eq('supabase_user_id', user.id)
          .maybeSingle();

      if (appUser == null) {
        final appUserByEmail = await Supabase.instance.client
            .from('app_users')
            .select('user_id, name, email, supabase_user_id')
            .eq('email', user.email!)
            .maybeSingle();

        if (appUserByEmail != null) {
          await Supabase.instance.client
              .from('app_users')
              .update({'supabase_user_id': user.id})
              .eq('user_id', appUserByEmail['user_id']);

          appUser = appUserByEmail;
        } else {
          if (mounted) {
            setState(() {
              _raiserData = {
                'name': 'Account Not Found',
                'email': user.email ?? 'N/A',
                'phone': 'N/A',
                'address': 'N/A',
                'pig_type': 'None',
                'lifecycle_stage': 'None',
              };
              _investedAmount = 0.0;
              _isLoading = false;
            });
          }
          return;
        }
      }

      final userId = appUser['user_id'];
      final fallbackName = (appUser['name'] ?? user.email ?? 'Hog Raiser') as String;

      // 2. Fetch raiser profile
      var raiser = await Supabase.instance.client
          .from('hog_raisers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (raiser == null) {
        final raiserByEmail = await Supabase.instance.client
            .from('hog_raisers')
            .select()
            .eq('email', user.email!)
            .maybeSingle();

        if (raiserByEmail != null) {
          await Supabase.instance.client
              .from('hog_raisers')
              .update({'user_id': userId})
              .eq('hog_raiser_id', raiserByEmail['hog_raiser_id']);

          raiser = await Supabase.instance.client
              .from('hog_raisers')
              .select()
              .eq('user_id', userId)
              .maybeSingle();
        } else {
          if (mounted) {
            setState(() {
              _raiserData = {
                'name': fallbackName,
                'email': user.email ?? 'N/A',
                'phone': 'N/A',
                'address': 'N/A',
                'pig_type': 'None',
                'lifecycle_stage': 'None',
              };
              _investedAmount = 0.0;
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (raiser == null) return;

      final raiserId = raiser['hog_raiser_id'] ?? raiser['id'];
      if (raiserId == null) {
        throw Exception('Raiser ID is null!');
      }

      // 3. Fetch total capital invested
      final capitalRes = await Supabase.instance.client
          .from('investment_records')
          .select('initial_capital')
          .eq('hog_raiser_id', raiserId.toString());

      double totalCapital = 0.0;
      for (var row in capitalRes) {
        totalCapital += (row['initial_capital'] as num).toDouble();
      }

      // 4. Fetch assignments
      final assignmentsRes = await Supabase.instance.client
          .from('assignments')
          .select('*, hog_types(*), batches(*)')
          .eq('hog_raiser_id', raiserId)
          .eq('status', 'active');
      final assignments = List<Map<String, dynamic>>.from(assignmentsRes);

      // 5. Fetch hogs
      final hogsRes = await Supabase.instance.client
          .from('hogs')
          .select('*, assignments!inner(*, hog_types(*))')
          .eq('assignments.hog_raiser_id', raiserId)
          .eq('assignments.status', 'active')
          .eq('status', 'active');
      final hogs = List<Map<String, dynamic>>.from(hogsRes)
          .where((h) => (h['health_status'] ?? '').toString().toLowerCase() != 'dead')
          .toList();
      hogs.sort((a, b) {
        final aId = a['hog_id'] as num? ?? 0;
        final bId = b['hog_id'] as num? ?? 0;
        return aId.compareTo(bId);
      });

      // 6. Fetch stock requests
      final requestsRes = await Supabase.instance.client
          .from('stock_requests')
          .select('*, assignments!inner(*, batches(*))')
          .eq('hog_raiser_id', raiserId)
          .order('request_date', ascending: false);
      final requests = List<Map<String, dynamic>>.from(requestsRes);

      // 7. Fetch health reports
      final reportsRes = await Supabase.instance.client
          .from('hog_reports')
          .select('*')
          .eq('hog_raiser_id', raiserId)
          .order('created_at', ascending: false);
      final reports = List<Map<String, dynamic>>.from(reportsRes);

      // 8. Fetch Notifications
      final notifRes = await Supabase.instance.client
          .from('raiser_notifications')
          .select('*')
          .eq('hog_raiser_id', raiserId)
          .order('created_at', ascending: false);
      final notifications = List<Map<String, dynamic>>.from(notifRes);

      // Resolve email, pig type, lifecycle stage and avatar with fallbacks
      final resolvedEmail = (raiser['email'] != null &&
              raiser['email'].toString().trim().isNotEmpty &&
              raiser['email'] != 'N/A')
          ? raiser['email'].toString().trim()
          : ((appUser['email'] != null && appUser['email'].toString().trim().isNotEmpty)
              ? appUser['email'].toString().trim()
              : (user.email ?? 'N/A'));

      final resolvedAvatar = raiser['avatar_url'] ??
          user.userMetadata?['avatar_url'] ??
          user.userMetadata?['picture'];

      String resolvedPigType = (raiser['pig_type'] != null &&
              raiser['pig_type'].toString().trim().isNotEmpty &&
              raiser['pig_type'] != 'N/A')
          ? raiser['pig_type'].toString().trim()
          : 'N/A';

      String resolvedStage = (raiser['lifecycle_stage'] != null &&
              raiser['lifecycle_stage'].toString().trim().isNotEmpty &&
              raiser['lifecycle_stage'] != 'N/A')
          ? raiser['lifecycle_stage'].toString().trim()
          : 'N/A';

      if (assignments.isNotEmpty) {
        if (resolvedPigType == 'N/A') {
          resolvedPigType = assignments[0]['hog_types']?['type_name']?.toString() ??
              assignments[0]['pig_type']?.toString() ??
              'N/A';
        }
        if (resolvedStage == 'N/A') {
          resolvedStage = assignments[0]['lifecycle_stage']?.toString() ??
              assignments[0]['current_stage']?.toString() ??
              'N/A';
        }
      }

      final Map<String, dynamic> combinedRaiserData = Map<String, dynamic>.from(raiser);
      combinedRaiserData['email'] = resolvedEmail;
      if (resolvedAvatar != null) combinedRaiserData['avatar_url'] = resolvedAvatar;
      combinedRaiserData['pig_type'] = resolvedPigType;
      combinedRaiserData['lifecycle_stage'] = resolvedStage;

      if (mounted) {
        setState(() {
          _raiserData = combinedRaiserData;
          _investedAmount = totalCapital;
          _activeAssignments = assignments;
          _hogsList = hogs;
          _requestsList = requests;
          _reportsList = reports;
          _notificationsList = notifications;
          if (_activeAssignments.isNotEmpty) {
            _selectedAssignmentId = BigInt.from(_activeAssignments[0]['assignment_id'] as num);
          }
        });
      }
    } catch (e, stacktrace) {
      debugPrint('DEBUG ERROR in _fetchRaiserData: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '$e\n\nSTACKTRACE:\n$stacktrace';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      await Supabase.instance.client
          .from('raiser_notifications')
          .update({'is_read': true})
          .eq('notification_id', notificationId);
      await _fetchRaiserData();
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> _markAllRead() async {
    final raiserId = _raiserData['hog_raiser_id'] ?? _raiserData['id'];
    if (raiserId != null) {
      try {
        await Supabase.instance.client
            .from('raiser_notifications')
            .update({'is_read': true})
            .eq('hog_raiser_id', raiserId);
        await _fetchRaiserData();
      } catch (e) {
        debugPrint('Error marking all read: $e');
      }
    }
  }

  Future<void> _updateLifecycleStage(String targetStage) async {
    final raiserId = _raiserData['hog_raiser_id'] ?? _raiserData['id'];
    if (raiserId == null) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('hog_raisers')
          .update({'lifecycle_stage': targetStage})
          .eq('hog_raiser_id', raiserId);

      await _fetchRaiserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Matagumpay na nailipat ang stage sa $targetStage!',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            backgroundColor: PiggyTrunkTheme.ptSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update stage: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitHogReport(BigInt hogId, String reportType, String notes) async {
    final raiserId = _raiserData['hog_raiser_id'] ?? _raiserData['id'];
    if (raiserId == null) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('hog_reports').insert({
        'hog_id': hogId.toInt(),
        'hog_raiser_id': raiserId,
        'report_type': reportType,
        'description': notes.isNotEmpty ? notes : null,
      });

      String nextHealth = 'Healthy';
      if (reportType == 'Sick' || reportType == 'Food Poisoning' || reportType == 'Fever' || reportType == 'Diarrhea') {
        nextHealth = 'Sick';
      } else if (reportType == 'Dead') {
        nextHealth = 'Dead';
      }

      final Map<String, dynamic> updateData = {'health_status': nextHealth};
      if (nextHealth == 'Dead') {
        updateData['status'] = 'dead';
      }

      await Supabase.instance.client
          .from('hogs')
          .update(updateData)
          .eq('hog_id', hogId.toInt());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Matagumpay na naipadala ang Hog Report!'),
            backgroundColor: PiggyTrunkTheme.ptSuccess,
          ),
        );
      }

      await _fetchRaiserData();
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    await AuthSessionService().clearSession();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final raiserId = _raiserData['hog_raiser_id'] ?? _raiserData['id'];
    if (raiserId == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final bytes = await image.readAsBytes();
      final fileName = 'avatar-$raiserId-${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = 'avatars/$fileName';

      await Supabase.instance.client.storage.from('profile_pictures').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = Supabase.instance.client.storage.from('profile_pictures').getPublicUrl(filePath);

      // 1. Update Supabase Auth user metadata (always supported)
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'avatar_url': publicUrl, 'picture': publicUrl}),
        );
      } catch (authErr) {
        debugPrint('Auth metadata update notice: $authErr');
      }

      // 2. Update hog_raisers table if column exists
      try {
        await Supabase.instance.client.from('hog_raisers').update({
          'avatar_url': publicUrl,
        }).eq('hog_raiser_id', raiserId);
      } catch (dbErr) {
        debugPrint('DB column update notice: $dbErr');
      }

      if (mounted) {
        setState(() {
          _raiserData['avatar_url'] = publicUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Matagumpay na na-update ang inyong profile picture!'),
            backgroundColor: PiggyTrunkTheme.ptSuccess,
          ),
        );
      }

      await _fetchRaiserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: _brandColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreDefaultAvatar() async {
    final raiserId = _raiserData['hog_raiser_id'] ?? _raiserData['id'];
    if (raiserId == null) return;

    setState(() => _isLoading = true);

    try {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'avatar_url': null, 'picture': null}),
        );
      } catch (_) {}

      try {
        await Supabase.instance.client.from('hog_raisers').update({
          'avatar_url': null,
        }).eq('hog_raiser_id', raiserId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _raiserData.remove('avatar_url');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nabalik sa default ang inyong profile picture!'),
            backgroundColor: PiggyTrunkTheme.ptSuccess,
          ),
        );
      }

      await _fetchRaiserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring image: ${e.toString()}'),
            backgroundColor: _brandColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditProfileDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentName = _raiserData['name'] ?? '';
    final currentPhone = _raiserData['phone'] ?? '';
    final currentAddress = _raiserData['address'] ?? '';

    final nameController = TextEditingController(text: currentName == 'N/A' ? '' : currentName);
    final phoneController = TextEditingController(text: currentPhone == 'N/A' ? '' : currentPhone);
    final addressController = TextEditingController(text: currentAddress == 'N/A' ? '' : currentAddress);

    final sheetBg = isDark ? const Color(0xFF151F2E) : Colors.white;
    final titleColor = isDark ? const Color(0xFFECF2FF) : _brandColor;
    final inputBg = isDark ? const Color(0xFF1B2A3F) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF2A3C55) : const Color(0xFFE2E8F0);
    final hintColor = isDark ? const Color(0xFF8A9FB8) : PiggyTrunkTheme.ptMuted;

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
                              color: isDark ? const Color(0xFF93C5FD) : _brandColor,
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

                  // 1. Pangalan
                  Text(
                    'Buong Pangalan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: titleColor, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Ilagay ang inyong buong pangalan',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: hintColor),
                      prefixIcon: Icon(Icons.badge_outlined, color: hintColor, size: 20),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF60A5FA) : _brandColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Phone Number (Numerical Only!)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Telepono / Phone Number',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        'Numbers only (11 digits)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: titleColor, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '09XXXXXXXXX',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: hintColor),
                      prefixIcon: Icon(Icons.phone_iphone_rounded, color: hintColor, size: 20),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF60A5FA) : _brandColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Address
                  Text(
                    'Address',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: titleColor, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Ilagay ang inyong kumpletong address',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: hintColor),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.location_on_outlined, color: hintColor, size: 20),
                      ),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF60A5FA) : _brandColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
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
                            final newName = nameController.text.trim();
                            final newPhone = phoneController.text.trim();
                            final newAddr = addressController.text.trim();

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

                            Navigator.pop(ctx);
                            await _updateProfile(
                              newName,
                              newPhone,
                              newAddr,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : _brandColor,
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

  Future<void> _updateProfile(String newName, String newPhone, String newAddress) async {
    final raiserId = _raiserData['hog_raiser_id'] ?? _raiserData['id'];
    if (raiserId == null) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('hog_raisers').update({
        'name': newName,
        'phone': newPhone,
        'address': newAddress,
      }).eq('hog_raiser_id', raiserId);

      final userId = _raiserData['user_id'];
      if (userId != null) {
        try {
          await Supabase.instance.client.from('app_users').update({
            'name': newName,
          }).eq('user_id', userId);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Matagumpay na nai-save ang inyong profile!'),
            backgroundColor: PiggyTrunkTheme.ptSuccess,
          ),
        );
      }

      await _fetchRaiserData();
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If on a sub-tab (Requests, Hogs, Profile), switch to Home tab
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // If on Home tab, require double-tap within 2 seconds to exit app safely
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pindutin ulit ang Back button upang isara ang app.'),
              duration: Duration(seconds: 2),
              backgroundColor: _brandColor,
            ),
          );
          return;
        }

        // Close the application directly without popping back to login
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: PiggyTrunkTheme.ptBg,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
                ),
              )
            : SafeArea(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    RaiserHomeTab(
                      raiserData: _raiserData,
                      investedAmount: _investedAmount,
                      requestsList: _requestsList,
                      notificationsList: _notificationsList,
                      errorMessage: _errorMessage,
                      onRefresh: _fetchRaiserData,
                      onNavigateToTab: (index) => setState(() => _currentIndex = index),
                      onMarkNotificationAsRead: _markNotificationAsRead,
                      onMarkAllRead: _markAllRead,
                      onUpdateLifecycleStage: _updateLifecycleStage,
                    ),
                    RaiserRequestTab(
                      activeAssignments: _activeAssignments,
                      raiserData: _raiserData,
                      requestsList: _requestsList,
                      onRefresh: _fetchRaiserData,
                    ),
                    RaiserHogsTab(
                      raiserData: _raiserData,
                      hogsList: _hogsList,
                      reportsList: _reportsList,
                      notificationsList: _notificationsList,
                      selectedAssignmentId: _selectedAssignmentId,
                      onRefresh: _fetchRaiserData,
                      onMarkNotificationAsRead: _markNotificationAsRead,
                      onMarkAllRead: _markAllRead,
                      onSubmitHogReport: _submitHogReport,
                    ),
                    RaiserProfileTab(
                      raiserData: _raiserData,
                      onPickAndUploadAvatar: _pickAndUploadAvatar,
                      onRestoreDefaultAvatar: _restoreDefaultAvatar,
                      onShowEditProfileDialog: _showEditProfileDialog,
                      onHandleSignOut: _handleSignOut,
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _brandColor,
          unselectedItemColor: const Color(0xffa0aec0),
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/sidebar/dashboard.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(Color(0xffa0aec0), BlendMode.srcIn),
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/sidebar/dashboard.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(_brandColor, BlendMode.srcIn),
              ),
              label: 'DASHBOARD',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              label: 'REQUEST',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'HOGS',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}
