enum MessageRole { user, assistant }

class Message {
  final int id;
  final int conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as int,
        conversationId: json['conversationId'] as int,
        role: (json['role'] as String) == 'user'
            ? MessageRole.user
            : MessageRole.assistant,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
