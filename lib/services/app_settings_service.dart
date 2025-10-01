import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AppSettingsService extends ChangeNotifier {
  static final AppSettingsService _instance = AppSettingsService._internal();
  factory AppSettingsService() => _instance;
  AppSettingsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _settings = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  Map<String, dynamic> get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // App Information
  String get appName => _settings['appName'] ?? 'EduTiv Learning';
  String get contactEmail => _settings['contactEmail'] ?? 'support@edutiv.com';
  String get supportPhone => _settings['supportPhone'] ?? '+91 9876543210';

  // Payment Settings
  String get razorpayApiKey => _settings['razorpayApiKey'] ?? '';
  String get currency => _settings['currency'] ?? 'INR';
  bool get testMode => _settings['testMode'] ?? true;

  // Learning Settings
  int get certificateEligibility => _settings['certificateEligibility'] ?? 70;
  int get maxFileUploadSize => _settings['maxFileUploadSize'] ?? 10;

  // Theme Settings
  String get theme => _settings['theme'] ?? 'light';

  /// Initialize settings from Firestore
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      final doc =
          await _firestore.collection('settings').doc('app_settings').get();

      if (doc.exists) {
        _settings = doc.data() as Map<String, dynamic>;
      } else {
        // Initialize with default settings
        _settings = {
          'appName': 'EduTiv Learning',
          'contactEmail': 'support@edutiv.com',
          'supportPhone': '+91 9876543210',
          'razorpayApiKey': '',
          'currency': 'INR',
          'testMode': true,
          'certificateEligibility': 70,
          'maxFileUploadSize': 10,
          'theme': 'light',
        };

        // Save default settings to Firestore
        await _firestore
            .collection('settings')
            .doc('app_settings')
            .set(_settings);
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing app settings: $e');
      // Use default settings if Firestore fails
      _settings = {
        'appName': 'EduTiv Learning',
        'contactEmail': 'support@edutiv.com',
        'supportPhone': '+91 9876543210',
        'razorpayApiKey': '',
        'currency': 'INR',
        'testMode': true,
        'certificateEligibility': 70,
        'maxFileUploadSize': 10,
        'theme': 'light',
      };
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh settings from Firestore
  Future<void> refreshSettings() async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc =
          await _firestore.collection('settings').doc('app_settings').get();

      if (doc.exists) {
        _settings = doc.data() as Map<String, dynamic>;
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing app settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a specific setting
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      _settings[key] = value;
      notifyListeners();

      await _firestore.collection('settings').doc('app_settings').update({
        key: value,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating setting $key: $e');
      // Revert the change
      _settings.remove(key);
      notifyListeners();
    }
  }

  /// Update multiple settings at once
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    try {
      _settings.addAll(newSettings);
      notifyListeners();

      await _firestore.collection('settings').doc('app_settings').update({
        ...newSettings,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating settings: $e');
      // Revert changes
      for (final key in newSettings.keys) {
        _settings.remove(key);
      }
      notifyListeners();
    }
  }

  /// Get support contact information
  Map<String, String> getSupportInfo() {
    return {
      'email': contactEmail,
      'phone': supportPhone,
      'appName': appName,
    };
  }

  /// Get payment configuration
  Map<String, dynamic> getPaymentConfig() {
    return {
      'razorpayApiKey': razorpayApiKey,
      'currency': currency,
      'testMode': testMode,
    };
  }

  /// Get learning configuration
  Map<String, dynamic> getLearningConfig() {
    return {
      'certificateEligibility': certificateEligibility,
      'maxFileUploadSize': maxFileUploadSize,
    };
  }

  /// Check if settings are loaded
  bool hasSetting(String key) {
    return _settings.containsKey(key);
  }

  /// Get setting value with fallback
  T getSetting<T>(String key, T fallback) {
    return _settings[key] ?? fallback;
  }
}
