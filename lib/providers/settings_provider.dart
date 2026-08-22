import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  bool _isLbs = false;
  double _barWeight = 20.0;
  double _collarWeight = 2.5;

  SettingsProvider(this._storage) {
    _isLbs = _storage.loadIsLbs();
    _barWeight = _storage.loadBarWeight();
    _collarWeight = _storage.loadCollarWeight();
  }

  bool get isLbs => _isLbs;
  double get barWeight => _barWeight;
  double get collarWeight => _collarWeight;
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
}
