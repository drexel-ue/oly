import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/body_composition_entry.dart';
import '../../providers/body_comp_provider.dart';
import '../../services/renpho_ocr_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutrition/body_donut_chart.dart';

class RenphoScannerSheet extends StatefulWidget {
  const RenphoScannerSheet({super.key});

  @override
  State<RenphoScannerSheet> createState() => _RenphoScannerSheetState();
}

class _RenphoScannerSheetState extends State<RenphoScannerSheet> {
  final RenphoOcrService _ocrService = RenphoOcrService();
  final ImagePicker _picker = ImagePicker();

  bool _isProcessing = false;
  BodyCompositionEntry? _parsedEntry;
  String? _errorMessage;

  // Controllers for verification
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatPctController = TextEditingController();
  final TextEditingController _skeletalMuscleController = TextEditingController();
  final TextEditingController _fatFreeMassController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _bmrController = TextEditingController();
  final TextEditingController _waterPctController = TextEditingController();
  final TextEditingController _muscleMassController = TextEditingController();
  final TextEditingController _boneMassController = TextEditingController();
  final TextEditingController _proteinPctController = TextEditingController();
  final TextEditingController _visceralController = TextEditingController();
  final TextEditingController _subcutaneousController = TextEditingController();
  final TextEditingController _metabolicAgeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default preview with sample baseline
    _populateFromEntry(
      BodyCompositionEntry.create(
        weightLb: 264.8,
        bmi: 34.9,
        bodyFatPct: 21.2,
        bodyFatLb: 56.2,
        skeletalMuscleLb: 134.6,
        skeletalMusclePct: 50.8,
        fatFreeMassLb: 208.6,
        subcutaneousFatPct: 16.8,
        visceralFat: 17,
        bodyWaterLb: 150.6,
        bodyWaterPct: 56.9,
        muscleMassLb: 198.4,
        muscleMassPct: 74.9,
        boneMassLb: 10.4,
        boneMassPct: 3.9,
        proteinLb: 47.6,
        proteinPct: 18.0,
        bmrKcal: 2394,
        metabolicAge: 35,
        source: 'renpho_ocr',
      ),
    );
  }

  void _populateFromEntry(BodyCompositionEntry entry) {
    setState(() {
      _parsedEntry = entry;
      _weightController.text = entry.weightLb.toStringAsFixed(1);
      _bodyFatPctController.text = entry.bodyFatPct?.toStringAsFixed(1) ?? '';
      _skeletalMuscleController.text = entry.skeletalMuscleLb?.toStringAsFixed(1) ?? '';
      _fatFreeMassController.text = entry.fatFreeMassLb?.toStringAsFixed(1) ?? '';
      _bmiController.text = entry.bmi?.toStringAsFixed(1) ?? '';
      _bmrController.text = entry.bmrKcal?.toString() ?? '';
      _waterPctController.text = entry.bodyWaterPct?.toStringAsFixed(1) ?? '';
      _muscleMassController.text = entry.muscleMassLb?.toStringAsFixed(1) ?? '';
      _boneMassController.text = entry.boneMassLb?.toStringAsFixed(1) ?? '';
      _proteinPctController.text = entry.proteinPct?.toStringAsFixed(1) ?? '';
      _visceralController.text = entry.visceralFat?.toString() ?? '';
      _subcutaneousController.text = entry.subcutaneousFatPct?.toStringAsFixed(1) ?? '';
      _metabolicAgeController.text = entry.metabolicAge?.toString() ?? '';
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _weightController.dispose();
    _bodyFatPctController.dispose();
    _skeletalMuscleController.dispose();
    _fatFreeMassController.dispose();
    _bmiController.dispose();
    _bmrController.dispose();
    _waterPctController.dispose();
    _muscleMassController.dispose();
    _boneMassController.dispose();
    _proteinPctController.dispose();
    _visceralController.dispose();
    _subcutaneousController.dispose();
    _metabolicAgeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final result = await _ocrService.processImage(pickedFile.path);
        if (result != null) {
          _populateFromEntry(result);
        } else {
          setState(() {
            _errorMessage = 'Could not auto-extract metrics. You can edit the values below.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'OCR error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _saveScan() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    if (weight <= 0) return;

    final entry = BodyCompositionEntry.create(
      timestamp: DateTime.now(),
      weightLb: weight,
      bmi: double.tryParse(_bmiController.text),
      bodyFatPct: double.tryParse(_bodyFatPctController.text),
      skeletalMuscleLb: double.tryParse(_skeletalMuscleController.text),
      fatFreeMassLb: double.tryParse(_fatFreeMassController.text),
      bmrKcal: int.tryParse(_bmrController.text),
      bodyWaterPct: double.tryParse(_waterPctController.text),
      muscleMassLb: double.tryParse(_muscleMassController.text),
      boneMassLb: double.tryParse(_boneMassController.text),
      proteinPct: double.tryParse(_proteinPctController.text),
      visceralFat: int.tryParse(_visceralController.text),
      subcutaneousFatPct: double.tryParse(_subcutaneousController.text),
      metabolicAge: int.tryParse(_metabolicAgeController.text),
      source: 'renpho_ocr',
    );

    final provider = Provider.of<BodyCompProvider>(context, listen: false);
    provider.addEntry(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAmber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.document_scanner, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Renpho Scale Ingest',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons: Gallery, Camera
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionPickerButton(
                          icon: Icons.photo_library_outlined,
                          label: 'Upload Screenshot',
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionPickerButton(
                          icon: Icons.camera_alt_outlined,
                          label: 'Snap Scale Screen',
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                    ],
                  ),

                  if (_isProcessing) ...[
                    const SizedBox(height: 20),
                    const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryAmber),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Scanning Renpho Biometrics...',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Donut Preview
                  if (_parsedEntry != null) ...[
                    BodyDonutChart(entry: _parsedEntry!),
                    const SizedBox(height: 18),
                  ],

                  // Form Verification Grid
                  Text(
                    'VERIFY EXTRACTED METRICS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildEditableRow('Weight (lb)', _weightController, 'e.g. 264.8', AppTheme.primaryAmber),
                  const SizedBox(height: 8),
                  _buildEditableRow('Body Fat %', _bodyFatPctController, 'e.g. 21.2', AppTheme.primaryAmber),
                  const SizedBox(height: 8),
                  _buildEditableRow('Fat-Free Mass / LBM (lb)', _fatFreeMassController, 'e.g. 208.6', AppTheme.secondaryCyan),
                  const SizedBox(height: 8),
                  _buildEditableRow('Skeletal Muscle (lb)', _skeletalMuscleController, 'e.g. 134.6', AppTheme.successGreen),
                  const SizedBox(height: 8),
                  _buildEditableRow('Muscle Mass (lb)', _muscleMassController, 'e.g. 198.4', AppTheme.successGreen),
                  const SizedBox(height: 8),
                  _buildEditableRow('BMR (kcal)', _bmrController, 'e.g. 2394', AppTheme.textPrimary),
                  const SizedBox(height: 8),
                  _buildEditableRow('Body Water %', _waterPctController, 'e.g. 56.9', AppTheme.secondaryCyan),
                  const SizedBox(height: 8),
                  _buildEditableRow('Bone Mass (lb)', _boneMassController, 'e.g. 10.4', const Color(0xFFFF453A)),
                  const SizedBox(height: 8),
                  _buildEditableRow('Protein %', _proteinPctController, 'e.g. 18.0', AppTheme.successGreen),
                  const SizedBox(height: 8),
                  _buildEditableRow('Visceral Fat', _visceralController, 'e.g. 17', AppTheme.warningOrange),
                  const SizedBox(height: 8),
                  _buildEditableRow('Subcutaneous Fat %', _subcutaneousController, 'e.g. 16.8', AppTheme.warningOrange),
                  const SizedBox(height: 8),
                  _buildEditableRow('Metabolic Age', _metabolicAgeController, 'e.g. 35', AppTheme.textSecondary),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Save Footer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Save Scan to Body History',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryAmber, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableRow(
    String label,
    TextEditingController controller,
    String hint,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
