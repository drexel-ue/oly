import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/services/food_database_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/nutrition/smart_portion_drawer.dart';
import 'package:provider/provider.dart';

class LiveBarcodeScannerSheet extends StatefulWidget {
  const LiveBarcodeScannerSheet({
    super.key,
    this.defaultCategory = MealCategory.lunch,
  });
  final MealCategory defaultCategory;

  @override
  State<LiveBarcodeScannerSheet> createState() =>
      _LiveBarcodeScannerSheetState();
}

class _LiveBarcodeScannerSheetState extends State<LiveBarcodeScannerSheet>
    with SingleTickerProviderStateMixin {
  final FoodDatabaseService _foodService = FoodDatabaseService();
  late final MobileScannerController _scannerController;

  final List<FoodItem> _scannedSessionItems = <FoodItem>[];
  final Set<String> _scannedBarcodes = <String>{};

  bool _isTorchOn = false;
  bool _isLoading = false;
  String? _statusText;
  DateTime _lastScanTime = DateTime.now().subtract(const Duration(seconds: 5));

  late AnimationController _reticleAnimation;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _reticleAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _reticleAnimation.dispose();
    _scannerController.dispose();
    _foodService.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(String barcode) async {
    final String clean = barcode.trim();
    if (clean.isEmpty) {
      return;
    }

    // Debounce scans to avoid duplicate rapid triggers
    final DateTime now = DateTime.now();
    if (now.difference(_lastScanTime).inMilliseconds < 1200) {
      return;
    }
    _lastScanTime = now;

    if (_scannedBarcodes.contains(clean)) {
      // Find previously scanned item in session list
      final FoodItem existing = _scannedSessionItems.firstWhere(
        (FoodItem e) => e.id == clean || e.barcode == clean,
        orElse: () => FoodItem(
          id: clean,
          name: 'Scanned Item',
          servingSize: '100g',
          servingWeightGrams: 100.0,
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          source: 'open_food_facts',
        ),
      );
      HapticFeedback.selectionClick();
      _openPortionDrawer(existing);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = 'Querying Open Food Facts for $clean...';
    });

    HapticFeedback.mediumImpact();
    AppLogService.instance.info(
      'SCANNER',
      'Live camera detected barcode: $clean',
    );

    try {
      final StorageService storage = Provider.of<NutritionProvider>(
        context,
        listen: false,
      ).storage;
      final FoodItem? item = await _foodService.lookupBarcode(
        clean,
        storage: storage,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (item != null) {
            _scannedBarcodes.add(clean);
            _scannedSessionItems.insert(0, item);
            _statusText = null;
            HapticFeedback.heavyImpact();
            _openPortionDrawer(item);
          } else {
            _statusText = 'Product not found for barcode: $clean';
            HapticFeedback.vibrate();
          }
        });
      }
    } catch (e, stack) {
      AppLogService.instance.error(
        'SCANNER',
        'Failed live lookup for $clean: $e',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = 'Lookup error: $e';
        });
      }
    }
  }

  void _openPortionDrawer(FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SmartPortionDrawer(
        initialFoodItem: item,
        defaultCategory: widget.defaultCategory,
        onAdded: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Logged ${item.name} (${item.calories} kcal)'),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onScanAnother: () {
          // Modal auto closes and returns to live camera
        },
      ),
    );
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      AppLogService.instance.warning('SCANNER', 'Torch toggle error: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (e) {
      AppLogService.instance.warning('SCANNER', 'Camera switch error: $e');
    }
  }

  void _showManualBarcodeDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enter Barcode (UPC/EAN)',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Enter the product barcode numbers printed below the lines (e.g. 737628064502).',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.firaCode(
                color: AppTheme.primaryAmber,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 737628064502',
                hintStyle: GoogleFonts.firaCode(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryAmber),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final String code = controller.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                _processBarcode(code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'Lookup Product',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // 1. Live Camera Viewfinder
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (BarcodeCapture capture) {
                for (final Barcode barcode in capture.barcodes) {
                  final String? val = barcode.rawValue;
                  if (val != null && val.isNotEmpty) {
                    _processBarcode(val);
                    break;
                  }
                }
              },
              errorBuilder:
                  (BuildContext context, MobileScannerException error) {
                    return _buildCameraFallback(error.toString());
                  },
            ),
          ),

          // 2. Camera Dark Mask with transparent Reticle Cutout
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                cutoutWidth: 280,
                cutoutHeight: 180,
                borderRadius: 20,
              ),
            ),
          ),

          // 3. Animated Golden Targeting Reticle & Laser
          Center(
            child: AnimatedBuilder(
              animation: _reticleAnimation,
              builder: (BuildContext context, Widget? child) {
                final double scale = 1.0 + (_reticleAnimation.value * 0.03);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 280,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryAmber.withValues(
                          alpha: 0.85 + (_reticleAnimation.value * 0.15),
                        ),
                        width: 3.0,
                      ),
                    ),
                    child: Stack(
                      children: <Widget>[
                        // Animated Scanning Laser Line
                        Positioned(
                          top: 10 + (_reticleAnimation.value * 150),
                          left: 14,
                          right: 14,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppTheme.primaryAmber.withValues(
                                    alpha: 0.9,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Align Barcode Here',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary.withValues(
                                  alpha: 0.9,
                                ),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Top Header & Camera Controls Floating Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Close Button
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.65),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Title Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.qr_code_scanner,
                          color: AppTheme.primaryAmber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live Scanner',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Camera Switch & Torch Controls
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.65),
                        child: IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _switchCamera,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: _isTorchOn
                            ? AppTheme.primaryAmber
                            : Colors.black.withValues(alpha: 0.65),
                        child: IconButton(
                          icon: Icon(
                            _isTorchOn ? Icons.flash_on : Icons.flash_off,
                            color: _isTorchOn ? Colors.black : Colors.white,
                            size: 18,
                          ),
                          onPressed: _toggleTorch,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Bottom Overlay: Status Banner, Manual Entry, and Scanned Items Ribbon
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Status / Loading Indicator
                  if (_isLoading || _statusText != null)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_isLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryAmber,
                              ),
                            )
                          else
                            const Icon(
                              Icons.info_outline,
                              size: 14,
                              color: AppTheme.primaryAmber,
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _statusText ?? 'Scanning...',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Manual Barcode Entry Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _showManualBarcodeDialog,
                      icon: const Icon(
                        Icons.keyboard,
                        size: 16,
                        color: AppTheme.primaryAmber,
                      ),
                      label: Text(
                        'Enter Barcode Manually',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  // Scanned Session Carousel Ribbon
                  if (_scannedSessionItems.isNotEmpty) ...<Widget>[
                    Container(
                      height: 80,
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _scannedSessionItems.length,
                        itemBuilder: (BuildContext context, int index) {
                          final FoodItem item = _scannedSessionItems[index];
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 10),
                            child: Material(
                              color: AppTheme.surfaceCard.withValues(
                                alpha: 0.92,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _openPortionDrawer(item),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppTheme.darkBackground,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          image: item.imageUrl != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                    item.imageUrl!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: item.imageUrl == null
                                            ? const Icon(
                                                Icons.fastfood,
                                                color: AppTheme.primaryAmber,
                                                size: 20,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              item.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.calories} kcal • ${item.protein}g P',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: AppTheme.primaryAmber,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFallback(String errorMessage) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.videocam_off,
                size: 48,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Camera Viewfinder',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Point camera at barcode or enter code below.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for semi-transparent dark mask with a rounded rectangular camera window cutout
class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({
    required this.cutoutWidth,
    required this.cutoutHeight,
    required this.borderRadius,
  });
  final double cutoutWidth;
  final double cutoutHeight;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55);

    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final RRect cutoutRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: cutoutWidth,
        height: cutoutHeight,
      ),
      Radius.circular(borderRadius),
    );

    final Path cutoutPath = Path()..addRRect(cutoutRect);

    final Path combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(combinedPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.cutoutWidth != cutoutWidth ||
        oldDelegate.cutoutHeight != cutoutHeight ||
        oldDelegate.borderRadius != borderRadius;
  }
}
