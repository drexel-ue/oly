import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/plate_calc.dart';
import 'package:oly/theme/app_theme.dart';

enum BarbellDisplayMode {
  /// Symmetrical left and right sleeves on a full barbell shaft with center knurl.
  fullBarbell,

  /// Close-up view of a single barbell sleeve with collar stop.
  singleSleeve,
}

/// An ultra-premium, dynamic Olympic Barbell visualizer featuring:
/// 1. Staggered physical slide-on entry animation (plates slide onto sleeve into collar).
/// 2. Live spring morphing animation when target weight changes.
/// 3. Authentic IWF bumper plate colors, metallic specular lighting, and collar clamps.
class AnimatedBarbellLoader extends StatefulWidget {
  const new({
    required this.targetWeight,
    super.key,
    this.barWeight,
    this.collarWeight,
    this.isLbs = false,
    this.displayMode = BarbellDisplayMode.fullBarbell,
    this.height = 110.0,
    this.showBreakdownChips = false,
    this.animateOnEntry = true,
    this.animateOnChange = true,
    this.onTap,
  });

  final double targetWeight;
  final double? barWeight;
  final double? collarWeight;
  final bool isLbs;
  final BarbellDisplayMode displayMode;
  final double height;
  final bool showBreakdownChips;
  final bool animateOnEntry;
  final bool animateOnChange;
  final VoidCallback? onTap;

  @override
  State<AnimatedBarbellLoader> createState() => _AnimatedBarbellLoaderState();
}

