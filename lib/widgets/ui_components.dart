import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class UIComponents {
  // Custom Card Widget
  static Widget customCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    bool isDark = false,
    double? elevation,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppTheme.darkCard : AppTheme.lightCard),
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusL),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
        child: child,
      ),
    );
  }

  // Gradient Card Widget
  static Widget gradientCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Gradient? gradient,
    BorderRadius? borderRadius,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.primaryGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
        child: child,
      ),
    );
  }

  // Custom Button Widget
  static Widget customButton({
    required String text,
    required VoidCallback onPressed,
    ButtonType type = ButtonType.primary,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    IconData? icon,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _getButtonHeight(size),
      child: _buildButton(type, text, onPressed, size, isLoading, icon),
    );
  }

  // Custom Input Field Widget
  static Widget customInputField({
    required String label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
    int? maxLines,
    bool isDark = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          maxLines: maxLines ?? 1,
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark
                  ? AppTheme.darkTextTertiary
                  : AppTheme.lightTextTertiary,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled
                ? (isDark ? AppTheme.darkSurface : AppTheme.lightSurface)
                : (isDark ? AppTheme.darkBackground : AppTheme.lightBackground),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: const BorderSide(
                color: AppTheme.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: const BorderSide(color: AppTheme.primaryRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide:
                  const BorderSide(color: AppTheme.primaryRed, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Custom Chip Widget
  static Widget customChip({
    required String text,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    VoidCallback? onTap,
    bool isSelected = false,
    bool isDark = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isSelected
                  ? AppTheme.primaryBlue
                  : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface)),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: textColor ??
                    (isSelected
                        ? Colors.white
                        : (isDark ? AppTheme.darkText : AppTheme.lightText)),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor ??
                    (isSelected
                        ? Colors.white
                        : (isDark ? AppTheme.darkText : AppTheme.lightText)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading Widget
  static Widget loadingWidget({
    String? message,
    bool isDark = false,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            Text(
              message,
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Empty State Widget
  static Widget emptyState({
    required String title,
    required String description,
    IconData? icon,
    Widget? action,
    bool isDark = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: isDark
                    ? AppTheme.darkTextTertiary
                    : AppTheme.lightTextTertiary,
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // Error State Widget
  static Widget errorState({
    required String message,
    VoidCallback? onRetry,
    bool isDark = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.primaryRed,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              customButton(
                text: 'Try Again',
                onPressed: onRetry,
                type: ButtonType.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper Methods
  static double _getButtonHeight(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 44;
      case ButtonSize.large:
        return 52;
    }
  }

  static Widget _buildButton(
    ButtonType type,
    String text,
    VoidCallback onPressed,
    ButtonSize size,
    bool isLoading,
    IconData? icon,
  ) {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          child: _buildButtonChild(text, isLoading, icon),
        );
      case ButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            foregroundColor: AppTheme.primaryBlue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          child: _buildButtonChild(text, isLoading, icon),
        );
      case ButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            side: const BorderSide(color: AppTheme.primaryBlue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          child: _buildButtonChild(text, isLoading, icon),
        );
      case ButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          child: _buildButtonChild(text, isLoading, icon),
        );
    }
  }

  static Widget _buildButtonChild(String text, bool isLoading, IconData? icon) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

enum ButtonType { primary, secondary, outline, text }

enum ButtonSize { small, medium, large }
