class AdminNotification {
  final int notificationId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AdminNotification({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.metadata,
    required this.createdAt,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      notificationId: json['notification_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()).toLocal() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AdminNotification copyWith({
    int? notificationId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return AdminNotification(
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
