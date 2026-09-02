class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.message,
    required this.sentAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String message;
  final DateTime sentAt;
}
