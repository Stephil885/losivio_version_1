// losivio/lib/widgets/message_widget.dart
import 'package:flutter/material.dart';

// Configuration des couleurs pour correspondre au MessagesScreen
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kSurfaceColor = Color(0xFF1E293B);

const LinearGradient kStoryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

class MessageWidget extends StatelessWidget {
  final String userName;
  final String message;
  final String time;
  final String? avatarUrl;
  final bool isOnline;
  final bool hasStory; 
  final VoidCallback? onTap;

  const MessageWidget({
    super.key,
    required this.userName,
    required this.message,
    required this.time,
    this.avatarUrl,
    this.isOnline = false,
    this.hasStory = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String firstLetter =
        userName.isNotEmpty ? userName.trim()[0].toUpperCase() : "?";

    return InkWell(
      onTap: onTap,
      splashColor: Colors.white10,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        child: Row(
          children: [
            // --- AVATAR AVEC LOGIQUE STORY & ONLINE ---
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(hasStory ? 2.5 : 1.5), 
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStory ? kStoryGradient : null,
                    border: !hasStory 
                        ? Border.all(color: Colors.white.withOpacity(0.1)) 
                        : null,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: const BoxDecoration(
                      color: kSurfaceColor,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF334155),
                      backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: (avatarUrl == null || avatarUrl!.isEmpty)
                          ? Text(
                              firstLetter,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D3EE),
                        shape: BoxShape.circle,
                        border: Border.all(color: kSurfaceColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22D3EE).withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // --- CONTENU TEXTE ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // AJOUT : Expanded ici pour gérer les noms trop longs
                      Expanded(
                        child: Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // Petit espace de sécurité
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}