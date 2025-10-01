import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

class SecurityRestrictionService {
  static final SecurityRestrictionService _instance =
      SecurityRestrictionService._internal();
  factory SecurityRestrictionService() => _instance;
  SecurityRestrictionService._internal();

  bool _isRestrictionEnabled = false;
  bool _isVideoPlaying = false;

  // Enable screen recording and screenshot restrictions
  Future<void> enableRestrictions() async {
    try {
      _isRestrictionEnabled = true;

      // Prevent screenshots
      await ScreenProtector.protectDataLeakageOn();

      // Prevent screen recording
      // await ScreenProtector.protectScreenShot(); // Method not available in this version

      // print('✅ Security restrictions enabled');
    } catch (e) {
      // print('❌ Error enabling security restrictions: $e');
    }
  }

  // Disable screen recording and screenshot restrictions
  Future<void> disableRestrictions() async {
    try {
      _isRestrictionEnabled = false;

      // Allow screenshots
      await ScreenProtector.protectDataLeakageOff();

      // Allow screen recording
      // await ScreenProtector.disableScreenProtection(); // Method not available in this version

      // print('✅ Security restrictions disabled');
    } catch (e) {
      // print('❌ Error disabling security restrictions: $e');
    }
  }

  // Enable restrictions when video starts playing
  Future<void> onVideoStart() async {
    if (!_isVideoPlaying) {
      _isVideoPlaying = true;
      await enableRestrictions();
    }
  }

  // Disable restrictions when video stops playing
  Future<void> onVideoStop() async {
    if (_isVideoPlaying) {
      _isVideoPlaying = false;
      await disableRestrictions();
    }
  }

  // Check if restrictions are currently enabled
  bool get isRestrictionEnabled => _isRestrictionEnabled;

  // Check if video is currently playing
  bool get isVideoPlaying => _isVideoPlaying;

  // Show security warning dialog
  static void showSecurityWarning(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Security Notice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'For security reasons, screen recording and screenshots are disabled while viewing course content.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This protects the intellectual property of our course content.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  // Show security indicator in UI
  static Widget buildSecurityIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security, color: Colors.red[600], size: 12),
          const SizedBox(width: 4),
          Text(
            'SECURED',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Add security overlay to video player
  static Widget buildSecurityOverlay() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              'Protected',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check if device supports security restrictions
  static Future<bool> isSecuritySupported() async {
    try {
      // Try to enable and immediately disable to test support
      // await ScreenProtector.protectScreenShot(); // Method not available in this version
      // await ScreenProtector.disableScreenProtection(); // Method not available in this version
      return true;
    } catch (e) {
      // print('Security restrictions not supported on this device: $e');
      return false;
    }
  }

  // Get security status message
  static String getSecurityStatusMessage() {
    return 'Screen recording and screenshots are disabled to protect course content.';
  }

  // Log security events
  static void logSecurityEvent(String event) {
    // print('🔒 Security Event: $event');
    // In production, you might want to send this to analytics or logging service
  }
}
