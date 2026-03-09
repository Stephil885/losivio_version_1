// "screens/setting_screen.dart"

import 'package:flutter/material.dart';

// On récupère les mêmes codes couleurs pour la cohérence
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kSurfaceColor = Color(0xFF1E293B);
const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSectionHeader('Compte'),
          _buildSettingTile(
            icon: Icons.person_outline_rounded,
            title: 'Modifier le profil',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.lock_outline_rounded,
            title: 'Changer le mot de passe',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.alternate_email_rounded,
            title: 'Changer l\'email',
            onTap: () {},
          ),

          const SizedBox(height: 30),
          _buildSectionHeader('Notifications'),
          _buildSettingTile(
            icon: Icons.notifications_none_rounded,
            title: 'Préférences',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.volume_up_outlined,
            title: 'Sons et alertes',
            onTap: () {},
          ),

          const SizedBox(height: 30),
          _buildSectionHeader('Aide & Légal'),
          _buildSettingTile(
            icon: Icons.help_outline_rounded,
            title: 'FAQ',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () {},
          ),

          const SizedBox(height: 40),
          
          // --- BOUTON DECONNEXION ---
          _buildLogoutButton(context),
          
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Version 2.0.1",
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
          const SizedBox(height: 45),
        ],
      ),
    );
  }

  // --- HEADERS DE SECTION ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // --- TILE DE PARAMÈTRE (STYLE GLASS) ---
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => kAccentGradient.createShader(bounds),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.2), size: 16),
        onTap: onTap,
      ),
    );
  }

  // --- BOUTON DECONNEXION UNIQUE ---
  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // Logique de déconnexion ici
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 10),
            Text(
              "Se déconnecter",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}