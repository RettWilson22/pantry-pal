import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/item_category.dart';
import '../models/pantry_item.dart';
import '../services/pantry_repository.dart';

/// A small summary of the pantry, shown in the dashboard header.
class PantrySummary {
  final int distinctItems;
  final int totalUnits;
  final int lowStockCount;
  const PantrySummary({
    required this.distinctItems,
    required this.totalUnits,
    required this.lowStockCount,
  });
}

/// Pantry items plus the active search and filters. Every change is saved
/// through [PantryRepository] before listeners are notified.
class PantryProvider extends ChangeNotifier {
  final PantryRepository _repository;

  PantryProvider(this._repository);

  List<PantryItem> _items = [];
  bool _isLoading = true;
  bool _loadFailed = false;

  String _searchQuery = '';
  ItemCategory? _categoryFilter; // null == all categories
  bool _showLowStockOnly = false;

  // Used together with the timestamp to make collision-free ids even when two
  // items are added in the same millisecond.
  int _idCounter = 0;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ItemCategory? get categoryFilter => _categoryFilter;
  bool get showLowStockOnly => _showLowStockOnly;

  /// No saved items at all, as opposed to filters matching nothing.
  bool get hasNoItems => _items.isEmpty;

  /// The saved pantry couldn't be parsed, so the list started out empty. The
  /// repository kept a backup of the old data.
  bool get loadFailed => _loadFailed;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repository.loadItems();
    } on FormatException {
      _loadFailed = true;
    }
    _sort();
    _isLoading = false;
    notifyListeners();
  }

  PantrySummary get summary => PantrySummary(
        distinctItems: _items.length,
        totalUnits: _items.fold(0, (sum, i) => sum + i.quantity),
        lowStockCount: _items.where((i) => i.isLowStock).length,
      );

  List<PantryItem> get filteredItems {
    final query = _searchQuery.trim().toLowerCase();
    return _items.where((item) {
      if (_categoryFilter != null && item.category != _categoryFilter) {
        return false;
      }
      if (_showLowStockOnly && !item.isLowStock) return false;
      if (query.isNotEmpty) {
        final haystack = '${item.name} ${item.note ?? ''} ${item.barcode ?? ''}'
            .toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  Map<ItemCategory, List<PantryItem>> get groupedItems {
    final map = <ItemCategory, List<PantryItem>>{};
    for (final item in filteredItems) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  PantryItem? itemById(String id) =>
      _items.where((item) => item.id == id).firstOrNull;

  /// Lets a re-scan offer to add to an existing item instead of duplicating it.
  PantryItem? findByBarcode(String barcode) {
    final target = barcode.trim();
    if (target.isEmpty) return null;
    return _items.where((item) => item.barcode == target).firstOrNull;
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setCategoryFilter(ItemCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void toggleLowStockOnly() {
    _showLowStockOnly = !_showLowStockOnly;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _showLowStockOnly = false;
    notifyListeners();
  }

  Future<PantryItem> addItem({
    required String name,
    String? barcode,
    required ItemCategory category,
    required int quantity,
    required String unit,
    required int lowStockThreshold,
    String? note,
  }) async {
    final now = DateTime.now();
    final item = PantryItem(
      id: '${now.microsecondsSinceEpoch}_${_idCounter++}',
      name: name.trim(),
      barcode: _trimToNull(barcode),
      category: category,
      quantity: quantity,
      unit: unit.trim(),
      lowStockThreshold: lowStockThreshold,
      note: _trimToNull(note),
      addedAt: now,
      updatedAt: now,
    );
    _items.add(item);
    _sort();
    await _persist();
    return item;
  }

  Future<void> updateItem(PantryItem updated) async {
    final index = _items.indexWhere((i) => i.id == updated.id);
    if (index == -1) return;
    _items[index] = updated.copyWith(updatedAt: DateTime.now());
    _sort();
    await _persist();
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    await _persist();
  }

  /// Changes an item's quantity by [delta], never going below zero.
  Future<void> adjustQuantity(String id, int delta) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final current = _items[index];
    final next = max(0, current.quantity + delta);
    _items[index] = current.copyWith(quantity: next, updatedAt: DateTime.now());
    _sort();
    await _persist();
  }

  /// Low-stock items first, then most recently updated.
  void _sort() {
    _items.sort((a, b) {
      if (a.isLowStock != b.isLowStock) return a.isLowStock ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<void> _persist() async {
    await _repository.saveItems(_items);
    notifyListeners();
  }

  static String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
