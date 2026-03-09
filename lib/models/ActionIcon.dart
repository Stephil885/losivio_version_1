import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ Remplacé redux par riverpod
import '../screens/profile_screen.dart';
import '../providers/user_provider.dart'; // ✅ Ton nouveau provider
import '../models/user.dart';
import '../config/api_config.dart';

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

const LinearGradient kDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF1E293B)],
);

// --- WIDGET ACTION ICON (Inchangé car stateless sans data) ---
class ActionIcon extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  const ActionIcon({
    super.key,
    required this.icon,
    this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Icon(icon, color: color ?? Colors.white, size: 26),
            ),
            if (label != null) ...[
              const SizedBox(height: 3),
              Text(
                label!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- WIDGET AVATAR PRINCIPAL (Migré vers Riverpod) ---
class Avatar extends ConsumerWidget {
  // ✅ Changé en ConsumerWidget
  final int? userId;
  final String? userName;
  final String? avatarUrl;
  final String? email;
  final double size;
  final bool showFollowButton;
  final bool isFollowing;
  final VoidCallback? onFollowTap;

  const Avatar({
    super.key,
    this.userId,
    this.userName,
    this.email,
    this.avatarUrl,
    this.size = 56,
    this.showFollowButton = false,
    this.isFollowing = false,
    this.onFollowTap,
  });

  bool get _hasAvatar {
    if (avatarUrl == null) return false;
    final url = avatarUrl!.trim().toLowerCase();
    return url.isNotEmpty && url != 'null' && url != 'undefined';
  }

  String get _initial {
    final name = userName?.trim() ?? "";
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  String get _finalImageUrl {
    if (avatarUrl == null) return "";

    // On construit l'URL de base sans le timestamp dynamique
    String url =
        avatarUrl!.startsWith('http')
            ? avatarUrl!
            : '${ApiConfig.avatarUrl}${avatarUrl!.startsWith('/') ? avatarUrl : '/$avatarUrl'}';

    return url; // 🚀 Plus de ?t=... ici !
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Ajout de WidgetRef
    // On récupère l'utilisateur actuel via Riverpod
    final userAsync = ref.watch(userProvider);
    final currentUser = userAsync.value; // On extrait la data de l'AsyncValue

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ProfileScreen(
                      userId: userId,
                      userName: userName,
                      email: email,
                      avatar: _finalImageUrl,
                    ),
              ),
            );
          },
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: kAccentGradient,
            ),
            child: ClipOval(
              child:
                  _hasAvatar
                      ? CachedNetworkImage(
                        imageUrl: _finalImageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, __) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                        errorWidget: (_, __, ___) => _fallback(),
                      )
                      : _fallback(),
            ),
          ),
        ),

        // ✅ Logique de comparaison d'ID simplifiée avec Riverpod
        if (showFollowButton && !isFollowing && userId != currentUser?.id)
          Positioned(
            bottom: -8,
            child: GestureDetector(
              onTap: onFollowTap,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(gradient: kDarkGradient),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
