import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import 'package:piggytrunk/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_session_service.dart';
import '../../utils/capitalization_formatters.dart';
import '../../utils/app_strings.dart';
import '../../widgets/piggy_toast.dart';

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
  double _initialCapital = 0.0;
  double _stocksSpendAmount = 0.0;
  List<Map<String, dynamic>> _providedStocksList = [];
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

      // 3. Fetch total capital invested and total hogs from investment_records
      final capitalRes = await Supabase.instance.client
          .from('investment_records')
          .select('initial_capital, total_hog, hog_type')
          .eq('hog_raiser_id', raiserId.toString());

      double totalCapital = 0.0;
      int totalHogsFromInvestment = 0;
      for (var row in (capitalRes as List? ?? [])) {
        totalCapital += (row['initial_capital'] as num?)?.toDouble() ?? 0.0;
        totalHogsFromInvestment += (row['total_hog'] as num?)?.toInt() ?? 0;
      }

      // 4. Fetch assignments
      final assignmentsRes = await Supabase.instance.client
          .from('assignments')
          .select('*, hog_types(*), batches(*)')
          .eq('hog_raiser_id', raiserId)
          .eq('status', 'active');
      final rawAssignments = List<Map<String, dynamic>>.from(assignmentsRes);
      final assignments = <Map<String, dynamic>>[];
      for (var a in rawAssignments) {
        final b = a['batches'] as Map<String, dynamic>?;
        if (b != null) {
          final bStatus = (b['status'] ?? '').toString().toLowerCase();
          if (bStatus != 'archived' && bStatus != 'deleted') {
            assignments.add(a);
          }
        } else {
          // Clean up orphaned assignment record
          try {
            Supabase.instance.client
                .from('assignments')
                .delete()
                .eq('assignment_id', a['assignment_id']);
          } catch (_) {}
        }
      }

      // 5. Fetch hogs
      List<dynamic> hogsRes = [];
      try {
        hogsRes = await Supabase.instance.client
            .from('hogs')
            .select('*, assignments!inner(*, hog_types(*))')
            .eq('assignments.hog_raiser_id', raiserId)
            .eq('assignments.status', 'active')
            .eq('status', 'active');
      } catch (_) {
        try {
          hogsRes = await Supabase.instance.client
              .from('hogs')
              .select('*')
              .eq('status', 'active');
        } catch (_) {}
      }

      var hogs = List<Map<String, dynamic>>.from(hogsRes)
          .where((h) => (h['health_status'] ?? '').toString().toLowerCase() != 'dead')
          .toList();

      // If hogs table is empty but investment assigned heads exist, auto-seed and display
      if (hogs.isEmpty && totalHogsFromInvestment > 0 && assignments.isNotEmpty) {
        final assignId = assignments[0]['assignment_id'] ?? assignments[0]['id'];
        final pigType = (raiser['pig_type'] ?? 'Fattening').toString();

        for (int i = 1; i <= totalHogsFromInvestment; i++) {
          try {
            await Supabase.instance.client.from('hogs').insert({
              'assignment_id': assignId,
              'status': 'active',
              'health_status': 'healthy',
              'weight': 15.0,
            });
          } catch (_) {}
        }

        hogs = List.generate(totalHogsFromInvestment, (i) => {
          'hog_id': i + 1,
          'assignment_id': assignId,
          'status': 'active',
          'health_status': 'healthy',
          'pig_type': pigType,
          'weight': 15.0,
        });
      }

      hogs.sort((a, b) {
        final aId = a['hog_id'] as num? ?? 0;
        final bId = b['hog_id'] as num? ?? 0;
        return aId.compareTo(bId);
      });

      // 6. Fetch stock requests & calculate distributed stocks spend
      List<dynamic> requestsRes = [];
      try {
        requestsRes = await Supabase.instance.client
            .from('stock_requests')
            .select('*, assignments!inner(*, batches(*))')
            .eq('hog_raiser_id', raiserId)
            .order('request_date', ascending: false);
      } catch (_) {
        try {
          requestsRes = await Supabase.instance.client
              .from('stock_requests')
              .select('*')
              .eq('hog_raiser_id', raiserId)
              .order('request_date', ascending: false);
        } catch (_) {}
      }
      final requests = List<Map<String, dynamic>>.from(requestsRes);

      // Fetch Product Price Catalog for accurate distributed product valuation
      final Map<String, double> productPriceMap = {};
      try {
        final productsRes = await Supabase.instance.client
            .from('inventory_products')
            .select('name, price, category');
        for (var p in (productsRes as List? ?? [])) {
          if (p is! Map) continue;
          final pName = (p['name'] ?? '').toString().trim().toLowerCase();
          final pCat = (p['category'] ?? '').toString().trim().toLowerCase();
          final pPrice = (p['price'] as num?)?.toDouble() ?? 0.0;
          if (pName.isNotEmpty && pPrice > 0) productPriceMap[pName] = pPrice;
          if (pCat.isNotEmpty && pPrice > 0 && !productPriceMap.containsKey(pCat)) {
            productPriceMap[pCat] = pPrice;
          }
        }
      } catch (pErr) {
        debugPrint('Notice fetching product prices: $pErr');
      }

      const double defaultFeedPrice = 1650.0;
      double totalStocksSpend = 0.0;
      final List<Map<String, dynamic>> providedStocks = [];

      for (var req in requests) {
        final status = (req['status'] ?? '').toString().toLowerCase();
        if (status == 'approved' || status == 'completed' || status == 'distributed') {
          final qty = (req['quantity'] as num?)?.toDouble() ?? 1.0;
          final fType = (req['feed_type'] ?? '').toString().trim();
          final cat = (req['category'] ?? '').toString().trim();
          final unitPrice = productPriceMap[fType.toLowerCase()] ??
              productPriceMap[cat.toLowerCase()] ??
              defaultFeedPrice;
          final totalAmount = qty * unitPrice;
          totalStocksSpend += totalAmount;

          providedStocks.add({
            'request_id': req['request_id'],
            'product_name': fType.isNotEmpty ? fType : (cat.isNotEmpty ? cat : 'Feeds / Supplies'),
            'category': cat.isNotEmpty ? cat : 'Feeds',
            'quantity': qty.toInt(),
            'unit_price': unitPrice,
            'total_amount': totalAmount,
            'request_date': req['request_date'] ?? req['created_at'],
            'decision_date': req['decision_date'],
            'status': req['status'] ?? 'approved',
            'notes': req['notes'] ?? '',
          });
        }
      }

      final double combinedInvestedAmount = totalCapital + totalStocksSpend;

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

      String? resolvedAvatar;

      bool isGoogleAvatar(String? url) {
        if (url == null) return false;
        final u = url.toLowerCase().trim();
        return u.contains('googleusercontent.com') ||
            u.contains('ggpht.com') ||
            u.contains('google.com') ||
            u.contains('graph.facebook.com');
      }

      // 1. Check direct database fields in hog_raisers & app_users (excluding Google OAuth avatar URLs)
      final possibleDbUrls = [
        raiser['avatar_url'],
        raiser['picture'],
        raiser['photo_url'],
        appUser['avatar_url'],
        appUser['picture'],
        appUser['photo_url'],
      ];
      for (final u in possibleDbUrls) {
        final s = u?.toString().trim();
        if (s != null && s.isNotEmpty && s != 'N/A' && s != 'null' && !isGoogleAvatar(s)) {
          resolvedAvatar = s;
          break;
        }
      }

      // 2. Check Supabase Storage profile_pictures/avatars bucket for uploaded avatar
      if (resolvedAvatar == null) {
        try {
          final storageFiles = await Supabase.instance.client.storage.from('profile_pictures').list(path: 'avatars');
          final rIdStr = raiserId.toString();
          final uIdStr = userId.toString();
          for (final file in storageFiles) {
            final fname = file.name;
            final match = RegExp(r'^avatar-(\d+)-').firstMatch(fname);
            if (match != null) {
              final matchedId = match.group(1)!;
              if (matchedId == rIdStr || matchedId == uIdStr) {
                resolvedAvatar = Supabase.instance.client.storage.from('profile_pictures').getPublicUrl('avatars/$fname');
                break;
              }
            }
          }
        } catch (sErr) {
          debugPrint('Notice checking storage avatar in mobile: $sErr');
        }
      }

      // 3. Clean up legacy Google avatars if stored in DB
      final dbRaiserAvatar = raiser['avatar_url']?.toString().trim();
      final dbAppUserAvatar = appUser['avatar_url']?.toString().trim();
      if (isGoogleAvatar(dbRaiserAvatar) || isGoogleAvatar(dbAppUserAvatar)) {
        try {
          await Supabase.instance.client
              .from('hog_raisers')
              .update({'avatar_url': null})
              .eq('hog_raiser_id', raiserId);
          await Supabase.instance.client
              .from('app_users')
              .update({'avatar_url': null})
              .eq('user_id', userId);
        } catch (_) {}
      }

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
      combinedRaiserData['avatar_url'] = resolvedAvatar;
      combinedRaiserData['pig_type'] = resolvedPigType;
      combinedRaiserData['lifecycle_stage'] = resolvedStage;

      if (mounted) {
        setState(() {
          _raiserData = combinedRaiserData;
          _investedAmount = combinedInvestedAmount;
          _initialCapital = totalCapital;
          _stocksSpendAmount = totalStocksSpend;
          _providedStocksList = providedStocks;
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
        PiggyToast.showSuccess(
          context,
          'Matagumpay na nailipat ang stage sa $targetStage!',
        );
      }
    } catch (e) {
      if (mounted) {
        PiggyToast.showError(
          context,
          'Failed to update stage: ${e.toString()}',
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
        PiggyToast.showSuccess(
          context,
          'Matagumpay na naipadala ang Hog Report!',
        );
      }

      await _fetchRaiserData();
    } catch (e) {
      if (mounted) {
        PiggyToast.showError(
          context,
          'Error: ${e.toString()}',
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

      // 2. Update hog_raisers & app_users tables
      try {
        await Supabase.instance.client.from('hog_raisers').update({
          'avatar_url': publicUrl,
        }).eq('hog_raiser_id', raiserId);
      } catch (dbErr) {
        debugPrint('DB hog_raisers column update notice: $dbErr');
      }

      final userId = _raiserData['user_id'];
      if (userId != null) {
        try {
          await Supabase.instance.client.from('app_users').update({
            'avatar_url': publicUrl,
          }).eq('user_id', userId);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _raiserData['avatar_url'] = publicUrl;
        });
        PiggyToast.showSuccess(
          context,
          'Matagumpay na na-update ang inyong profile picture!',
        );
      }

      await _fetchRaiserData();
    } catch (e) {
      if (mounted) {
        PiggyToast.showError(
          context,
          'Error uploading image: ${e.toString()}',
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

    // Show Tagalog Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'I-reset ang Profile?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: _brandColor,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Sigurado ka bang nais mong ibalik sa default ang iyong profile picture at mga setting?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'Hindi',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'Oo, I-reset',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

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

      final userId = _raiserData['user_id'];
      if (userId != null) {
        try {
          await Supabase.instance.client.from('app_users').update({
            'avatar_url': null,
          }).eq('user_id', userId);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _raiserData.remove('avatar_url');
        });
        PiggyToast.showSuccess(
          context,
          'Matagumpay na naibalik sa default ang inyong profile!',
        );
      }

      await _fetchRaiserData();
    } catch (e) {
      if (mounted) {
        PiggyToast.showError(
          context,
          'Error restoring image: ${e.toString()}',
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
                    textCapitalization: TextCapitalization.words,
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
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: const [CapitalizeWordsInputFormatter()],
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
                              PiggyToast.showWarning(
                                context,
                                'Mangyaring ilagay ang buong pangalan.',
                              );
                              return;
                            }

                            if (newPhone.isNotEmpty && (newPhone.length != 11 || !newPhone.startsWith('09'))) {
                              PiggyToast.showWarning(
                                context,
                                'Ang numero ng telepono ay dapat eksaktong 11 numero na nagsisimula sa 09.',
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
        PiggyToast.showSuccess(
          context,
          'Matagumpay na nai-save ang inyong profile!',
        );
      }

      await _fetchRaiserData();
    } catch (e) {
      if (mounted) {
        PiggyToast.showError(
          context,
          'Error: ${e.toString()}',
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
          PiggyToast.showInfo(
            context,
            'Pindutin ulit ang Back button upang isara ang app.',
          );
          return;
        }

        // Close the application directly without popping back to login
        SystemNavigator.pop();
      },
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final strings = AppStrings.of(context);
          final scaffoldBg = isDark ? PiggyTrunkTheme.ptBgDark : PiggyTrunkTheme.ptBg;
          final navBg = isDark ? PiggyTrunkTheme.ptSurfaceDark : Colors.white;
          final navSelectedColor = isDark ? Colors.white : _brandColor;
          final navUnselectedColor = isDark ? PiggyTrunkTheme.ptMutedDark : const Color(0xffa0aec0);

          return Scaffold(
            backgroundColor: scaffoldBg,
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(navSelectedColor),
                    ),
                  )
                : SafeArea(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: [
                        RaiserHomeTab(
                          raiserData: _raiserData,
                          investedAmount: _investedAmount,
                          initialCapital: _initialCapital,
                          stocksSpendAmount: _stocksSpendAmount,
                          providedStocksList: _providedStocksList,
                          requestsList: _requestsList,
                          notificationsList: _notificationsList,
                          activeAssignments: _activeAssignments,
                          hogsList: _hogsList,
                          reportsList: _reportsList,
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
                          investedAmount: _investedAmount,
                          activeAssignments: _activeAssignments,
                          hogsList: _hogsList,
                          reportsList: _reportsList,
                          notificationsList: _notificationsList,
                          selectedAssignmentId: _selectedAssignmentId,
                          onRefresh: _fetchRaiserData,
                          onMarkNotificationAsRead: _markNotificationAsRead,
                          onMarkAllRead: _markAllRead,
                          onSubmitHogReport: _submitHogReport,
                          onUpdateLifecycleStage: _updateLifecycleStage,
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
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? PiggyTrunkTheme.ptBorderDark : PiggyTrunkTheme.ptBorder,
                    width: 1,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: navBg,
                selectedItemColor: navSelectedColor,
                unselectedItemColor: navUnselectedColor,
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
                      colorFilter: ColorFilter.mode(navUnselectedColor, BlendMode.srcIn),
                    ),
                    activeIcon: SvgPicture.asset(
                      'assets/icons/sidebar/dashboard.svg',
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(navSelectedColor, BlendMode.srcIn),
                    ),
                    label: strings.navDashboard,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.description_outlined),
                    label: strings.navRequest,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.pets),
                    label: strings.navHogs,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline_rounded),
                    label: strings.navProfile,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
