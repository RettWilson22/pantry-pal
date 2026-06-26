import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pantry_item.dart';

/// Persists the pantry to local device storage.
///
/// We use [SharedPreferences] with a single JSON string. For an inventory of
/// this size that's simpler and more portable than a SQLite schema, while still
/// giving us durable, fully on-device storage. The repository is the only place
/// that knows the data is JSON — callers work purely with [PantryItem]s.
class PantryRepository {
  static const String _storageKey = 'pantry_items_v1';

  /// Load every saved item. Returns an empty list on first launch or if the
  /// stored data is somehow unreadable, so the UI can show its empty state
  /// instead of crashing.
  Future<List<PantryItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupted data — fail safe to empty rather than blocking the app.
      return [];
    }
  }

  /// Persist the full list, overwriting the previous snapshot.
  Future<void> saveItems(List<PantryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
