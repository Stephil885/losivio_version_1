// widget/SingleVideo.dart


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'open.dart';

class RoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  const RoleBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


/* -------------------------------------------------------------------------- */
/* HELPERS PANNEAU STREAMER                                                   */
/* -------------------------------------------------------------------------- */

Future<void> openStreamerPanel(BuildContext context, bool currentLock, Function(bool) onLockChanged) async {
  bool isTranslated = true;
  await showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 25),
                const Text("PARAMÈTRES DU LIVE 🎥", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                buildToggleRow(
                  icon: Icons.lock_outline,
                  label: "Verrouiller l'écran",
                  value: currentLock,
                  onChanged: (val) {
                    setModalState(() => currentLock = val!);
                    onLockChanged(val!);
                    HapticFeedback.lightImpact();
                  },
                ),
                const Divider(color: Colors.white10, height: 32),
                buildToggleRow(
                  icon: Icons.translate,
                  label: "Traduire le live",
                  value: isTranslated,
                  onChanged: (val) {
                    setModalState(() => isTranslated = val!);
                    HapticFeedback.lightImpact();
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("VALIDER", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

