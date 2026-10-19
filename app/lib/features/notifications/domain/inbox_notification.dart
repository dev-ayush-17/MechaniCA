class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.templateId,
    required this.deepLink,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String templateId;
  final String deepLink;
  final bool isRead;
  final DateTime createdAt;

  InboxNotification copyWith({bool? isRead}) {
    return InboxNotification(
      id: id,
      title: title,
      body: body,
      templateId: templateId,
      deepLink: deepLink,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
