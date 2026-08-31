import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';

/// Modal dialog / full-view QR scanner with outdoor tactical styling
class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({super.key});

  /// Opens the QR scanner dialog and returns the scanned raw string or null if closed
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const QrScannerDialog(),
    );
  }

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  bool _isDispatched = false;
  late AnimationController _animController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isDispatched) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        _isDispatched = true;
        _controller.stop();
        Navigator.of(context).pop(raw.trim());
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isDesktop = screenSize.width > 600;
    final dialogWidth = isDesktop ? 440.0 : screenSize.width * 0.92;
    final dialogHeight = isDesktop ? 560.0 : screenSize.height * 0.75;

    return Dialog(
      backgroundColor: OutdoorTheme.darkBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.5),
      ),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Live Camera Stream
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) {
                  return Container(
                    color: OutdoorTheme.surfaceCard,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam_off_outlined,
                          size: 56,
                          color: OutdoorTheme.alertRed,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Камера недоступна',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: OutdoorTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Предоставьте разрешение на использование камеры в настройках устройства или введите ключ синхронизации вручную.\n(${error.errorCode.name})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: OutdoorTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(null),
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Ввести ключ вручную'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 2. Viewfinder Mask & Target Overlay
              CustomPaint(
                painter: _ViewfinderOverlayPainter(laserFraction: _laserAnimation),
              ),

              // 3. Header Controls (Close, Flash, Switch Camera)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: OutdoorTheme.borderSubtle),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: OutdoorTheme.textPrimary),
                        tooltip: 'Закрыть',
                        onPressed: () => Navigator.of(context).pop(null),
                      ),
                    ),

                    // Controls (Torch + Switch Camera)
                    Row(
                      children: [
                        // Flash toggle
                        ValueListenableBuilder<MobileScannerState>(
                          valueListenable: _controller,
                          builder: (context, state, child) {
                            final isOn = state.torchState == TorchState.on;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isOn ? OutdoorTheme.signalOrange : Colors.black54,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isOn ? OutdoorTheme.signalOrange : OutdoorTheme.borderSubtle,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isOn ? Icons.flash_on : Icons.flash_off,
                                  color: isOn ? Colors.black : OutdoorTheme.textPrimary,
                                ),
                                tooltip: 'Фонарик',
                                onPressed: () => _controller.toggleTorch(),
                              ),
                            );
                          },
                        ),

                        // Switch Camera
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                            border: Border.all(color: OutdoorTheme.borderSubtle),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.cameraswitch, color: OutdoorTheme.textPrimary),
                            tooltip: 'Сменить камеру',
                            onPressed: () => _controller.switchCamera(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 4. Bottom Hint Panel
              Positioned(
                bottom: 16,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.surfaceCard.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OutdoorTheme.borderSubtle),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: OutdoorTheme.signalOrange, size: 20),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Наведите камеру на QR-код похода',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: OutdoorTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that creates dark vignette and glowing outdoor tactical reticle
class _ViewfinderOverlayPainter extends CustomPainter {
  final Animation<double> laserFraction;

  _ViewfinderOverlayPainter({required this.laserFraction}) : super(repaint: laserFraction);

  @override
  void paint(Canvas canvas, Size size) {
    const boxSize = 240.0;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2;
    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);

    // Semi-transparent blackout outside the scanner window
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bgPaint);

    // Corner target brackets
    final cornerPaint = Paint()
      ..color = OutdoorTheme.signalOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;

    // Top-Left
    canvas.drawLine(Offset(rect.left, rect.top + cornerLength), Offset(rect.left, rect.top + 8), cornerPaint);
    canvas.drawLine(Offset(rect.left + 8, rect.top), Offset(rect.left + cornerLength, rect.top), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(rect.right, rect.top + cornerLength), Offset(rect.right, rect.top + 8), cornerPaint);
    canvas.drawLine(Offset(rect.right - 8, rect.top), Offset(rect.right - cornerLength, rect.top), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(rect.left, rect.bottom - cornerLength), Offset(rect.left, rect.bottom - 8), cornerPaint);
    canvas.drawLine(Offset(rect.left + 8, rect.bottom), Offset(rect.left + cornerLength, rect.bottom), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(rect.right, rect.bottom - cornerLength), Offset(rect.right, rect.bottom - 8), cornerPaint);
    canvas.drawLine(Offset(rect.right - 8, rect.bottom), Offset(rect.right - cornerLength, rect.bottom), cornerPaint);

    // Animated Tactical Laser Scanner Line
    final laserY = rect.top + (rect.height * laserFraction.value);
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          OutdoorTheme.signalOrange.withValues(alpha: 0.0),
          OutdoorTheme.signalOrange,
          OutdoorTheme.signalOrange.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(rect.left, laserY, rect.width, 2))
      ..strokeWidth = 2.5;

    canvas.drawLine(Offset(rect.left + 10, laserY), Offset(rect.right - 10, laserY), laserPaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderOverlayPainter oldDelegate) => true;
}
