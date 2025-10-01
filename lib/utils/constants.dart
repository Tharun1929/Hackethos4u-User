class ApiConstants {
  // For development/demo purposes, we'll use mock data
  // In production, replace with your actual API URL
  static const String baseUrl = 'https://api.example.com';
  static const String token =
      ''; // This should be dynamically set based on user authentication

  // Mock data flag - set to true for development
  static const bool useMockData = false;
}

class AppConstants {
  static const String appName = 'Hackethos4u';
  static const String appTagline = 'Learn Cybersecurity & Ethical Hacking';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appDescription =
      'Master cybersecurity fundamentals, ethical hacking, network security, and digital forensics. Learn to protect systems, detect threats, and become a certified security professional.';

  // App URLs
  static const String appWebsite = 'https://hackethos4u.com';
  static const String appPrivacyPolicy = 'https://hackethos4u.com/privacy';
  static const String appTermsOfService = 'https://hackethos4u.com/terms';
  static const String appSupportEmail = 'support@hackethos4u.com';
  static const String appContactEmail = 'hello@hackethos4u.com';
  static const String appLegalEmail = 'legal@hackethos4u.com';
  static const String appSupportPhone = '+1-800-HACKETHOS';

  // Social Media
  static const String appLinkedIn = 'https://linkedin.com/company/hackethos4u';
  static const String appTwitter = 'https://twitter.com/hackethos4u';
  static const String appFacebook = 'https://facebook.com/hackethos4u';
  static const String appInstagram = 'https://instagram.com/hackethos4u';
  static const String appYouTube = 'https://youtube.com/hackethos4u';

  // Help & Support
  static const String appHelpCenter = 'https://help.hackethos4u.com';
  static const String appUserGuide = 'https://guide.hackethos4u.com';
  static const String appTutorials = 'https://tutorials.hackethos4u.com';
  static const String appCommunity = 'https://community.hackethos4u.com';
  static const String appBugReport = 'https://bugs.hackethos4u.com';

  // Notification Constants
  static const String notificationChannelId = 'hackethos4u_notifications';
  static const String notificationChannelName = 'Hackethos4u Notifications';
  static const String notificationChannelDescription =
      'Notifications from Hackethos4u app';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/profile';
  static const String whoLoginEndpoint = '/auth/who-login';

  // Course endpoints
  static const String coursesEndpoint = '/courses';
  static const String categoriesEndpoint = '/categories';
  static const String enrollmentsEndpoint = '/enrollments';

  // QA endpoints
  static const String qaEndpoint = '/qa';
  static const String questionsEndpoint = '/questions';
  static const String answersEndpoint = '/answers';

  // Certificate endpoints
  static const String certificatesEndpoint = '/certificates';
  static const String downloadCertificateEndpoint = '/certificates/download';

  // Community endpoints
  static const String communityEndpoint = '/community';
  static const String chatEndpoint = '/chat';
  static const String messagesEndpoint = '/messages';

  // User endpoints
  static const String usersEndpoint = '/users';
  static const String wishlistEndpoint = '/wishlist';
  static const String cartEndpoint = '/cart';

  // FAQ endpoints
  static const String faqEndpoint = '/faq';

  // Request endpoints
  static const String requestsEndpoint = '/requests';

  // Review endpoints
  static const String reviewsEndpoint = '/reviews';

  // Payment endpoints
  static const String paymentsEndpoint = '/payments';
  static const String checkoutEndpoint = '/checkout';

  // Download endpoints
  static const String downloadsEndpoint = '/downloads';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Error messages
  static const String networkError =
      'Network error occurred. Please check your connection.';
  static const String serverError =
      'Server error occurred. Please try again later.';
  static const String unauthorizedError = 'Unauthorized. Please login again.';
  static const String notFoundError = 'Resource not found.';
  static const String validationError =
      'Validation error. Please check your input.';

  // Success messages
  static const String loginSuccess = 'Login successful!';
  static const String registerSuccess = 'Registration successful!';
  static const String profileUpdateSuccess = 'Profile updated successfully!';
  static const String courseEnrollmentSuccess = 'Course enrolled successfully!';
  static const String messageSentSuccess = 'Message sent successfully!';
  static const String certificateDownloadSuccess =
      'Certificate downloaded successfully!';

  // Validation messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email address';
  static const String passwordRequired = 'Password is required';
  static const String passwordMinLength =
      'Password must be at least 6 characters';
  static const String nameRequired = 'Name is required';
  static const String messageRequired = 'Message is required';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultElevation = 2.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // File upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'txt'
  ];

  // Cache
  static const Duration cacheTimeout = Duration(hours: 1);
  static const Duration userCacheTimeout = Duration(days: 7);

  // Deep links
  static const String deepLinkScheme = 'hackethos4u';
  static const String deepLinkHost = 'app.hackethos4u.com';

  // Social media
  static const String facebookUrl = 'https://facebook.com/hackethos4u';
  static const String twitterUrl = 'https://twitter.com/hackethos4u';
  static const String instagramUrl = 'https://instagram.com/hackethos4u';
  static const String linkedinUrl = 'https://linkedin.com/company/hackethos4u';

  // Support
  static const String supportEmail = 'support@hackethos4u.com';
  static const String supportPhone = '+1-800-HACKETHOS';
  static const String helpCenterUrl = 'https://help.hackethos4u.com';

  // Legal
  static const String privacyPolicyUrl = 'https://hackethos4u.com/privacy';
  static const String termsOfServiceUrl = 'https://hackethos4u.com/terms';
  static const String cookiePolicyUrl = 'https://hackethos4u.com/cookies';
}
