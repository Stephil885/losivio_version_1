// losivio/lib/models/comment_model.dart
class CommentModel {
  final int id;
  final int userId;
  final String username;
  final String? profilePicture;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    this.profilePicture,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      userId: json['userId'],
      username: json['username'] ?? 'Anonyme',
      profilePicture: json['profile_picture'],
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}

