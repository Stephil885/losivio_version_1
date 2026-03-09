//losivio/lib/services/frend_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/friend_model.dart';
import '../config/api_config.dart';

class FriendService {
  // Remplace localhost par 10.0.2.2 si tu es sur émulateur Android
  //static const String baseUrl = "http://10.113.49.126:9010/api/follow";

  /// Récupère le flux des publications des amis (dernières 24h)
  static Future<List<FriendPost>> getFriendFeed(int followerId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getFriendFeed}/$followerId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // On vérifie directement 'friends' à la racine de responseData
        if (responseData['friends'] != null) {
          final List<dynamic> friendsJson = responseData['friends'];
          print("FriendService: Récupéré ${friendsJson.length} amis pour l'ID ${followerId}");
          return friendsJson.map((json) => FriendPost.fromJson(json)).toList();
        } else {
          print("FriendService: Clé 'friends' absente de la réponse: $responseData");
        }
      }
      return [];
    } catch (e) {
      print("Erreur FriendService: $e");
      return [];
    }
  }

  /// S'abonner ou se désabonner
  /// Retourne true si on suit désormais l'utilisateur, false sinon
  static Future<bool?> toggleFollow({
    required int followerId,
    required int followingId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.toggleFollow),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "followerId": followerId,
          "followingId": followingId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['isFollowing']; // Retourne le nouvel état
      }
      return null;
    } catch (e) {
      print("Erreur FriendService (toggle): $e");
      return null;
    }
  }
}

