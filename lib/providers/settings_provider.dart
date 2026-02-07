import 'package:flutter/foundation.dart';
import '../utils/storage_helper.dart';

/// Settings provider for app-wide preferences
class SettingsProvider extends ChangeNotifier {
  int _totalRounds = 20;
  bool _oneStockPerRoll = false;
  bool _soundEnabled = true;
  bool? _darkMode; // null = system default

  int get totalRounds => _totalRounds;
  bool get oneStockPerRoll => _oneStockPerRoll;
  bool get soundEnabled => _soundEnabled;
  bool? get darkMode => _darkMode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageHelper.getSettings();
    _totalRounds = settings['totalRounds'] as int? ?? 20;
    _oneStockPerRoll = settings['oneStockPerRoll'] as bool? ?? false;
    _soundEnabled = settings['soundEnabled'] as bool? ?? true;
    _darkMode = settings['darkMode'] as bool?;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await StorageHelper.saveSettings({
      'totalRounds': _totalRounds,
      'oneStockPerRoll': _oneStockPerRoll,
      'soundEnabled': _soundEnabled,
      'darkMode': _darkMode,
    });
  }

  void setTotalRounds(int rounds) {
    _totalRounds = rounds;
    _saveSettings();
    notifyListeners();
  }

  void setOneStockPerRoll(bool value) {
    _oneStockPerRoll = value;
    _saveSettings();
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setDarkMode(bool? value) {
    _darkMode = value;
    _saveSettings();
    notifyListeners();
  }
}
