import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft muted palette from the user's coolors.co pick:
/// 738290 (slate) · A1B5D8 (periwinkle) · FFFCF7 (cream) · E4F0D0 (pale
/// green) · C2D8B9 (sage). Amounts still get the monospace numeral
/// treatment as the one deliberate "ledger" signature; everything else
/// stays quiet — hairline dividers, no glassmorphism, one accent used
/// sparingly.
///
/// Legacy field names (primaryCoral, glassBackground, textPrimary, etc.)
/// are kept as aliases to the new tokens below so existing call sites
/// across the app keep compiling unchanged — only the values moved.
class AppTheme {
  // ---- Brightness switch -------------------------------------------------
  // Set by ThemeController (see main.dart) before each rebuild. Every token
  // below that differs between light and dark is a getter that reads this,
  // so existing `AppTheme.ink` / `AppTheme.glassBackground` call sites pick
  // up the right colour without being touched.
  static Brightness _brightness = Brightness.light;
  static Brightness get brightness => _brightness;
  static bool get isDark => _brightness == Brightness.dark;
  static void setBrightness(Brightness b) => _brightness = b;

  static Color _pick(Color light, Color dark) => isDark ? dark : light;

  // ---- Light palette (from the coolors.co picks; the two text greys were
  // darkened along the same slate hue so small text meets WCAG AA 4.5:1) ----
  static const Color _lPaper = Color(0xFFFFFCF7); // cream
  static const Color _lPaperRaised = Color(0xFFFFFFFF);
  static const Color _lPaperLine = Color(0xFFE4F0D0); // pale green hairline
  static const Color _lInk = Color(0xFF3F4750);
  static const Color _lInkFaded = Color(0xFF5C6873); // was 738290 (3.9:1); now 5.6:1 on paper
  static const Color _lInkQuiet = Color(0xFF6C7379); // was 9BA5AD (2.5:1); now 4.7:1 on paper
  static const Color _lStampText = Color(0xFF3D5A80);
  static const Color _lIncome = Color(0xFF5F7A56);
  static const Color _lIncomeTint = Color(0xFFC2D8B9);
  static const Color _lWarn = Color(0xFFB5482E);

  // ---- Dark palette — same slate/periwinkle family, near-black base ----
  // Contrast vs. _dPaper: ink 15.6, inkFaded 7.4, inkQuiet 5.2, stampText 8.8,
  // income 7.9, warn 6.7 (all pass WCAG AA for body text).
  static const Color _dPaper = Color(0xFF121518);
  static const Color _dPaperRaised = Color(0xFF1B1F24);
  static const Color _dPaperLine = Color(0xFF2A3037);
  static const Color _dInk = Color(0xFFE9EDF0);
  static const Color _dInkFaded = Color(0xFF9AA6B1);
  static const Color _dInkQuiet = Color(0xFF7E8A95);
  static const Color _dStampText = Color(0xFFA1B5D8);
  static const Color _dIncome = Color(0xFF8FB583);
  static const Color _dIncomeTint = Color(0xFF243127);
  static const Color _dWarn = Color(0xFFE8806A);

  // ---- Theme-aware tokens ----
  static Color get paper => _pick(_lPaper, _dPaper); // page background
  static Color get paperRaised => _pick(_lPaperRaised, _dPaperRaised); // hero cards / sheets
  static Color get paperLine => _pick(_lPaperLine, _dPaperLine); // hairline dividers & borders

  static Color get ink => _pick(_lInk, _dInk); // primary text
  static Color get inkFaded => _pick(_lInkFaded, _dInkFaded); // secondary text
  static Color get inkQuiet => _pick(_lInkQuiet, _dInkQuiet); // tertiary / caption text

  static Color get stampText => _pick(_lStampText, _dStampText); // accent used as text/icon colour
  static Color get income => _pick(_lIncome, _dIncome);
  static Color get incomeTint => _pick(_lIncomeTint, _dIncomeTint);
  static Color get warn => _pick(_lWarn, _dWarn); // over-budget rust — alerts must still read as alerts

  // ---- Fixed tokens (identical in both modes) ----
  static const Color stamp = Color(0xFFA1B5D8); // the one accent — periwinkle
  /// Text/icon colour for anything drawn ON a [stamp] fill (selected chips,
  /// primary buttons, the FAB). Must NOT follow `ink`: in dark mode `ink` is
  /// near-white, which is unreadable on light periwinkle.
  static const Color onStamp = Color(0xFF1F2933);

  /// Hive-persisted colours. Category.defaultExpenseCategories() stores these
  /// on first launch, so they MUST NOT depend on the active theme.
  static const Color incomeFixed = Color(0xFF5F7A56);
  static const Color otherFixed = Color(0xFF9BA5AD);

