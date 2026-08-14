import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_notification_model.dart';

/// Stream Provider that listens to real-time additions/modifications in the admin_notifications table
final adminNotificationsProvider = StreamProvider<List<AdminNotification>>((ref) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('admin_notifications')
      .stream(primaryKey: ['notification_id'])
      .map((rows) {
        final rawList = rows.map((row) => AdminNotification.fromJson(row)).toList();
        // Sort descending by created_at so newest notifications are first
        rawList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Deduplicate by notification_id and title+message signature to eliminate redundant notifications
        final seenIds = <int>{};
        final seenSignatures = <String>{};
        final uniqueList = <AdminNotification>[];

        for (final notif in rawList) {
          if (seenIds.contains(notif.notificationId)) continue;

          final sig = '${notif.title.trim().toLowerCase()}_${notif.message.trim().toLowerCase()}';
          if (seenSignatures.contains(sig)) continue;

          seenIds.add(notif.notificationId);
          seenSignatures.add(sig);
          uniqueList.add(notif);
        }

        return uniqueList;
      });
});

/// Service class containing operations to manage notifications
class AdminNotificationService {
  static final _supabase = Supabase.instance.client;

  /// Marks a specific notification as read
  static Future<void> markAsRead(int notificationId) async {
    try {
      await _supabase
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('notification_id', notificationId);
    } catch (_) {
      // Silently catch database failures or offline states
    }
  }

  /// Marks all unread notifications as read
  static Future<void> markAllAsRead() async {
    try {
      await _supabase
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (_) {
      // Silently catch database failures or offline states
    }
  }

  /// Deletes a specific notification
  static Future<void> deleteNotification(int notificationId) async {
    try {
      await _supabase
          .from('admin_notifications')
          .delete()
          .eq('notification_id', notificationId);
    } catch (_) {
      // Silently catch database failures or offline states
    }
  }

  /// Deletes all notifications (clears list)
  static Future<void> clearAll() async {
    try {
      await _supabase
          .from('admin_notifications')
          .delete()
          .neq('notification_id', 0);
    } catch (_) {
      // Silently catch database failures or offline states
    }
  }
}
