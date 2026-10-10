import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pantry_pal/models/item_category.dart';
import 'package:pantry_pal/models/pantry_item.dart';
import 'package:pantry_pal/providers/pantry_provider.dart';
import 'package:pantry_pal/services/pantry_repository.dart';

/// An in-memory stand-in for the real repository so provider logic can be
/// tested without the shared_preferences platform plugin.
class FakeRepository extends PantryRepository {
  List<PantryItem> store = [];

  @override
  Future<List<PantryItem>> loadItems() async => List.of(store);

  @override
  Future<void> saveItems(List<PantryItem> items) async =>
      store = List.of(items);
}

void main() {
  group('PantryItem', () {
    test('round-trips through JSON', () {
      final item = PantryItem(
        id: '1',
        name: 'Milk',
        barcode: '123',
        category: ItemCategory.dairy,
        quantity: 2,
        unit: 'L',
        lowStockThreshold: 1,
        note: 'skim',
        addedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
      final restored = PantryItem.fromJson(item.toJson());
      expect(restored.name, 'Milk');
      expect(restored.category, ItemCategory.dairy);
      expect(restored.quantity, 2);
      expect(restored.barcode, '123');
    });

    test('low-stock flag tracks the threshold', () {
      final item = PantryItem(
        id: '1',
        name: 'Eggs',
        category: ItemCategory.dairy,
        quantity: 1,
        unit: 'box',
        lowStockThreshold: 1,
        addedAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(item.isLowStock, isTrue);
      expect(item.copyWith(quantity: 5).isLowStock, isFalse);
    });
  });

  group('PantryRepository', () {
    test('backs up unreadable data before a save can replace it', () async {
      SharedPreferences.setMockInitialValues({'pantry_items_v1': '[{"id": 1'});
      final repository = PantryRepository();

      await expectLater(repository.loadItems(), throwsFormatException);
      await repository.saveItems([]);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pantry_items_v1_backup'), '[{"id": 1');
    });
  });

  group('PantryProvider', () {
    test('flags a saved pantry it could not read', () async {
      SharedPreferences.setMockInitialValues({'pantry_items_v1': 'not json'});
      final provider = PantryProvider(PantryRepository());
      await provider.load();

      expect(provider.loadFailed, isTrue);
      expect(provider.hasNoItems, isTrue);
    });

    test('adds an item and updates the summary', () async {
      final provider = PantryProvider(FakeRepository());
      await provider.load();
      expect(provider.hasNoItems, isTrue);

      await provider.addItem(
        name: 'Apples',
        category: ItemCategory.produce,
        quantity: 4,
        unit: 'pcs',
        lowStockThreshold: 2,
      );

      expect(provider.summary.distinctItems, 1);
      expect(provider.summary.totalUnits, 4);
      expect(provider.summary.lowStockCount, 0);
    });

    test('adjustQuantity clamps at zero and flags low stock', () async {
      final provider = PantryProvider(FakeRepository());
      await provider.load();
      final item = await provider.addItem(
        name: 'Rice',
        category: ItemCategory.pantry,
        quantity: 1,
        unit: 'kg',
        lowStockThreshold: 1,
      );

      await provider.adjustQuantity(item.id, -5);
      expect(provider.itemById(item.id)!.quantity, 0);
      expect(provider.summary.lowStockCount, 1);
    });

    test('findByBarcode locates an existing record', () async {
      final provider = PantryProvider(FakeRepository());
      await provider.load();
      await provider.addItem(
        name: 'Soda',
        barcode: '049000006344',
        category: ItemCategory.beverages,
        quantity: 6,
        unit: 'can',
        lowStockThreshold: 2,
      );
      expect(provider.findByBarcode('049000006344'), isNotNull);
      expect(provider.findByBarcode('000'), isNull);
    });

    test('search and category filters narrow the list', () async {
      final provider = PantryProvider(FakeRepository());
      await provider.load();
      await provider.addItem(
        name: 'Banana',
        category: ItemCategory.produce,
        quantity: 3,
        unit: 'pcs',
        lowStockThreshold: 1,
      );
      await provider.addItem(
        name: 'Cheddar',
        category: ItemCategory.dairy,
        quantity: 1,
        unit: 'block',
        lowStockThreshold: 1,
      );

      provider.setSearchQuery('ban');
      expect(provider.filteredItems.length, 1);

      provider.setSearchQuery('');
      provider.setCategoryFilter(ItemCategory.dairy);
      expect(provider.filteredItems.single.name, 'Cheddar');
    });
  });
}
