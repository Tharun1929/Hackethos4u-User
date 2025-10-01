import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

class AdminUserBridgeService {
  static final AdminUserBridgeService _instance =
      AdminUserBridgeService._internal();
  factory AdminUserBridgeService() => _instance;
  AdminUserBridgeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Stream controllers for real-time admin updates
  final StreamController<Map<String, dynamic>> _adminCourseUpdateController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _adminUserUpdateController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>>
      _adminEnrollmentUpdateController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _adminNotificationController =
      StreamController.broadcast();

  // Streams for UI updates
  Stream<Map<String, dynamic>> get adminCourseUpdates =>
      _adminCourseUpdateController.stream;
  Stream<Map<String, dynamic>> get adminUserUpdates =>
      _adminUserUpdateController.stream;
  Stream<Map<String, dynamic>> get adminEnrollmentUpdates =>
      _adminEnrollmentUpdateController.stream;
  Stream<Map<String, dynamic>> get adminNotifications =>
      _adminNotificationController.stream;

  // Collection references (same as admin app)
  CollectionReference get coursesCollection => _firestore.collection('courses');
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get enrollmentsCollection =>
      _firestore.collection('enrollments');
  CollectionReference get reviewsCollection => _firestore.collection('reviews');
  CollectionReference get qaCollection => _firestore.collection('qa');
  CollectionReference get settingsCollection =>
      _firestore.collection('settings');
  CollectionReference get couponsCollection => _firestore.collection('coupons');
  CollectionReference get userProgressCollection =>
      _firestore.collection('user_progress');
  CollectionReference get userNotificationsCollection =>
      _firestore.collection('user_notifications');

  // Initialize bridge service
  Future<void> initialize() async {
    try {
      // Set up real-time listeners for admin changes
      await _setupAdminCourseListeners();
      await _setupAdminUserListeners();
      await _setupAdminEnrollmentListeners();
      await _setupAdminNotificationListeners();

      // Initialize FCM for admin notifications
      await _initializeFCM();

      // print('Admin-User Bridge Service initialized successfully');
    } catch (e) {
      // print('Error initializing admin-user bridge service: $e');
    }
  }

  // ===== ADMIN COURSE LISTENERS =====

