import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static bool _isSecureModeEnabled = false;

  /// Initialize security service
  static Future<void> initialize() async {
    // Initialize any required security features
    // print('Security service initialized');
  }

  /// Dispose security service
  static Future<void> dispose() async {
    await disableSecureMode();
    // print('Security service disposed');
  }

  /// Enable security features to prevent screenshots and screen recording
  static Future<void> enableSecureMode() async {
    try {
      _isSecureModeEnabled = true;

      // Prevent screenshots and screen recording (cross-platform)
      await ScreenProtector.preventScreenshotOn();

      // Keep screen awake during sensitive operations
      await WakelockPlus.enable();

      // print('Security mode enabled - Screenshots and screen recording blocked');
    } catch (e) {
      // print('Error enabling security mode: $e');
    }
  }

  /// Disable security features
  static Future<void> disableSecureMode() async {
    try {
      _isSecureModeEnabled = false;

      // Remove screenshot protection
      await ScreenProtector.preventScreenshotOff();

      // Allow screen to sleep
      await WakelockPlus.disable();

      // print('Security mode disabled');
    } catch (e) {
      // print('Error disabling security mode: $e');
    }
  }

  /// Check if security mode is enabled
  static bool get isSecureModeEnabled => _isSecureModeEnabled;

  /// Enable security for sensitive screens (payment, video player, etc.)
  static Future<void> enableForSensitiveScreen() async {
    await enableSecureMode();
  }

  /// Disable security when leaving sensitive screens
  static Future<void> disableForNormalScreen() async {
    await disableSecureMode();
  }

  /// Hide sensitive content from recent apps
  static Future<void> hideFromRecentApps() async {
    try {
      // Best-effort: obscure content in app switcher if supported
      await ScreenProtector.protectDataLeakageOn();
    } catch (e) {
      // print('Error hiding from recent apps: $e');
    }
  }

  /// Clear app data on security breach detection
  static Future<void> clearSensitiveData() async {
    try {
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear cache
      // Add more cleanup as needed

      // print('Sensitive data cleared');
    } catch (e) {
      // print('Error clearing sensitive data: $e');
    }
  }

  /// Detect if app is running in debug mode
  static bool isDebugMode() {
    bool isDebug = false;
    assert(isDebug = true);
    return isDebug;
  }

  /// Show security warning dialog
  static void showSecurityWarning(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Security Notice'),
          content: const Text(
            'This app contains sensitive educational content. Screenshots and screen recording are disabled for security purposes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I Understand'),
            ),
          ],
        );
      },
    );
  }
}
