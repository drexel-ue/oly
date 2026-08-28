import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/theme/app_theme.dart';

class InteractiveBodyMap extends StatefulWidget {
  const InteractiveBodyMap({
    required this.injuries,
    super.key,
    this.selectedRegion,
    this.onRegionSelected,
    this.isCompact = false,
    this.initialIsFront = true,
    this.customPainMap,
  });

  final List<InjuryRecord> injuries;
  final InjuryRegion? selectedRegion;
  final ValueChanged<InjuryRegion>? onRegionSelected;
  final bool isCompact;
  final bool initialIsFront;
  final Map<InjuryRegion, int>? customPainMap;

  @override
  State<InteractiveBodyMap> createState() => _InteractiveBodyMapState();
}

class _InteractiveBodyMapState extends State<InteractiveBodyMap> {
  late bool _isFront;

  @override
  void initState() {
    super.initState();
    _isFront = widget.initialIsFront;
  }

  @override
  Widget build(BuildContext context) {
    final double height = widget.isCompact ? 240 : 380;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Controls / View Switcher Header
        if (!widget.isCompact)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(
                        _isFront ? 'ANTERIOR (FRONT)' : 'POSTERIOR (BACK)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: <Widget>[
                      _buildViewButton(
                        label: 'Front',
                        isSelected: _isFront,
                        onTap: () => setState(() => _isFront = true),
                      ),
                      _buildViewButton(
                        label: 'Back',
                        isSelected: !_isFront,
                        onTap: () => setState(() => _isFront = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Body Canvas Area
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderColor.withValues(alpha: 0.7),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return GestureDetector(
                  onTapUp: (TapUpDetails details) => _handleTap(
                    details.localPosition,
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: BodyMapPainter(
                      isFront: _isFront,
                      injuries: widget.injuries,
                      selectedRegion: widget.selectedRegion,
                      customPainMap: widget.customPainMap,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Legend / Quick Status
        if (!widget.isCompact) ...<Widget>[
          const SizedBox(height: 10),
          _buildLegend(),
        ],
      ],
    );
  }

  Widget _buildViewButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAmber : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildLegendItem(const Color(0xFF30D158), 'Clear (0)'),
        const SizedBox(width: 12),
        _buildLegendItem(AppTheme.primaryAmber, 'Mild (1-3)'),
        const SizedBox(width: 12),
        _buildLegendItem(const Color(0xFFFF9F0A), 'Mod (4-6)'),
        const SizedBox(width: 12),
        _buildLegendItem(Colors.redAccent, 'Severe (7+)'),
        const SizedBox(width: 12),
        _buildLegendItem(const Color(0xFFBF5AF2), 'Chronic (6w+)'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _handleTap(Offset tapPos, double width, double height) {
    final double normX = tapPos.dx / width;
    final double normY = tapPos.dy / height;

    final InjuryRegion? hitRegion = _hitTest(normX, normY, _isFront);
    if (hitRegion != null && widget.onRegionSelected != null) {
      widget.onRegionSelected!(hitRegion);
    }
  }

  static InjuryRegion? _hitTest(double nx, double ny, bool isFront) {
    // Normal coordinate bounding boxes (nx in [0, 1], ny in [0, 1], center is ~0.5)
    // Head & Neck
    if (ny >= 0.05 && ny <= 0.17 && nx >= 0.42 && nx <= 0.58) {
      return InjuryRegion.neck;
    }

    // Shoulders
    if (ny >= 0.17 && ny <= 0.28) {
      if (nx >= 0.25 && nx <= 0.40) {
        return isFront ? InjuryRegion.rightShoulder : InjuryRegion.leftShoulder;
      }
      if (nx >= 0.60 && nx <= 0.75) {
        return isFront ? InjuryRegion.leftShoulder : InjuryRegion.rightShoulder;
      }
    }

    // Elbows & Forearms
    if (ny >= 0.28 && ny <= 0.40) {
      if (nx >= 0.20 && nx <= 0.35) {
        return isFront ? InjuryRegion.rightElbow : InjuryRegion.leftElbow;
      }
      if (nx >= 0.65 && nx <= 0.80) {
        return isFront ? InjuryRegion.leftElbow : InjuryRegion.rightElbow;
      }
    }

    // Wrists & Hands
    if (ny >= 0.40 && ny <= 0.54) {
      if (nx >= 0.15 && nx <= 0.32) {
        return isFront ? InjuryRegion.rightWrist : InjuryRegion.leftWrist;
      }
      if (nx >= 0.68 && nx <= 0.85) {
        return isFront ? InjuryRegion.leftWrist : InjuryRegion.rightWrist;
      }
    }

    // Torso (Front vs Back)
    if (ny >= 0.18 && ny <= 0.32 && nx >= 0.38 && nx <= 0.62) {
      return isFront ? InjuryRegion.chestPecs : InjuryRegion.thoracicSpine;
    }

    if (ny >= 0.32 && ny <= 0.44 && nx >= 0.38 && nx <= 0.62) {
      return isFront ? InjuryRegion.coreAbs : InjuryRegion.lumbarSpine;
    }

    // Hips / Glutes
    if (ny >= 0.44 && ny <= 0.54) {
      if (nx >= 0.35 && nx <= 0.50) {
        return isFront ? InjuryRegion.rightHipGlute : InjuryRegion.leftHipGlute;
      }
      if (nx >= 0.50 && nx <= 0.65) {
        return isFront ? InjuryRegion.leftHipGlute : InjuryRegion.rightHipGlute;
      }
    }

    // Thighs (Quads vs Hamstrings)
    if (ny >= 0.54 && ny <= 0.68) {
      if (nx >= 0.33 && nx <= 0.49) {
        return isFront ? InjuryRegion.rightQuad : InjuryRegion.leftHamstring;
      }
      if (nx >= 0.51 && nx <= 0.67) {
        return isFront ? InjuryRegion.leftQuad : InjuryRegion.rightHamstring;
      }
    }

    // Knees
    if (ny >= 0.68 && ny <= 0.77) {
      if (nx >= 0.34 && nx <= 0.49) {
        return isFront ? InjuryRegion.rightKnee : InjuryRegion.leftKnee;
      }
      if (nx >= 0.51 && nx <= 0.66) {
        return isFront ? InjuryRegion.leftKnee : InjuryRegion.rightKnee;
      }
    }

    // Calves & Ankles
    if (ny >= 0.77 && ny <= 0.94) {
      if (nx >= 0.33 && nx <= 0.49) {
        return isFront ? InjuryRegion.rightCalfAnkle : InjuryRegion.leftCalfAnkle;
      }
      if (nx >= 0.51 && nx <= 0.67) {
        return isFront ? InjuryRegion.leftCalfAnkle : InjuryRegion.rightCalfAnkle;
      }
    }

    return null;
  }
}

class BodyMapPainter extends CustomPainter {
  BodyMapPainter({
    required this.isFront,
    required this.injuries,
    this.selectedRegion,
    this.customPainMap,
  });

  final bool isFront;
  final List<InjuryRecord> injuries;
  final InjuryRegion? selectedRegion;
  final Map<InjuryRegion, int>? customPainMap;

  /// Renders the vector anatomical body map into a PNG byte buffer
  static Future<Uint8List> renderBodyMapPng({
    required bool isFront,
    required List<InjuryRecord> injuries,
    double width = 280,
    double height = 360,
    Map<InjuryRegion, int>? customPainMap,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Dark card background
    final Paint bgPaint = Paint()..color = const Color(0xFF18181B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(10),
      ),
      bgPaint,
    );

    final BodyMapPainter painter = BodyMapPainter(
      isFront: isFront,
      injuries: injuries,
      customPainMap: customPainMap,
    );
    painter.paint(canvas, Size(width, height));

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width.toInt(), height.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double scale = size.height / 400.0;

    // Draw subtle grid / ambient rings
    _drawBackgroundAesthetics(canvas, size, cx);

    // Anatomical Segments
    // 1. Head & Neck
    _drawHeadNeck(canvas, cx, scale);

    // 2. Torso (Chest/Abs or Thoracic/Lumbar)
    _drawTorso(canvas, cx, scale);

    // 3. Arms (Shoulders, Biceps/Elbows, Wrists)
    _drawUpperLimbs(canvas, cx, scale);

    // 4. Lower Limbs (Hips/Glutes, Thighs, Knees, Calves/Feet)
    _drawLowerLimbs(canvas, cx, scale);
  }

  void _drawBackgroundAesthetics(Canvas canvas, Size size, double cx) {
    final Paint linePaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Center vertical axis
    canvas.drawLine(
      Offset(cx, 10),
      Offset(cx, size.height - 10),
      linePaint,
    );

    // Subtle horizontal section guides
    final List<double> yGuides = <double>[
      size.height * 0.17,
      size.height * 0.44,
      size.height * 0.68,
      size.height * 0.77,
    ];

    for (final double y in yGuides) {
      canvas.drawLine(
        Offset(cx - 60, y),
        Offset(cx + 60, y),
        linePaint..color = AppTheme.borderColor.withValues(alpha: 0.15),
      );
    }
  }

  Color _getRegionColor(InjuryRegion region) {
    if (customPainMap != null && customPainMap!.containsKey(region)) {
      final int pain = customPainMap![region] ?? 0;
      return _painToColor(pain, isChronic: false);
    }

    try {
      final InjuryRecord injury =
          injuries.firstWhere((InjuryRecord i) => i.region == region && i.isActive);
      return _painToColor(
        injury.painScale,
        isChronic: injury.stage == InjuryStage.chronic,
      );
    } catch (_) {
      return AppTheme.surfaceElevated;
    }
  }

  bool _isRegionChronic(InjuryRegion region) {
    try {
      final InjuryRecord injury =
          injuries.firstWhere((InjuryRecord i) => i.region == region && i.isActive);
      return injury.stage == InjuryStage.chronic;
    } catch (_) {
      return false;
    }
  }

  Color _painToColor(int pain, {required bool isChronic}) {
    if (pain <= 0) {
      return AppTheme.surfaceElevated;
    }
    if (isChronic) {
      return const Color(0xFFBF5AF2); // Neon Purple for Chronic
    }
    if (pain <= 3) {
      return AppTheme.primaryAmber; // Neon Amber
    }
    if (pain <= 6) {
      return const Color(0xFFFF9F0A); // Neon Orange
    }
    return const Color(0xFFFF3B30); // Neon Red
  }

  Paint _createPaint(InjuryRegion region) {
    final Color color = _getRegionColor(region);
    final bool hasActiveStrain = color != AppTheme.surfaceElevated;

    final Paint paint = Paint()
      ..color = hasActiveStrain ? color.withValues(alpha: 0.85) : color
      ..style = PaintingStyle.fill;

    return paint;
  }

  Paint _createStrokePaint(InjuryRegion region) {
    final bool isSelected = selectedRegion == region;
    final Color color = _getRegionColor(region);
    final bool hasActiveStrain = color != AppTheme.surfaceElevated;

    return Paint()
      ..color = isSelected
          ? Colors.white
          : (hasActiveStrain
              ? color
              : AppTheme.borderColor.withValues(alpha: 0.8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : (hasActiveStrain ? 1.8 : 1.2);
  }

  void _drawHeadNeck(Canvas canvas, double cx, double scale) {
    const InjuryRegion region = InjuryRegion.neck;
    final Paint fill = _createPaint(region);
    final Paint stroke = _createStrokePaint(region);

    // Head
    final Rect headRect = Rect.fromCenter(
      center: Offset(cx, 40 * scale),
      width: 32 * scale,
      height: 42 * scale,
    );
    canvas.drawOval(headRect, fill);
    canvas.drawOval(headRect, stroke);

    // Neck
    final Rect neckRect = Rect.fromCenter(
      center: Offset(cx, 66 * scale),
      width: 20 * scale,
      height: 16 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(neckRect, Radius.circular(4 * scale)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(neckRect, Radius.circular(4 * scale)),
      stroke,
    );

    _drawChronicBadge(canvas, region, Offset(cx, 40 * scale));
  }

  void _drawTorso(Canvas canvas, double cx, double scale) {
    final double torsoTopY = 76 * scale;

    if (isFront) {
      // 1. Chest / Pecs
      const InjuryRegion chest = InjuryRegion.chestPecs;
      final Rect chestRect = Rect.fromCenter(
        center: Offset(cx, torsoTopY + 22 * scale),
        width: 68 * scale,
        height: 38 * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chestRect, Radius.circular(8 * scale)),
        _createPaint(chest),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chestRect, Radius.circular(8 * scale)),
        _createStrokePaint(chest),
      );
      _drawChronicBadge(canvas, chest, Offset(cx, torsoTopY + 22 * scale));

      // 2. Core / Abdominals
      const InjuryRegion abs = InjuryRegion.coreAbs;
      final Rect absRect = Rect.fromCenter(
        center: Offset(cx, torsoTopY + 66 * scale),
        width: 58 * scale,
        height: 44 * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(absRect, Radius.circular(8 * scale)),
        _createPaint(abs),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(absRect, Radius.circular(8 * scale)),
        _createStrokePaint(abs),
      );
      _drawChronicBadge(canvas, abs, Offset(cx, torsoTopY + 66 * scale));
    } else {
      // 1. Thoracic Spine / Upper Back
      const InjuryRegion upperBack = InjuryRegion.thoracicSpine;
      final Rect upperRect = Rect.fromCenter(
        center: Offset(cx, torsoTopY + 24 * scale),
        width: 72 * scale,
        height: 42 * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(upperRect, Radius.circular(8 * scale)),
        _createPaint(upperBack),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(upperRect, Radius.circular(8 * scale)),
        _createStrokePaint(upperBack),
      );
      _drawChronicBadge(canvas, upperBack, Offset(cx, torsoTopY + 24 * scale));

      // 2. Lumbar Spine / Lower Back
      const InjuryRegion lumbar = InjuryRegion.lumbarSpine;
      final Rect lumbarRect = Rect.fromCenter(
        center: Offset(cx, torsoTopY + 66 * scale),
        width: 60 * scale,
        height: 44 * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(lumbarRect, Radius.circular(8 * scale)),
        _createPaint(lumbar),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(lumbarRect, Radius.circular(8 * scale)),
        _createStrokePaint(lumbar),
      );
      _drawChronicBadge(canvas, lumbar, Offset(cx, torsoTopY + 66 * scale));
    }
  }

  void _drawUpperLimbs(Canvas canvas, double cx, double scale) {
    final double shoulderY = 90 * scale;

    final InjuryRegion leftShoulder =
        isFront ? InjuryRegion.leftShoulder : InjuryRegion.rightShoulder;
    final InjuryRegion rightShoulder =
        isFront ? InjuryRegion.rightShoulder : InjuryRegion.leftShoulder;

    final InjuryRegion leftElbow =
        isFront ? InjuryRegion.leftElbow : InjuryRegion.rightElbow;
    final InjuryRegion rightElbow =
        isFront ? InjuryRegion.rightElbow : InjuryRegion.leftElbow;

    final InjuryRegion leftWrist =
        isFront ? InjuryRegion.leftWrist : InjuryRegion.rightWrist;
    final InjuryRegion rightWrist =
        isFront ? InjuryRegion.rightWrist : InjuryRegion.leftWrist;

    // Shoulders
    // Right on screen (Left anatomical for front view)
    final Rect rShoulder = Rect.fromCenter(
      center: Offset(cx + 50 * scale, shoulderY),
      width: 26 * scale,
      height: 26 * scale,
    );
    canvas.drawOval(rShoulder, _createPaint(leftShoulder));
    canvas.drawOval(rShoulder, _createStrokePaint(leftShoulder));
    _drawChronicBadge(canvas, leftShoulder, Offset(cx + 50 * scale, shoulderY));

    // Left on screen (Right anatomical for front view)
    final Rect lShoulder = Rect.fromCenter(
      center: Offset(cx - 50 * scale, shoulderY),
      width: 26 * scale,
      height: 26 * scale,
    );
    canvas.drawOval(lShoulder, _createPaint(rightShoulder));
    canvas.drawOval(lShoulder, _createStrokePaint(rightShoulder));
    _drawChronicBadge(canvas, rightShoulder, Offset(cx - 50 * scale, shoulderY));

    // Elbows / Upper Arm
    final double elbowY = 135 * scale;
    final Rect rElbow = Rect.fromCenter(
      center: Offset(cx + 62 * scale, elbowY),
      width: 20 * scale,
      height: 38 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rElbow, Radius.circular(8 * scale)),
      _createPaint(leftElbow),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rElbow, Radius.circular(8 * scale)),
      _createStrokePaint(leftElbow),
    );
    _drawChronicBadge(canvas, leftElbow, Offset(cx + 62 * scale, elbowY));

    final Rect lElbow = Rect.fromCenter(
      center: Offset(cx - 62 * scale, elbowY),
      width: 20 * scale,
      height: 38 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lElbow, Radius.circular(8 * scale)),
      _createPaint(rightElbow),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lElbow, Radius.circular(8 * scale)),
      _createStrokePaint(rightElbow),
    );
    _drawChronicBadge(canvas, rightElbow, Offset(cx - 62 * scale, elbowY));

    // Wrists / Hands
    final double wristY = 185 * scale;
    final Rect rWrist = Rect.fromCenter(
      center: Offset(cx + 72 * scale, wristY),
      width: 18 * scale,
      height: 38 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rWrist, Radius.circular(6 * scale)),
      _createPaint(leftWrist),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rWrist, Radius.circular(6 * scale)),
      _createStrokePaint(leftWrist),
    );
    _drawChronicBadge(canvas, leftWrist, Offset(cx + 72 * scale, wristY));

    final Rect lWrist = Rect.fromCenter(
      center: Offset(cx - 72 * scale, wristY),
      width: 18 * scale,
      height: 38 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lWrist, Radius.circular(6 * scale)),
      _createPaint(rightWrist),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lWrist, Radius.circular(6 * scale)),
      _createStrokePaint(rightWrist),
    );
    _drawChronicBadge(canvas, rightWrist, Offset(cx - 72 * scale, wristY));
  }

  void _drawLowerLimbs(Canvas canvas, double cx, double scale) {
    final double hipY = 195 * scale;

    final InjuryRegion leftHip =
        isFront ? InjuryRegion.leftHipGlute : InjuryRegion.rightHipGlute;
    final InjuryRegion rightHip =
        isFront ? InjuryRegion.rightHipGlute : InjuryRegion.leftHipGlute;

    final InjuryRegion leftThigh =
        isFront ? InjuryRegion.leftQuad : InjuryRegion.rightHamstring;
    final InjuryRegion rightThigh =
        isFront ? InjuryRegion.rightQuad : InjuryRegion.leftHamstring;

    final InjuryRegion leftKnee =
        isFront ? InjuryRegion.leftKnee : InjuryRegion.rightKnee;
    final InjuryRegion rightKnee =
        isFront ? InjuryRegion.rightKnee : InjuryRegion.leftKnee;

    final InjuryRegion leftCalf =
        isFront ? InjuryRegion.leftCalfAnkle : InjuryRegion.rightCalfAnkle;
    final InjuryRegion rightCalf =
        isFront ? InjuryRegion.rightCalfAnkle : InjuryRegion.leftCalfAnkle;

    // Pelvis / Hips
    final Rect rHip = Rect.fromCenter(
      center: Offset(cx + 20 * scale, hipY),
      width: 32 * scale,
      height: 30 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rHip, Radius.circular(8 * scale)),
      _createPaint(leftHip),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rHip, Radius.circular(8 * scale)),
      _createStrokePaint(leftHip),
    );
    _drawChronicBadge(canvas, leftHip, Offset(cx + 20 * scale, hipY));

    final Rect lHip = Rect.fromCenter(
      center: Offset(cx - 20 * scale, hipY),
      width: 32 * scale,
      height: 30 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lHip, Radius.circular(8 * scale)),
      _createPaint(rightHip),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lHip, Radius.circular(8 * scale)),
      _createStrokePaint(rightHip),
    );
    _drawChronicBadge(canvas, rightHip, Offset(cx - 20 * scale, hipY));

    // Thighs (Quads vs Hamstrings)
    final double thighY = 245 * scale;
    final Rect rThigh = Rect.fromCenter(
      center: Offset(cx + 24 * scale, thighY),
      width: 28 * scale,
      height: 58 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rThigh, Radius.circular(10 * scale)),
      _createPaint(leftThigh),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rThigh, Radius.circular(10 * scale)),
      _createStrokePaint(leftThigh),
    );
    _drawChronicBadge(canvas, leftThigh, Offset(cx + 24 * scale, thighY));

    final Rect lThigh = Rect.fromCenter(
      center: Offset(cx - 24 * scale, thighY),
      width: 28 * scale,
      height: 58 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lThigh, Radius.circular(10 * scale)),
      _createPaint(rightThigh),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lThigh, Radius.circular(10 * scale)),
      _createStrokePaint(rightThigh),
    );
    _drawChronicBadge(canvas, rightThigh, Offset(cx - 24 * scale, thighY));

    // Knees
    final double kneeY = 290 * scale;
    final Rect rKnee = Rect.fromCenter(
      center: Offset(cx + 24 * scale, kneeY),
      width: 22 * scale,
      height: 22 * scale,
    );
    canvas.drawOval(rKnee, _createPaint(leftKnee));
    canvas.drawOval(rKnee, _createStrokePaint(leftKnee));
    _drawChronicBadge(canvas, leftKnee, Offset(cx + 24 * scale, kneeY));

    final Rect lKnee = Rect.fromCenter(
      center: Offset(cx - 24 * scale, kneeY),
      width: 22 * scale,
      height: 22 * scale,
    );
    canvas.drawOval(lKnee, _createPaint(rightKnee));
    canvas.drawOval(lKnee, _createStrokePaint(rightKnee));
    _drawChronicBadge(canvas, rightKnee, Offset(cx - 24 * scale, kneeY));

    // Calves & Ankles
    final double calfY = 345 * scale;
    final Rect rCalf = Rect.fromCenter(
      center: Offset(cx + 24 * scale, calfY),
      width: 22 * scale,
      height: 68 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rCalf, Radius.circular(8 * scale)),
      _createPaint(leftCalf),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rCalf, Radius.circular(8 * scale)),
      _createStrokePaint(leftCalf),
    );
    _drawChronicBadge(canvas, leftCalf, Offset(cx + 24 * scale, calfY));

    final Rect lCalf = Rect.fromCenter(
      center: Offset(cx - 24 * scale, calfY),
      width: 22 * scale,
      height: 68 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lCalf, Radius.circular(8 * scale)),
      _createPaint(rightCalf),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lCalf, Radius.circular(8 * scale)),
      _createStrokePaint(rightCalf),
    );
    _drawChronicBadge(canvas, rightCalf, Offset(cx - 24 * scale, calfY));
  }

  void _drawChronicBadge(Canvas canvas, InjuryRegion region, Offset center) {
    if (_isRegionChronic(region)) {
      final Paint badgePaint = Paint()
        ..color = const Color(0xFFBF5AF2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx + 8, center.dy - 8), 4, badgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BodyMapPainter oldDelegate) {
    return oldDelegate.isFront != isFront ||
        oldDelegate.injuries != injuries ||
        oldDelegate.selectedRegion != selectedRegion ||
        oldDelegate.customPainMap != customPainMap;
  }
}
