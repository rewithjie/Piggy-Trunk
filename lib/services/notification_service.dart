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

  /// Shows a native OS status bar / lockscreen notification
  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
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
      title,
      body,
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
    } else {
      debugPrint("Realtime notification channel skipped for non-admin/raiser role: $role");
      return;
    }

    final channelName = 'public:$tableName:user_$userId';

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

              final notifUserId = newRecord['user_id']?.toString() ?? newRecord['raiser_id']?.toString();
              
              // If user ID matches or if broadcast notification
              if (notifUserId == null || notifUserId == userId || role == 'admin') {
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
