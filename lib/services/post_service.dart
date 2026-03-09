// losivio/lib/services/post_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/comment_model.dart'; 
import '../config/api_config.dart';

class PostService {
  
  // --- 1. GET POSTS ---
  static Future<List<PostModel>> getPosts({
    required int? userId,
    required String tab, // 🔥 AJOUT ICI
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse(ApiConfig.getPosts).replace(
      queryParameters: {
        "page": page.toString(),
        "limit": limit.toString(),
        "tab": tab, // 🔥 AJOUT ICI : Le backend saura quoi renvoyer
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          "x-author-id": userId?.toString() ?? "",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200) {
        print("❌ Erreur API getPosts: ${response.body}");
        throw Exception("Erreur API");
      }

      final decoded = jsonDecode(response.body);
      final List postsJson = decoded["posts"] ?? [];

      return postsJson
          .map<PostModel>((json) => PostModel.fromJson(json))
          .toList();
    } catch (e) {
      print("❌ Exception getPosts: $e");
      rethrow;
    }
  }

  // --- 2. TOGGLE FOLLOW ---
  static Future<bool> toggleFollow({
    required int currentUserId,
    required int targetUserId,
  }) async {
    final uri = Uri.parse(ApiConfig.toggleFollow);
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "followerId": currentUserId,
          "followingId": targetUserId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? true;
      }
      return false;
    } catch (e) {
      print("❌ Erreur Follow: $e");
      return false;
    }
  }

  // --- 3. TOGGLE LIKE ---
  static Future<bool> toggleLike({
    required int postId,
    required int userId,
    required int postUserId,
  }) async {
    final uri = Uri.parse(ApiConfig.toggleLike);
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "postId": postId,
          "userId": userId,
          "postUserId": postUserId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? true;
      }
      return false;
    } catch (e) {
      print("❌ Erreur Like: $e");
      return false;
    }
  }

  // --- 4. GET COMMENTS ---
  static Future<List<CommentModel>> getComments(int postId) async {
    final uri = Uri.parse("${ApiConfig.getComments}/$postId");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Vérifie bien si ton backend renvoie 'comments' ou autre chose
        final List list = data['comments'] ?? []; 
        return list.map((item) => CommentModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Erreur getComments: $e");
      return [];
    }
  }

  // --- 5. ADD COMMENT ---
  static Future<bool> addComment({
    required int postId,
    required int userId,
    required String content,
  }) async {
    final uri = Uri.parse(ApiConfig.addComment);
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "postId": postId,
          "userId": userId,
          "content": content,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Erreur addComment: $e");
      return false;
    }
  }

  // --- 6. REGISTER VIEW ---
  static Future<bool> registerView({
    required int postId,
    required int mediaId,
    required int watchTime,
    required int userId,
  }) async {
    final uri = Uri.parse(ApiConfig.registerView(postId));

    try {
      final response = await http.post(
        uri,
        headers: {
          "x-author-id": userId.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "mediaId": mediaId,
          "watchTime": watchTime,
        }),
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      print("❌ Erreur registerView: $e");
      return false;
    }
  }
} 