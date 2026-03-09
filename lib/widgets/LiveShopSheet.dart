import 'package:flutter/material.dart';

class TokenPack {
  final int tokens;
  final double price;

  const TokenPack(this.tokens, this.price);
}

class LiveShopSheet extends StatelessWidget {
  const LiveShopSheet({super.key});

  static const List<TokenPack> packs = [
    TokenPack(5, 0.15),
    TokenPack(10, 0.20),
    TokenPack(25, 0.45),
    TokenPack(30, 0.60),
    TokenPack(40, 0.80),
    TokenPack(50, 1.05),
    TokenPack(70, 1.40),
    TokenPack(140, 2.80),
    TokenPack(160, 3.00),
    TokenPack(180, 3.10),
    TokenPack(200, 3.20),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    // 🔁 AUTO-ADAPTATIF
    final int crossAxisCount = width > 350 ? 3 : 2;

    return SizedBox(
      height: height * 0.7,
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
                  "Boutique de tokens",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              /// BALANCE
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("🪙", style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      "Solde : 12 tokens",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// PACKS
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount, // 🔥 DYNAMIQUE
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: packs.length,
                  itemBuilder: (_, i) {
                    final pack = packs[i];
                    return _TokenPackCard(pack: pack);
                  },
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
/*                               TOKEN CARD                                   */
/* -------------------------------------------------------------------------- */

class _TokenPackCard extends StatelessWidget {
  final TokenPack pack;

  const _TokenPackCard({required this.pack});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint(
          "🛒 Achat pack : ${pack.tokens} tokens pour \$${pack.price}",
        );
        // 👉 Stripe / Mobile Money / Google Play plus tard
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFEC4899),
              Color(0xFFA855F7),
            ],
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "🪙 ${pack.tokens}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "\$${pack.price.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Acheter",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
