class AppConfig {
  // Razorpay Configuration
  // Note: Key ID is now stored in Firestore settings, not hardcoded
  // Secret key is stored securely on the backend server only

  // Default test key (will be overridden by admin settings)
  static const String defaultRazorpayKeyId = 'rzp_test_1DP5mmOlF5G5ag';

  // App Configuration
  static const String appName = 'EduTiv Learning Platform';
  static const String appVersion = '1.0.0';
  static const String companyName = 'EduTiv Learning Platform';
  static const String companyEmail = 'support@edutiv.com';
  static const String companyPhone = '+91 98765 43210';

  // Firebase Configuration
  static const String firebaseProjectId = 'e-learn-ea824';

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enablePushNotifications = true;
  static const bool enableOfflineMode = true;

  // API Configuration
  static const String baseUrl = 'https://api.edutiv.com';
  static const int apiTimeoutSeconds = 30;

  // Storage Configuration
  static const int maxFileSizeMB = 100;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedVideoTypes = ['mp4', 'avi', 'mov', 'wmv'];

  // UI Configuration
  static const int animationDurationMs = 300;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Course Configuration
  static const int maxCourseModules = 20;
  static const int maxSubmodulesPerModule = 50;
  static const int maxCourseDurationHours = 100;

  // Payment Configuration
  static const String defaultCurrency = 'INR';
  static const double taxRate = 0.18; // 18% GST
  static const double platformFeeRate = 0.05; // 5% platform fee

  // Security Configuration
  static const int maxLoginAttempts = 5;
  static const int sessionTimeoutMinutes = 30;
  static const bool requireEmailVerification = true;

  // Performance Configuration
  static const int imageCacheSize = 100;
  static const int videoCacheSize = 10;
  static const bool enableImageCompression = true;
  static const bool enableVideoCompression = true;
}
