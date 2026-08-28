import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/widgets/interactive_body_map.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InjuryExportService {
  InjuryExportService._();

  static const String exportVersion = '1.0.0';

  /// Generates a structured JSON string containing all injuries and summary stats
  static String generateJsonExport({
    required List<InjuryRecord> allInjuries,
    String? athleteName,
  }) {
    final List<InjuryRecord> active =
        allInjuries.where((InjuryRecord i) => i.isActive).toList();
    final List<InjuryRecord> resolved =
        allInjuries.where((InjuryRecord i) => !i.isActive).toList();

    final int acuteCount =
        active.where((InjuryRecord i) => i.stage == InjuryStage.acute).length;
    final int subacuteCount = active
        .where((InjuryRecord i) => i.stage == InjuryStage.subacute)
        .length;
    final int chronicCount =
        active.where((InjuryRecord i) => i.stage == InjuryStage.chronic).length;

    final double avgPain = active.isEmpty
        ? 0.0
        : active.map((InjuryRecord i) => i.painScale).reduce((int a, int b) => a + b) /
            active.length;

    final Map<String, dynamic> exportData = <String, dynamic>{
      'exportVersion': exportVersion,
      'exportTimestamp': DateTime.now().toUtc().toIso8601String(),
      'athleteName': athleteName ?? 'Olympic Weightlifting Athlete',
      'athleteSummary': <String, dynamic>{
        'totalInjuriesLogged': allInjuries.length,
        'activeInjuriesCount': active.length,
        'acuteCount': acuteCount,
        'subacuteCount': subacuteCount,
        'chronicCount': chronicCount,
        'resolvedCount': resolved.length,
        'averagePainScore': double.parse(avgPain.toStringAsFixed(1)),
      },
      'injuries': allInjuries.map((InjuryRecord injury) {
        final Map<String, dynamic> map = injury.toJson();
        map['regionDisplayName'] = injury.region.displayName;
        map['durationInDays'] = injury.durationInDays;
        map['formattedDuration'] = injury.formattedDuration;
        map['stage'] = injury.stage.name;
        map['stageLabel'] = injury.stage.label;
        map['severity'] = injury.severity.name;
        return map;
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Generates a PDF document with visual body maps, tables, clinical history, and biomechanical guidelines
  static Future<Uint8List> generatePdfReport({
    required List<InjuryRecord> allInjuries,
    String? athleteName,
  }) async {
    final pw.Document pdf = pw.Document();

    final List<InjuryRecord> active =
        allInjuries.where((InjuryRecord i) => i.isActive).toList();

    final int acuteCount =
        active.where((InjuryRecord i) => i.stage == InjuryStage.acute).length;
    final int chronicCount =
        active.where((InjuryRecord i) => i.stage == InjuryStage.chronic).length;

    final double avgPain = active.isEmpty
        ? 0.0
        : active.map((InjuryRecord i) => i.painScale).reduce((int a, int b) => a + b) /
            active.length;

    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final String reportDate = dateFormat.format(DateTime.now());

    // Render high-res vector anatomical body maps to PNG offscreen
    final Uint8List frontImageBytes = await BodyMapPainter.renderBodyMapPng(
      isFront: true,
      injuries: allInjuries,
      width: 260,
      height: 340,
    );
    final Uint8List backImageBytes = await BodyMapPainter.renderBodyMapPng(
      isFront: false,
      injuries: allInjuries,
      width: 260,
      height: 340,
    );

    final pw.MemoryImage frontPdfImage = pw.MemoryImage(frontImageBytes);
    final pw.MemoryImage backPdfImage = pw.MemoryImage(backImageBytes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.amber, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: <pw.Widget>[
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      'OLYMPIC WEIGHTLIFTING - INJURY & REHAB REPORT',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.amber900,
                      ),
                    ),
                    pw.Text(
                      'Kinetic Chain Tracking & Biomechanical Modification Summary',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Report: $reportDate',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            margin: const pw.EdgeInsets.only(top: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: <pw.Widget>[
                pw.Text(
                  'OLY Athlete Recovery Engine | Confidential Sports Medicine Summary',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return <pw.Widget>[
            // 1. Athlete & Executive Overview Block
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    'Athlete: ${athleteName ?? "Olympic Weightlifter"}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      _buildMetricBox('Total Logged', '${allInjuries.length}'),
                      _buildMetricBox('Active Strains', '${active.length}'),
                      _buildMetricBox('Acute (<14d)', '$acuteCount'),
                      _buildMetricBox('Chronic (6w+)', '$chronicCount'),
                      _buildMetricBox(
                        'Avg Active Pain',
                        '${avgPain.toStringAsFixed(1)} / 10',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 2. Visual Anatomical Kinetic Chain Heatmap
            pw.Text(
              'ANATOMICAL KINETIC CHAIN STRAIN MAP',
              style: const pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber900,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey900,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: <pw.Widget>[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: <pw.Widget>[
                      pw.Column(
                        children: <pw.Widget>[
                          pw.Text(
                            'ANTERIOR (FRONT VIEW)',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.amber,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Image(frontPdfImage, width: 175, height: 230),
                        ],
                      ),
                      pw.Container(
                        height: 220,
                        width: 1,
                        color: PdfColors.grey800,
                      ),
                      pw.Column(
                        children: <pw.Widget>[
                          pw.Text(
                            'POSTERIOR (BACK VIEW)',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.amber,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Image(backPdfImage, width: 175, height: 230),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: <pw.Widget>[
                      _buildPdfLegendDot(PdfColors.green400, 'Clear (0)'),
                      pw.SizedBox(width: 12),
                      _buildPdfLegendDot(PdfColors.amber, 'Mild (1-3)'),
                      pw.SizedBox(width: 12),
                      _buildPdfLegendDot(PdfColors.orange400, 'Moderate (4-6)'),
                      pw.SizedBox(width: 12),
                      _buildPdfLegendDot(PdfColors.red400, 'Severe (7-10)'),
                      pw.SizedBox(width: 12),
                      _buildPdfLegendDot(PdfColors.purple300, 'Chronic (6w+)'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // 3. Active Strains & Biomechanical Constraints Table
            pw.Text(
              'ACTIVE JOINT & TISSUE STRAINS',
              style: const pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber900,
              ),
            ),
            pw.SizedBox(height: 8),

            if (active.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.green300),
                ),
                child: pw.Text(
                  'No active strains recorded. All joint complexes clear for standard loading.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.green900),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: const pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                headers: <String>[
                  'Region',
                  'Condition / Pathology',
                  'OSIICS',
                  'Stage & Duration',
                  'Pain',
                  'Loading Vectors to Avoid',
                ],
                data: active.map((InjuryRecord injury) {
                  return <String>[
                    injury.region.displayName,
                    injury.name,
                    if (injury.osiicsCode.isEmpty) '-' else injury.osiicsCode,
                    '${injury.stage.label}\n(${injury.formattedDuration})',
                    '${injury.painScale}/10\n(${injury.severity.displayName})',
                    if (injury.constraints.isEmpty)
                      'Standard'
                    else
                      injury.constraints
                          .map((BiomechanicalConstraint c) => c.displayName)
                          .join(', '),
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 18),

            // 4. Recommended Movement Substitutions & Rehab Cues
            if (active.any((InjuryRecord i) =>
                i.safeSubstitutions.isNotEmpty || i.rehabCues.isNotEmpty)) ...<pw.Widget>[
              pw.Text(
                'RECOMMENDED EXERCISE REGRESSIONS & REHAB PROTOCOLS',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: const pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                headers: <String>[
                  'Condition',
                  'Standard Lift',
                  'Safe Regression',
                  '1RM Load %',
                  'Biomechanical Rationale',
                ],
                data: active.expand((InjuryRecord injury) {
                  if (injury.safeSubstitutions.isEmpty) {
                    return <List<String>>[];
                  }
                  return injury.safeSubstitutions.map((InjurySubstitution sub) {
                    return <String>[
                      injury.name,
                      sub.targetExercise,
                      sub.replacementName,
                      '${(sub.weightMultiplier * 100).round()}%',
                      sub.rationale,
                    ];
                  });
                }).toList(),
              ),
              pw.SizedBox(height: 18),
            ],

            // 5. Historical Check-In & Resolution Audit
            pw.Text(
              'INJURY CHECK-IN TIMELINE & RESOLUTION HISTORY',
              style: const pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber900,
              ),
            ),
            pw.SizedBox(height: 8),

            if (allInjuries.isEmpty)
              pw.Text('No historical records logged.', style: const pw.TextStyle(fontSize: 9))
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: const pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                headers: <String>[
                  'Onset Date',
                  'Region',
                  'Condition Name',
                  'Status',
                  'Pain Check-In History',
                  'Notes',
                ],
                data: allInjuries.map((InjuryRecord injury) {
                  final String onsetStr =
                      DateFormat('yyyy-MM-dd').format(injury.onsetDate);
                  final String statusStr = injury.isActive
                      ? 'ACTIVE\n(${injury.stage.label})'
                      : 'RESOLVED\n${injury.resolvedAt != null ? DateFormat("MM/dd/yy").format(injury.resolvedAt!) : ""}';

                  final String historyStr = injury.history.isEmpty
                      ? 'Initial: ${injury.painScale}/10'
                      : injury.history
                          .map((InjuryHistoryEntry h) =>
                              '${DateFormat("MM/dd").format(h.date)}: ${h.painScale}/10')
                          .join('\n');

                  return <String>[
                    onsetStr,
                    injury.region.displayName,
                    injury.name,
                    statusStr,
                    historyStr,
                    if (injury.notes.isEmpty) '-' else injury.notes,
                  ];
                }).toList(),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetricBox(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfLegendDot(PdfColor color, String label) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: <pw.Widget>[
        pw.Container(
          width: 7,
          height: 7,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
        ),
      ],
    );
  }

  /// Generates a standardized timestamp string (yyyyMMdd_HHmmss)
  static String generateTimestamp([DateTime? dt]) {
    final DateTime target = dt ?? DateTime.now();
    return DateFormat('yyyyMMdd_HHmmss').format(target);
  }

  /// Generates the filename for PDF export
  static String generatePdfFileName([DateTime? dt]) {
    return 'oly_injury_report_${generateTimestamp(dt)}.pdf';
  }

  /// Generates the filename for JSON export
  static String generateJsonFileName([DateTime? dt]) {
    return 'oly_injury_history_${generateTimestamp(dt)}.json';
  }

  /// Shares or triggers saving for the PDF report
  static Future<void> sharePdfReport({
    required List<InjuryRecord> allInjuries,
    String? athleteName,
  }) async {
    final Uint8List pdfBytes = await generatePdfReport(
      allInjuries: allInjuries,
      athleteName: athleteName,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: generatePdfFileName(),
    );
  }

  /// Opens the native system PDF preview & print dialogue
  static Future<void> previewOrPrintPdf({
    required List<InjuryRecord> allInjuries,
    String? athleteName,
  }) async {
    await Printing.layoutPdf(
      name: generatePdfFileName(),
      onLayout: (PdfPageFormat format) async {
        return generatePdfReport(
          allInjuries: allInjuries,
          athleteName: athleteName,
        );
      },
    );
  }

  /// Shares or triggers saving for the JSON export file
  static Future<void> shareJsonExport({
    required List<InjuryRecord> allInjuries,
    String? athleteName,
  }) async {
    final String jsonStr = generateJsonExport(
      allInjuries: allInjuries,
      athleteName: athleteName,
    );
    final Uint8List jsonBytes = Uint8List.fromList(utf8.encode(jsonStr));

    await Printing.sharePdf(
      bytes: jsonBytes,
      filename: generateJsonFileName(),
    );
  }
}
