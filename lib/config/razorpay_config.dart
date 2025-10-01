class RazorpayConfig {
  // Razorpay Configuration
  // Working test credentials for development
  
  // Test Mode Credentials (for development)
  static const String testKeyId = 'rzp_test_RIwpmsMiWbNozZ';
  static const String testKeySecret = 'MsBn4wd6VQLok4K6OTprRpD7';
  
  // Live Mode Credentials (for production)
  static const String liveKeyId = 'rzp_live_your_live_key_id_here';
  static const String liveKeySecret = 'your_live_key_secret_here';
  
  // Current mode - using TEST mode for development
  static const bool isTestMode = true;
  
  // Get current key ID based on mode
  static String get currentKeyId => isTestMode ? testKeyId : liveKeyId;
  
  // Get current key secret based on mode
  static String get currentKeySecret => isTestMode ? testKeySecret : liveKeySecret;
  
  // Backend URL for payment processing - using a working test backend
  static const String backendUrl = 'https://api.razorpay.com/v1';
  
  // Webhook URL for payment notifications
  static const String webhookUrl = 'https://api-6b7a3347va-uc.a.run.app/webhook/razorpay';
  
  // Payment timeout in minutes
  static const int paymentTimeoutMinutes = 10;
  
  // Supported currencies
  static const List<String> supportedCurrencies = ['INR', 'USD', 'EUR'];
  
  // Default currency
  static const String defaultCurrency = 'INR';
  
  // Payment methods to show
  static const List<String> supportedPaymentMethods = [
    'card',
    'netbanking',
    'wallet',
    'upi',
    'emi',
  ];
  
  // Theme configuration
  static const Map<String, dynamic> theme = {
    'color': '#2196F3',
    'modal': {
      'ondismiss': null,
    },
  };
  
  // Validation
  static bool get isConfigured {
    if (isTestMode) {
      return testKeyId.isNotEmpty && 
             testKeyId.startsWith('rzp_test_') &&
             testKeySecret.isNotEmpty;
    } else {
      return liveKeyId.isNotEmpty && 
             liveKeyId.startsWith('rzp_live_') &&
             liveKeySecret.isNotEmpty;
    }
  }
  
  // Get configuration status message
  static String get configurationStatus {
    if (!isConfigured) {
      return 'Razorpay not configured. Please update RazorpayConfig.dart with your credentials.';
    }
    return 'Razorpay configured for ${isTestMode ? 'TEST' : 'LIVE'} mode.';
  }
}
