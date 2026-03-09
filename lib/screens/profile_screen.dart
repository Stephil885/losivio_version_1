// screens/profile_screen.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';
import './auth_screen.dart';
import '../widgets/profile_header.dart';
import './setting_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import 'chat_screen.dart';
import '../config/api_config.dart';

// --- CONFIGURATION DESIGN PREMIUM ---
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kSurfaceColor = Color(0xFF1E293B);
const Color kPlaceholderColor = Colors.black;

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

class ProfileScreen extends ConsumerStatefulWidget {
  final void Function(int)? onChangeTab;
  final int? userId;
  final String? userName;
  final String? email;
  final String? avatar;

  const ProfileScreen({
    super.key,
    this.onChangeTab,
    this.userId,
    this.userName,
    this.email,
    this.avatar,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  Shader _createShader(Rect bounds) => kAccentGradient.createShader(bounds);

  Future<void> _handleEditImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              "Photo de profil",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20),
            _buildSheetTile(
              icon: Icons.photo_library_rounded,
              label: "Galerie",
              color: const Color(0xFFA855F7),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) _processPickedImage(File(image.path));
              },
            ),
            _buildSheetTile(
              icon: Icons.camera_alt_rounded,
              label: "Appareil photo",
              color: const Color(0xFFEC4899),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) _processPickedImage(File(image.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _processPickedImage(File imageFile) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mise à jour du profil... ☁️")),
    );
    try {
      await ref.read(userProvider.notifier).uploadAvatar(imageFile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil mis à jour ! ✅")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const Scaffold(backgroundColor: kBackgroundColor, body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(backgroundColor: kBackgroundColor, body: Center(child: Text("Erreur : $err", style: const TextStyle(color: Colors.white)))),
      data: (user) {
        if (user == null) return _buildGuestProfile(context);

        final bool isMe = widget.userId == null || widget.userId == user.id;

        String displayImage;
        if (isMe) {
          displayImage = (user.avatar != null && user.avatar!.isNotEmpty)
              ? (user.avatar!.startsWith('http') ? user.avatar! : "${ApiConfig.avatarUrl}/${user.avatar}")
              : 'https://i.pravatar.cc/150?u=${user.id}';
        } else {
          displayImage = (widget.avatar != null && widget.avatar!.isNotEmpty)
              ? widget.avatar!
              : 'https://i.pravatar.cc/150?u=${widget.userId ?? 0}';
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: kBackgroundColor,
            appBar: AppBar(
              backgroundColor: kBackgroundColor,
              elevation: 0,
              centerTitle: true,
              title: Text(
                isMe ? "Mon Compte" : (widget.userName ?? "Profil"),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19),
              ),
              actions: [
                if (isMe) ...[
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Color(0xFFEC4899)),
                    onPressed: () async {
                      await ref.read(userProvider.notifier).logout();
                      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BottomNavBar()));
                    },
                  ),
                ],
              ],
              bottom: TabBar(
                indicatorColor: const Color(0xFFA855F7),
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white30,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                  Tab(icon: Icon(Icons.favorite_rounded, size: 22)),
                  Tab(icon: Icon(Icons.bookmark_rounded, size: 22)),
                ],
              ),
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      ProfileHeader(
                        userId: isMe ? user.id : widget.userId ?? 0,
                        username: isMe ? user.username : (widget.userName ?? "Utilisateur"),
                        bio: isMe 
                            ? '✨ Créateur de contenu • ${user.email}' 
                            : '✨ Passionné de vidéos',
                        imageUrl: displayImage,
                        followers: 1240,
                        following: 150,
                        likes: 3800,
                        isMe: isMe,
                        onEditImage: isMe ? _handleEditImage : null,
                        // --- AJOUTE CES DEUX LIGNES ---
                        email: isMe ? (user.email ?? '') : (widget.email ?? ''),
                        phone: isMe ? (user.phone ?? '') : '', 
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: _PremiumButton(
                                icon: isMe ? Icons.edit_note_rounded : Icons.person_add_rounded,
                                label: isMe ? "Modifier" : "Suivre",
                                isPrimary: !isMe,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PremiumButton(
                                icon: isMe ? Icons.share_rounded : Icons.send_rounded,
                                label: isMe ? "Partager" : "Message",
                                isPrimary: false,
                                onTap: () {
                                  if (!isMe && widget.userId != null) {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        friendId: widget.userId!,
                                        friendName: widget.userName ?? "Utilisateur",
                                        friendAvatar: displayImage,
                                      ),
                                    ));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
              body: const TabBarView(
                children: [
                  VideosGrid(tabType: 'Mes vidéos'),
                  VideosGrid(tabType: 'Favoris'),
                  VideosGrid(tabType: 'Enregistrés'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: _createShader,
              child: const Icon(Icons.person_outline, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              "Rejoignez la communauté",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 32),
            _PremiumButton(
              label: "Se connecter",
              isPrimary: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

// --- BOUTONS PREMIUM ---
class _PremiumButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _PremiumButton({this.icon, required this.label, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isPrimary ? kAccentGradient : null,
          color: isPrimary ? null : kSurfaceColor,
          boxShadow: isPrimary ? [
            BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// --- GRILLE DE VIDÉOS ---
class VideosGrid extends StatelessWidget {
  final String tabType;
  const VideosGrid({super.key, required this.tabType});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.75,
      ),
      itemCount: 15,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage('https://picsum.photos/id/${index + 10}/300/450'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 8,
              left: 8,
              child: Row(
                children: const [
                  Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                  Text(' 1.2k', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}