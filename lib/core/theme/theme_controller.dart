import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

enum AppAppearanceMode { light, dark, amoled }

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const String _prefKeyAppearance = 'studesk_appearance_mode';
  static const String _prefKeyCompactSpacing = 'studesk_compact_spacing';
  static const String _prefKeyReducedMotion = 'studesk_reduced_motion';
  static const String _prefKeyAccentIndex = 'studesk_accent_index';

  AppAppearanceMode _appearanceMode = AppAppearanceMode.amoled;
  bool _isCompactSpacing = false;
  bool _reducedMotion = false;
  int _accentIndex = 0;

  static const List<Color> availableAccents = [
    AppColors.goldLight,
    AppColors.accentAmber,
    AppColors.accentSun,
    AppColors.accentHoney,
  ];

  AppAppearanceMode get appearanceMode => _appearanceMode;
  bool get isCompactSpacing => _isCompactSpacing;
  bool get reducedMotion => _reducedMotion;
  Color get currentAccent =>
      availableAccents[_accentIndex.clamp(0, availableAccents.length - 1)];
  int get accentIndex => _accentIndex;

  ThemeMode get themeMode {
    switch (_appearanceMode) {
      case AppAppearanceMode.light:
        return ThemeMode.light;
      case AppAppearanceMode.dark:
      case AppAppearanceMode.amoled:
        return ThemeMode.dark;
    }
  }

  bool get isDarkMode => _appearanceMode != AppAppearanceMode.light;
  bool get isAmoled => _appearanceMode == AppAppearanceMode.amoled;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKeyAppearance);
      if (savedMode == 'light') {
        _appearanceMode = AppAppearanceMode.light;
      } else if (savedMode == 'dark') {
        _appearanceMode = AppAppearanceMode.dark;
      } else if (savedMode == 'amoled') {
        _appearanceMode = AppAppearanceMode.amoled;
      } else {
        _appearanceMode = AppAppearanceMode.amoled;
      }

      _isCompactSpacing = prefs.getBool(_prefKeyCompactSpacing) ?? false;
      _reducedMotion = prefs.getBool(_prefKeyReducedMotion) ?? false;
      _accentIndex = prefs.getInt(_prefKeyAccentIndex) ?? 0;
      notifyListeners();
    } catch (_) {
      // Graceful fallback
    }
  }

  void setAppearanceMode(AppAppearanceMode mode) {
    if (_appearanceMode != mode) {
      _appearanceMode = mode;
      notifyListeners();
      _savePreferences();
    }
  }

  void toggleTheme() {
    if (_appearanceMode == AppAppearanceMode.light) {
      _appearanceMode = AppAppearanceMode.amoled;
    } else {
      _appearanceMode = AppAppearanceMode.light;
    }
    notifyListeners();
    _savePreferences();
  }

  void setCompactSpacing(bool isCompact) {
    if (_isCompactSpacing != isCompact) {
      _isCompactSpacing = isCompact;
      notifyListeners();
      _savePreferences();
    }
  }

  void setReducedMotion(bool reduce) {
    if (_reducedMotion != reduce) {
      _reducedMotion = reduce;
      notifyListeners();
      _savePreferences();
    }
  }

  void setAccentIndex(int index) {
    if (_accentIndex != index &&
        index >= 0 &&
        index < availableAccents.length) {
      _accentIndex = index;
      notifyListeners();
      _savePreferences();
    }
  }

  Future<void> restoreDefaults() async {
    _appearanceMode = AppAppearanceMode.amoled;
    _isCompactSpacing = false;
    _reducedMotion = false;
    _accentIndex = 0;
    notifyListeners();
    _savePreferences();
  }

  void _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyAppearance, _appearanceMode.name);
      await prefs.setBool(_prefKeyCompactSpacing, _isCompactSpacing);
      await prefs.setBool(_prefKeyReducedMotion, _reducedMotion);
      await prefs.setInt(_prefKeyAccentIndex, _accentIndex);
    } catch (_) {}
  }
}
