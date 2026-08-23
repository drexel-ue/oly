import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  bool _isLbs = false;
  double _barWeight = 20.0;
  double _collarWeight = 2.5;
  bool _soundAlertsEnabled = true;
  bool _hapticsEnabled = true;

  SettingsProvider(this._storage) {
    _isLbs = _storage.loadIsLbs();
    _barWeight = _storage.loadBarWeight();
    _collarWeight = _storage.loadCollarWeight();
    _soundAlertsEnabled = _storage.loadSoundAlerts();
    _hapticsEnabled = _storage.loadHapticsEnabled();
  }

  bool get isLbs => _isLbs;
  double get barWeight => _barWeight;
  double get collarWeight => _collarWeight;
  bool get soundAlertsEnabled => _soundAlertsEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  String get unitLabel => _isLbs ? 'lbs' : 'kg';

  // Conversion utilities (Base weight stored in DB is ALWAYS KG)
  double kgToLbs(double kg) => kg * 2.20462;
  double lbsToKg(double lbs) => lbs / 2.20462;

  double toDisplayWeight(double weightKg) {
    if (_isLbs) {
      return (kgToLbs(weightKg) / 2.5).round() * 2.5; // Round to nearest 2.5 lbs
    }
    return (weightKg / 0.5).round() * 0.5; // Round to nearest 0.5 kg
  }

  double toBaseKg(double displayWeight) {
    if (_isLbs) {
      return lbsToKg(displayWeight);
    }
    return displayWeight;
  }

  String formatWeight(double weightKg, {bool includeUnit = true}) {
    final val = toDisplayWeight(weightKg);
    final str = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
    return includeUnit ? '$str $unitLabel' : str;
  }

  /// Converts any inline metric weight references (e.g. "2.5kg" or "8-16kg")
  /// in prose text according to the user's active unit preference (lbs vs kg).
  String formatTextUnits(String text) {
    if (!_isLbs) return text;

    return text.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)(?:\s*-\s*(\d+(?:\.\d+)?))?\s*kg', caseSensitive: false),
      (match) {
        final val1Kg = double.tryParse(match.group(1)!) ?? 0.0;
        final val1Lbs = (kgToLbs(val1Kg) / 0.5).round() * 0.5;
        final str1 = val1Lbs % 1 == 0 ? val1Lbs.toInt().toString() : val1Lbs.toStringAsFixed(1);

        if (match.group(2) != null) {
          final val2Kg = double.tryParse(match.group(2)!) ?? 0.0;
          final val2Lbs = (kgToLbs(val2Kg) / 0.5).round() * 0.5;
          final str2 = val2Lbs % 1 == 0 ? val2Lbs.toInt().toString() : val2Lbs.toStringAsFixed(1);
          return '$str1-$str2 lbs';
        }

        return '$str1 lbs';
      },
    );
  }

  void toggleUnit() {
    _isLbs = !_isLbs;
    _storage.saveIsLbs(_isLbs);
    notifyListeners();
  }

  void setBarWeight(double weight) {
    _barWeight = weight;
    _storage.saveBarWeight(_barWeight);
    notifyListeners();
  }

  void setCollarWeight(double weight) {
    _collarWeight = weight;
    _storage.saveCollarWeight(_collarWeight);
    notifyListeners();
  }

  void toggleSoundAlerts() {
    _soundAlertsEnabled = !_soundAlertsEnabled;
    _storage.saveSoundAlerts(_soundAlertsEnabled);
    notifyListeners();
  }

  void toggleHaptics() {
    _hapticsEnabled = !_hapticsEnabled;
    _storage.saveHapticsEnabled(_hapticsEnabled);
    notifyListeners();
  }

  String exportFullDataJson() => _storage.exportFullAppDataJson();
  String exportPrsCsv() => _storage.exportPrsCsv();
  Future<bool> importDataJson(String jsonStr) async {
    final success = await _storage.importAppDataJson(jsonStr);
    if (success) {
      _isLbs = _storage.loadIsLbs();
      _barWeight = _storage.loadBarWeight();
      _collarWeight = _storage.loadCollarWeight();
      _soundAlertsEnabled = _storage.loadSoundAlerts();
      _hapticsEnabled = _storage.loadHapticsEnabled();
      notifyListeners();
    }
    return success;
  }
}
