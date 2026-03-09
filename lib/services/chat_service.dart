// lib/services/chat_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/chat_model.dart';
import '../config/api_config.dart';

class ChatService {
  //static const String baseUrl = "http://10.113.49.126:9010/api";
  //static const String serverUrl = "http://10.113.49.126:9010";

  // --- CONTACTS ---
  Future<List<Map<String, dynamic>>> getChatContacts(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.getContacts}/$userId"),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        
        return body.map((user) {
          if (user['avatar'] != null && !user['avatar'].startsWith('http')) {
            user['avatar'] = "${ApiConfig.avatarUrl}/${user['avatar']}";
          }
          return Map<String, dynamic>.from(user);
        }).toList();
        
      } else {
        print("❌ Erreur Serveur (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print("❌ Erreur réseau getChatContacts: $e");
    }
    return [];
  }

  // --- RÉCUPÉRER LES MESSAGES ---
  Future<List<ChatMessage>> getMessages(int senderId, int receiverId) async {
    try {
      final response = await http.get(Uri.parse("${ApiConfig.getMessages}/$senderId/$receiverId"));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((json) => ChatMessage.fromMap(json, senderId, ApiConfig.avatarUrl)).toList();
      }
    } catch (e) {
      print("❌ ChatService (getMessages): $e");
    }
    return [];
  }

  // --- ENVOYER UN MESSAGE (Texte + Fichiers) ---
  Future<ChatMessage?> sendMessage({
    required int senderId,
    required int receiverId,
    String? text,
    List<File>? files,
    int? parentMessageId,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.sendMessages));
      request.fields['sender_id'] = senderId.toString();
      request.fields['receiver_id'] = receiverId.toString();
      request.fields['message'] = text ?? "";
      if (parentMessageId != null) request.fields['parent_message_id'] = parentMessageId.toString();

      if (files != null) {
        for (var file in files) {
          request.files.add(await http.MultipartFile.fromPath('files', file.path));
        }
      }

      var res = await http.Response.fromStream(await request.send());
      if (res.statusCode == 201) {
        return ChatMessage.fromMap(jsonDecode(res.body), senderId, ApiConfig.avatarUrl);
      }
    } catch (e) {
      print("❌ ChatService (sendMessage): $e");
    }
    return null;
  }

  // --- ENVOYER UN VOCAL ---
  Future<ChatMessage?> sendVoiceMessage({
    required int senderId,
    required int receiverId,
    required String filePath,
    int? parentMessageId,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.sendVoiceMessage));
      request.fields['sender_id'] = senderId.toString();
      request.fields['receiver_id'] = receiverId.toString();
      if (parentMessageId != null) request.fields['parent_message_id'] = parentMessageId.toString();

      request.files.add(await http.MultipartFile.fromPath(
        'audio', filePath,
        contentType: MediaType('audio', 'm4a'),
      ));

      var res = await http.Response.fromStream(await request.send());
      if (res.statusCode == 201) {
        return ChatMessage.fromMap(jsonDecode(res.body), senderId, ApiConfig.avatarUrl);
      }
    } catch (e) {
      print("❌ ChatService (sendVoice): $e");
    }
    return null;
  }
}