class Goal {
  final int id;
  final int userId;
  final String content;
  final String? motivation;
  final DateTime? deadline;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.content,
    this.motivation,
    this.deadline,
    required this.createdAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as int,
        userId: json['userId'] as int,
        content: json['content'] as String,
        motivation: json['motivation'] as String?,
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
