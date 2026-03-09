// models/gift_item.dart

class GiftItem {
  final String emoji;
  final String name;
  final int cost;
  final bool isPremium;

  const GiftItem({
    required this.emoji,
    required this.name,
    required this.cost,
    this.isPremium = false,
  });

  // Pour les cadeaux système gratuits pendant les likes
  GiftItem copyWith({int? cost}) {
    return GiftItem(
      emoji: emoji,
      name: name,
      cost: cost ?? this.cost,
      isPremium: isPremium,
    );
  }
}

// AJOUT DE LA CLASSE MANQUANTE ICI
class GiftCategory {
  final String id;
  final String label;
  final String emoji;
  final List<GiftItem> gifts;

  const GiftCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.gifts,
  });
}