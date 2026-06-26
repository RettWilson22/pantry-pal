import '../models/item_category.dart';

/// A scanned barcode pre-filled against the local catalog.
class CatalogMatch {
  final String name;
  final ItemCategory category;
  const CatalogMatch(this.name, this.category);
}

/// A tiny, fully on-device catalog of common grocery barcodes.
///
/// Real barcode databases live behind a network API, but this assignment keeps
/// everything on-device, so we ship a small seed map instead. When a scanned
/// barcode is recognised the add-item form is pre-filled with a sensible name
/// and category; when it isn't, the user just types the name themselves. This
/// keeps the scan-to-save flow fast for the common case without ever needing a
/// connection.
class ProductCatalog {
  static const Map<String, CatalogMatch> _entries = {
    '049000006344': CatalogMatch('Coca-Cola 12oz Can', ItemCategory.beverages),
    '038000138416': CatalogMatch('Pringles Original', ItemCategory.snacks),
    '021130126026': CatalogMatch('Whole Milk 1 Gallon', ItemCategory.dairy),
    '044000032029': CatalogMatch('Oreo Cookies', ItemCategory.snacks),
    '016000275287': CatalogMatch('Cheerios Cereal', ItemCategory.pantry),
    '078742370361': CatalogMatch('Large Eggs (Dozen)', ItemCategory.dairy),
    '037600106474': CatalogMatch('Spam Classic', ItemCategory.meat),
    '051500255162': CatalogMatch('Jif Peanut Butter', ItemCategory.pantry),
    '011110038364': CatalogMatch('Bag of Apples', ItemCategory.produce),
    '030000010204': CatalogMatch('Quaker Oats', ItemCategory.pantry),
  };

  /// Returns a pre-fill suggestion for [barcode], or null if it's unknown.
  static CatalogMatch? lookup(String barcode) => _entries[barcode.trim()];
}
