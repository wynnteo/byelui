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
  // ---- Palette (from the coolors.co picks) ----
  static const Color paper = Color(0xFFFFFCF7); // page background — cream
  static const Color paperRaised = Color(0xFFFFFFFF); // hero cards / sheets
  static const Color paperLine = Color(0xFFE4F0D0); // hairline dividers & borders — pale green

  static const Color ink = Color(0xFF3F4750); // primary text — deepened slate for real contrast
  static const Color inkFaded = Color(0xFF738290); // secondary text — the slate itself
  static const Color inkQuiet = Color(0xFF9BA5AD); // tertiary / caption text — lightened slate

  static const Color stamp = Color(0xFFA1B5D8); // the one accent — periwinkle, paired with ink text (not white)
  static const Color stampText = Color(0xFF3D5A80); // deepened variant for text/icons on the light background — stamp itself is too light to read as text
  static const Color income = Color(0xFF5F7A56); // readable green, derived from the sage C2D8B9
  static const Color incomeTint = Color(0xFFC2D8B9); // sage — background tint for income pills
  static const Color warn = Color(0xFFB5482E); // over-budget rust — deliberately outside the palette so alerts still read as alerts

  // ---- Legacy aliases (kept const so existing const usages still compile) ----
  static const Color primaryCoral = stamp;
  static const Color primaryCharcoal = paper; // legacy name; used only as a surface/background color throughout the app
  static const Color accentCoral = stamp;
  static const Color accentAmber = Color(0xFFAD9A6B); // muted tan — second accent only for charts
  static const Color successColor = income;
  static const Color errorColor = warn;
  static const Color glassBackground = paperRaised;
  static const Color glassBorder = paperLine;
  static const Color cardBackground = paperRaised;
  static const Color borderColor = paperLine;
  static const Color textPrimary = ink;
  static const Color textSecondary = inkFaded;
  static const Color textTertiary = inkQuiet;
  static const Color otherColor = inkQuiet;

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
  static const incomeColor = income;

  /// No decorative gradient — flat paper background. Kept as a
  /// LinearGradient (not a solid Color) so `Container(decoration:
  /// BoxDecoration(gradient: AppTheme.primaryGradient))` call sites across
  /// the app keep compiling unchanged.
  static const primaryGradient = LinearGradient(colors: [paper, paper]);
  static const buttonGradient = LinearGradient(colors: [stamp, stamp]);

  // ---- Type ----
  // Work Sans for UI text (set app-wide via ThemeData.fontFamily in
  // main.dart, so these const styles below don't need to change). IBM Plex
  // Mono for every number — the one deliberate "ledger" signature.
  static TextStyle numeral({double size = 15, FontWeight weight = FontWeight.w600, Color color = ink}) {
    return GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color, height: 1.2);
  }

  static const TextStyle headingLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.15,
    letterSpacing: -0.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ink,
    height: 1.25,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: ink,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: ink,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: inkFaded,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: inkFaded,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
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
  static const BorderSide hairline = BorderSide(color: paperLine, width: 1);

  // Primary buttons use dark ink text on the periwinkle fill, not white —
  // A1B5D8 is too light for white text to read well on top of it.
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: stamp,
    foregroundColor: ink,
    disabledBackgroundColor: stamp.withOpacity(0.4),
    shadowColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: ink,
    shadowColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: paperLine),
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
        borderSide: const BorderSide(color: paperLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: paperLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: stamp, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
