import 'package:flutter/foundation.dart';
import '../services/data_service.dart';
import 's.dart';

class LanguageController extends ChangeNotifier {
  LanguageController._();
  static final LanguageController _instance = LanguageController._();
  factory LanguageController() => _instance;

  AppLanguage _preference = AppLanguage.system;
  AppLanguage get preference => _preference;

  /// Reads the saved preference. Call once after DataService.initialize().
  void load() {
    final saved = DataService().getSelectedLanguage();
    _preference = AppLanguage.values.firstWhere(
      (l) => l.name == saved,
      orElse: () => AppLanguage.system,
    );
    S.apply(_preference);
  }

  void setPreference(AppLanguage language) {
    if (language == _preference) return;
    _preference = language;
    DataService().setSelectedLanguage(language.name);
    S.apply(_preference);
    notifyListeners();
  }

  /// The phone's language changed while we're following the system.
  void onSystemLocaleChanged() {
    if (_preference != AppLanguage.system) return;
    S.apply(_preference);
    notifyListeners();
  }
}
