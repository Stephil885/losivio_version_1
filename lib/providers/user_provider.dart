// providers/user_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/session_storage.dart';
import '../config/api_config.dart';

/// Le provider global qui expose l'utilisateur actuel et ses préférences
final userProvider = AsyncNotifierProvider<UserNotifier, User?>(UserNotifier.new);

class UserNotifier extends AsyncNotifier<User?> {

  @override
  Future<User?> build() async {
    // Chargé automatiquement au démarrage de l'application depuis le stockage local
    return await SessionStorage.load();
  }

  // --- PRÉFÉRENCES (TRADUCTION & SOUS-TITRES) ---

  /// Basculer l'état de la traduction des publications
  Future<void> toggleTranslation(bool value) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    // Mise à jour de l'objet User avec la nouvelle valeur
    final updatedUser = currentUser.copyWith(translatePost: value);
    
    // Mise à jour de l'état UI et sauvegarde locale
    state = AsyncData(updatedUser);
    await SessionStorage.save(updatedUser);
  }

  /// Basculer l'état des sous-titres des publications
  Future<void> toggleSubtitles(bool value) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    // Mise à jour de l'objet User avec la nouvelle valeur
    final updatedUser = currentUser.copyWith(sousTitrePost: value);
    
    // Mise à jour de l'état UI et sauvegarde locale
    state = AsyncData(updatedUser);
    await SessionStorage.save(updatedUser);
  }

  // --- ACTIONS DE COMPTE ---

  Future<void> login(User user) async {
    state = AsyncData(user);
    await SessionStorage.save(user);
  }

  Future<void> logout() async {
    state = const AsyncData(null);
    await SessionStorage.clear();
  }

  // --- ACTIONS MULTIMÉDIA ---

  /// Mise à jour de l'avatar avec un fichier réel (Multipart)
  Future<void> uploadAvatar(File imageFile) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    // On passe en chargement tout en gardant l'utilisateur actuel affiché
    state = const AsyncLoading<User?>().copyWithPrevious(AsyncData(currentUser));

    state = await AsyncValue.guard(() async {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiConfig.baseUrl}/auth/profile-picture'),
      );

      request.headers['Authorization'] = 'Bearer ${currentUser.token}';
      
      // Envoi du fichier sous la clé 'avatar'
      request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extraction du chemin renvoyé par le serveur
        final String serverPath = data['imageUrl'] ?? data['profile_picture'] ?? '';

        // On met à jour l'utilisateur avec son nouvel avatar (en gardant ses préférences)
        final updatedUser = currentUser.copyWith(avatar: serverPath);
        
        await SessionStorage.save(updatedUser);
        return updatedUser;
      } else {
        throw Exception("Erreur serveur lors de l'upload (${response.statusCode})");
      }
    });
  }
}