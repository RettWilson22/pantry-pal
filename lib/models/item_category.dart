import 'package:flutter/material.dart';

/// The fixed set of categories a pantry item can belong to.
///
/// Keeping this as an enum (rather than free-text) means the rest of the app
/// can group, filter and colour items reliably, and the user always picks from
/// a known list instead of typing inconsistent category names.
enum ItemCategory {
  produce,
  dairy,
  meat,
  bakery,
  pantry,
  frozen,
  beverages,
  snacks,
  household,
  other,
}

/// Display metadata + (de)serialisation helpers for [ItemCategory].
///
/// Storing the enum's `name` (a stable String) in JSON keeps saved data
/// readable and resilient if we ever reorder the enum.
extension ItemCategoryInfo on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.produce:
        return 'Produce';
      case ItemCategory.dairy:
        return 'Dairy';
      case ItemCategory.meat:
        return 'Meat';
      case ItemCategory.bakery:
        return 'Bakery';
      case ItemCategory.pantry:
        return 'Pantry';
      case ItemCategory.frozen:
        return 'Frozen';
      case ItemCategory.beverages:
        return 'Beverages';
      case ItemCategory.snacks:
        return 'Snacks';
      case ItemCategory.household:
        return 'Household';
      case ItemCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.produce:
        return Icons.eco_outlined;
      case ItemCategory.dairy:
        return Icons.egg_outlined;
      case ItemCategory.meat:
        return Icons.set_meal_outlined;
      case ItemCategory.bakery:
        return Icons.bakery_dining_outlined;
      case ItemCategory.pantry:
        return Icons.kitchen_outlined;
      case ItemCategory.frozen:
        return Icons.ac_unit_outlined;
      case ItemCategory.beverages:
        return Icons.local_cafe_outlined;
      case ItemCategory.snacks:
        return Icons.cookie_outlined;
      case ItemCategory.household:
        return Icons.cleaning_services_outlined;
      case ItemCategory.other:
        return Icons.inventory_2_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ItemCategory.produce:
        return const Color(0xFF2E7D32);
      case ItemCategory.dairy:
        return const Color(0xFF1565C0);
      case ItemCategory.meat:
        return const Color(0xFFC62828);
      case ItemCategory.bakery:
        return const Color(0xFF8D6E63);
      case ItemCategory.pantry:
        return const Color(0xFF6A1B9A);
      case ItemCategory.frozen:
        return const Color(0xFF00838F);
      case ItemCategory.beverages:
        return const Color(0xFFEF6C00);
      case ItemCategory.snacks:
        return const Color(0xFFAD1457);
      case ItemCategory.household:
        return const Color(0xFF455A64);
      case ItemCategory.other:
        return const Color(0xFF546E7A);
    }
  }

  /// Convert the stored String back into an enum, defaulting to [other] so a
  /// corrupted/old record never crashes the app.
  static ItemCategory fromName(String? name) {
    return ItemCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => ItemCategory.other,
    );
  }
}
