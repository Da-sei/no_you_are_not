class Conversation {
  final int id;
  final int userId;
  final int? goalId;
  final String? title;
  final bool archived;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.userId,
    this.goalId,
    this.title,
    required this.archived,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as int,
        userId: json['userId'] as int,
        goalId: json['goalId'] as int?,
        title: json['title'] as String?,
        archived: json['isArchived'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
