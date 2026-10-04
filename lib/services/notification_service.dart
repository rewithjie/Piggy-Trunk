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
    if (isFilipino) return clean;

    final lower = clean.toLowerCase();
    if (lower.contains('bagong investment na na-assign') ||
        (lower.contains('bagong investment') && lower.contains('na-assign'))) {
      return 'New Investment Assigned to You!';
    }
    if (lower.contains('bagong batch na na-assign') ||
        (lower.contains('bagong batch') && lower.contains('na-assign'))) {
      return 'New Batch Assigned to You!';
    }
    if (lower.contains('pondo para sa iyong batch') || lower.contains('bagong pondo')) {
      return 'New Funds Allocated for Your Batch!';
    }
    if (lower.contains('bagong stock ng feeds') || lower.contains('bagong supply')) {
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
    return clean;
  }

  /// Translates notification message based on the active language (isFilipino)
  static String localizeMessage(String message, bool isFilipino) {
    final clean = cleanText(message).trim();
    if (isFilipino) return clean;

    // Pattern 1: Nag-assign ang Admin ng bagong Investment na may X Type na may pondong ₱Y para sa iyong pangangalaga.
    final investRegexWithCapital = RegExp(
      r'nag-assign ang admin ng bagong investment na may\s*(\d+)\s*([a-zA-Z\s]+)?\s*na may pondong\s*([₱\d,.]+)\s*para sa iyong pangangalaga\.?',
      caseSensitive: false,
    );
    final match1 = investRegexWithCapital.firstMatch(clean);
    if (match1 != null) {
      final count = match1.group(1) ?? '1';
      final type = match1.group(2)?.trim() ?? 'hog';
      final capital = match1.group(3) ?? '';
      return 'Admin assigned a new investment of $count $type with a budget of $capital for your care.';
    }

    final investRegexSimple = RegExp(
      r'nag-assign ang admin ng bagong investment na may\s*(\d+)\s*([a-zA-Z\s]+)?\s*para sa iyong pangangalaga\.?',
      caseSensitive: false,
    );
    final match2 = investRegexSimple.firstMatch(clean);
    if (match2 != null) {
      final count = match2.group(1) ?? '1';
      final type = match2.group(2)?.trim() ?? 'hog';
      return 'Admin assigned a new investment of $count $type for your care.';
    }

    // Pattern 2: Na-assign sa iyo ng Admin ang X. Maaari mo nang simulan ang pagsubaybay at pag-update ng logs.
    final batchRegex = RegExp(
      r'na-assign sa iyo ng admin ang\s*(.*?)\.\s*maaari mo nang simulan ang pagsubaybay.*?logs\.?',
      caseSensitive: false,
    );
    final match3 = batchRegex.firstMatch(clean);
    if (match3 != null) {
      final batchName = match3.group(1) ?? 'the batch';
      return 'Admin assigned $batchName to you. You can now start monitoring and updating logs.';
    }

    // Pattern 3: Naglaan ang partner ng karagdagang pondo...
    if (clean.toLowerCase().contains('naglaan ang partner ng karagdagang pondo')) {
      return clean
          .replaceAll(RegExp(r'Naglaan ang partner ng karagdagang pondo', caseSensitive: false), 'Partner allocated additional funds')
          .replaceAll(RegExp(r'para sa iyong batch', caseSensitive: false), 'for your batch');
    }

    // Pattern 4: Stock request approved / declined
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
        : 'public:$tableName:user_$userId';

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
              if (notifUserId == null || notifUserId == userId || roleLower == 'admin' || roleLower == 'partner' || roleLower == 'partner_investor') {
                final title = newRecord['title']?.toString() ?? 'PiggyTrunk Alert';
                final body = newRecord['message']?.toString() ??
                    newRecord['content']?.toString() ??
                    newRecord['body']?.toString() ??
                    'You have a new update in PiggyTrunk.';

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
