enum UserRole {
  user,
  vip,
  moderator,
  host,
  admin,
}

class LiveMessage {
  final String id;
  final String avatar;
  final String username;
  final String message;
  final UserRole role;
  final bool isGift;
  final String? giftIcon; // 🎁 animation

  LiveMessage({
    required this.id,
    required this.avatar,
    required this.username,
    required this.message,
    this.role = UserRole.user,
    this.isGift = false,
    this.giftIcon,
  });
}
