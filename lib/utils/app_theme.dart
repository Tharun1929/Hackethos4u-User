import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color primaryOrange = Color(0xFFF59E0B);
  static const Color primaryRed = Color(0xFFEF4444);

  // Legacy compatibility properties
  static const Color primaryColor = primaryBlue;
  static const Color backgroundColor = lightBackground;
  static const Color cardColor = lightCard;
  static const Color borderColor = lightBorder;
  static const Color textSecondaryColor = lightTextSecondary;
  static const Color textHintColor = lightTextTertiary;
  static const Color successColor = primaryGreen;
  static const Color warningColor = primaryOrange;
  static const Color errorColor = primaryRed;
  static const Color infoColor = Color(0xFF06B6D4);
  static const Color shadowColor = Color(0xFF000000);

  // Additional compatibility properties
  static const Color primarySolid = primaryBlue;
  static const Color borderLight = lightBorder;
  static const Color textSecondary = lightTextSecondary;
  static const Color success = primaryGreen;
  static const Color badgeBeginner = primaryGreen;

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightText = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF262626);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkText = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkTextTertiary = Color(0xFF9CA3AF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryPurple],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, Color(0xFF059669)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryOrange, Color(0xFFD97706)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, Color(0xFFDC2626)],
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryPurple,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightText,
      error: primaryRed,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightCard,
    dividerColor: lightBorder,
    textTheme: _lightTextTheme,
    elevatedButtonTheme: _elevatedButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
    cardTheme: _cardTheme,
    appBarTheme: _appBarTheme,
    bottomNavigationBarTheme: _bottomNavigationBarTheme,
    chipTheme: _chipTheme,
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryPurple,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkText,
      error: primaryRed,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    dividerColor: darkBorder,
    textTheme: _darkTextTheme,
    elevatedButtonTheme: _elevatedButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
    cardTheme: _cardTheme,
    appBarTheme: _appBarTheme,
    bottomNavigationBarTheme: _bottomNavigationBarTheme,
    chipTheme: _chipTheme,
  );

  // Text Themes
  static const TextTheme _lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: lightText,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: lightText,
      letterSpacing: -0.25,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: lightText,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: lightText,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: lightText,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: lightText,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: lightTextSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: lightTextTertiary,
    ),
  );

  static const TextTheme _darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: darkText,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: darkText,
      letterSpacing: -0.25,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: darkText,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: darkText,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: darkText,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: darkText,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: darkTextSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: darkTextTertiary,
    ),
  );

  // Button Themes
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: const BorderSide(color: primaryBlue),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Input Decoration Theme
  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryRed, width: 2),
    ),
  );

  // Card Theme
  static final CardThemeData _cardTheme = CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.all(8),
  );

  // AppBar Theme
  static final AppBarTheme _appBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.black,
  );

  // Bottom Navigation Bar Theme
  static final BottomNavigationBarThemeData _bottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    elevation: 0,
    type: BottomNavigationBarType.fixed,
  );

  // Chip Theme
  static final ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: primaryBlue.withOpacity(0.1),
    selectedColor: primaryBlue,
    disabledColor: lightBorder,
    labelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  );

  // Custom Widget Styles
  static BoxDecoration getCardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? darkCard : lightCard,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration getGradientDecoration() {
    return const BoxDecoration(
      gradient: primaryGradient,
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
  }

  static BoxDecoration getBorderDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? darkSurface : lightSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? darkBorder : lightBorder,
        width: 1,
      ),
    );
  }

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // Border Radius
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;
}
