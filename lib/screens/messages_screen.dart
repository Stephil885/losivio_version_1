// losivio/lib/screens/messages_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'dart:ui'; // Pour le BackdropFilter si besoin
import 'package:wakelock_plus/wakelock_plus.dart';

import '../widgets/message_widget.dart';
//import '../widgets/friend_widget.dart';
import '../config/api_config.dart';
import '../models/friend_model.dart';
import '../services/friend_service.dart';
import '../services/chat_service.dart';
import '../providers/user_provider.dart';
import 'chat_screen.dart';
import '../providers/user_provider.dart';
import './auth_screen.dart';

// --- CONFIGURATION DESIGN ---
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kSurfaceColor = Color(
  0xFF1E293B,
); // Un bleu un peu plus clair pour les cartes
const Color kPlaceholderColor = Colors.black;

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  // On utilise un tuple (Record) pour combiner les deux appels API
  late Future<({List<FriendPost> friends, List<Map<String, dynamic>> contacts})> _combinedFuture;
  
  @override
  void initState() {
    super.initState();
    // On attend que la première frame soit prête pour déclencher le wakelock
    Future.microtask(() async {
      try {
        await WakelockPlus.enable();
        debugPrint("Wakelock activé avec succès");
      } catch (e) {
        debugPrint("Erreur Wakelock : $e");
      }
    });
  }

  @override
  void dispose() {
    // Désactive le maintien de l'écran quand on quitte l'écran
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _loadData() {
    final user = ref.read(userProvider).value;
    final currentUserId = user?.id ?? 0;
    
    setState(() {
      // Future.wait charge les deux listes en parallèle
      _combinedFuture = Future.wait([
        FriendService.getFriendFeed(currentUserId),
        ChatService().getChatContacts(currentUserId),
      ]).then((results) {
        return (
          friends: results[0] as List<FriendPost>,
          contacts: results[1] as List<Map<String, dynamic>>,
        );
      });
    });
  }

  @override
Widget build(BuildContext context) {
  // 1. On surveille l'utilisateur
  final userAsync = ref.watch(userProvider);
  final user = userAsync.value; // Récupère la valeur actuelle (User? ou null)

  return Scaffold(
    backgroundColor: kBackgroundColor,
    appBar: AppBar(
      backgroundColor: kBackgroundColor.withOpacity(0.8),
      elevation: 0,
      centerTitle: false,
      title: ShaderMask(
        shaderCallback: (bounds) => kAccentGradient.createShader(bounds),
        child: const Text(
          'Discussions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1,
          ),
        ),
      ),
      actions: [
        _buildGlassButton(Icons.search_rounded, "Recherche"),
        _buildGlassButton(Icons.person_add_alt_1_rounded, "Global"),
        const SizedBox(width: 12),
      ],
    ),
    // 2. C'est ici que la magie opère
    body: user == null 
      ? _buildLoginPrompt() // Si pas de user, on affiche le bouton de connexion
      : RefreshIndicator(   // Si user présent, on affiche la liste normale
          onRefresh: () async => _loadData(),
          color: const Color(0xFFA855F7),
          backgroundColor: kSurfaceColor,
          child: FutureBuilder<({List<FriendPost> friends, List<Map<String, dynamic>> contacts})>(
            future: _combinedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF22D3EE)));
              }

              final friends = snapshot.data?.friends ?? [];
              final contacts = snapshot.data?.contacts ?? [];

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- SECTION STORIES ---
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 20, top: 10, bottom: 15),
                          child: Text("ACTIVITÉ", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 16),
                            itemCount: friends.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) return _buildAddStory(user.id);
                              final friend = friends[index - 1];
                              return _buildStoryItem(friend);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- LISTE DES MESSAGES (SliverFillRemaining pour le fond de couleur) ---
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: const BoxDecoration(
                        color: kSurfaceColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                      ),
                      child: contacts.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.only(top: 20, bottom: 100),
                              itemCount: contacts.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), indent: 80),
                              itemBuilder: (context, index) {
                                final contact = contacts[index];
                                return MessageWidget(
                                  userName: contact['name'] ?? "Utilisateur",
                                  message: "Envoyer un message...",
                                  time: "12:45",
                                  avatarUrl: contact['avatar'],
                                  isOnline: true,
                                  hasStory: friends.any((f) => f.id == contact['id'] && f.hasStory),
                                  onTap: () => _openChat(context, contact),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
  );
}

// 3. Le Widget pour inciter à la connexion (Design Premium)
Widget _buildLoginPrompt() {
  return Container( // Changé de Center à Container
    alignment: Alignment.center, // Pour garder l'effet "Center"
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 80, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 24),
        const Text(
          "Connectez-vous pour discuter",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          "Rejoignez la communauté pour échanger avec vos amis.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            shadowColor: Colors.transparent,
          ).copyWith(
            elevation: WidgetStateProperty.all(0), // Corrigé pour les versions récentes de Flutter
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: kAccentGradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              constraints: const BoxConstraints(minWidth: 150, minHeight: 50),
              alignment: Alignment.center,
              child: const Text("Se connecter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    ),
  );
}

  // --- WIDGETS DE DESIGN ---

  Widget _buildGlassButton(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: () => debugPrint(label),
      ),
    );
  }

  Widget _buildAddStory(int userId) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kSurfaceColor,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: kBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF22D3EE),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Moi",
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(FriendPost friend) {
    final bool hasAvatar =
        friend.profilePicture != null && friend.profilePicture!.isNotEmpty;

    return GestureDetector(
      // --- L'ACTION DE CLIC ---
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              friendId: friend.id,
              friendName: friend.username,
              friendAvatar: friend.profilePicture ?? "", // On gère le cas null
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: friend.hasStory ? kAccentGradient : null,
                border: friend.hasStory ? null : Border.all(color: Colors.white10),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: kSurfaceColor,
                backgroundImage: hasAvatar
                    ? NetworkImage(
                        '${ApiConfig.avatarUrl}/${friend.profilePicture!}',
                      )
                    : null,
                child: !hasAvatar
                    ? Text(
                        friend.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            // On contraint la largeur au diamètre approximatif de l'avatar (radius 32 + bordure = ~70)
            SizedBox(
              width: 74, 
              child: Text(
                friend.username,
                textAlign: TextAlign.center, // Toujours plus beau centré sous la bulle
                maxLines: 1, // Une seule ligne autorisée
                overflow: TextOverflow.ellipsis, // Ajoute "..." à la fin si c'est trop long
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            "Silence radio...",
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, Map<String, dynamic> contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          friendId: contact['id'],
          friendName: contact['name'],
          friendAvatar: contact['avatar'],
        ),
      ),
    );
  }
}