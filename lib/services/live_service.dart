// services/live_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class LiveService {
  // 💡 Rappel : Utilise ton IP locale (192.168.x.x) pour tester sur un vrai téléphone
  static const String baseUrl = "http://192.168.2.88:9010/api";

  /// ▶️ DÉMARRER UN LIVE
  static Future<Map<String, dynamic>> startLive({
    required String title,
    String? description,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.startLive),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "title": title,
            "description": description,
          }),
        )
        .timeout(const Duration(seconds: 10));

    // ✅ On accepte 200, 201 (Créé) et 409 (Déjà en cours)
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception("Erreur API (${response.statusCode}): ${response.body}");
  }

  /// 🔴 ARRÊTER UN LIVE
  static Future<void> stopLive({
    required int liveId, 
    required int streamerId // 1. Rendu obligatoire
  }) async {
    
    // 2. URL plus propre (sans paramètre)
    final url = Uri.parse(ApiConfig.stopLive); 
    print(liveId);
    print(streamerId);
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "liveId": liveId,
        "streamerId": streamerId, // Tout est dans le body
      }),
    );
    print(response.body);
    // 3. Meilleure gestion d'erreur
    if (response.statusCode != 200) {
      throw Exception("Erreur stopLive (${response.statusCode}): ${response.body}");
    }
  }
}