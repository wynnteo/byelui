import 'dart:ui' show Locale, PlatformDispatcher;
import 'package:intl/intl.dart';
import 'app_strings.dart';
import 'strings_en.dart';
import 'strings_zh.dart';

/// What the user picked in Settings → Language.
enum AppLanguage { system, en, zh }

/// Global access to the active translation, same idea as AppTheme's
/// brightness switch: `S.t.addTransaction`. Works anywhere — widgets, models,
/// services — because it needs no BuildContext. LanguageController swaps the
/// language and the app rebuilds.
class S {
  S._();

  static const AppStrings _en = EnStrings();
  static const AppStrings _zh = ZhStrings();

  static AppStrings _current = _en;
  static AppStrings get t => _current;

  static bool get isChinese => identical(_current, _zh);

  /// Locale handed to MaterialApp (date pickers, dialog buttons, etc).
  static Locale get locale => isChinese ? const Locale('zh', 'CN') : const Locale('en');

  /// Sets the concrete language. `AppLanguage.system` follows the phone, and
  /// only Chinese is special-cased: any other phone language falls back to English.
  static void apply(AppLanguage language) {
    final resolved = language == AppLanguage.system ? systemLanguage() : language;
    _current = resolved == AppLanguage.zh ? _zh : _en;
  }

  static AppLanguage systemLanguage() =>
      PlatformDispatcher.instance.locale.languageCode == 'zh' ? AppLanguage.zh : AppLanguage.en;

  // ---- Locale-aware date helpers (patterns live in the string table) ----
  static String _fmt(String pattern, DateTime d) => DateFormat(pattern, _current.localeName).format(d);

  static String dayMonth(DateTime d) => _fmt(_current.patDayMonth, d); // 12 Oct | 10月12日
  static String monthYearShort(DateTime d) => _fmt(_current.patMonthYearShort, d); // Oct 2026 | 2026年10月
  static String monthYearLong(DateTime d) => _fmt(_current.patMonthYearLong, d); // October 2026 | 2026年10月
  static String monthLong(DateTime d) => _fmt(_current.patMonthLong, d);
  static String monthShort(DateTime d) => _fmt(_current.patMonthShort, d);
  static String dateFull(DateTime d) => _fmt(_current.patDateFull, d); // Mon, 12 Oct 2026 | 2026年10月12日 周一
}
