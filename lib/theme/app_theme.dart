import 'package:flutter/material.dart';

class AppTheme {
  // Main gradient colors - same dark base as MyLui for a matching sibling feel
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1D29), // deep charcoal
      Color(0xFF2A2D3A), // warm gray
      Color(0xFF1A1D29), // deep charcoal
    ],
  );

  // ByeLui accent - coral/amber ("money leaving") instead of MyLui's cyan
  static const primaryCoral = Color(0xFFFF6B4A);
  static const primaryCharcoal = Color(0xFF2A2D3A);
  static const Color accentCoral = Color(0xFFFF6B4A);
  static const Color accentAmber = Color(0xFFF59E0B);

  // Category accent colors
  static const foodColor = Color(0xFFF59E0B);
  static const transportColor = Color(0xFF3B82F6);
  static const groceriesColor = Color(0xFF10B981);
  static const billsColor = Color(0xFFEF4444);
  static const healthColor = Color(0xFFEC4899);
  static const shoppingColor = Color(0xFF8B5CF6);
  static const entertainmentColor = Color(0xFF06B6D4);
  static const incomeColor = Color(0xFF10B981);
  static const otherColor = Color(0xFF64748B);

  static const glassBackground = Color(0x0DFFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);

  static const cardBackground = Color(0x14252836);
  static const borderColor = Color(0x28383B4A);

  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xCBCBD5E1);
  static const textTertiary = Color(0x8094A3B8);

  // Status colors
  static const successColor = Color(0xFF10B981); // emerald - income
  static const errorColor = Color(0xFFEF4444); // red - over budget / expense spike

  // Button gradient
  static const buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF6B4A),
      Color(0xFFF59E0B),
    ],
  );

  static BoxDecoration glassDecoration({double borderRadius = 16}) {
    return BoxDecoration(
      color: glassBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: glassBorder,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration({double borderRadius = 16}) {
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
    letterSpacing: -0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: 1.3,
  );

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: textPrimary,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: glassBackground,
    foregroundColor: textPrimary,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: glassBorder),
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
      fillColor: glassBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryCoral, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
