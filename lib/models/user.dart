// models/user.dart
class User {
  final int id;
  final String username;
  final String email;
  final String? phone;
  final String? bio;
  final String? langue;
  final String? avatar;
  final String token;
  
  // 🔥 ON AJOUTE ÇA ICI
  final bool translatePost;
  final bool sousTitrePost;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.bio,
    this.langue,
    this.avatar,
    required this.token,
    this.translatePost = false, // Par défaut
    this.sousTitrePost = false,  // Par défaut
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      token: json['token'] ?? '',
      bio: json['bio'],
      langue: json['language'] ?? json['langue'],
      avatar: json['profile_picture'] ?? json['avatar'],
      // 🔥 ET ICI POUR LA LECTURE
      translatePost: json['translatePost'] ?? false,
      sousTitrePost: json['sousTitrePost'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'token': token,
      'bio': bio,
      'langue': langue,
      'profile_picture': avatar,
      // 🔥 ET ICI POUR LA SAUVEGARDE
      'translatePost': translatePost,
      'sousTitrePost': sousTitrePost,
    };
  }

  // N'oublie pas de les ajouter dans le copyWith pour pouvoir les modifier !
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? phone,
    String? token,
    String? bio,
    String? langue,
    String? avatar,
    bool? translatePost,
    bool? sousTitrePost,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      bio: bio ?? this.bio,
      langue: langue ?? this.langue,
      avatar: avatar ?? this.avatar,
      translatePost: translatePost ?? this.translatePost,
      sousTitrePost: sousTitrePost ?? this.sousTitrePost,
    );
  }
}