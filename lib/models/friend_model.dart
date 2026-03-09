// losivio/lib/models/freind_model.dart

class FriendPost {
  final int id;
  final String username;
  final String? profilePicture;
  final String? bio;
  final bool hasStory;
  final int? postId;
  final DateTime? createdAt;
  final String? mediaUrl;
  final String? mediaType;

  FriendPost({
    required this.id,
    required this.username,
    this.profilePicture,
    this.bio,
    this.hasStory = false,
    this.postId,
    this.createdAt,
    this.mediaUrl,
    this.mediaType,
  });

  factory FriendPost.fromJson(Map<String, dynamic> json) {
    final postDetails = json['postDetails'] as Map<String, dynamic>?;

    return FriendPost(
      id: json['authorId'] ?? 0, 
      username: json['authorName'] ?? 'Inconnu',
      profilePicture: json['authorAvatar'],
      bio: json['authorBio'],
      hasStory: json['hasStory'] ?? false,
      
      postId: postDetails?['postId'],
      createdAt: postDetails?['createdAt'] != null 
          ? DateTime.tryParse(postDetails!['createdAt'].toString()) 
          : null,
      mediaUrl: postDetails?['mediaUrl'],
      mediaType: postDetails?['mediaType'],
    );
  }
}