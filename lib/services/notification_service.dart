import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  RealtimeChannel? _realtimeChannel;
  bool _isInitialized = false;
  final Map<String, DateTime> _recentNotificationDebounce = {};

  /// Initializes native notification settings and Android notification channel
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification clicked with payload: ${response.payload}");
      },
    );

    // Create High Importance Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'piggytrunk_alerts',
      'PiggyTrunk Alerts',
      description: 'System alerts and updates for PiggyTrunk app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _isInitialized = true;
  }

  /// Requests native OS permission for notifications on mobile devices
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    // Check & request permission via Permission Handler
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }

    // Also request platform-specific local notifications permissions
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final iosImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return status.isGranted;
  }

  /// Utility to remove emoticons / emojis to keep notification text clean, serious, and professional
  static String cleanText(String text) {
    if (text.isEmpty) return text;
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}'
      r'\u{1FA00}-\u{1FAFF}'
      r'\u{1F600}-\u{1F64F}'
      r'\u{1F680}-\u{1F6FF}'
      r'\u{2600}-\u{26FF}'
      r'\u{2700}-\u{27BF}'
      r'\u{FE00}-\u{FE0F}'
      r'\u{200D}'
      r']+',
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Translates notification title based on the active language (isFilipino)
  static String localizeTitle(String title, bool isFilipino) {
    final clean = cleanText(title).trim();
    final lower = clean.toLowerCase();

    if (isFilipino) {
      if (lower.contains('new investment') || lower.contains('investment assigned')) {
        return 'May Bagong Investment na Na-assign sa Iyo!';
      }
      if (lower.contains('new batch') || lower.contains('batch assigned')) {
        return 'Bagong Batch na Na-assign sa Iyo!';
      }
      if (lower.contains('new funds') || lower.contains('funds allocated')) {
        return 'May Bagong Pondo ang Iyong Batch!';
      }
      if (lower.contains('feeds restocked') || lower.contains('feeds & supplies')) {
        return 'Nag-restock ng Feeds!';
      }
      if (lower.contains('has been approved') || lower.contains('request approved')) {
        return 'Naaprubahan ang Iyong Request!';
      }
      if (lower.contains('was declined') || lower.contains('request declined')) {
        return 'Tinanggihan ang Iyong Request';
      }
      if (lower.contains('stage updated') || lower.contains('lifecycle')) {
        return 'Na-update ang Lifecycle Stage';
      }
      if (lower.contains('investment confirmed')) {
        return 'Nakumpirma ang Iyong Puhunan!';
      }
      if (lower.contains('investment approved')) {
        return 'Naaprubahan ang Iyong Puhunan!';
      }
      if (lower.contains('investment declined')) {
        return 'Tinanggihan ang Iyong Puhunan';
      }
      if (lower.contains('batch ready for selling') || lower.contains('harvest')) {
        return 'Handa na ang Batch para Ibenta / Anihin!';
      }
      if (lower.contains('health report')) {
        return 'Ulat sa Kalusugan';
      }
      if (lower.contains('stock request update')) {
        return 'Update sa Kahilingan ng Stock';
      }
      return clean;
    } else {
      if (lower.contains('nakumpirma ang iyong puhunan')) {
        return 'Investment Confirmed!';
      }
      if (lower.contains('naaprubahan ang iyong puhunan')) {
        return 'Investment Approved!';
      }
      if (lower.contains('tinanggihan ang iyong puhunan')) {
        return 'Investment Declined';
      }
      if (lower.contains('handa na ang batch para ibenta') || lower.contains('anihin')) {
        return 'Batch Ready for Selling / Harvest!';
      }
      if (lower.contains('bagong investment') || lower.contains('investment na na-assign')) {
        return 'New Investment Assigned to You!';
      }
      if (lower.contains('bagong batch') || lower.contains('batch na na-assign')) {
        return 'New Batch Assigned to You!';
      }
      if (lower.contains('pondo ang iyong batch') || lower.contains('pondo para sa iyong batch') || lower.contains('bagong pondo')) {
        return 'New Funds Allocated for Your Batch!';
      }
      if (lower.contains('nag-restock ng feeds') || lower.contains('bagong stock') || lower.contains('bagong supply')) {
        return 'New Feeds & Supplies Available!';
      }
      if (lower.contains('naaprubahan ang iyong request') || lower.contains('naaprubahan')) {
        return 'Your Request Has Been Approved!';
      }
      if (lower.contains('tinanggihan ang iyong request') || lower.contains('tinanggihan')) {
        return 'Your Request Was Declined';
      }
      if (lower.contains('na-update ang lifecycle') || lower.contains('stage updated')) {
        return 'Lifecycle Stage Updated';
      }
      if (lower.contains('ulat sa kalusugan') || lower.contains('health report')) {
        return 'Health Report Update';
      }
      if (lower.contains('update sa kahilingan ng stock')) {
        return 'Stock Request Update';
      }
      return clean;
    }
  }

  /// Translates notification message based on the active language (isFilipino)
  static String localizeMessage(String message, bool isFilipino) {
    final clean = cleanText(message).trim();

    if (isFilipino) {
      // 1. English -> Filipino: Investment with budget
      final investRegexWithCapitalEng = RegExp(
        r'admin assigned a new investment of\s*(\d+)\s*(.*?)\s*with a budget of\s*([₱\d,.]+)\s*for your care\.?',
        caseSensitive: false,
      );
      final matchE1 = investRegexWithCapitalEng.firstMatch(clean);
      if (matchE1 != null) {
        final count = matchE1.group(1) ?? '1';
        final type = matchE1.group(2)?.trim() ?? 'baboy';
        final capital = matchE1.group(3) ?? '';
        return 'Nag-assign ang Admin ng bagong investment na may $count $type na may pondong $capital para sa iyong pangangalaga.';
      }

      // 2. English -> Filipino: Simple Investment
      final investRegexSimpleEng = RegExp(
        r'admin assigned a new investment of\s*(\d+)\s*(.*?)\s*for your care\.?',
        caseSensitive: false,
      );
      final matchE2 = investRegexSimpleEng.firstMatch(clean);
      if (matchE2 != null) {
        final count = matchE2.group(1) ?? '1';
        final type = matchE2.group(2)?.trim() ?? 'baboy';
        return 'Nag-assign ang Admin ng bagong investment na may $count $type para sa iyong pangangalaga.';
      }

      // 3. English -> Filipino: Batch assignment
      final batchRegexEng = RegExp(
        r'admin assigned\s*(.*?)\s*to you\.\s*you can now start monitoring and updating logs\.?',
        caseSensitive: false,
      );
      final matchE3 = batchRegexEng.firstMatch(clean);
      if (matchE3 != null) {
        final batchName = matchE3.group(1)?.trim() ?? 'bagong batch';
        return 'Na-assign sa iyo ng Admin ang $batchName. Maaari mo nang simulan ang pagsubaybay at pag-update ng logs.';
      }

      // 4. English -> Filipino: Partner funds
      final partnerFundsEng1 = RegExp(
        r'(.*?)\s*allocated\s*([₱\d,.]+)\s*in funds for\s*(.*?)\.?',
        caseSensitive: false,
      );
      final matchPE1 = partnerFundsEng1.firstMatch(clean);
      if (matchPE1 != null) {
        final partner = matchPE1.group(1)?.trim() ?? 'Isang Partner Investor';
        final amount = matchPE1.group(2)?.trim() ?? '';
        final batch = matchPE1.group(3)?.trim() ?? 'batch';
        return '$partner ang naglaan ng $amount na pondo para sa $batch.';
      }

      if (clean.toLowerCase().contains('partner allocated additional funds')) {
        return clean
            .replaceAll(RegExp(r'Partner allocated additional funds', caseSensitive: false), 'Naglaan ang partner ng karagdagang pondo')
            .replaceAll(RegExp(r'for your batch', caseSensitive: false), 'para sa iyong batch');
      }

      // 5. English -> Filipino: Feed restock
      final restockRegexEng = RegExp(
        r'(.*?)\s*is now restocked and available \((.*?) units added\)\.?',
        caseSensitive: false,
      );
      final matchRestockE = restockRegexEng.firstMatch(clean);
      if (matchRestockE != null) {
        final product = matchRestockE.group(1)?.trim() ?? 'Feeds';
        final units = matchRestockE.group(2)?.trim() ?? '0';
        return 'Ang $product ay na-restock na at available na ($units units ang naidagdag).';
      }

      // 6. English -> Filipino: Stock requests
      final reqApprEng = RegExp(
        r'your request for\s*(.*?)\s*has been approved\.?',
        caseSensitive: false,
      );
      if (clean.toLowerCase().contains('your request has been approved for')) {
        return clean
            .replaceAll(RegExp(r'Your request has been approved for', caseSensitive: false), 'Naaprubahan ang iyong request para sa')
            .replaceAll(RegExp(r'You can now claim it from the store\.?', caseSensitive: false), 'Maaari mo na itong kunin sa tindahan.');
      } else if (reqApprEng.hasMatch(clean)) {
        return clean.replaceAllMapped(reqApprEng, (m) => 'Naaprubahan ang iyong request para sa ${m.group(1)}.');
      }

      if (clean.toLowerCase().contains('your request was declined for')) {
        return clean
            .replaceAll(RegExp(r'Your request was declined for', caseSensitive: false), 'Tinanggihan ang iyong request para sa');
      }

      // English -> Filipino: Partner Investment
      final pInvConfEng = RegExp(
        r'you have successfully funded\s*([₱\d,.]+)\s*for\s*(.*?)\.?',
        caseSensitive: false,
      );
      final matchPIC = pInvConfEng.firstMatch(clean);
      if (matchPIC != null) {
        final amount = matchPIC.group(1)?.trim() ?? '';
        final batch = matchPIC.group(2)?.trim() ?? 'batch';
        return 'Matagumpay kang naglaan ng $amount na pondo para sa $batch.';
      }

      final pInvApprEng = RegExp(
        r'admin has approved and activated your investment for\s*(.*?)\.?',
        caseSensitive: false,
      );
      final matchPIA = pInvApprEng.firstMatch(clean);
      if (matchPIA != null) {
        final batch = matchPIA.group(1)?.trim() ?? 'batch';
        return 'Inaprubahan at pinagana ng Admin ang iyong puhunan para sa $batch.';
      }

      final pInvDecEng = RegExp(
        r'your investment request for\s*(.*?)\s*was declined by admin\.?',
        caseSensitive: false,
      );
      final matchPID = pInvDecEng.firstMatch(clean);
      if (matchPID != null) {
        final batch = matchPID.group(1)?.trim() ?? 'batch';
        return 'Ang iyong kahilingan sa pamumuhunan para sa $batch ay tinanggihan ng Admin.';
      }

      if (clean.toLowerCase().contains('ready for harvest & payout distribution')) {
        return clean
            .replaceAll(RegExp(r'has reached (.*?). Ready for harvest & payout distribution!?', caseSensitive: false), 'ay umabot na sa yugtong handa na para sa pag-ani at pamamahagi ng kita!');
      }

      return clean;
    } else {
      // 1. Filipino -> English: Investment with budget (supports multiple comma-separated hog types e.g. "4 Fattening, Sow")
      final investRegexWithCapitalTag = RegExp(
        r'nag-assign ang admin ng bagong investment na may\s*(\d+)\s*(.*?)\s*na may pondong\s*([₱\d,.]+)\s*para sa iyong pangangalaga\.?',
        caseSensitive: false,
      );
      final match1 = investRegexWithCapitalTag.firstMatch(clean);
      if (match1 != null) {
        final count = match1.group(1) ?? '1';
        final type = match1.group(2)?.trim() ?? 'hog';
        final capital = match1.group(3) ?? '';
        return 'Admin assigned a new investment of $count $type with a budget of $capital for your care.';
      }

      // 2. Filipino -> English: Simple Investment
      final investRegexSimpleTag = RegExp(
        r'nag-assign ang admin ng bagong investment na may\s*(\d+)\s*(.*?)\s*para sa iyong pangangalaga\.?',
        caseSensitive: false,
      );
      final match2 = investRegexSimpleTag.firstMatch(clean);
      if (match2 != null) {
        final count = match2.group(1) ?? '1';
        final type = match2.group(2)?.trim() ?? 'hog';
        return 'Admin assigned a new investment of $count $type for your care.';
      }

      // 3. Filipino -> English: Batch assignment
      final batchRegexTag = RegExp(
        r'na-assign sa iyo ng admin ang\s*(.*?)\.\s*maaari mo nang simulan ang pagsubaybay.*?logs\.?',
        caseSensitive: false,
      );
      final match3 = batchRegexTag.firstMatch(clean);
      if (match3 != null) {
        final batchName = match3.group(1)?.trim() ?? 'the batch';
        return 'Admin assigned $batchName to you. You can now start monitoring and updating logs.';
      }

      // 4. Filipino -> English: Partner funds
      final partnerFundsTag1 = RegExp(
        r'(.*?)\s*ang naglaan ng\s*([₱\d,.]+)\s*na pondo para sa\s*(.*?)\.?',
        caseSensitive: false,
      );
      final matchP1 = partnerFundsTag1.firstMatch(clean);
      if (matchP1 != null) {
        final partner = matchP1.group(1)?.trim() ?? 'A Partner Investor';
        final amount = matchP1.group(2)?.trim() ?? '';
        final batch = matchP1.group(3)?.trim() ?? 'the batch';
        return '$partner allocated $amount in funds for $batch.';
      }

      if (clean.toLowerCase().contains('naglaan ang partner ng karagdagang pondo')) {
        return clean
            .replaceAll(RegExp(r'Naglaan ang partner ng karagdagang pondo', caseSensitive: false), 'Partner allocated additional funds')
            .replaceAll(RegExp(r'para sa iyong batch', caseSensitive: false), 'for your batch');
      }

      // 5. Filipino -> English: Feed restock
      final restockRegexTag = RegExp(
        r'ang\s*(.*?)\s*ay na-restock na at available na \((.*?) units ang naidagdag\)\.?',
        caseSensitive: false,
      );
      final matchRestock = restockRegexTag.firstMatch(clean);
      if (matchRestock != null) {
        final product = matchRestock.group(1)?.trim() ?? 'Feeds';
        final units = matchRestock.group(2)?.trim() ?? '0';
        return '$product is now restocked and available ($units units added).';
      }

      // 6. Filipino -> English: Stock requests
      if (clean.toLowerCase().contains('naaprubahan ang iyong request para sa')) {
        return clean
            .replaceAll(RegExp(r'Naaprubahan ang iyong request para sa', caseSensitive: false), 'Your request has been approved for')
            .replaceAll(RegExp(r'Maaari mo na itong kunin sa tindahan\.?', caseSensitive: false), 'You can now claim it from the store.');
      }

      if (clean.toLowerCase().contains('tinanggihan ang iyong request para sa')) {
        return clean
            .replaceAll(RegExp(r'Tinanggihan ang iyong request para sa', caseSensitive: false), 'Your request was declined for');
      }

      return clean;
    }
  }

  /// Shows a native OS status bar / lockscreen notification
  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final String sanitizedTitle = cleanText(title);
    final String sanitizedBody = cleanText(body);

    if (kIsWeb) {
      debugPrint('[Web Notification] $sanitizedTitle: $sanitizedBody');
      return;
    }
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'piggytrunk_alerts',
      'PiggyTrunk Alerts',
      channelDescription: 'System alerts and updates for PiggyTrunk app',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _localNotifications.show(
      notificationId,
      sanitizedTitle,
      sanitizedBody,
      details,
      payload: payload,
    );
  }

  /// Starts listening to Supabase Realtime notifications table specific to the user's role
  Future<void> startRoleRealtimeListener({
    required String role,
    required String userId,
    String? secondaryId,
  }) async {
    await stopListener(); // Ensure clean channel state

    final String roleLower = role.toLowerCase();
    String? tableName;

    if (roleLower == 'admin') {
      tableName = 'admin_notifications';
    } else if (roleLower == 'raiser' || roleLower == 'hog_raiser') {
      tableName = 'raiser_notifications';
    } else if (roleLower == 'partner' || roleLower == 'partner_investor') {
      tableName = 'partner_notifications';
    } else if (roleLower == 'cashier') {
      tableName = 'stock_requests';
    } else {
      debugPrint("Realtime notification channel skipped for unhandled role: $role");
      return;
    }

    final channelName = roleLower == 'cashier'
        ? 'public:stock_requests_notifs'
        : 'public:$tableName:user_${userId}_${secondaryId ?? ''}';

    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: tableName,
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord.isEmpty) return;

              if (roleLower == 'cashier') {
                final qty = newRecord['quantity'] ?? newRecord['sacks'] ?? 1;
                final prodName = newRecord['product_name'] ?? newRecord['item_name'] ?? 'Feed Stock';
                showNotification(
                  title: 'New Stock Request',
                  body: 'A raiser submitted a request for $qty sacks of $prodName.',
                  payload: newRecord.toString(),
                );
                return;
              }

              final notifUserId = newRecord['partner_investor_id']?.toString() ??
                  newRecord['user_id']?.toString() ??
                  newRecord['raiser_id']?.toString() ??
                  newRecord['hog_raiser_id']?.toString();
              
              // If user ID matches or if broadcast/admin/partner notification
              final bool matches = notifUserId == null ||
                  notifUserId == userId ||
                  (secondaryId != null && notifUserId == secondaryId) ||
                  roleLower == 'admin' ||
                  roleLower == 'partner' ||
                  roleLower == 'partner_investor';

              if (matches) {
                final title = newRecord['title']?.toString() ?? 'PiggyTrunk Alert';
                final body = newRecord['message']?.toString() ??
                    newRecord['content']?.toString() ??
                    newRecord['body']?.toString() ??
                    'You have a new update in PiggyTrunk.';

                // Real-time deduplication / debounce to prevent redundant popups
                final dedupeKey = '$roleLower:${title.trim()}:${body.trim()}';
                final now = DateTime.now();
                if (_recentNotificationDebounce.containsKey(dedupeKey)) {
                  final lastSeen = _recentNotificationDebounce[dedupeKey]!;
                  if (now.difference(lastSeen).inSeconds < 8) {
                    debugPrint("Skipping redundant realtime notification popup: $dedupeKey");
                    return;
                  }
                }
                _recentNotificationDebounce[dedupeKey] = now;

                showNotification(
                  title: title,
                  body: body,
                  payload: newRecord.toString(),
                );
              }
            },
          )
          .subscribe();
      
      debugPrint("Subscribed to Realtime notification channel: $channelName for role: $role");
    } catch (e) {
      debugPrint("Error starting realtime notification listener: $e");
    }
  }

  /// Stops and unsubscribes the current Realtime listener channel
  Future<void> stopListener() async {
    if (_realtimeChannel != null) {
      await Supabase.instance.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }
}
