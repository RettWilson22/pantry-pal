import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pantry_item.dart';

/// Saves the whole pantry as one JSON string in [SharedPreferences], which is
/// plenty for a list this size.
class PantryRepository {
  static const String _storageKey = 'pantry_items_v1';
  static const String _backupKey = 'pantry_items_v1_backup';

  /// Returns an empty list on first launch. If the saved data can't be parsed,
  /// it's copied to a backup key and a [FormatException] is thrown, so the next
  /// save can't wipe out the only copy.
  Future<List<PantryItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await prefs.setString(_backupKey, raw);
      throw FormatException('Saved pantry could not be read: $e');
    }
  }

  Future<void> saveItems(List<PantryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
