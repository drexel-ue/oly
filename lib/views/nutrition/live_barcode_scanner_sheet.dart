import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_entry.dart';
import '../../providers/nutrition_provider.dart';
import '../../services/food_database_service.dart';
import '../../services/renpho_ocr_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutrition/smart_portion_drawer.dart';

class LiveBarcodeScannerSheet extends StatefulWidget {
  final MealCategory defaultCategory;

  const LiveBarcodeScannerSheet({
    super.key,
    this.defaultCategory = MealCategory.lunch,
  });

  @override
  State<LiveBarcodeScannerSheet> createState() => _LiveBarcodeScannerSheetState();
}

class _LiveBarcodeScannerSheetState extends State<LiveBarcodeScannerSheet> with SingleTickerProviderStateMixin {
  final FoodDatabaseService _foodService = FoodDatabaseService();
  final RenphoOcrService _ocrService = RenphoOcrService();
  final ImagePicker _picker = ImagePicker();

  final List<FoodItem> _scannedSessionItems = [];
  final Set<String> _scannedBarcodes = {};
  FoodItem? _selectedItemForDrawer;

  bool _isTorchOn = false;
  bool _isLoading = false;
  String? _statusText;

  late AnimationController _reticleAnimation;

  @override
  void initState() {
    super.initState();
    _reticleAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _reticleAnimation.dispose();
    _foodService.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(String barcode) async {
    final clean = barcode.trim();
    if (clean.isEmpty || _scannedBarcodes.contains(clean)) return;

    setState(() {
      _isLoading = true;
      _statusText = 'Querying Open Food Facts for $clean...';
    });

    HapticFeedback.mediumImpact();
    final storage = Provider.of<NutritionProvider>(context, listen: false).storage;
    final item = await _foodService.lookupBarcode(clean, storage: storage);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (item != null) {
          _scannedBarcodes.add(clean);
          _scannedSessionItems.insert(0, item);
          _selectedItemForDrawer = item;
          _statusText = null;
        } else {
          _statusText = 'Product not found for barcode: $clean';
        }
      });
    }
  }

  Future<void> _scanFromCameraImage() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo == null) return;

      setState(() {
        _isLoading = true;
        _statusText = 'Reading barcode from camera...';
      });

      // OCR & Barcode recognition from photo
      final rawText = await _ocrService.extractRawTextFromImage(photo.path);

      // Search for numeric barcode pattern (8, 12, 13, or 14 digits)
      final barcodeRegex = RegExp(r'\b\d{8,14}\b');
      final match = barcodeRegex.firstMatch(rawText);

      if (match != null) {
        final code = match.group(0)!;
        await _processBarcode(code);
      } else {
        setState(() {
          _isLoading = false;
          _statusText = 'No barcode detected in image. Try manual entry.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = 'Camera error: $e';
      });
    }
  }

  void _showManualBarcodeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text('Enter Barcode (UPC/EAN)', style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the product barcode number printed below the lines (e.g. 737628064502).',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.firaCode(color: AppTheme.primaryAmber),
              decoration: InputDecoration(
                hintText: 'e.g. 737628064502',
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              Navigator.pop(ctx);
              _processBarcode(code);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAmber, foregroundColor: Colors.black),
            child: const Text('Lookup Product'),
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
        children: [
          // Simulated Camera Viewfinder with dark gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.grey[900]!,
                  Colors.black,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Targeting Reticle
                  AnimatedBuilder(
                    animation: _reticleAnimation,
                    builder: (context, child) {
                      final scale = 1.0 + (_reticleAnimation.value * 0.05);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 260,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryAmber.withOpacity(0.8 + (_reticleAnimation.value * 0.2)),
                              width: 2.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Scanning laser line
                              Positioned(
                                top: 10 + (_reticleAnimation.value * 150),
                                left: 16,
                                right: 16,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAmber,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryAmber.withOpacity(0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  'Align Barcode Here',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _scanFromCameraImage,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Capture Barcode Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Navigation Controls & Torch Toggle
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Row(
                    children: [
                      IconButton.filled(
                        icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: AppTheme.primaryAmber),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        tooltip: 'Toggle Flashlight',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isTorchOn = !_isTorchOn);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.keyboard, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        tooltip: 'Enter Barcode Number',
                        onPressed: _showManualBarcodeDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Status & Loading Indicator
          if (_isLoading || _statusText != null)
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryAmber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryAmber),
                      )
                    else
                      const Icon(Icons.info_outline, size: 18, color: AppTheme.primaryAmber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusText ?? 'Scanning...',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Continuous Scanned Ribbon / Active Drawer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Continuous Scanned Ribbon Tray
                if (_scannedSessionItems.isNotEmpty)
                  Container(
                    height: 90,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      border: Border(top: BorderSide(color: AppTheme.borderColor)),
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _scannedSessionItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, idx) {
                        final item = _scannedSessionItems[idx];
                        final isSelected = _selectedItemForDrawer?.id == item.id;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedItemForDrawer = item);
                          },
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryAmber.withOpacity(0.2) : AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppTheme.primaryAmber : AppTheme.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.calories} kcal • ${item.protein}g P',
                                  style: GoogleFonts.firaCode(fontSize: 11, color: AppTheme.primaryAmber),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Selected Item Smart Portion Drawer
                if (_selectedItemForDrawer != null)
                  SmartPortionDrawer(
                    key: Key(_selectedItemForDrawer!.id),
                    initialFoodItem: _selectedItemForDrawer!,
                    defaultCategory: widget.defaultCategory,
                    onScanAnother: () {
                      setState(() => _selectedItemForDrawer = null);
                    },
                    onAdded: () {
                      setState(() => _selectedItemForDrawer = null);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
