// widgets/LiveGiftSheet.dart

import 'package:flutter/material.dart';
import '../models/gift_item.dart';
import 'GiftCategory.dart';
/* -------------------------------------------------------------------------- */
/*                               LIVE GIFT SHEET                              */
/* -------------------------------------------------------------------------- */

class LiveGiftSheet extends StatefulWidget {
  final Function(GiftItem) onGiftSelected;
  final int tokenBalance;

  const LiveGiftSheet({
    super.key,
    required this.onGiftSelected,
    required this.tokenBalance,
  });

  @override
  State<LiveGiftSheet> createState() => _LiveGiftSheetState();
}

class _LiveGiftSheetState extends State<LiveGiftSheet> {
  int selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final gifts = categories[selectedCategoryIndex].gifts;

    return SizedBox(
      height: height * 0.6,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              /// HANDLE
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              /// TITLE
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Envoyer un cadeau 🎁",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              /// TOKEN BALANCE
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🪙", style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      "Solde : ${widget.tokenBalance} tokens",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// CONTENT
              Expanded(
                child: Column(
                  children: [
                    /// GIFTS GRID
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 155,
                        ),
                        itemCount: gifts.length,
                        itemBuilder: (_, i) {
                          return _GiftCard(
                            gift: gifts[i],
                            tokenBalance: widget.tokenBalance,
                            onSelected: widget.onGiftSelected,
                          );
                        },
                      ),
                    ),

                    /// CATEGORIES
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        border: Border(top: BorderSide(color: Colors.white12)),
                      ),
                      child: SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final selected =
                                index == selectedCategoryIndex;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategoryIndex = index;
                                });
                              },
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Text(category.emoji),
                                    const SizedBox(width: 6),
                                    Text(
                                      category.label,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                  GIFT CARD                                 */
/* -------------------------------------------------------------------------- */

class _GiftCard extends StatelessWidget {
  final GiftItem gift;
  final Function(GiftItem) onSelected;
  final int tokenBalance;

  const _GiftCard({
    required this.gift,
    required this.onSelected,
    required this.tokenBalance,
  });

  @override
  Widget build(BuildContext context) {
    final canSend = tokenBalance >= gift.cost;

    return GestureDetector(
      onTap: canSend
          ? () {
              Navigator.of(context).pop();
              onSelected(gift);
            }
          : () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("❌ Solde insuffisant"),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
      child: Opacity(
        opacity: canSend ? 1 : 0.45,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(gift.emoji,
                            style:
                                const TextStyle(fontSize: 30)),
                        const SizedBox(height: 4),
                        Text(
                          gift.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "🪙 ${gift.cost}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FittedBox(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            canSend ? Colors.white : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Envoyer",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
