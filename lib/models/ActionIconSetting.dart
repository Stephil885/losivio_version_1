// /models/ActionIconSetting.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';

class ActionIconSetting extends ConsumerWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  const ActionIconSetting({
    super.key,
    required this.icon,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCircularButton(context, ref),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(
              label!,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                shadows: [
                  const Shadow(
                    blurRadius: 4, 
                    color: Colors.black54, 
                    offset: Offset(0, 2),
                  )
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap ?? () => _showPostOptions(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // On utilise un Consumer ici pour que le menu se mette à jour 
        // instantanément quand on clique sur un switch
        return Consumer(
          builder: (context, ref, child) {
            final userState = ref.watch(userProvider).value;
            
            // Valeurs par défaut si l'utilisateur n'est pas connecté
            final isTranslateActive = userState?.translatePost ?? false;
            final isSubtitlesActive = userState?.sousTitrePost ?? true;

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHandle(),
                  const SizedBox(height: 20),
                  
                  // Section Actions Rapides
                  _buildSectionContainer([
                    _buildMenuTile(
                      icon: Icons.bookmark_outline,
                      text: "Enregistrer",
                      onTap: () => Navigator.pop(context),
                    ),
                    const Divider(height: 1, color: Colors.white10, indent: 50),
                    _buildMenuTile(
                      icon: Icons.link,
                      text: "Copier le lien",
                      onTap: () => Navigator.pop(context),
                    ),
                    const Divider(height: 1, color: Colors.white10, indent: 50),
                    _buildMenuTile(
                      icon: Icons.share_outlined,
                      text: "Partager vers...",
                      onTap: () => Navigator.pop(context),
                    ),
                  ]),
                  
                  const SizedBox(height: 20),

                  // Section Paramètres d'Accessibilité (Connectée au Provider)
                  _buildSectionContainer([
                    _buildSwitchTile(
                      icon: Icons.translate,
                      text: "Traduire automatiquement",
                      value: isTranslateActive,
                      onChanged: (v) => ref.read(userProvider.notifier).toggleTranslation(v),
                    ),
                    const Divider(height: 1, color: Colors.white10, indent: 50),
                    _buildSwitchTile(
                      icon: Icons.subtitles_outlined,
                      text: "Afficher les sous-titres",
                      value: isSubtitlesActive,
                      onChanged: (v) => ref.read(userProvider.notifier).toggleSubtitles(v),
                    ),
                  ]),

                  const SizedBox(height: 30),

                  // Section Danger
                  _buildSectionContainer([
                    _buildMenuTile(
                      icon: Icons.report_gmailerrorred,
                      text: "Signaler le contenu",
                      color: Colors.redAccent,
                      onTap: () => Navigator.pop(context),
                    ),
                  ]),
                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color.withOpacity(0.8), size: 22),
      title: Text(
        text,
        style: GoogleFonts.inter(color: color, fontSize: 15, fontWeight: FontWeight.w400),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String text,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
      title: Text(
        text,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: const Color(0xFF22D3EE),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 36,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}