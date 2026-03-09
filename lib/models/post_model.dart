// losivio/lib/models/post_model.dart
import 'media_model.dart';

class PostModel {
  final int id;
  final int authorId;
  final String authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final List<MediaModel> medias;
  final int likesCount;
  final int commentsCount;
  final int viewsCount; 
  final bool isLiked;
  final bool isFollowing;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.medias,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.isLiked,
    required this.isFollowing,
  });

  PostModel copyWith({
    bool? isFollowing,
    bool? isLiked,
    int? likesCount,
    int? commentsCount,
    int? viewsCount, 
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      createdAt: createdAt,
      medias: medias,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount, 
      isLiked: isLiked ?? this.isLiked,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['postId'] ?? 0,
      authorId: json['authorId'] ?? 0,
      //title: json['title'] ?? '',
      authorName: json['authorName'] ?? 'Utilisateur',
      authorAvatar: json['authorAvatar'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      medias: (json['medias'] as List? ?? [])
          .map((m) => MediaModel.fromJson(m))
          .toList(),
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      viewsCount: json['countViews'] ?? 0, // ✅ AJOUTÉ
      isLiked: json['isLiked'] == true || json['isLiked'] == 1,
      isFollowing: json['isFollowing'] == true || json['isFollowing'] == 1,
    );
  }
}
