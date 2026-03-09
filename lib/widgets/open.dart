import 'dart:math';
import 'package:flutter/material.dart';

import 'AiMainbutton.dart';
import 'LiveChatSheet.dart';
import 'LiveShopSheet.dart';
import 'LiveGiftSheet.dart';
import '../models/gift_item.dart';
import '../models/Streamer_model.dart';
import '../components/listStreamers.dart';
//import '../models/streamer_mock.dart';
import 'TikTokLikeEffect.dart';

/* -------------------------------------------------------------------------- */
/* HELPERS POUR LES SHEETS                                                    */
/* -------------------------------------------------------------------------- */

Future<void> openChat(BuildContext context) async {
  final height = MediaQuery.of(context).size.height;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(maxHeight: height * 0.6),
    builder: (_) => const LiveChatSheet(),
  );
}

Future<void> openShop(BuildContext context) async {
  final height = MediaQuery.of(context).size.height;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(maxHeight: height * 0.6),
    builder: (_) => const LiveShopSheet(),
  );
}

Future<void> openGift(
  BuildContext context,
  Function(GiftItem) onGiftSelected,
  int tokenBalance,
) async {
  final height = MediaQuery.of(context).size.height;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(maxHeight: height * 0.6),
    builder:
        (_) => LiveGiftSheet(
          tokenBalance: tokenBalance,
          onGiftSelected: onGiftSelected,
        ),
  );
}


// Petit helper interne pour construire les lignes du menu
Widget buildToggleRow({
  required IconData icon,
  required String label,
  required bool value,
  required Function(bool?) onChanged,
}) {
  return Row(
    children: [
      Icon(icon, color: Colors.white70, size: 24),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.redAccent,
        checkColor: Colors.white,
        side: const BorderSide(color: Colors.white54, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ],
  );
}



