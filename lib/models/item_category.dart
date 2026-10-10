import 'package:flutter/material.dart';

/// The fixed list of categories, so items can be grouped and filtered
/// reliably instead of relying on free-text names.
enum ItemCategory {
  produce('Produce', Icons.eco_outlined, Color(0xFF2E7D32)),
  dairy('Dairy', Icons.egg_outlined, Color(0xFF1565C0)),
  meat('Meat', Icons.set_meal_outlined, Color(0xFFC62828)),
  bakery('Bakery', Icons.bakery_dining_outlined, Color(0xFF8D6E63)),
  pantry('Pantry', Icons.kitchen_outlined, Color(0xFF6A1B9A)),
  frozen('Frozen', Icons.ac_unit_outlined, Color(0xFF00838F)),
  beverages('Beverages', Icons.local_cafe_outlined, Color(0xFFEF6C00)),
  snacks('Snacks', Icons.cookie_outlined, Color(0xFFAD1457)),
  household('Household', Icons.cleaning_services_outlined, Color(0xFF455A64)),
  other('Other', Icons.inventory_2_outlined, Color(0xFF546E7A));

  const ItemCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// Parses a stored [name], falling back to [other] for unknown or missing
  /// values so an old or corrupted record still loads.
  static ItemCategory fromName(String? name) => ItemCategory.values.firstWhere(
        (c) => c.name == name,
        orElse: () => ItemCategory.other,
      );
}
