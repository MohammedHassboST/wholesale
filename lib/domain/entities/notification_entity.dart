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


  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'payload': payload,
    'targetPhone': targetPhone,
  };

  factory NotificationEntity.fromMap(String id, Map<String, dynamic> map) => NotificationEntity(
    id: id,
    title: map['title'] ?? '',
    body: map['body'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
    payload: map['payload'],
    targetPhone: map['targetPhone'],
  );
}
