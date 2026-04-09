import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/constants.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;
  final VoidCallback? onClose;

  const BarcodeScannerWidget({
    super.key,
    required this.onBarcodeScanned,
    this.onClose,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _hasScanned = true;
        widget.onBarcodeScanned(barcode.rawValue!);

        // Reset _hasScanned after a delay to allow re-scanning
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _hasScanned = false;
            });
          }
        });
        break;
      }
    }
  }

  void resetScanner() {
    setState(() {
      _hasScanned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),

        // Scanning overlay
        _buildScanOverlay(context),

        // Top controls
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              if (widget.onClose != null)
                _buildCircleButton(
                  Icons.close,
                  widget.onClose!,
                ),

              const Spacer(),

              // Flash toggle
              _buildCircleButton(
                Icons.flash_on,
                () => _controller.toggleTorch(),
              ),

              const SizedBox(width: 12),

              // Camera flip
              _buildCircleButton(
                Icons.cameraswitch_outlined,
                () => _controller.switchCamera(),
              ),
            ],
          ),
        ),

        // Bottom instruction
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _hasScanned
                    ? 'Processing...'
                    : 'Point camera at a barcode',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return CustomPaint(
      size: size,
      painter: _ScanOverlayPainter(
        scanAreaSize: scanAreaSize,
        borderColor: _hasScanned ? AppColors.success : AppColors.accent,
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Color borderColor;

  _ScanOverlayPainter({
    required this.scanAreaSize,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw background with hole
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw corner brackets
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const radius = 12.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLength)
        ..lineTo(scanRect.left, scanRect.top + radius)
        ..quadraticBezierTo(scanRect.left, scanRect.top, scanRect.left + radius, scanRect.top)
        ..lineTo(scanRect.left + cornerLength, scanRect.top),
      borderPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..lineTo(scanRect.right - radius, scanRect.top)
        ..quadraticBezierTo(scanRect.right, scanRect.top, scanRect.right, scanRect.top + radius)
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      borderPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.left, scanRect.bottom - radius)
        ..quadraticBezierTo(scanRect.left, scanRect.bottom, scanRect.left + radius, scanRect.bottom)
        ..lineTo(scanRect.left + cornerLength, scanRect.bottom),
      borderPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
        ..lineTo(scanRect.right - radius, scanRect.bottom)
        ..quadraticBezierTo(scanRect.right, scanRect.bottom, scanRect.right, scanRect.bottom - radius)
        ..lineTo(scanRect.right, scanRect.bottom - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}
