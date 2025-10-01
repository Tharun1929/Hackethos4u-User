import 'package:flutter/material.dart';

class AppThemes {
  // Primary Colors
  static const Color primarySolid = Color(0xFF3B82F6);
  static const Color secondaryAccent = Color(0xFF8B5CF6);

  // Badge Colors
  static const Color badgeBeginner = Color(0xFF10B981);
  static const Color badgeIntermediate = Color(0xFFF59E0B);
  static const Color badgeAdvanced = Color(0xFFEF4444);

  // Chip Tint Colors
  static const Color chipTintDefault = Color(0xFF6B7280);
  static const Color chipTintPython = Color(0xFF3776AB);
  static const Color chipTintAI = Color(0xFF8B5CF6);
  static const Color chipTintFlutter = Color(0xFF02569B);
  static const Color chipTintReact = Color(0xFF61DAFB);
  static const Color chipTintJavaScript = Color(0xFFF7DF1E);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A1A);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x4D000000);

  // Legacy compatibility properties
  static const Color primaryColor = primarySolid;
  static const Color backgroundColor = backgroundLight;
  static const Color cardColor = surfaceLight;
  static const Color textPrimaryColor = textPrimary;
  static const Color textSecondaryColor = textSecondary;
  static const Color textHintColor = textTertiary;
  static const Color successColor = success;
  static const Color warningColor = warning;
  static const Color errorColor = error;
  static const Color infoColor = info;
  static const Color borderColor = borderLight;
  static const Color dividerColor = borderLight;
  static const Color shadowColor = shadowLight;
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppThemes.primarySolid, AppThemes.secondaryAccent],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppThemes.success, Color(0xFF059669)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppThemes.warning, Color(0xFFD97706)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppThemes.error, Color(0xFFDC2626)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF262626)],
  );
}