class _AnimatedBarbellLoaderState extends State<AnimatedBarbellLoader>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  late AnimationController _adjustController;
  late Animation<double> _adjustAnimation;

  late PlateCalcResult _currentResult;
  List<PlateSpec> _previousPlates = <PlateSpec>[];
  bool _isWeightDecreased = false;

  @override
  void initState() {
    super.initState();

    _currentResult = PlateCalculator.calculate(
      targetWeight: widget.targetWeight,
      barWeight: widget.barWeight,
      collarWeight: widget.collarWeight,
      isLbs: widget.isLbs,
    );
    _previousPlates = List<PlateSpec>.from(_currentResult.platesPerSide);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    _adjustController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _adjustAnimation = CurvedAnimation(
      parent: _adjustController,
      curve: Curves.easeOutBack,
    );

    if (widget.animateOnEntry) {
      _entryController.forward();
    } else {
      _entryController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedBarbellLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.targetWeight != widget.targetWeight ||
        oldWidget.barWeight != widget.barWeight ||
        oldWidget.collarWeight != widget.collarWeight ||
        oldWidget.isLbs != widget.isLbs) {
      final PlateCalcResult newResult = PlateCalculator.calculate(
        targetWeight: widget.targetWeight,
        barWeight: widget.barWeight,
        collarWeight: widget.collarWeight,
        isLbs: widget.isLbs,
      );

      _isWeightDecreased = widget.targetWeight < oldWidget.targetWeight;
      _previousPlates = List<PlateSpec>.from(_currentResult.platesPerSide);
      _currentResult = newResult;

      if (widget.animateOnChange) {
        _entryController.forward(from: 0);
      } else {
        _entryController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _adjustController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _entryAnimation,
              _adjustAnimation,
            ]),
            builder: (context, _) {
              return CustomPaint(
                painter: _BarbellPainter(
                  result: _currentResult,
                  previousPlates: _previousPlates,
                  displayMode: widget.displayMode,
                  entryProgress: _entryAnimation.value,
                  adjustProgress: _adjustAnimation.value,
                  isWeightDecreased: _isWeightDecreased,
                  isLbs: widget.isLbs,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
        if (widget.showBreakdownChips &&
            _currentResult.platesPerSide.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          _buildPlateBreakdownChips(),
        ],
      ],
    );

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else if (widget.animateOnChange) {
          _entryController.forward(from: 0);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  Widget _buildPlateBreakdownChips() {
    // Group plates by weight
    final Map<double, int> counts = <double, int>{};
    final Map<double, PlateSpec> plateMap = <double, PlateSpec>{};

    for (final PlateSpec plate in _currentResult.platesPerSide) {
      counts[plate.weight] = (counts[plate.weight] ?? 0) + 1;
      plateMap[plate.weight] = plate;
    }

    final String unit = widget.isLbs ? 'lbs' : 'kg';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              '${_currentResult.barWeight.toInt()}$unit bar',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ...counts.entries.map((entry) {
            final PlateSpec plate = plateMap[entry.key]!;
            final int count = entry.value;
            final String weightStr = entry.key % 1 == 0
                ? entry.key.toInt().toString()
                : entry.key.toString();

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: plate.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: plate.color.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: plate.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    count > 1
                        ? '$count×$weightStr$unit'
                        : '$weightStr$unit',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_currentResult.collarWeight > 0) ...<Widget>[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                '+collars',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarbellPainter extends CustomPainter {
  new({
    required this.result,
    required this.previousPlates,
    required this.displayMode,
    required this.entryProgress,
    required this.adjustProgress,
    required this.isWeightDecreased,
    required this.isLbs,
  });

  final PlateCalcResult result;
  final List<PlateSpec> previousPlates;
  final BarbellDisplayMode displayMode;
  final double entryProgress;
  final double adjustProgress;
  final bool isWeightDecreased;
  final bool isLbs;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;

    if (displayMode == BarbellDisplayMode.fullBarbell) {
      _paintFullBarbell(canvas, size, centerY);
    } else {
      _paintSingleSleeve(canvas, size, centerY);
    }
  }

  void _paintFullBarbell(Canvas canvas, Size size, double centerY) {
    final double centerX = size.width / 2;
    final double barLength = size.width - 24;
    const double barLeft = 12;
    final double barRight = size.width - 12;
    const double barThickness = 8;

    // 1. Draw central knurled barbell shaft
    final Paint shaftPaint = Paint()
      ..shader = AppTheme.barbellSteelGradient.createShader(
        Rect.fromLTWH(barLeft, centerY - barThickness / 2, barLength, barThickness),
      );

    final RRect shaftRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, centerY - barThickness / 2, barLength, barThickness),
      const Radius.circular(3),
    );
    canvas.drawRRect(shaftRRect, shaftPaint);

    // Center knurl & grip marks
    final Paint knurlPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Center knurl mark
    canvas.drawLine(
      Offset(centerX, centerY - barThickness / 2),
      Offset(centerX, centerY + barThickness / 2),
      knurlPaint,
    );

    // IWF grip marks (left and right)
    final double gripDistance = size.width * 0.18;
    canvas.drawLine(
      Offset(centerX - gripDistance, centerY - barThickness / 2),
      Offset(centerX - gripDistance, centerY + barThickness / 2),
      knurlPaint,
    );
    canvas.drawLine(
      Offset(centerX + gripDistance, centerY - barThickness / 2),
      Offset(centerX + gripDistance, centerY + barThickness / 2),
      knurlPaint,
    );

    // Collar stops
    final double collarStopOffset = size.width * 0.24;
    final double leftCollarStopX = centerX - collarStopOffset;
    final double rightCollarStopX = centerX + collarStopOffset;
    const double collarStopWidth = 6;
    const double collarStopHeight = 28;

    final Paint collarPaint = Paint()
      ..shader = AppTheme.collarChromeGradient.createShader(
        Rect.fromLTWH(
          leftCollarStopX - collarStopWidth / 2,
          centerY - collarStopHeight / 2,
          collarStopWidth,
          collarStopHeight,
        ),
      );

    // Left collar stop
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          leftCollarStopX - collarStopWidth,
          centerY - collarStopHeight / 2,
          collarStopWidth,
          collarStopHeight,
        ),
        const Radius.circular(2),
      ),
      collarPaint,
    );

    // Right collar stop
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rightCollarStopX,
          centerY - collarStopHeight / 2,
          collarStopWidth,
          collarStopHeight,
        ),
        const Radius.circular(2),
      ),
      collarPaint,
    );

    // 2. Draw plates on left and right sleeves
    final List<PlateSpec> plates = result.platesPerSide;
    final int plateCount = plates.length;

    // Draw Right Sleeve Plates (left-to-right from collar outward)
    double currentRightX = rightCollarStopX + collarStopWidth + 2;
    for (int i = 0; i < plateCount; i++) {
      final PlateSpec plate = plates[i];
      final double plateWidth = plate.isFractional ? 7.0 : 11.0;
      final double plateHeight = (size.height - 18) * plate.heightFactor;

      // Innermost plate arrives first, outer plates slide from right edge inward
      final double plateDelay = i * 0.08;
      final double rawEntry = math.max(
        0,
        math.min(1, (entryProgress - plateDelay) / (1.0 - plateDelay + 0.001)),
      );
      final double plateProgress = Curves.easeOutCubic.transform(rawEntry);

      final double slideOffset = (1.0 - plateProgress) * (barRight - currentRightX);
      final double animatedX = currentRightX + slideOffset;

      _paintPlate(
        canvas: canvas,
        x: animatedX,
        centerY: centerY,
        width: plateWidth,
        height: plateHeight,
        plate: plate,
        opacity: plateProgress.clamp(0, 1),
      );

      currentRightX += plateWidth + 2;
    }

    // Draw Left Sleeve Plates (mirrored right-to-left from collar outward)
    double currentLeftX = leftCollarStopX - collarStopWidth - 2;
    for (int i = 0; i < plateCount; i++) {
      final PlateSpec plate = plates[i];
      final double plateWidth = plate.isFractional ? 7.0 : 11.0;
      final double plateHeight = (size.height - 18) * plate.heightFactor;

      final double plateDelay = i * 0.08;
      final double rawEntry = math.max(
        0,
        math.min(1, (entryProgress - plateDelay) / (1.0 - plateDelay + 0.001)),
      );
      final double plateProgress = Curves.easeOutCubic.transform(rawEntry);

      final double slideOffset = (1.0 - plateProgress) * (barLeft - currentLeftX);
      final double animatedX = currentLeftX - plateWidth + slideOffset;

      _paintPlate(
        canvas: canvas,
        x: animatedX,
        centerY: centerY,
        width: plateWidth,
        height: plateHeight,
        plate: plate,
        opacity: plateProgress.clamp(0, 1),
      );

      currentLeftX -= plateWidth + 2;
    }

    // Draw outer collar clamps if collar weight is specified
    if (result.collarWeight > 0 && plates.isNotEmpty) {
      const double collarWidth = 5;
      const double collarHeight = 22;
      final double collarDelay = plateCount * 0.08;
      final double rawCollar = math.max(
        0,
        math.min(1, (entryProgress - collarDelay) / (1.0 - collarDelay + 0.001)),
      );
      final double collarProgress = Curves.easeOutCubic.transform(rawCollar);

      final Paint clampPaint = Paint()
        ..color = const Color(0xFFE2E8F0).withValues(alpha: collarProgress)
        ..style = PaintingStyle.fill;

      // Right collar clamp
      final double rightCollarRestX = currentRightX + 1;
      final double rightCollarSlide = (1.0 - collarProgress) * (barRight - rightCollarRestX);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rightCollarRestX + rightCollarSlide,
            centerY - collarHeight / 2,
            collarWidth,
            collarHeight,
          ),
          const Radius.circular(1.5),
        ),
        clampPaint,
      );

      // Left collar clamp
      final double leftCollarRestX = currentLeftX - collarWidth - 1;
      final double leftCollarSlide = (1.0 - collarProgress) * (barLeft - leftCollarRestX);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            leftCollarRestX + leftCollarSlide,
            centerY - collarHeight / 2,
            collarWidth,
            collarHeight,
          ),
          const Radius.circular(1.5),
        ),
        clampPaint,
      );
    }
  }

  void _paintSingleSleeve(Canvas canvas, Size size, double centerY) {
    const double barLeft = 16;
    final double barRight = size.width - 16;
    const double barThickness = 12;

    // Shaft
    final Paint shaftPaint = Paint()
      ..shader = AppTheme.barbellSteelGradient.createShader(
        Rect.fromLTWH(barLeft, centerY - barThickness / 2, barRight - barLeft, barThickness),
      );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, centerY - barThickness / 2, barRight - barLeft, barThickness),
        const Radius.circular(4),
      ),
      shaftPaint,
    );

    // Collar Stop at left
    const double collarStopX = 42;
    const double collarStopWidth = 10;
    const double collarStopHeight = 44;

    final Paint collarPaint = Paint()
      ..shader = AppTheme.collarChromeGradient.createShader(
        Rect.fromLTWH(collarStopX, centerY - collarStopHeight / 2, collarStopWidth, collarStopHeight),
      );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(collarStopX, centerY - collarStopHeight / 2, collarStopWidth, collarStopHeight),
        const Radius.circular(3),
      ),
      collarPaint,
    );

    // Plates stacked from collarStopX + collarStopWidth to right
    final List<PlateSpec> plates = result.platesPerSide;
    final int plateCount = plates.length;

    double currentX = collarStopX + collarStopWidth + 4;
    for (int i = 0; i < plateCount; i++) {
      final PlateSpec plate = plates[i];
      final double plateWidth = plate.isFractional ? 13.0 : 19.0;
      final double plateHeight = (size.height - 16) * plate.heightFactor;

      final double plateDelay = i * 0.08;
      final double rawEntry = math.max(
        0,
        math.min(1, (entryProgress - plateDelay) / (1.0 - plateDelay + 0.001)),
      );
      final double plateProgress = Curves.easeOutCubic.transform(rawEntry);

      final double slideOffset = (1.0 - plateProgress) * (barRight - currentX);
      final double animatedX = currentX + slideOffset;

      _paintPlate(
        canvas: canvas,
        x: animatedX,
        centerY: centerY,
        width: plateWidth,
        height: plateHeight,
        plate: plate,
        opacity: plateProgress.clamp(0, 1),
        showLabel: true,
      );

      currentX += plateWidth + 3;
    }

    // Collar clamp
    if (result.collarWeight > 0 && plates.isNotEmpty) {
      const double collarWidth = 10;
      const double collarHeight = 32;
      final double collarDelay = plateCount * 0.08;
      final double rawCollar = math.max(
        0,
        math.min(1, (entryProgress - collarDelay) / (1.0 - collarDelay + 0.001)),
      );
      final double collarProgress = Curves.easeOutCubic.transform(rawCollar);
      final double collarRestX = currentX + 2;
      final double collarSlide = (1.0 - collarProgress) * (barRight - collarRestX);

      final Paint clampPaint = Paint()
        ..color = const Color(0xFFE2E8F0).withValues(alpha: collarProgress)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            collarRestX + collarSlide,
            centerY - collarHeight / 2,
            collarWidth,
            collarHeight,
          ),
          const Radius.circular(2),
        ),
        clampPaint,
      );
    }
  }

  void _paintPlate({
    required Canvas canvas,
    required double x,
    required double centerY,
    required double width,
    required double height,
    required PlateSpec plate,
    required double opacity,
    bool showLabel = false,
  }) {
    if (opacity <= 0.01) {
      return;
    }

    final Rect plateRect = Rect.fromLTWH(
      x,
      centerY - height / 2,
      width,
      height,
    );

    // 1. Plate Drop Shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        plateRect.shift(const Offset(1, 2)),
        const Radius.circular(3),
      ),
      shadowPaint,
    );

    // 2. Main Plate Body with Cylindrical Specular Gradient
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          plate.color.withValues(alpha: opacity),
          Color.lerp(plate.color, Colors.white, 0.28)!.withValues(alpha: opacity),
          plate.color.withValues(alpha: opacity),
          Color.lerp(plate.color, Colors.black, 0.35)!.withValues(alpha: opacity),
        ],
        stops: const <double>[0, 0.28, 0.65, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(plateRect);

    final RRect rrect = RRect.fromRectAndRadius(plateRect, const Radius.circular(3));
    canvas.drawRRect(rrect, bodyPaint);

    // 3. Rim highlight (top 1px)
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(x + 1, centerY - height / 2 + 0.5),
      Offset(x + width - 1, centerY - height / 2 + 0.5),
      highlightPaint,
    );

    // 4. Center Stainless Steel Hub Ring
    const double hubHeight = 10;
    final Rect hubRect = Rect.fromLTWH(
      x,
      centerY - hubHeight / 2,
      width,
      hubHeight,
    );
    final Paint hubPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.85 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(hubRect, hubPaint);

    // 5. Plate Label if space permits or singleSleeve mode
    if (showLabel && width >= 12 && height >= 38) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: plate.label,
          style: GoogleFonts.outfit(
            fontSize: width > 16 ? 10.5 : 9.0,
            fontWeight: FontWeight.bold,
            color: plate.textColor.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x + width / 2, centerY - height * 0.26);
      canvas.rotate(-math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BarbellPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.entryProgress != entryProgress ||
        oldDelegate.adjustProgress != adjustProgress ||
        oldDelegate.displayMode != displayMode;
  }
}
