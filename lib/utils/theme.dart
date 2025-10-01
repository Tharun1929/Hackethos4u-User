import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB),
      Color(0xFF3B82F6),
    ],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF06B6D4),
      Color(0xFF0891B2),
    ],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF22C55E),
      Color(0xFF16A34A),
    ],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF97316),
      Color(0xFFEA580C),
    ],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444),
      Color(0xFFDC2626),
    ],
  );
}

class AppThemes {
  // Light Theme Colors (Clean & Professional)
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightPrimary = Color(0xFF2563EB); // Royal Blue
  static const Color lightSecondary = Color(0xFF3B82F6); // Sky Blue
  static const Color lightTextPrimary = Color(0xFF111827); // Dark Charcoal
  static const Color lightTextSecondary = Color(0xFF6B7280); // Gray
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // Dark Theme Colors (Cybersecurity Feel)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkPrimary = Color(0xFF3B82F6); // Bright Blue
  static const Color darkSecondary = Color(0xFF06B6D4); // Cyan
  static const Color darkTextPrimary = Color(0xFFF9FAFB); // White
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // Gray
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkDivider = Color(0xFF334155);

  // Additional brand colors
  static const Color badgeBeginner = Color(0xFF22C55E);
  static const Color badgeIntermediate = Color(0xFFF97316);
  static const Color badgeAdvanced = Color(0xFFEF4444);

  // Additional theme colors for missing properties
  static const Color primarySolid = Color(0xFF2563EB);
  static const Color secondaryAccent = Color(0xFF06B6D4);
  static const Color chipTintDefault = Color(0xFFE5E7EB);
  static const Color chipTintPython = Color(0xFFFEF3C7);
  static const Color chipTintAI = Color(0xFFDBEAFE);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        error: Color(0xFFEF4444),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          side: const BorderSide(color: lightPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: lightTextSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightBackground,
        selectedColor: lightPrimary.withOpacity(0.12),
        secondarySelectedColor: lightPrimary,
        labelStyle: const TextStyle(color: lightTextPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightPrimary,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: lightTextPrimary,
        size: 24,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 34, fontWeight: FontWeight.w700, color: lightTextPrimary),
        displayMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, color: lightTextPrimary),
        displaySmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: lightTextPrimary),
        headlineLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: lightTextPrimary),
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: lightTextPrimary),
        headlineSmall: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: lightTextPrimary),
        titleLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary),
        titleMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: lightTextPrimary),
        titleSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: lightTextSecondary),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: lightTextPrimary),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: lightTextPrimary),
        bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: lightTextSecondary),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: lightTextPrimary),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: lightTextPrimary),
        labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: lightTextSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        error: Color(0xFFEF4444),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: darkPrimary.withOpacity(0.18),
        secondarySelectedColor: darkPrimary,
        labelStyle: const TextStyle(color: darkTextPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: darkTextPrimary,
        size: 24,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 34, fontWeight: FontWeight.w700, color: darkTextPrimary),
        displayMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, color: darkTextPrimary),
        displaySmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: darkTextPrimary),
        headlineLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: darkTextPrimary),
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
        headlineSmall: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: darkTextPrimary),
        titleSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: darkTextPrimary),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: darkTextPrimary),
        bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: darkTextSecondary),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: darkTextPrimary),
        labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary),
      ),
    );
  }
}
