// lib/models/chat_model.dart

import 'package:intl/intl.dart';

class ChatMessage {
  final int? id;
  final String text;
  final bool isMe;
  final String time;
  final int senderId;
  final int receiverId;
  final bool isAudio;
  final String? audioPath;
  final bool isImage;
  final String? imagePath;
  final bool isVideo;
  final String? videoPath;
  final int? parentMessageId;
  final Map<String, dynamic>? replyTo;

  ChatMessage({
    this.id,
    required this.text,
    required this.isMe,
    required this.time,
    required this.senderId,
    required this.receiverId,
    this.isAudio = false,
    this.isImage = false,
    this.isVideo = false,
    this.audioPath,
    this.imagePath,
    this.videoPath,
    this.parentMessageId,
    this.replyTo,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, int currentUserId, String serverUrl) {
    // Sécurité de parsing pour Redis (qui peut transformer les int en string)
    int sId = int.tryParse(map['sender_id'].toString()) ?? 0;
    int rId = int.tryParse(map['receiver_id'].toString()) ?? 0;

    String content = map['message'] ?? map['text'] ?? "";
    
    // Gestion des pièces jointes
    List attachments = map['attachments'] ?? [];
    String? img;
    String? vid;

    for (var att in attachments) {
      String url = att['url'] ?? "";
      String fullUrl = url.startsWith('http') ? url : "$serverUrl$url";
      if (att['type'] == 'image') img = fullUrl;
      if (att['type'] == 'video') vid = fullUrl;
    }

    // Gestion du vocal (Clé backend : audioVocal_path)
    String? aPath = map['audioVocal_path'];
    if (aPath != null && aPath.isNotEmpty) {
      aPath = aPath.startsWith('http') ? aPath : "$serverUrl$aPath";
    }

    // Formatage de l'heure
    String formattedTime = "";
    try {
      DateTime date = map['created_at'] != null 
          ? DateTime.parse(map['created_at']).toLocal() 
          : DateTime.now();
      formattedTime = DateFormat('HH:mm').format(date);
    } catch (e) {
      formattedTime = DateFormat('HH:mm').format(DateTime.now());
    }

    // Récupération sécurisée du replyTo
    Map<String, dynamic>? replyData;
    if (map['replyTo'] != null) {
      replyData = Map<String, dynamic>.from(map['replyTo']);
      // On s'assure que la clé 'text' existe, même si le backend a envoyé 'message'
      replyData['text'] = replyData['text'] ?? replyData['message'] ?? "";
    }

    return ChatMessage(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      text: content,
      isMe: sId == currentUserId,
      senderId: sId,
      receiverId: rId,
      time: formattedTime,
      isAudio: aPath != null,
      audioPath: aPath,
      isImage: img != null,
      imagePath: img,
      isVideo: vid != null,
      videoPath: vid,
      parentMessageId: map['parent_message_id'],
      replyTo: replyData,
    );
  }
}