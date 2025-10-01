import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color primaryLightColor = Color(0xFFBBDEFB);

  // Secondary Colors
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color secondaryDarkColor = Color(0xFF018786);
  static const Color secondaryLightColor = Color(0xFFB2DFDB);

  // Accent Colors
  static const Color accentColor = Color(0xFFFF4081);
  static const Color accentDarkColor = Color(0xFFE91E63);
  static const Color accentLightColor = Color(0xFFF8BBD9);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textHintColor = Color(0xFFBDBDBD);

  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Border Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFBDBDBD);

  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, secondaryDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: textHintColor,
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // Card Style
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Input Decoration
  static InputDecoration inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // App Bar Theme
  static AppBarTheme appBarTheme = const AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  );

  // Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData bottomNavTheme =
      const BottomNavigationBarThemeData(
    backgroundColor: surfaceColor,
    selectedItemColor: primaryColor,
    unselectedItemColor: textSecondaryColor,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );

  // Floating Action Button Theme
  static FloatingActionButtonThemeData fabTheme =
      const FloatingActionButtonThemeData(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 4,
  );

  // Icon Theme
  static IconThemeData iconTheme = const IconThemeData(
    color: textPrimaryColor,
    size: 24,
  );

  // Divider Theme
  static DividerThemeData dividerTheme = const DividerThemeData(
    color: dividerColor,
    thickness: 1,
    space: 1,
  );
}
