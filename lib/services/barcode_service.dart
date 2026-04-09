import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeService {
  MobileScannerController? _controller;

  MobileScannerController getController() {
    _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    return _controller!;
  }

  /// Parse barcode from scan result. Returns the first valid barcode string.
  String? parseBarcode(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        return barcode.rawValue!;
      }
    }
    return null;
  }

  /// Dispose the scanner controller
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
