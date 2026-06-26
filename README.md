# Pantry Pal 🧺

A mobile **pantry & grocery inventory** app built with Flutter. You scan a
product's barcode, confirm the details, and Pantry Pal keeps an organized,
searchable inventory of what you have at home — including which items are
running low so you know what to buy.

Built for the *On-Device Machine Learning* assignment (Mobile Applications
Development).

---

## On-device ML feature

The core feature is **barcode scanning**, performed entirely **on-device**:

- On **Android** it uses **Google ML Kit's Barcode Scanning** model.
- On **iOS** it uses **Apple's Vision** framework.

Both run locally with **no network connection** — nothing leaves the phone.
This is wired up through the [`mobile_scanner`](https://pub.dev/packages/mobile_scanner)
plugin in [`lib/screens/scan_screen.dart`](lib/screens/scan_screen.dart).

A small **offline product catalog**
([`lib/services/product_catalog.dart`](lib/services/product_catalog.dart))
recognizes some common barcodes and pre-fills the item's name and category — but
the user always reviews and confirms before saving.

---

## What the app does

1. **Scan** a barcode with the live camera (the ML step).
2. **Confirm / edit** the auto-filled details — name, category, quantity, unit,
   low-stock threshold, and an optional note. *(User input beyond the ML result.)*
3. **Save** it to a categorized, searchable pantry stored on the device.
4. **Manage** items over time: adjust quantity inline, edit, restock, or delete.

---

## How it meets the rubric

| Requirement | Where it lives |
|---|---|
| **On-device ML feature** | Barcode scanning via ML Kit / Vision — `scan_screen.dart` |
| **User input beyond the ML result** | Add/edit form: name, category, quantity, unit, threshold, note — `item_form_screen.dart` |
| **Organized saved data** | Dashboard grouped by category, with cards + a detail screen — `home_screen.dart`, `item_detail_screen.dart` |
| **Manage saved info** | Edit, delete (with confirm), inline +/- quantity, restock — provider + detail screen |
| **Extra useful feature(s)** | Summary totals (items / units / low-stock), category filter, search, low-stock filter, detail screen |
| **Empty & error states** | First-run empty pantry, "no matches" state, camera-permission/error view, manual-entry fallback, duplicate-barcode prompt, form validation |
| **Code organization** | Split into `models/`, `services/`, `providers/`, `screens/`, `widgets/`, `theme/` |

---

## Project structure

```
lib/
├── main.dart                     # App entry; wires up the provider
├── models/
│   ├── item_category.dart        # Category enum + labels/icons/colors
│   └── pantry_item.dart          # Item model with JSON (de)serialization
├── services/
│   ├── pantry_repository.dart    # Local persistence (shared_preferences)
│   └── product_catalog.dart      # Offline barcode → product lookup
├── providers/
│   └── pantry_provider.dart      # State, CRUD, filters, summary (ChangeNotifier)
├── screens/
│   ├── home_screen.dart          # Dashboard: summary, search, filters, list
│   ├── scan_screen.dart          # Camera barcode scanner (the ML feature)
│   ├── item_form_screen.dart     # Add / edit form with validation
│   └── item_detail_screen.dart   # Detail view + manage actions
├── widgets/
│   ├── summary_bar.dart
│   ├── category_filter.dart
│   ├── pantry_item_card.dart
│   ├── quantity_stepper.dart
│   └── empty_state.dart
└── theme/
    └── app_theme.dart            # Material 3 theme
```

State management uses the `provider` package; persistence uses
`shared_preferences`. Everything works offline.

---

## Running it

Requires the Flutter SDK and a device/emulator with a camera (barcode scanning
needs a real camera — the iOS simulator has none, so use a physical device or an
Android emulator with a virtual/webcam camera).

```bash
flutter pub get
flutter run
```

Run the tests:

```bash
flutter test
```

### Permissions
- **Android** — `CAMERA` permission is declared in `AndroidManifest.xml`
  (`minSdkVersion` is set to 21 for ML Kit).
- **iOS** — `NSCameraUsageDescription` is set in `Info.plist`.

---

## Dependencies

- [`mobile_scanner`](https://pub.dev/packages/mobile_scanner) — on-device barcode scanning (ML Kit / Vision)
- [`provider`](https://pub.dev/packages/provider) — state management
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) — local storage