  // ---- Legacy aliases ----
  static const Color primaryCoral = stamp;
  static const Color accentCoral = stamp;
  static const Color accentAmber = Color(0xFFAD9A6B); // muted tan — chart accent (6.6:1 on dark paper)
  static Color get primaryCharcoal => paper; // legacy name; used only as a surface/background colour
  static Color get successColor => income;
  static Color get errorColor => warn;
  static Color get glassBackground => paperRaised;
  static Color get glassBorder => paperLine;
  static Color get cardBackground => paperRaised;
  static Color get borderColor => paperLine;
  static Color get textPrimary => ink;
  static Color get textSecondary => inkFaded;
  static Color get textTertiary => inkQuiet;
  static Color get otherColor => inkQuiet;

  // Category accents — kept vivid and varied; they read as small dots/marks
  // (17-color set defined separately in category_picker_dialog.dart), not
  // fills, so they don't need to match the muted 5-color brand palette.
  static const foodColor = Color(0xFFF59E0B);
  static const transportColor = Color(0xFF3B82F6);
  static const groceriesColor = Color(0xFF10B981);
  static const billsColor = Color(0xFFEF4444);
  static const healthColor = Color(0xFFEC4899);
  static const shoppingColor = Color(0xFF8B5CF6);
  static const entertainmentColor = Color(0xFF06B6D4);
  static Color get incomeColor => income;

  /// No decorative gradient — flat paper background. Kept as a
  /// LinearGradient (not a solid Color) so `Container(decoration:
  /// BoxDecoration(gradient: AppTheme.primaryGradient))` call sites across
  /// the app keep compiling unchanged.
  static LinearGradient get primaryGradient => LinearGradient(colors: [paper, paper]);
  static const buttonGradient = LinearGradient(colors: [stamp, stamp]);

  // ---- Type ----
  // Work Sans for UI text (set app-wide via ThemeData.fontFamily in
  // main.dart, so the style getters below don't need to repeat it). IBM Plex
  // Mono for every number — the one deliberate "ledger" signature.
  static TextStyle numeral({double size = 15, FontWeight weight = FontWeight.w600, Color? color}) {
    return GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color ?? ink, height: 1.2);
  }

  static TextStyle get headingLarge => TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.15,
    letterSpacing: -0.3,
  );

  static TextStyle get headingMedium => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ink,
    height: 1.25,
  );

  static TextStyle get headingSmall => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: ink,
    height: 1.3,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: ink,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: inkFaded,
    height: 1.5,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: inkFaded,
    height: 1.4,
  );

  static TextStyle get caption => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: inkQuiet,
    height: 1.3,
  );

  // ---- Surfaces ----
  // The one "raised" treatment, reserved for hero content — hairline
  // border, no shadow, no glassmorphism.
  static BoxDecoration glassDecoration({double borderRadius = 14}) {
    return BoxDecoration(
      color: paperRaised,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: paperLine, width: 1),
    );
  }

  static BoxDecoration cardDecoration({double borderRadius = 14}) => glassDecoration(borderRadius: borderRadius);

  /// A single hairline rule for grouping rows without a card — used by
  /// list separators.
  static BorderSide get hairline => BorderSide(color: paperLine, width: 1);

  // Primary buttons use dark onStamp text on the periwinkle fill, not white —
  // A1B5D8 is too light for white text to read well on top of it.
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: stamp,
    foregroundColor: onStamp,
    disabledBackgroundColor: stamp.withOpacity(0.4),
    shadowColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: ink,
    shadowColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: paperLine),
    ),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  );

  static InputDecoration glassInputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: caption,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: paperRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: paperLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: paperLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: stamp, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // ---- Material ThemeData ----
  /// Single ThemeData for the given brightness. Passed straight to
  /// MaterialApp.theme (we resolve System/Light/Dark ourselves in
  /// ThemeController, so MaterialApp.darkTheme/themeMode aren't used).
  ///
  /// The light branch is exactly what main.dart used before dark mode
  /// existed; Material-level overrides (dialogs, sheets, chips, snackbars)
  /// are applied to dark only, so light mode renders unchanged.
  static ThemeData themeData(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? _dPaper : _lPaper;
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      fontFamily: GoogleFonts.workSans().fontFamily,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: stamp, brightness: b, surface: bg),
    );
    if (!dark) return base;

    return base.copyWith(
      canvasColor: _dPaper,
      dividerColor: _dPaperLine,
      colorScheme: base.colorScheme.copyWith(
        primary: stamp,
        onPrimary: onStamp,
        surfaceContainerHighest: _dPaperRaised,
        outlineVariant: _dPaperLine,
      ),
      chipTheme: const ChipThemeData(checkmarkColor: onStamp),
      dialogTheme: const DialogThemeData(backgroundColor: _dPaperRaised, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: _dPaperRaised, surfaceTintColor: Colors.transparent),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _dInk,
        contentTextStyle: TextStyle(color: _dPaper),
      ),
    );
  }
}
