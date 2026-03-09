// lib/widgets/chat_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;
  final bool isAudio; 
  final String? audioPath; // était manquant
  final bool isImage;
  final bool isVideo;
  final bool isSticker;
  final String? duration;
  final String? imagePath;
  final String? stickerPath;
  final String? videoPath;
  final Map<String, dynamic>? replyTo;
  final VoidCallback onReply;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
    this.isAudio = false,
    this.audioPath,
    this.isImage = false,
    this.isVideo = false,
    this.isSticker = false,
    this.duration,
    this.imagePath,
    this.stickerPath,
    this.videoPath,
    this.replyTo,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    // Si c'est un Sticker, on l'affiche sans bulle de couleur
    if (isSticker && stickerPath != null) {
      return _buildSticker();
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Affichage de la réponse citée (Swipe to reply)
            if (replyTo != null) _buildReplyPreview(),

            // Contenu principal (Bulle)
            GestureDetector(
              onLongPress: onReply, // Ou Swipe, mais LongPress est plus simple ici
              child: Container(
                padding: isImage || isVideo 
                    ? const EdgeInsets.all(4) // Moins de padding pour les images
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFFA855F7) : Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildContent(context),
                    const SizedBox(height: 4),
                    // Heure
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: (isMe && !isImage && !isVideo) ? Colors.white70 : Colors.black54,
                        // Pour les images, on met l'heure en blanc avec une ombre ou juste en dessous
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isImage && imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(imagePath!), fit: BoxFit.cover),
      );
    }
    
    if (isVideo) {
      return Container(
        height: 150,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
        ),
      );
    }

    if (isAudio) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, color: isMe ? Colors.white : Colors.black, size: 30),
          const SizedBox(width: 8),
          // Simulation d'une onde audio
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: isMe ? Colors.white54 : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            duration ?? "0:00",
            style: TextStyle(color: isMe ? Colors.white : Colors.black),
          ),
        ],
      );
    }

    // Texte par défaut
    return Text(
      message,
      style: TextStyle(
        fontSize: 16,
        color: isMe ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildSticker() {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Image.asset(stickerPath!, width: 120, height: 120),
            Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final bool replyIsMe = replyTo!['isMe'] ?? false;
    final String replyText = replyTo!['isAudio'] == true 
        ? "🎵 Message vocal" 
        : (replyTo!['text'] ?? "Fichier média");

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        border: Border(left: BorderSide(color: isMe ? const Color(0xFFA855F7) : Colors.grey, width: 3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyIsMe ? "Vous" : "Ami",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isMe ? const Color(0xFFA855F7) : Colors.black87,
            ),
          ),
          Text(
            replyText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}