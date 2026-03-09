// losivio/lib/widgets/friend_widget.dart
import 'package:flutter/material.dart';

const LinearGradient kDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF0F172A), // slate-900
    Color(0xFF111827), // gray-900
    Color(0xFF1E293B), // slate-800
  ],
);

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFEC4899), // pink-500
    Color(0xFFA855F7), // purple-500
    Color(0xFF22D3EE), // cyan-400
  ],
);

class FriendWidget extends StatelessWidget {
  final String name;
  final String? avatarUrl; // ← nullable maintenant
  final bool hasStory;
  final VoidCallback? onTap;

  const FriendWidget({
    super.key,
    required this.name,
    this.avatarUrl,
    this.hasStory = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter =
        name.isNotEmpty ? name.trim()[0].toUpperCase() : "?";

    final bool hasValidAvatar =
        avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 10),
          child: Column(
            children: [
              // --- AVATAR + STORY BORDER ---
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: hasStory
                      ? null
                      : Border.all(color: Colors.grey.shade300, width: 1),
                  gradient: hasStory ? kAccentGradient : null,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade300,

                  // ✅ IMAGE si dispo
                  backgroundImage:
                      hasValidAvatar ? NetworkImage(avatarUrl!) : null,

                  // ✅ LETTRE si pas d'image
                  child: hasValidAvatar
                      ? null
                      : Text(
                          firstLetter,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 6),

              // --- NAME ---
              SizedBox(
                width: 64,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        hasStory ? FontWeight.w600 : FontWeight.normal,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
