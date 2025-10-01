import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== USER PROPERTIES =====

  /// Set user properties for analytics
  Future<void> setUserProperties({
    required String userId,
    String? userType,
    String? subscriptionPlan,
    int? coursesEnrolled,
    int? coursesCompleted,
    int? certificatesEarned,
  }) async {
    try {
      await _analytics.setUserId(id: userId);

      if (userType != null) {
        await _analytics.setUserProperty(name: 'user_type', value: userType);
      }

      if (subscriptionPlan != null) {
        await _analytics.setUserProperty(
            name: 'subscription_plan', value: subscriptionPlan);
      }

      if (coursesEnrolled != null) {
        await _analytics.setUserProperty(
            name: 'courses_enrolled', value: coursesEnrolled.toString());
      }

      if (coursesCompleted != null) {
        await _analytics.setUserProperty(
            name: 'courses_completed', value: coursesCompleted.toString());
      }

      if (certificatesEarned != null) {
        await _analytics.setUserProperty(
            name: 'certificates_earned', value: certificatesEarned.toString());
      }
    } catch (e) {
      print('Error setting user properties: $e');
    }
  }

  /// Update user properties from Firestore data
  Future<void> updateUserPropertiesFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final stats = userData['stats'] as Map<String, dynamic>? ?? {};

      await setUserProperties(
        userId: user.uid,
        userType: userData['role']?.toString() ?? 'student',
        coursesEnrolled: stats['coursesEnrolled'] as int? ?? 0,
        coursesCompleted: stats['coursesCompleted'] as int? ?? 0,
        certificatesEarned: stats['certificatesEarned'] as int? ?? 0,
      );
    } catch (e) {
      print('Error updating user properties from Firestore: $e');
    }
  }

  // ===== COURSE EVENTS =====

  /// Track course viewed
  Future<void> trackCourseViewed({
    required String courseId,
    required String courseTitle,
    required String category,
    required double price,
    String? instructor,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'course_viewed',
        parameters: {
          'course_id': courseId,
          'course_title': courseTitle,
          'course_category': category,
          'course_price': price,
          if (instructor != null) 'instructor': instructor,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking course viewed: $e');
    }
  }

  /// Track course purchased
  Future<void> trackCoursePurchased({
    required String courseId,
    required String courseTitle,
    required double amount,
    required String currency,
    String? couponCode,
    double? discountAmount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'course_purchased',
        parameters: {
          'course_id': courseId,
          'course_title': courseTitle,
          'amount': amount,
          'currency': currency,
          if (couponCode != null) 'coupon_code': couponCode,
          if (discountAmount != null) 'discount_amount': discountAmount,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Update user properties
      await _updateCourseEnrollmentCount();
    } catch (e) {
      print('Error tracking course purchased: $e');
    }
  }

  /// Track course enrollment
  Future<void> trackCourseEnrolled({
    required String courseId,
    required String courseTitle,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'course_enrolled',
        parameters: {
          'course_id': courseId,
          'course_title': courseTitle,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking course enrolled: $e');
    }
  }

  /// Track course completion
  Future<void> trackCourseCompleted({
    required String courseId,
    required String courseTitle,
    required double completionPercentage,
    required int timeSpent,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'course_completed',
        parameters: {
          'course_id': courseId,
          'course_title': courseTitle,
          'completion_percentage': completionPercentage,
          'time_spent_minutes': timeSpent,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Update user properties
      await _updateCourseCompletionCount();
    } catch (e) {
      print('Error tracking course completed: $e');
    }
  }

  // ===== VIDEO EVENTS =====

  /// Track video started
  Future<void> trackVideoStarted({
    required String courseId,
    required String moduleId,
    required String videoTitle,
    required int videoDuration,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'video_started',
        parameters: {
          'course_id': courseId,
          'module_id': moduleId,
          'video_title': videoTitle,
          'video_duration': videoDuration,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking video started: $e');
    }
  }

  /// Track video completed
  Future<void> trackVideoCompleted({
    required String courseId,
    required String moduleId,
    required String videoTitle,
    required int videoDuration,
    required int watchTime,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'video_completed',
        parameters: {
          'course_id': courseId,
          'module_id': moduleId,
          'video_title': videoTitle,
          'video_duration': videoDuration,
          'watch_time': watchTime,
          'completion_rate': (watchTime / videoDuration) * 100,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking video completed: $e');
    }
  }

  /// Track video paused
  Future<void> trackVideoPaused({
    required String courseId,
    required String moduleId,
    required String videoTitle,
    required int currentPosition,
    required int totalDuration,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'video_paused',
        parameters: {
          'course_id': courseId,
          'module_id': moduleId,
          'video_title': videoTitle,
          'current_position': currentPosition,
          'total_duration': totalDuration,
          'progress_percentage': (currentPosition / totalDuration) * 100,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking video paused: $e');
    }
  }

  // ===== CERTIFICATE EVENTS =====

  /// Track certificate downloaded
  Future<void> trackCertificateDownloaded({
    required String certificateId,
    required String courseId,
    required String courseTitle,
    required double finalScore,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'certificate_downloaded',
        parameters: {
          'certificate_id': certificateId,
          'course_id': courseId,
          'course_title': courseTitle,
          'final_score': finalScore,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Update user properties
      await _updateCertificateCount();
    } catch (e) {
      print('Error tracking certificate downloaded: $e');
    }
  }

  /// Track certificate shared
  Future<void> trackCertificateShared({
    required String certificateId,
    required String courseId,
    required String courseTitle,
    String? shareMethod,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'certificate_shared',
        parameters: {
          'certificate_id': certificateId,
          'course_id': courseId,
          'course_title': courseTitle,
          if (shareMethod != null) 'share_method': shareMethod,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking certificate shared: $e');
    }
  }

  // ===== PAYMENT EVENTS =====

  /// Track payment initiated
  Future<void> trackPaymentInitiated({
    required String courseId,
    required String courseTitle,
    required double amount,
    required String currency,
    String? paymentMethod,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'payment_initiated',
        parameters: {
          'course_id': courseId,
          'course_title': courseTitle,
          'amount': amount,
          'currency': currency,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking payment initiated: $e');
    }
  }

  /// Track payment completed
  Future<void> trackPaymentCompleted({
    required String courseId,
    required String courseTitle,
    required double amount,
    required String currency,
    required String paymentId,
    String? paymentMethod,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'payment_completed',
        parameters: {
          'course_id': courseId,
          'course_title': courseTitle,
          'amount': amount,
          'currency': currency,
          'payment_id': paymentId,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking payment completed: $e');
    }
  }

  /// Track payment failed
  Future<void> trackPaymentFailed({
    required String courseId,
    required String courseTitle,
    required double amount,
    required String currency,
    required String errorCode,
    String? errorMessage,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'payment_failed',
        parameters: {
          'course_id': courseId,
          'course_title': courseTitle,
          'amount': amount,
          'currency': currency,
          'error_code': errorCode,
          if (errorMessage != null) 'error_message': errorMessage,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking payment failed: $e');
    }
  }

  // ===== SEARCH EVENTS =====

  /// Track search performed
  Future<void> trackSearchPerformed({
    required String searchQuery,
    String? category,
    int? resultCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'search_performed',
        parameters: {
          'search_query': searchQuery,
          if (category != null) 'category': category,
          if (resultCount != null) 'result_count': resultCount,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking search performed: $e');
    }
  }

  /// Track filter applied
  Future<void> trackFilterApplied({
    required String filterType,
    required String filterValue,
    int? resultCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'filter_applied',
        parameters: {
          'filter_type': filterType,
          'filter_value': filterValue,
          if (resultCount != null) 'result_count': resultCount,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking filter applied: $e');
    }
  }

  // ===== APP EVENTS =====

  /// Track app opened
  Future<void> trackAppOpened() async {
    try {
      await _analytics.logEvent(
        name: 'app_opened',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking app opened: $e');
    }
  }

  /// Track screen viewed
  Future<void> trackScreenViewed({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'screen_view',
        parameters: {
          'screen_name': screenName,
          if (screenClass != null) 'screen_class': screenClass,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking screen viewed: $e');
    }
  }

  /// Track user engagement
  Future<void> trackUserEngagement({
    required String engagementType,
    required int duration,
    String? contentId,
    String? contentType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_engagement',
        parameters: {
          'engagement_type': engagementType,
          'duration_seconds': duration,
          if (contentId != null) 'content_id': contentId,
          if (contentType != null) 'content_type': contentType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking user engagement: $e');
    }
  }

  // ===== HELPER METHODS =====

  /// Update course enrollment count in user properties
  Future<void> _updateCourseEnrollmentCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .get();

      await _analytics.setUserProperty(
        name: 'courses_enrolled',
        value: enrollmentsSnapshot.docs.length.toString(),
      );
    } catch (e) {
      print('Error updating course enrollment count: $e');
    }
  }

  /// Update course completion count in user properties
  Future<void> _updateCourseCompletionCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      await _analytics.setUserProperty(
        name: 'courses_completed',
        value: enrollmentsSnapshot.docs.length.toString(),
      );
    } catch (e) {
      print('Error updating course completion count: $e');
    }
  }

  /// Update certificate count in user properties
  Future<void> _updateCertificateCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final certificatesSnapshot = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: user.uid)
          .get();

      await _analytics.setUserProperty(
        name: 'certificates_earned',
        value: certificatesSnapshot.docs.length.toString(),
      );
    } catch (e) {
      print('Error updating certificate count: $e');
    }
  }

  // ===== CUSTOM EVENTS =====

  /// Track custom event
  Future<void> trackCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final eventParams = <String, dynamic>{
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (parameters != null) {
        eventParams.addAll(parameters);
      }

      await _analytics.logEvent(
        name: eventName,
        parameters: eventParams as Map<String, Object>?,
      );
    } catch (e) {
      print('Error tracking custom event: $e');
    }
  }

  // ===== CONVERSION EVENTS =====

  /// Track conversion event
  Future<void> trackConversion({
    required String conversionType,
    required double value,
    String? currency,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final eventParams = <String, dynamic>{
        'conversion_type': conversionType,
        'value': value,
        if (currency != null) 'currency': currency,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (parameters != null) {
        eventParams.addAll(parameters);
      }

      await _analytics.logEvent(
        name: 'conversion',
        parameters: eventParams as Map<String, Object>?,
      );
    } catch (e) {
      print('Error tracking conversion: $e');
    }
  }
}
