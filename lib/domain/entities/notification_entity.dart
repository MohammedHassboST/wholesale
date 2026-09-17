class NotificationEntity {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? payload;
  final String? targetPhone;
  bool isRead;

  NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.payload,
    this.targetPhone,
    this.isRead = false,
  });


  // snake_case keys to match the Supabase `notifications` table conventions
  // (created_at / target_phone / is_read) used by the read path.
  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'created_at': createdAt.toIso8601String(),
    'payload': payload,
    'target_phone': targetPhone,
    'is_read': isRead,
  };

  factory NotificationEntity.fromMap(String id, Map<String, dynamic> map) => NotificationEntity(
    id: map['id']?.toString() ?? id,
    title: map['title']?.toString() ?? '',
    body: map['body']?.toString() ?? '',
    createdAt: DateTime.tryParse((map['created_at'] ?? map['createdAt'] ?? '').toString()) ?? DateTime.now(),
    payload: map['payload']?.toString(),
    targetPhone: (map['target_phone'] ?? map['targetPhone'])?.toString(),
    isRead: (map['is_read'] ?? map['isRead'] ?? false) == true,
  );
}
