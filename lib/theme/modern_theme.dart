import 'package:flutter/material.dart';

class ModernTheme {
  // Modern Blue & White Color Palette (matching reference image)
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryBlueDark = Color(0xFF1976D2);
  static const Color primaryBlueLight = Color(0xFFE3F2FD);
  static const Color accentBlue = Color(0xFF42A5F5);

  // Background Colors
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Border & Shadow
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color shadowColor = Color(0x1A000000);

  // Modern Border Radius (curve edges)
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: textHint,
    height: 1.2,
  );

  // Button Styles
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: textWhite,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: primaryBlue,
    side: const BorderSide(color: primaryBlue, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: primaryBlue,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusSmall),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration cardDecorationSmall = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 8,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
  );

  // Input Decoration
  static InputDecoration inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: textHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: surfaceColor,
    );
  }

  // App Bar Theme
  static AppBarTheme appBarTheme = const AppBarTheme(
    backgroundColor: surfaceColor,
    foregroundColor: textPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
  );

  // Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData bottomNavTheme =
      const BottomNavigationBarThemeData(
    backgroundColor: surfaceColor,
    selectedItemColor: primaryBlue,
    unselectedItemColor: textSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ),
  );

  // Icon Theme
  static IconThemeData iconTheme = const IconThemeData(
    color: textPrimary,
    size: 24,
  );

  // Divider Theme
  static DividerThemeData dividerTheme = const DividerThemeData(
    color: borderColor,
    thickness: 1,
    space: 1,
  );

  // Create Theme Data
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentBlue,
        surface: surfaceColor,
        error: error,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onSurface: textPrimary,
        onError: textWhite,
      ),
      appBarTheme: appBarTheme,
      bottomNavigationBarTheme: bottomNavTheme,
      iconTheme: iconTheme,
      dividerTheme: dividerTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButton),
      textButtonTheme: TextButtonThemeData(style: textButton),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        shadowColor: shadowColor,
      ),
    );
  }
}
