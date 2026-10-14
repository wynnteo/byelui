import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'data_service.dart';

enum AppThemeMode { system, light, dark }

/// Owns the user's System / Light / Dark choice and resolves it to a concrete
/// [Brightness]. `ByeLuiApp` listens to this and rebuilds the whole tree.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController _instance = ThemeController._();
  factory ThemeController() => _instance;

  AppThemeMode _mode = AppThemeMode.system;
  AppThemeMode get mode => _mode;

  /// Reads the saved preference. Call once after DataService.initialize().
  void load() {
    final saved = DataService().getThemeMode();
    _mode = AppThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => AppThemeMode.system,
    );
    AppTheme.setBrightness(resolve());
  }

  /// The brightness actually in effect (System follows the OS setting).
  Brightness resolve() {
    switch (_mode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return PlatformDispatcher.instance.platformBrightness;
    }
  }

  void setMode(AppThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    DataService().setThemeMode(mode.name);
    AppTheme.setBrightness(resolve());
    notifyListeners();
  }

  /// Called when the OS flips light/dark while we're in System mode.
  void onPlatformBrightnessChanged() {
    if (_mode != AppThemeMode.system) return;
    AppTheme.setBrightness(resolve());
    notifyListeners();
  }
}
