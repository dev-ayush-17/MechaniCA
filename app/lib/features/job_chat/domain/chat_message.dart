enum ChatMessageState { sending, sent, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderRole,
    required this.createdAt,
    required this.state,
    this.text,
    this.mediaPath,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String senderRole;
  final String? text;
  final String? mediaPath;
  final DateTime createdAt;
  final ChatMessageState state;

  ChatMessage copyWith({ChatMessageState? state}) => ChatMessage(
        id: id,
        bookingId: bookingId,
        senderId: senderId,
        senderRole: senderRole,
        text: text,
        mediaPath: mediaPath,
        createdAt: createdAt,
        state: state ?? this.state,
      );
}
