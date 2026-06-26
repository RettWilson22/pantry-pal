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

/// The single source of truth for the pantry UI.
///
/// Holds the in-memory item list plus the active search/category/low-stock
/// filters, exposes derived views (filtered list, grouped list, summary), and
/// owns all create/update/delete operations — each of which persists through
/// the [PantryRepository] and then notifies listeners so the screens rebuild.
class PantryProvider extends ChangeNotifier {
  final PantryRepository _repository;

  PantryProvider(this._repository);

  List<PantryItem> _items = [];
  bool _isLoading = true;

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

  /// True when there are no saved items at all (drives the first-run empty
  /// state, as opposed to "filters matched nothing").
  bool get hasNoItems => _items.isEmpty;

  /// Load saved items from storage. Call once at startup.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _items = await _repository.loadItems();
    _sort();
    _isLoading = false;
    notifyListeners();
  }

  PantrySummary get summary => PantrySummary(
        distinctItems: _items.length,
        totalUnits: _items.fold(0, (sum, i) => sum + i.quantity),
        lowStockCount: _items.where((i) => i.isLowStock).length,
      );

  /// The item list after applying search + category + low-stock filters.
  List<PantryItem> get filteredItems {
    final query = _searchQuery.trim().toLowerCase();
    return _items.where((item) {
      if (_categoryFilter != null && item.category != _categoryFilter) {
        return false;
      }
      if (_showLowStockOnly && !item.isLowStock) return false;
      if (query.isNotEmpty) {
        final haystack =
            '${item.name} ${item.note ?? ''} ${item.barcode ?? ''}'
                .toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  /// Filtered items bucketed by category, for the grouped list view.
  Map<ItemCategory, List<PantryItem>> get groupedItems {
    final map = <ItemCategory, List<PantryItem>>{};
    for (final item in filteredItems) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  PantryItem? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Find an existing item by barcode so a re-scan can offer to bump quantity
  /// instead of creating a duplicate record.
  PantryItem? findByBarcode(String barcode) {
    final target = barcode.trim();
    if (target.isEmpty) return null;
    for (final item in _items) {
      if (item.barcode == target) return item;
    }
    return null;
  }

  // ---- Filter mutations -----------------------------------------------------

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

  // ---- CRUD -----------------------------------------------------------------

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
      barcode: barcode?.trim().isEmpty ?? true ? null : barcode!.trim(),
      category: category,
      quantity: quantity,
      unit: unit.trim(),
      lowStockThreshold: lowStockThreshold,
      note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
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

  /// Adjust a single item's quantity by [delta] (clamped at zero). Used by the
  /// inline +/- steppers on the cards and detail screen.
  Future<void> adjustQuantity(String id, int delta) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final current = _items[index];
    final next = (current.quantity + delta).clamp(0, 1 << 31);
    _items[index] = current.copyWith(quantity: next, updatedAt: DateTime.now());
    _sort();
    await _persist();
  }

  // ---- Internal -------------------------------------------------------------

  /// Low-stock items float to the top, then newest first. Re-sorting on every
  /// change keeps the list stable and predictable.
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
}
