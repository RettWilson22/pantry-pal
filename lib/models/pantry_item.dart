import 'item_category.dart';

/// An item in the pantry. Immutable; edits go through [copyWith].
class PantryItem {
  final String id;
  final String name;

  /// Null when the item was added by hand.
  final String? barcode;

  final ItemCategory category;
  final int quantity;

  /// Unit such as "pcs", "g" or "pack".
  final String unit;

  /// The item counts as low once [quantity] drops to this number.
  final int lowStockThreshold;

  final String? note;
  final DateTime addedAt;
  final DateTime updatedAt;

  const PantryItem({
    required this.id,
    required this.name,
    this.barcode,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
    this.note,
    required this.addedAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get isOutOfStock => quantity <= 0;

  PantryItem copyWith({
    String? name,
    String? barcode,
    ItemCategory? category,
    int? quantity,
    String? unit,
    int? lowStockThreshold,
    String? note,
    DateTime? updatedAt,
  }) {
    return PantryItem(
      id: id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      note: note ?? this.note,
      addedAt: addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'barcode': barcode,
        'category': category.name,
        'quantity': quantity,
        'unit': unit,
        'lowStockThreshold': lowStockThreshold,
        'note': note,
        'addedAt': addedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return PantryItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed item',
      barcode: json['barcode'] as String?,
      category: ItemCategory.fromName(json['category'] as String?),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'pcs',
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 1,
      note: json['note'] as String?,
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
    );
  }
}
