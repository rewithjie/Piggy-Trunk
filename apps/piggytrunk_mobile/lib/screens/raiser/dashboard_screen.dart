import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

      // 1. Fetch user profile from app_users
      var appUser = await Supabase.instance.client
          .from('app_users')
          .select('user_id, name')
          .eq('supabase_user_id', user.id)
          .maybeSingle();

      if (appUser == null) {
        final appUserByEmail = await Supabase.instance.client
            .from('app_users')
            .select('user_id, name, supabase_user_id')
            .eq('email', user.email!)
            .maybeSingle();

        if (appUserByEmail != null) {
          await Supabase.instance.client
              .from('app_users')
              .update({'supabase_user_id': user.id})
              .eq('user_id', appUserByEmail['user_id']);

          appUser = {
            'user_id': appUserByEmail['user_id'],
            'name': appUserByEmail['name'],
          };
        } else {
          if (mounted) {
            setState(() {
              _raiserData = {
                'name': 'Account Not Found',
                'email': user.email,
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
      final fallbackName = appUser['name'] as String;

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
                'email': user.email,
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

      if (mounted) {
        setState(() {
          _raiserData = raiser!;
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
    await Supabase.instance.client.auth.signOut();
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

      await Supabase.instance.client.from('hog_raisers').update({
        'avatar_url': publicUrl,
      }).eq('hog_raiser_id', raiserId);

      if (mounted) {
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
      await Supabase.instance.client.from('hog_raisers').update({
        'avatar_url': null,
      }).eq('hog_raiser_id', raiserId);

      if (mounted) {
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
    final currentName = _raiserData['name'] ?? '';
    final currentPhone = _raiserData['phone'] ?? '';
    final currentAddress = _raiserData['address'] ?? '';

    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final addressController = TextEditingController(text: currentAddress);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'I-edit ang Profile',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: _brandColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pangalan',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _brandColor),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _brandColor),
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang inyong pangalan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Telepono / Phone Number',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _brandColor),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _brandColor),
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang inyong numero',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Address',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _brandColor),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _brandColor),
                  decoration: InputDecoration(
                    hintText: 'Ilagay ang inyong address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Kanselahin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateProfile(
                  nameController.text.trim(),
                  phoneController.text.trim(),
                  addressController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'I-save',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
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
    return Scaffold(
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
    );
  }
}
