import 'item_category.dart';

/// A single item stored in the pantry.
///
/// This is an immutable value object: edits produce a new instance via
/// [copyWith]. It owns its own JSON (de)serialisation so the storage layer
/// ([PantryRepository]) only deals with maps and never with the field details.
class PantryItem {
  final String id;
  final String name;

  /// The raw barcode value captured by the scanner. Null when the user added
  /// the item by hand (manual fallback when no barcode is detected).
  final String? barcode;

  final ItemCategory category;
  final int quantity;

  /// Free-text unit such as "pcs", "g", "ml", "pack". Kept as a String so the
  /// user isn't boxed into a fixed list.
  final String unit;

  /// When [quantity] is at or below this number the item is flagged "low".
  /// Drives the low-stock summary and the restock prompts.
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
      category: ItemCategoryInfo.fromName(json['category'] as String?),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'pcs',
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 1,
      note: json['note'] as String?,
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
    );
  }
}
