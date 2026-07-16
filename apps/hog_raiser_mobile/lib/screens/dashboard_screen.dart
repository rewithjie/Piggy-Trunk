import 'dart:ui' show PathMetric;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:piggytrunk/widgets/piggy_trunk_logo.dart';
import 'request_form_screen.dart';
import 'request_history_screen.dart';
import 'package:image_picker/image_picker.dart';

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
  
  // Form variables
  BigInt? _selectedAssignmentId;
  bool _isSubmittingRequest = false;
  String? _errorMessage;
  String _requestView = 'home';
  String? _previousRequestView;

  // Web style neutral colors
  static const Color _brandColor = Color(0xFF18314F);
  static const Color _gradientEndColor = Color(0xFF3B5270);

  @override
  void initState() {
    super.initState();
    _fetchRaiserData();
  }

  Future<void> _fetchRaiserData() async {
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
        debugPrint('DEBUG WARNING: No app_users record found for supabase_user_id: ${user.id}. Querying by email instead...');
        final appUserByEmail = await Supabase.instance.client
            .from('app_users')
            .select('user_id, name, supabase_user_id')
            .eq('email', user.email!)
            .maybeSingle();

        if (appUserByEmail != null) {
          debugPrint('DEBUG INFO: Found app_users record by email: ${user.email}. Linking supabase_user_id...');
          await Supabase.instance.client
              .from('app_users')
              .update({'supabase_user_id': user.id})
              .eq('user_id', appUserByEmail['user_id']);
          
          appUser = {
            'user_id': appUserByEmail['user_id'],
            'name': appUserByEmail['name'],
          };
          debugPrint('DEBUG SUCCESS: Linked app_users record successfully.');
        } else {
          debugPrint('DEBUG ERROR: No app_users record found by email either.');
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
          return;
        }
      }

      final userId = appUser['user_id'];
      final fallbackName = appUser['name'] as String;
      debugPrint('DEBUG INFO: Found app_users userId: $userId, Name: $fallbackName');

      // 2. Fetch raiser profile
      var raiser = await Supabase.instance.client
          .from('hog_raisers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (raiser == null) {
        debugPrint('DEBUG WARNING: No hog_raisers record found for user_id: $userId. Querying by email instead...');
        final raiserByEmail = await Supabase.instance.client
            .from('hog_raisers')
            .select()
            .eq('email', user.email!)
            .maybeSingle();

        if (raiserByEmail != null) {
          debugPrint('DEBUG INFO: Found hog_raisers record by email: ${user.email}. Linking user_id: $userId...');
          await Supabase.instance.client
              .from('hog_raisers')
              .update({'user_id': userId})
              .eq('hog_raiser_id', raiserByEmail['hog_raiser_id']);
          
          // Re-fetch the raiser profile now that it is linked
          raiser = await Supabase.instance.client
              .from('hog_raisers')
              .select()
              .eq('user_id', userId)
              .maybeSingle();
          debugPrint('DEBUG SUCCESS: Linked hog_raisers record successfully.');
        } else {
          debugPrint('DEBUG ERROR: No hog_raisers record found by email either.');
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
          return;
        }
      }

      if (raiser == null) {
        debugPrint('DEBUG ERROR: Hog raiser profile mapping still unresolved.');
        return;
      }

      final raiserId = raiser['hog_raiser_id'] ?? raiser['id'];
      if (raiserId == null) {
        throw Exception('Raiser ID is null! Keys in raiser: ${raiser.keys.toList()}. Values in raiser: ${raiser.values.toList()}');
      }
      debugPrint('DEBUG INFO: Found hog_raiser_id: $raiserId. Loading other records...');

      // 3. Fetch total capital invested from investment_records
      final capitalRes = await Supabase.instance.client
          .from('investment_records')
          .select('initial_capital')
          .eq('hog_raiser_id', raiserId.toString());

      double totalCapital = 0.0;
      for (var row in capitalRes) {
        totalCapital += (row['initial_capital'] as num).toDouble();
      }
      debugPrint('DEBUG INFO: Total Capital Invested: $totalCapital');

      // 4. Fetch assignments
      final assignmentsRes = await Supabase.instance.client
          .from('assignments')
          .select('*, hog_types(*), batches(*)')
          .eq('hog_raiser_id', raiserId)
          .eq('status', 'active');
      final assignments = List<Map<String, dynamic>>.from(assignmentsRes);
      debugPrint('DEBUG INFO: Loaded ${assignments.length} assignments.');

      // 5. Fetch hogs
      final hogsRes = await Supabase.instance.client
          .from('hogs')
          .select('*, assignments!inner(*, hog_types(*))')
          .eq('assignments.hog_raiser_id', raiserId);
      final hogs = List<Map<String, dynamic>>.from(hogsRes);
      debugPrint('DEBUG INFO: Loaded ${hogs.length} hogs.');

      // 6. Fetch requests
      final requestsRes = await Supabase.instance.client
          .from('stock_requests')
          .select('*, assignments(*, batches(*))')
          .eq('hog_raiser_id', raiserId)
          .order('request_date', ascending: false);
      final requests = List<Map<String, dynamic>>.from(requestsRes);
      debugPrint('DEBUG INFO: Loaded ${requests.length} requests.');

      // 7. Fetch hog reports
      List<Map<String, dynamic>> reports = [];
      try {
        final reportsRes = await Supabase.instance.client
            .from('hog_reports')
            .select('*, hogs(*)')
            .eq('hog_raiser_id', raiserId)
            .order('created_at', ascending: false);
        reports = List<Map<String, dynamic>>.from(reportsRes);
        debugPrint('DEBUG INFO: Loaded ${reports.length} reports.');
      } catch (err) {
        debugPrint('DEBUG WARN: Failed to fetch hog_reports, table might be empty or missing: $err');
      }

      // 8. Fetch notifications
      List<Map<String, dynamic>> notifications = [];
      try {
        final notifRes = await Supabase.instance.client
            .from('raiser_notifications')
            .select('*')
            .eq('hog_raiser_id', raiserId)
            .order('created_at', ascending: false);
        notifications = List<Map<String, dynamic>>.from(notifRes);
        debugPrint('DEBUG INFO: Loaded ${notifications.length} notifications.');
      } catch (err) {
        debugPrint('DEBUG WARN: Failed to fetch raiser_notifications: $err');
      }

      setState(() {
        _raiserData = {
          ...raiser!,
          'name': raiser['name'] ?? fallbackName,
          'email': user.email,
        };
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
    } catch (e, stacktrace) {
      debugPrint('DEBUG ERROR: Exception in _fetchRaiserData: $e');
      debugPrint(stacktrace.toString());
      setState(() {
        _errorMessage = '$e\n\nSTACKTRACE:\n$stacktrace';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      await Supabase.instance.client
          .from('raiser_notifications')
          .update({'is_read': true})
          .eq('notification_id', notificationId);
      // Reload notifications list
      _fetchRaiserData();
    } catch (e) {
      debugPrint('DEBUG ERROR: Failed to mark notification as read: $e');
    }
  }

  void _showNotificationsBottomSheet() {
    final unreadCount = _notificationsList.where((n) => n['is_read'] == false).length;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag indicator
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mga Notification',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _brandColor,
                          ),
                        ),
                        if (unreadCount > 0)
                          TextButton(
                            onPressed: () async {
                              final raiserId = _raiserData['hog_raiser_id'] ?? _raiserData['id'];
                              if (raiserId != null) {
                                try {
                                  await Supabase.instance.client
                                      .from('raiser_notifications')
                                      .update({'is_read': true})
                                      .eq('hog_raiser_id', raiserId);
                                  
                                  // Fetch fresh data
                                  await _fetchRaiserData();
                                  setBottomSheetState(() {});
                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  debugPrint('Error marking all read: $e');
                                }
                              }
                            },
                            child: Text(
                              'Mark all as read',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: PiggyTrunkTheme.ptSuccess,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // Notification list
                  Expanded(
                    child: _notificationsList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Walang notification sa kasalukuyan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _notificationsList.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final notif = _notificationsList[index];
                              final isRead = notif['is_read'] == true;
                              final dateStr = _formatDate(notif['created_at']);
                              
                              IconData iconData = Icons.notifications_none;
                              Color iconColor = _brandColor;
                              
                              if (notif['type'] == 'request_status') {
                                final status = notif['metadata']?['status']?.toString().toLowerCase() ?? '';
                                if (status == 'approved') {
                                  iconData = Icons.check_circle_outline;
                                  iconColor = PiggyTrunkTheme.ptSuccess;
                                } else if (status == 'rejected') {
                                  iconData = Icons.cancel_outlined;
                                  iconColor = _brandColor;
                                } else {
                                  iconData = Icons.help_outline;
                                  iconColor = PiggyTrunkTheme.ptInProgress;
                                }
                              } else if (notif['type'] == 'batch_assigned') {
                                iconData = Icons.assignment_turned_in_outlined;
                                iconColor = PiggyTrunkTheme.ptSuccess;
                              }
                              
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconData, color: iconColor, size: 24),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif['title'] ?? '',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                          color: _brandColor,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      notif['message'] ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  if (!isRead) {
                                    await _markNotificationAsRead(notif['notification_id']);
                                    setBottomSheetState(() {});
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('DEBUG ERROR: Exception in _updateLifecycleStage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update stage: ${e.toString()}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
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

  Future<void> _submitStockRequest() async {
    if (_selectedAssignmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paki-pili ang assignment batch para sa request.')),
      );
      return;
    }

    setState(() => _isSubmittingRequest = true);

    try {
      final raiserId = _raiserData['hog_raiser_id'];
      if (raiserId == null) throw Exception('Raiser profile is not available.');

      await Supabase.instance.client.from('stock_requests').insert({
        'assignment_id': _selectedAssignmentId!.toInt(),
        'hog_raiser_id': raiserId,
        'status': 'pending',
        'request_date': DateTime.now().toIso8601String().split('T').first,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Matagumpay na naipadala ang Stock Request!'),
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
      setState(() => _isSubmittingRequest = false);
    }
  }

  Future<void> _handleSignOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
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
                  _buildDashboardTab(),
                  _buildRequestTab(),
                  _buildHogsTab(),
                  _buildProfileTab(),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'DASHBOARD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'REQUEST',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'HOGS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }

  // ==================== DASHBOARD TAB ====================
  Widget _buildDashboardTab() {
    final raiserName = _raiserData['name'] ?? 'Hog Raiser';
    final formattedAmount = _investedAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    final String? pigType = _raiserData['pig_type'];

    return RefreshIndicator(
      onRefresh: _fetchRaiserData,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'DEBUG DATABASE ERROR:\n$_errorMessage',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.red[800],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello Hog Raiser,',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: PiggyTrunkTheme.ptMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      raiserName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _brandColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, color: _brandColor),
                      onPressed: () {},
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_outlined, color: _brandColor),
                          onPressed: _showNotificationsBottomSheet,
                        ),
                        if (_notificationsList.any((n) => n['is_read'] == false))
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
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
            const SizedBox(height: 24),

            // Invested Amount Card (Slate Blue Web Gradient)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _brandColor,
                    _gradientEndColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _brandColor.withValues(alpha: 0.20),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invested Amount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₱ $formattedAmount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          color: _brandColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Feeds Stages Card - Render conditionally based on DB sync
            if (pigType == 'Fattening') ...[
              _buildFeedsCard(
                title: 'Feeds Stages',
                badgeText: 'Fattening',
                stages: const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Finisher', 'Selling'],
                activeStage: _raiserData['lifecycle_stage'] ?? 'Booster',
              ),
              const SizedBox(height: 28),
            ] else if (pigType == 'Sow') ...[
              _buildFeedsCard(
                title: 'Feeds Stages',
                badgeText: 'Sow',
                stages: const ['Booster', 'Pre-Starter', 'Starter', 'Grower', 'Breeder', 'Lactation'],
                activeStage: _raiserData['lifecycle_stage'] ?? 'Booster',
              ),
              const SizedBox(height: 28),
            ] else ...[
              // Empty State for Feeds Stages
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PiggyTrunkTheme.ptBorder),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.assignment_late_outlined, size: 40, color: Color(0xffa0aec0)),
                      const SizedBox(height: 12),
                      Text(
                        'Walang nakatalagang feeds stage.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Recent Activities Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: Text(
                    'See all',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _brandColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recent Activities List (Strict DB sync - no placeholder mocks)
            _requestsList.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PiggyTrunkTheme.ptBorder),
                    ),
                    child: Center(
                      child: Text(
                        'Walang kamakailang aktibidad.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: _requestsList.take(3).map((req) {
                      final dateStr = _formatDate(req['request_date']);
                      final status = req['status'] as String;
                      final batchName = req['assignments']?['batches']?['batch_name'] ?? 'N/A';
                      
                      return _buildActivityItem(
                        icon: Icons.assignment_outlined,
                        title: 'Stock Request ($batchName)',
                        subtitle: '$dateStr • Status: ${status.toUpperCase()}',
                        isCompleted: status.toLowerCase() == 'approved',
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedsCard({
    required String title,
    required String badgeText,
    required List<String> stages,
    required String activeStage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PiggyTrunkTheme.ptBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _brandColor,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _brandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _brandColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.more_vert, color: Color(0xffa0aec0), size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTimeline(stages, activeStage),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<String> stages, String activeStage) {
    int activeIndex = stages.indexWhere((s) => s.toLowerCase() == activeStage.toLowerCase());
    if (activeIndex == -1) {
      activeIndex = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final stepWidth = totalWidth / stages.length;

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            // Background line connecting circles
            Positioned(
              top: 15,
              left: stepWidth / 2,
              right: stepWidth / 2,
              child: Row(
                children: List.generate(stages.length - 1, (index) {
                  final isPassed = index < activeIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      color: isPassed ? _brandColor : const Color(0xffe6ebf2),
                    ),
                  );
                }),
              ),
            ),
            // Circles and Text Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (index) {
                final isPassed = index < activeIndex;
                final isActive = index == activeIndex;
                final isFuture = index > activeIndex;

                Color circleColor;
                Widget iconWidget;

                if (isPassed) {
                  circleColor = _brandColor;
                  iconWidget = const Icon(Icons.check, size: 14, color: Colors.white);
                } else if (isActive) {
                  circleColor = _brandColor;
                  iconWidget = const Icon(Icons.priority_high_rounded, size: 16, color: Colors.white);
                } else {
                  circleColor = const Color(0xffe6ebf2);
                  iconWidget = const Icon(Icons.lock, size: 12, color: Color(0xffa0aec0));
                }

                return GestureDetector(
                  onTap: () {
                    if (isActive) return;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'Baguhin ang Active Stage?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _brandColor,
                          ),
                        ),
                        content: Text(
                          'Gusto mo bang baguhin ang stage ng iyong alagang baboy mula sa "$activeStage" patungong "${stages[index]}"?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF5D6A7B),
                            height: 1.4,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'I-cancel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xffa0aec0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateLifecycleStage(stages[index]);
                            },
                            child: Text(
                              'Oo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: _brandColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: SizedBox(
                    width: stepWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isActive ? 34 : 28,
                          height: isActive ? 34 : 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: circleColor,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: _brandColor.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(child: iconWidget),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stages[index],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                            color: isActive
                                ? _brandColor
                                : (isFuture ? const Color(0xffa0aec0) : _brandColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PiggyTrunkTheme.ptBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xfff7f8fb),
              shape: BoxShape.circle,
              border: Border.all(color: PiggyTrunkTheme.ptBorder),
            ),
            child: Icon(
              icon,
              color: _brandColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PiggyTrunkTheme.ptMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REQUEST TAB ====================
  Widget _buildRequestTab() {
    if (_requestView == 'form') {
      return RequestFormScreen(
        activeAssignments: _activeAssignments,
        raiserData: _raiserData,
        onBack: () {
          setState(() {
            _requestView = 'home';
          });
        },
        onSuccess: () {
          setState(() {
            _requestView = 'home';
          });
          _fetchRaiserData();
        },
        onViewHistory: () {
          setState(() {
            _previousRequestView = 'form';
            _requestView = 'history';
          });
        },
      );
    } else if (_requestView == 'history') {
      return RequestHistoryScreen(
        raiserData: _raiserData,
        onBack: () {
          setState(() {
            _requestView = _previousRequestView ?? 'home';
            _previousRequestView = null;
          });
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row matching mockup (Requests, Search, Notifications)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Requests',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _brandColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: _brandColor),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded, color: _brandColor),
                    onPressed: () {
                      setState(() {
                        _previousRequestView = 'home';
                        _requestView = 'history';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Dashed Request stocks action button
          GestureDetector(
            onTap: () {
              setState(() {
                _requestView = 'form';
              });
            },
            child: CustomPaint(
              painter: DashedRectPainter(
                color: _brandColor.withValues(alpha: 0.3),
                gap: 5.0,
              ),
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _brandColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 28,
                          color: _brandColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Request Stocks',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _brandColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Requests Activity',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _brandColor,
            ),
          ),
          const SizedBox(height: 12),

          // Request logs list (Strict DB sync - no placeholder mocks)
          Expanded(
            child: _requestsList.isEmpty
                ? Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PiggyTrunkTheme.ptBorder),
                      ),
                      child: Center(
                        child: Text(
                          'Walang kamakailang aktibidad.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: PiggyTrunkTheme.ptMuted,
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _requestsList.length,
                    itemBuilder: (context, index) {
                      final req = _requestsList[index];
                      final dateStr = _formatDate(req['request_date']);
                      final status = req['status'] as String;
                      final quantity = req['quantity'] ?? 1;
                      final category = req['category'] ?? 'Feeds';
                      final feedType = req['feed_type'];
                      final batchName = req['assignments']?['batches']?['batch_name'] ?? 'Batch';
                      
                      Color statusColor = const Color(0xffa0aec0);
                      if (status.toLowerCase() == 'approved') {
                        statusColor = PiggyTrunkTheme.ptSuccess;
                      } else if (status.toLowerCase() == 'pending') {
                        statusColor = PiggyTrunkTheme.ptInProgress;
                      } else if (status.toLowerCase() == 'rejected') {
                        statusColor = _brandColor;
                      }

                      IconData icon = Icons.shopping_basket_outlined;
                      if (category == 'Vitamins') {
                        icon = Icons.favorite_border_rounded;
                      } else if (category == 'Medicine') {
                        icon = Icons.medication_liquid_outlined;
                      }

                      String titleText = '$quantity Sacks of $category';
                      if (category == 'Feeds' && feedType != null) {
                        titleText = '$quantity Sacks of $feedType';
                      } else if (category != 'Feeds') {
                        titleText = '$quantity Items of $category';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PiggyTrunkTheme.ptBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _brandColor.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: _brandColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleText,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _brandColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$batchName • $dateStr',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: PiggyTrunkTheme.ptMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatReportTime(String? createdAtStr) {
    if (createdAtStr == null) return 'N/A';
    try {
      final created = DateTime.parse(createdAtStr);
      final now = DateTime.now();
      final diff = now.difference(created);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (_) {
      return '';
    }
  }

  Future<void> _submitHogReport(BigInt hogId, String reportType, String notes) async {
    final raiserId = _raiserData['hog_raiser_id'] ?? _raiserData['id'];
    if (raiserId == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Insert report record
      await Supabase.instance.client.from('hog_reports').insert({
        'hog_id': hogId.toInt(),
        'hog_raiser_id': raiserId,
        'report_type': reportType,
        'description': notes.isNotEmpty ? notes : null,
      });

      // 2. Automatically sync state by updating hog health_status
      String nextHealth = 'Healthy';
      if (reportType == 'Sick' || reportType == 'Food Poisoning' || reportType == 'Fever' || reportType == 'Diarrhea') {
        nextHealth = 'Sick';
      } else if (reportType == 'Dead') {
        nextHealth = 'Dead';
      }

      await Supabase.instance.client
          .from('hogs')
          .update({'health_status': nextHealth})
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
      debugPrint('DEBUG ERROR: Exception in _submitHogReport: $e');
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

  void _showAddReportDialog() {
    BigInt? selectedHogId;
    if (_hogsList.isNotEmpty) {
      selectedHogId = BigInt.from(_hogsList[0]['hog_id'] as num);
    }
    String selectedReportType = 'Food Poisoning';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Mag-submit ng Hog Report',
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
                      'Piliin ang Baboy / Hog ID',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _brandColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _hogsList.isEmpty
                        ? Text(
                            'Walang nakatalagang baboy.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: PiggyTrunkTheme.ptMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : DropdownButtonFormField<BigInt>(
                            value: selectedHogId,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: _brandColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              fillColor: const Color(0xfff7f8fb),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            items: _hogsList.map((h) {
                              final id = h['hog_id'];
                              final type = h['assignments']?['hog_types']?['type_name'] ?? 'N/A';
                              return DropdownMenuItem<BigInt>(
                                value: BigInt.from(id as num),
                                child: Text('Hog ID: #$id ($type)'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                selectedHogId = val;
                              });
                            },
                          ),
                    const SizedBox(height: 16),
                    Text(
                      'Piliin ang Kondisyon / Report Type',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _brandColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedReportType,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: _brandColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        fillColor: const Color(0xfff7f8fb),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Food Poisoning', child: Text('Food Poisoning (Pagkalason)')),
                        DropdownMenuItem(value: 'Fever', child: Text('Fever (Lagnat)')),
                        DropdownMenuItem(value: 'Diarrhea', child: Text('Diarrhea (Pagtatae)')),
                        DropdownMenuItem(value: 'Sick', child: Text('Sick (May Sakit)')),
                        DropdownMenuItem(value: 'Dead', child: Text('Dead (Namatay)')),
                        DropdownMenuItem(value: 'Other', child: Text('Other (Iba pa)')),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedReportType = val ?? 'Food Poisoning';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Notes / Paliwanag',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _brandColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _brandColor),
                      decoration: InputDecoration(
                        hintText: 'Iulat ang mga detalye ng kondisyon...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xffa0aec0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'I-cancel', 
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xffa0aec0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: selectedHogId == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _submitHogReport(selectedHogId!, selectedReportType, notesController.text.trim());
                        },
                  child: Text(
                    'I-submit', 
                    style: GoogleFonts.plusJakartaSans(
                      color: _brandColor, 
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== HOGS TAB ====================
  Widget _buildHogsTab() {
    final String? pigType = _raiserData['pig_type'];

    return RefreshIndicator(
      onRefresh: _fetchRaiserData,
      color: _brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row matching mockup (Hog Status, Search, Notification bell)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hog Status',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _brandColor,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, color: _brandColor),
                      onPressed: () {},
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: _brandColor),
                          onPressed: _showNotificationsBottomSheet,
                        ),
                        if (_notificationsList.any((n) => n['is_read'] == false))
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
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
            const SizedBox(height: 20),

            Text(
              pigType != null ? 'HOG ${pigType.toUpperCase()}' : 'HOG STATUS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _brandColor,
              ),
            ),
            const SizedBox(height: 16),

            // Feeds Stages Progress card (calling _buildFeedsCard!)
            if (pigType == 'Fattening') ...[
              _buildFeedsCard(
                title: 'Feeds Stages',
                badgeText: 'Fattening',
                stages: const ['Booster', 'Pre-starter', 'Starter', 'Grower', 'Finisher'],
                activeStage: _raiserData['lifecycle_stage'] ?? 'Grower',
              ),
              const SizedBox(height: 20),
            ] else if (pigType == 'Sow') ...[
              _buildFeedsCard(
                title: 'Feeds Stages',
                badgeText: 'Sow',
                stages: const ['Booster', 'Pre-starter', 'Starter', 'Grower', 'Breeder', 'Lactation'],
                activeStage: _raiserData['lifecycle_stage'] ?? 'Breeder',
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Empty State
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PiggyTrunkTheme.ptBorder),
                ),
                child: Center(
                  child: Text(
                    'Walang nakatalagang feeds stage.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PiggyTrunkTheme.ptMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Add Report Button matching mockup (Align Right, Green)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _showAddReportDialog,
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(
                  'Add Report',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B33), // Green theme matching mockup!
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Report Activity Title Row with See All
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report Activity',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
                ),
                Text(
                  'See All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFef5b6c), // Pinkish text matching mockup!
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List of reported activities
            _reportsList.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PiggyTrunkTheme.ptBorder),
                    ),
                    child: Center(
                      child: Text(
                        'Walang naitalang ulat sa kalusugan.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PiggyTrunkTheme.ptMuted,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reportsList.length,
                    itemBuilder: (context, index) {
                      final report = _reportsList[index];
                      final type = report['report_type'] ?? 'Report';
                      final timeAgo = _formatReportTime(report['created_at']);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PiggyTrunkTheme.ptBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xffef5b6c).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xffef5b6c),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _brandColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: PiggyTrunkTheme.ptMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.more_vert, color: Color(0xffa0aec0), size: 20),
                          ],
                        ),
                      );
                    },
                  ),
          ],
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
      debugPrint('DEBUG ERROR: Exception in _updateProfile: $e');
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'I-cancel', 
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xffa0aec0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateProfile(
                  nameController.text.trim(),
                  phoneController.text.trim(),
                  addressController.text.trim(),
                );
              },
              child: Text(
                'I-save', 
                style: GoogleFonts.plusJakartaSans(
                  color: _brandColor, 
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
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

      // 1. Upload to Supabase Storage
      await Supabase.instance.client.storage.from('profile_pictures').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // 2. Get Public URL
      final publicUrl = Supabase.instance.client.storage.from('profile_pictures').getPublicUrl(filePath);

      // 3. Update in database
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
      debugPrint('DEBUG ERROR: Exception in _pickAndUploadAvatar: $e');
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
      // 1. Update database to set avatar_url to null
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
      debugPrint('DEBUG ERROR: Exception in _restoreDefaultAvatar: $e');
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

  // ==================== PROFILE TAB ====================
  Widget _buildProfileTab() {
    final name = _raiserData['name'] ?? 'Hog Raiser';
    final email = _raiserData['email'] ?? 'N/A';
    final phone = _raiserData['phone'] ?? 'N/A';
    final address = _raiserData['address'] ?? 'N/A';
    final type = _raiserData['pig_type'] ?? 'Fattening';
    final stage = _raiserData['lifecycle_stage'] ?? 'Grower';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Title
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _brandColor, width: 2),
                          color: const Color(0xfff7f8fb),
                        ),
                        child: ClipOval(
                          child: _raiserData['avatar_url'] != null && _raiserData['avatar_url'].toString().isNotEmpty
                              ? Image.network(
                                  _raiserData['avatar_url'],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/piggytrunk_logo.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, err, st) => Container(
                                      color: _brandColor,
                                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  'assets/piggytrunk_logo.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, err, st) => Container(
                                    color: _brandColor,
                                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: _brandColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _brandColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hog Raiser',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: PiggyTrunkTheme.ptMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detalye ng Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _brandColor,
                ),
              ),
              Row(
                children: [
                  if (_raiserData['avatar_url'] != null && _raiserData['avatar_url'].toString().isNotEmpty) ...[
                    GestureDetector(
                      onTap: _restoreDefaultAvatar,
                      child: Row(
                        children: [
                          const Icon(Icons.refresh, size: 16, color: _brandColor),
                          const SizedBox(width: 4),
                          Text(
                            'I-reset',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _brandColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 16, color: _brandColor),
                        const SizedBox(width: 4),
                        Text(
                          'I-edit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _brandColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Details List
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PiggyTrunkTheme.ptBorder),
            ),
            child: Column(
              children: [
                _buildProfileRow(Icons.email_outlined, 'Email Address', email),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.phone_iphone, 'Phone Number', phone),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.location_on_outlined, 'Address', address),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.style_outlined, 'Pig Type Assignment', type),
                const Divider(height: 24, color: PiggyTrunkTheme.ptBorder),
                _buildProfileRow(Icons.hourglass_empty_outlined, 'Current Stage', stage),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: _handleSignOut,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _brandColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Mag-Sign Out',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: _brandColor,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: PiggyTrunkTheme.ptMuted, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: PiggyTrunkTheme.ptMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _brandColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = const Color(0xFF18314F),
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    ));

    final Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) => false;
}
