import 'dart:ui' show Locale, PlatformDispatcher;
import 'package:intl/intl.dart';
import 'app_strings.dart';
import 'strings_en.dart';
import 'strings_zh.dart';

/// What the user picked in Settings → Language.
enum AppLanguage { system, en, zh }

class S {
  S._();

  static const AppStrings _en = EnStrings();
  static const AppStrings _zh = ZhStrings();

  static AppStrings _current = _en;
  static AppStrings get t => _current;

  static bool get isChinese => identical(_current, _zh);

  static Locale get locale => isChinese ? const Locale('zh', 'CN') : const Locale('en');

  static void apply(AppLanguage language) {
    final resolved = language == AppLanguage.system ? systemLanguage() : language;
    _current = resolved == AppLanguage.zh ? _zh : _en;
  }

  static AppLanguage systemLanguage() =>
      PlatformDispatcher.instance.locale.languageCode == 'zh' ? AppLanguage.zh : AppLanguage.en;

  static String _fmt(String pattern, DateTime d) => DateFormat(pattern, _current.localeName).format(d);

  static String dayMonth(DateTime d) => _fmt(_current.patDayMonth, d); // 12 Oct | 10月12日
  static String monthYearShort(DateTime d) => _fmt(_current.patMonthYearShort, d); // Oct 2026 | 2026年10月
  static String monthYearLong(DateTime d) => _fmt(_current.patMonthYearLong, d); // October 2026 | 2026年10月
  static String monthLong(DateTime d) => _fmt(_current.patMonthLong, d);
  static String monthShort(DateTime d) => _fmt(_current.patMonthShort, d);
  static String dateFull(DateTime d) => _fmt(_current.patDateFull, d); // Mon, 12 Oct 2026 | 2026年10月12日 周一
}