  Future<void> _setupAdminCourseListeners() async {
    // Listen for course updates from admin
    coursesCollection.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final courseData = change.doc.data() as Map<String, dynamic>;
        final courseId = change.doc.id;

        // Only process published courses for user app
        if (courseData['published'] == true) {
          switch (change.type) {
            case DocumentChangeType.added:
              _adminCourseUpdateController.add({
                'type': 'admin_course_added',
                'courseId': courseId,
                'data': _mapAdminCourseToUserFormat(courseData, courseId),
                'timestamp': DateTime.now().toIso8601String(),
              });
              break;
            case DocumentChangeType.modified:
              _adminCourseUpdateController.add({
                'type': 'admin_course_updated',
                'courseId': courseId,
                'data': _mapAdminCourseToUserFormat(courseData, courseId),
                'timestamp': DateTime.now().toIso8601String(),
              });
              break;
            case DocumentChangeType.removed:
              _adminCourseUpdateController.add({
                'type': 'admin_course_removed',
                'courseId': courseId,
                'timestamp': DateTime.now().toIso8601String(),
              });
              break;
          }
        }
      }
    });
  }

  // ===== ADMIN USER LISTENERS =====

  Future<void> _setupAdminUserListeners() async {
    // Listen for user updates from admin
    usersCollection.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final userData = change.doc.data() as Map<String, dynamic>;
        final userId = change.doc.id;

        // Only process current user updates
        if (_auth.currentUser?.uid == userId) {
          switch (change.type) {
            case DocumentChangeType.modified:
              _adminUserUpdateController.add({
                'type': 'admin_user_updated',
                'userId': userId,
                'data': _mapAdminUserToUserFormat(userData, userId),
                'timestamp': DateTime.now().toIso8601String(),
              });
              break;
            case DocumentChangeType.added:
            case DocumentChangeType.removed:
              // Handle added/removed cases if needed
              break;
          }
        }
      }
    });
  }

  // ===== ADMIN ENROLLMENT LISTENERS =====

  Future<void> _setupAdminEnrollmentListeners() async {
    // Listen for enrollment updates from admin
    enrollmentsCollection.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final enrollmentData = change.doc.data() as Map<String, dynamic>;
        final enrollmentId = change.doc.id;

        // Only process current user enrollments
        if (_auth.currentUser?.email == enrollmentData['studentEmail']) {
          switch (change.type) {
            case DocumentChangeType.added:
              _adminEnrollmentUpdateController.add({
                'type': 'admin_enrollment_added',
                'enrollmentId': enrollmentId,
                'data': _mapAdminEnrollmentToUserFormat(
                    enrollmentData, enrollmentId),
                'timestamp': DateTime.now().toIso8601String(),
              });
              break;
            case DocumentChangeType.modified:
              _adminEnrollmentUpdateController.add({
                'type': 'admin_enrollment_updated',
                'enrollmentId': enrollmentId,
                'data': _mapAdminEnrollmentToUserFormat(
                    enrollmentData, enrollmentId),
                'timestamp': DateTime.now().toIso8601String(),
              });
              break;
            case DocumentChangeType.removed:
              _adminEnrollmentUpdateController.add({
                'type': 'admin_enrollment_removed',
                'enrollmentId': enrollmentId,
                'timestamp': DateTime.now().toIso8601String(),
              });
              break;
          }
        }
      }
    });
  }

  // ===== ADMIN NOTIFICATION LISTENERS =====

  Future<void> _setupAdminNotificationListeners() async {
    // Listen for admin notifications
    userNotificationsCollection
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final notificationData = change.doc.data() as Map<String, dynamic>;
        final notificationId = change.doc.id;

        switch (change.type) {
          case DocumentChangeType.added:
            _adminNotificationController.add({
              'type': 'admin_notification_added',
              'notificationId': notificationId,
              'data': notificationData,
              'timestamp': DateTime.now().toIso8601String(),
            });
            break;
          case DocumentChangeType.modified:
            _adminNotificationController.add({
              'type': 'admin_notification_updated',
              'notificationId': notificationId,
              'data': notificationData,
              'timestamp': DateTime.now().toIso8601String(),
            });
            break;
          case DocumentChangeType.removed:
            // Handle removed notifications if needed
            break;
        }
      }
    });
  }

  // ===== DATA MAPPING FUNCTIONS =====

  // Map admin course format to user app format
  Map<String, dynamic> _mapAdminCourseToUserFormat(
      Map<String, dynamic> adminData, String courseId) {
    return {
      'id': courseId,
      'title': adminData['title'] ?? '',
      'courseName': adminData['title'] ?? '',
      'shortDesc': adminData['shortDesc'] ?? '',
      'description': adminData['longDesc'] ?? adminData['description'] ?? '',
      'category': adminData['category'] ?? '',
      'instructor': {
        'name': adminData['instructor'] ?? 'Unknown Instructor',
        'title': adminData['instructorTitle'] ?? 'Course Instructor',
        'avatar': adminData['instructorAvatar'] ?? '',
        'bio': adminData['instructorBio'] ?? '',
      },
      'thumbnail': (adminData['thumbnail'] is String &&
              (adminData['thumbnail'] as String).isNotEmpty)
          ? adminData['thumbnail']
          : 'assets/default_pp.png',
      'courseImage': (adminData['thumbnail'] is String &&
              (adminData['thumbnail'] as String).isNotEmpty)
          ? adminData['thumbnail']
          : 'assets/default_pp.png',
      'price': _parsePrice(adminData['price']),
      'originalPrice':
          _parsePrice(adminData['originalPrice'] ?? adminData['price']),
      'rating': adminData['rating'] ?? 4.5,
      'totalRating': adminData['totalRating'] ?? 4.5,
      'reviewsCount': adminData['reviewsCount'] ?? 0,
      'studentsCount': adminData['studentsCount'] ?? 0,
      'students': adminData['studentsCount'] ?? 0,
      'duration': adminData['duration'] ?? '10 hours',
      'totalTime': adminData['duration'] ?? '10 hours',
      'totalVideo': _calculateTotalVideos(adminData['modules']),
      'level': adminData['level'] ?? 'Beginner',
      'language': adminData['language'] ?? 'English',
      'certificate': adminData['certificate'] ?? true,
      'lifetimeAccess': adminData['lifetimeAccess'] ?? true,
      'demoAvailable': adminData['demoAvailable'] ?? false,
      'demoVideo': adminData['demoVideo'] ?? '',
      'videoPreview': adminData['demoVideo'] ?? '',
      'modules': _mapAdminModulesToUserFormat(adminData['modules'] ?? []),
      'sections': _mapAdminModulesToUserFormat(adminData['modules'] ?? []),
      'whatYouLearn': adminData['whatYouLearn'] ?? [],
      'requirements': adminData['requirements'] ?? [],
      'tags': adminData['tags'] ?? [adminData['category'] ?? ''],
      'isNew': _isNewCourse(adminData['createdAt']),
      'isPopular': adminData['isPopular'] ?? true,
      'published': adminData['published'] ?? false,
      'createdAt': adminData['createdAt'],
      'updatedAt': adminData['updatedAt'],
      'access': adminData['access'] ?? 'Unlimited',
      'certificatePercent': adminData['certificatePercent'] ?? '70',
      'courseMcqs': adminData['courseMcqs'] ?? [],
    };
  }

  // Map admin user format to user app format
  Map<String, dynamic> _mapAdminUserToUserFormat(
      Map<String, dynamic> adminData, String userId) {
    return {
      'id': userId,
      'email': adminData['email'] ?? '',
      'name': adminData['name'] ?? '',
      'firstName': adminData['firstName'] ?? '',
      'lastName': adminData['lastName'] ?? '',
      'avatar': adminData['avatar'] ?? '',
      'role': adminData['role'] ?? 'student',
      'isActive': adminData['isActive'] ?? true,
      'createdAt': adminData['createdAt'],
      'updatedAt': adminData['updatedAt'],
      'profile': {
        'bio': adminData['bio'] ?? '',
        'phone': adminData['phone'] ?? '',
        'location': adminData['location'] ?? '',
        'website': adminData['website'] ?? '',
        'socialLinks': adminData['socialLinks'] ?? {},
      },
    };
  }

  // Map admin enrollment format to user app format
  Map<String, dynamic> _mapAdminEnrollmentToUserFormat(
      Map<String, dynamic> adminData, String enrollmentId) {
    return {
      'id': enrollmentId,
      'courseId': adminData['courseId'] ?? '',
      'userId': adminData['studentEmail'] ?? '',
      'enrolledAt': adminData['enrolledAt'],
      'progress': adminData['progress'] ?? 0.0,
      'completedLessons': adminData['completedLessons'] ?? 0,
      'totalLessons': adminData['totalLessons'] ?? 0,
      'timeSpent': adminData['timeSpent'] ?? 0,
      'lastAccessed': adminData['lastAccessed'],
      'certificateEarned': adminData['certificateEarned'] ?? false,
      'certificateIssuedAt': adminData['certificateIssuedAt'],
      'status': adminData['status'] ?? 'active',
    };
  }

  // Map admin modules format to user app format
  List<Map<String, dynamic>> _mapAdminModulesToUserFormat(
      List<dynamic> adminModules) {
    return adminModules.map<Map<String, dynamic>>((module) {
      return {
        'id': module['id'] ?? '',
        'title': module['title'] ?? '',
        'description': module['description'] ?? '',
        'lessons': (module['lessons'] as List<dynamic>?)
                ?.map<Map<String, dynamic>>((lesson) {
              return {
                'id': lesson['id'] ?? '',
                'title': lesson['title'] ?? '',
                'type': lesson['type'] ?? 'video',
                'duration': lesson['duration'] ?? '0',
                'videoUrl': lesson['videoUrl'] ?? '',
                'content': lesson['content'] ?? '',
                'isCompleted': lesson['isCompleted'] ?? false,
                'order': lesson['order'] ?? 0,
              };
            }).toList() ??
            [],
        'order': module['order'] ?? 0,
        'isUnlocked': module['isUnlocked'] ?? true,
      };
    }).toList();
  }

  // Helper functions
  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is int) return price.toDouble();
    if (price is double) return price;
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  int _calculateTotalVideos(List<dynamic> modules) {
    int total = 0;
    for (final module in modules) {
      final lessons = module['lessons'] as List<dynamic>? ?? [];
      for (final lesson in lessons) {
        if (lesson['type'] == 'video') total++;
      }
    }
    return total;
  }

  bool _isNewCourse(dynamic createdAt) {
    if (createdAt == null) return false;
    final created = createdAt is Timestamp
        ? createdAt.toDate()
        : DateTime.parse(createdAt.toString());
    final now = DateTime.now();
    return now.difference(created).inDays <= 30;
  }

  // ===== FCM INITIALIZATION =====

  Future<void> _initializeFCM() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          // Save token to user document for admin notifications
          await _saveFCMToken(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _saveFCMToken(newToken);
        });

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleForegroundMessage(message);
        });

        // Handle notification taps
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationTap(message);
        });
      }
    } catch (e) {
      // print('Error initializing FCM: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      if (_auth.currentUser != null) {
        await usersCollection.doc(_auth.currentUser!.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // print('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Handle foreground notification
    // print('Foreground message: ${message.notification?.title}');

    // You can show a local notification here
    // or update the UI directly
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Handle notification tap
    // print('Notification tapped: ${message.notification?.title}');

    // Navigate to appropriate screen based on notification data
    final data = message.data;
    if (data['type'] == 'course_update') {
      // Navigate to course detail
    } else if (data['type'] == 'enrollment_update') {
      // Navigate to course progress
    }
  }

  // ===== PUBLIC METHODS =====

  // Get real-time course updates
  Stream<Map<String, dynamic>> getCourseUpdates() {
    return adminCourseUpdates;
  }

  // Get real-time user updates
  Stream<Map<String, dynamic>> getUserUpdates() {
    return adminUserUpdates;
  }

  // Get real-time enrollment updates
  Stream<Map<String, dynamic>> getEnrollmentUpdates() {
    return adminEnrollmentUpdates;
  }

  // Get real-time notifications
  Stream<Map<String, dynamic>> getNotifications() {
    return adminNotifications;
  }

  // Send user progress update to admin
  Future<void> sendProgressUpdateToAdmin(
      Map<String, dynamic> progressData) async {
    try {
      await userProgressCollection.add({
        ...progressData,
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'user_app',
      });
    } catch (e) {
      // print('Error sending progress update to admin: $e');
    }
  }

  // Send user feedback to admin
  Future<void> sendFeedbackToAdmin(Map<String, dynamic> feedbackData) async {
    try {
      await _firestore.collection('user_feedback').add({
        ...feedbackData,
        'userId': _auth.currentUser?.uid,
        'userEmail': _auth.currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'user_app',
      });
    } catch (e) {
      // print('Error sending feedback to admin: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _adminCourseUpdateController.close();
    _adminUserUpdateController.close();
    _adminEnrollmentUpdateController.close();
    _adminNotificationController.close();
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // print('Background message: ${message.notification?.title}');
  // Handle background messages here
}
