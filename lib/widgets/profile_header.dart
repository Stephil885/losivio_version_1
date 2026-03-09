import 'dart:ui';
import 'package:flutter/material.dart';


// --- CONFIGURATION DESIGN ---
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kSurfaceColor = Color(0xFF1E293B);

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

class ProfileHeader extends StatelessWidget {
  final int? userId;
  final String username;
  final String bio;
  final String imageUrl;
  final int followers;
  final int likes;
  final int following;
  final String email;
  final String phone;
  final bool isMe;
  final VoidCallback? onEditImage;

  const ProfileHeader({
    super.key,
    this.userId,
    required this.username,
    required this.bio,
    required this.imageUrl,
    required this.followers,
    required this.following,
    required this.likes,
    required this.email,
    required this.phone,
    this.isMe = false,
    this.onEditImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200, 
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // --- FOND DYNAMIQUE (Vibe Premium) ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1E293B), kBackgroundColor],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.blur_on_rounded, size: 200, color: Colors.white),
                  ),
                ),
              ),

              // --- AVATAR AVEC GLOW ---
              Positioned(
                bottom: 0,
                child: _AvatarWithGlow(
                  imageUrl: imageUrl,
                  isMe: isMe,
                  onEdit: onEditImage,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- USERNAME & BADGE ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24), // Sécurité pour les bords
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // S'adapte au contenu
            children: [
              Flexible( // <--- Rend le texte flexible
                child: Text(
                  username,
                  maxLines: 1, // On reste sur une seule ligne
                  overflow: TextOverflow.ellipsis, // Ajoute "..." si besoin
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _VerifiedBadge(), // Le badge restera toujours visible à droite
            ],
          ),
        ),
        const SizedBox(height: 8),
        // --- BIO ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // --- STATS CARD (Glassmorphism) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _GlassStatsCard(
            followers: followers,
            following: following,
            likes: likes,
          ),
        ),

        const SizedBox(height: 30),

        // --- ACTIVITY PROGRESS ---
        _ActivityProgressBar(),
      ],
    );
  }
}

// --- SOUS-WIDGETS POUR LE LOOK "WAHOU" ---

class _AvatarWithGlow extends StatelessWidget {
  final String imageUrl;
  final bool isMe;
  final VoidCallback? onEdit;

  const _AvatarWithGlow({required this.imageUrl, required this.isMe, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: kAccentGradient),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: kBackgroundColor, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: kSurfaceColor,
                backgroundImage: NetworkImage(imageUrl),
              ),
            ),
          ),
          if (isMe)
            Positioned(
              bottom: 5,
              right: 5,
              child: GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.edit_rounded, color: Color(0xFF1E293B), size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassStatsCard extends StatelessWidget {
  final int followers, following, likes;
  const _GlassStatsCard({required this.followers, required this.following, required this.likes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem("Abonnés", followers),
          _StatDivider(),
          _StatItem("Abonnements", following),
          _StatDivider(),
          _StatItem("Likes", likes),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  const _StatItem(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count > 999 ? "${(count / 1000).toStringAsFixed(1)}k" : count.toString(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 20, width: 1, color: Colors.white.withOpacity(0.1));
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: kAccentGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text("PRO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _ActivityProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Niveau d'influence", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              Text("75%", style: TextStyle(color: const Color(0xFF22D3EE), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.75,
              child: Container(
                decoration: BoxDecoration(
                  gradient: kAccentGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: const Color(0xFFEC4899).withOpacity(0.3), blurRadius: 10)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}