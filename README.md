# Pantry Pal

A Flutter app for keeping track of what's in your kitchen. You scan a product's barcode, check the details, and it goes into a pantry list that's grouped by category and flags anything that's running low.

I built it for the On-Device Machine Learning assignment in Mobile Applications Development.

## What it does

- Scans barcodes with the camera (EAN-13, EAN-8, UPC-A, UPC-E, Code 128 and QR codes)
- Fills in the name and category for a few known products, otherwise you type the name yourself
- Lets you set quantity, unit, a low-stock threshold and an optional note before saving
- Groups the pantry by category, with search and a row of category filters
- Shows totals at the top (items, units, how many are low). Tapping the low-stock count filters the list down to just those items
- If you scan something that's already saved, it asks if you want to add one more or edit the existing item instead of making a duplicate
- Has +/- buttons on every card, and edit, delete and restock on the detail screen
- Stores everything on the phone, so there's no account and no network needed

## How it works

Scanning goes through the [`mobile_scanner`](https://pub.dev/packages/mobile_scanner) plugin, which runs Google ML Kit's barcode model on Android and Apple's Vision framework on iOS. Both run on the device, so the camera feed never leaves the phone. That code is in `lib/screens/scan_screen.dart`. It also has buttons for the flashlight and switching cameras.

If the camera can't start (usually a denied permission) the scanner shows an error with an "Enter manually" button, and there's a "Can't scan?" link under the viewfinder for codes that won't read.

All the app state is in one `PantryProvider` (a `ChangeNotifier` from the `provider` package). It handles add/edit/delete, the filters and the summary numbers. `PantryRepository` saves the whole list as a single JSON string in `shared_preferences`. Low-stock items get sorted to the top, then everything else by most recently updated.

```
lib/
  main.dart
  models/      pantry_item.dart, item_category.dart
  services/    pantry_repository.dart, product_catalog.dart
  providers/   pantry_provider.dart
  screens/     home, scan, item form, item detail
  widgets/     summary bar, category filter, item card, quantity stepper, empty state
  theme/       app_theme.dart
```

## Running it

You need the Flutter SDK (Dart 3.3.4 or newer) and a device with a camera. The iOS simulator doesn't have a camera, so use a real phone or an Android emulator with a webcam or virtual camera set up. Without a camera you can still add items by hand.

```bash
flutter pub get
flutter run
```

The camera permission is already set up: `CAMERA` in the Android manifest (with `minSdkVersion 21`) and `NSCameraUsageDescription` in the iOS `Info.plist`.

There are unit tests for the item model and the provider (JSON round trip, the low-stock flag, quantity clamping at zero, barcode lookup, search and category filters), plus a couple for saved data that can't be parsed:

```bash
flutter test
```

## Notes

The "catalog" in `product_catalog.dart` is just a hardcoded map of 10 grocery barcodes (Coca-Cola, Cheerios, Jif, a gallon of milk, and so on). A real version would look codes up online, but the assignment was about keeping everything on-device, so for anything not in the map you just fill in the name yourself.

Restock bumps the quantity to one above the item's low-stock threshold, which is the smallest amount that clears the "running low" warning.
