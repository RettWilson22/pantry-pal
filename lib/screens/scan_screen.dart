import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Live barcode scanner. `mobile_scanner` runs ML Kit on Android and Vision on
/// iOS, both on-device.
///
/// Pops with the barcode value, an empty string if the user chose to enter the
/// item by hand, or null if they backed out.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.qrCode,
    ],
  );

  // The detector can fire again for a different code while we're popping.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _handled = true;
    Navigator.of(context).pop(value);
  }

  void _enterManually() => Navigator.of(context).pop('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan barcode'),
        actions: [
          IconButton(
            tooltip: 'Toggle torch',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Switch camera',
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) =>
                _CameraError(error: error, onManual: _enterManually),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Column(
              children: [
                const Text(
                  'Point the camera at a product barcode',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _enterManually,
                  icon: const Icon(Icons.keyboard_outlined,
                      color: Colors.white),
                  label: const Text(
                    "Can't scan? Enter manually",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the camera can't start, usually because permission was denied.
class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onManual;

  const _CameraError({required this.error, required this.onManual});

  @override
  Widget build(BuildContext context) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                denied ? Icons.no_photography_outlined : Icons.error_outline,
                color: Colors.white70,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                denied ? 'Camera permission needed' : 'Camera unavailable',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                denied
                    ? 'Enable camera access in Settings to scan barcodes, or '
                        'add the item by hand.'
                    : 'We couldn\'t start the camera. You can still add the '
                        'item by hand.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onManual,
                icon: const Icon(Icons.keyboard_outlined),
                label: const Text('Enter manually'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
