import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Stream controllers for real-time updates
  final StreamController<Map<String, dynamic>> _courseUpdateController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _progressUpdateController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _analyticsController =
      StreamController.broadcast();

  // Streams for UI updates
  Stream<Map<String, dynamic>> get courseUpdates =>
      _courseUpdateController.stream;
  Stream<Map<String, dynamic>> get progressUpdates =>
      _progressUpdateController.stream;
  Stream<Map<String, dynamic>> get notificationUpdates =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get analyticsUpdates =>
      _analyticsController.stream;

  // Collection references
  CollectionReference get coursesCollection => _firestore.collection('courses');
  CollectionReference get enrollmentsCollection =>
      _firestore.collection('enrollments');
  CollectionReference get userProgressCollection =>
      _firestore.collection('user_progress');
  CollectionReference get userNotificationsCollection =>
      _firestore.collection('user_notifications');
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get analyticsCollection =>
      _firestore.collection('analytics');

  // Initialize data synchronization
  Future<void> initialize() async {
    try {
      // Set up real-time listeners
      await _setupCourseListeners();
      await _setupProgressListeners();
      await _setupNotificationListeners();
      await _setupAnalyticsListeners();

      // Initialize FCM for notifications
      await _initializeFCM();

      // print('Data sync service initialized successfully');
    } catch (e) {
      // print('Error initializing data sync service: $e');
    }
  }

  // ===== COURSE SYNCHRONIZATION =====

  Future<void> _setupCourseListeners() async {
    // Listen for course updates
    coursesCollection
        .where('published', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final courseData = change.doc.data() as Map<String, dynamic>;
        final courseId = change.doc.id;

        switch (change.type) {
          case DocumentChangeType.added:
            _courseUpdateController.add({
              'type': 'course_added',
              'courseId': courseId,
              'data': courseData,
            });
            break;
          case DocumentChangeType.modified:
            _courseUpdateController.add({
              'type': 'course_updated',
              'courseId': courseId,
              'data': courseData,
            });
            break;
          case DocumentChangeType.removed:
            _courseUpdateController.add({
              'type': 'course_removed',
              'courseId': courseId,
            });
            break;
        }
      }
    });
  }

  // Get course with proper field mapping
  Future<Map<String, dynamic>?> getCourseById(String courseId) async {
    try {
      final doc = await coursesCollection.doc(courseId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapCourseDataForUserApp(data, courseId);
      }
      return null;
    } catch (e) {
      // print('Error getting course: $e');
      return null;
    }
  }

  // Map admin course data to user app format
  Map<String, dynamic> _mapCourseDataForUserApp(
      Map<String, dynamic> adminData, String courseId) {
    return {
      'id': courseId,
      'title': adminData['title'] ?? '',
      'courseName': adminData['title'] ?? '', // For compatibility
      'shortDesc': adminData['shortDesc'] ?? '',
      'description': adminData['longDesc'] ?? adminData['description'] ?? '',
      'category': adminData['category'] ?? '',
      'instructor': {
        'name': adminData['instructor'] ?? 'Unknown Instructor',
        'title': adminData['instructorTitle'] ?? 'Course Instructor',
        'avatar': adminData['instructorAvatar'] ?? '',
        'bio': adminData['instructorBio'] ?? '',
      },
      // Prefer uploaded URL; avoid asset fallback for web 404s
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
      'modules': _mapModulesForUserApp(adminData['modules'] ?? []),
      'sections': _mapModulesForUserApp(adminData['modules'] ?? []),
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

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) {
      return double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  int _calculateTotalVideos(List<dynamic>? modules) {
    if (modules == null) return 0;
    int total = 0;
    for (final module in modules) {
      if (module is Map<String, dynamic>) {
        final submodules = module['submodules'] as List<dynamic>? ?? [];
        total += submodules.length;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> _mapModulesForUserApp(List<dynamic> modules) {
    return modules.map<Map<String, dynamic>>((module) {
      if (module is Map<String, dynamic>) {
        return {
          'title': module['title'] ?? '',
          'desc': module['desc'] ?? '',
          'submodules':
              (module['submodules'] as List<dynamic>? ?? []).map((submodule) {
            if (submodule is Map<String, dynamic>) {
              return {
                'title': submodule['title'] ?? '',
                'desc': submodule['desc'] ?? '',
                'videoUrl': submodule['videoUrl'] ?? '',
                'duration': submodule['duration'] ?? '',
                'type': submodule['type'] ?? 'video',
              };
            }
            return <String, dynamic>{};
          }).toList(),
          'moduleMcqs': module['moduleMcqs'] ?? [],
        };
      }
      return <String, dynamic>{};
    }).toList();
  }

  bool _isNewCourse(String? createdAt) {
    if (createdAt == null) return false;
    try {
      final createdDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      return now.difference(createdDate).inDays < 30;
    } catch (e) {
      return false;
    }
  }

  // ===== PROGRESS SYNCHRONIZATION =====

  Future<void> _setupProgressListeners() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen for user progress updates
    userProgressCollection
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final progressData = change.doc.data() as Map<String, dynamic>;
        final progressId = change.doc.id;

        _progressUpdateController.add({
          'type': 'progress_updated',
          'progressId': progressId,
          'data': progressData,
        });
      }
    });

    // Listen for enrollment updates
    enrollmentsCollection
        .where('studentEmail', isEqualTo: user.email)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final enrollmentData = change.doc.data() as Map<String, dynamic>;
        final enrollmentId = change.doc.id;

        _progressUpdateController.add({
          'type': 'enrollment_updated',
          'enrollmentId': enrollmentId,
          'data': enrollmentData,
        });
      }
    });
  }

  // Update user progress with admin app compatibility
  Future<void> updateUserProgress({
    required String courseId,
    required String lessonId,
    required double progress,
    required bool isCompleted,
    required int timeSpent,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final progressData = {
        'userId': user.uid,
        'userEmail': user.email,
        'courseId': courseId,
        'lessonId': lessonId,
        'progress': progress,
        'isCompleted': isCompleted,
        'timeSpent': timeSpent,
        'lastAccessed': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update in user_progress collection
      await userProgressCollection
          .doc('${user.uid}_${courseId}_$lessonId')
          .set(progressData, SetOptions(merge: true));

      // Update enrollment progress for admin app
      await _updateEnrollmentProgress(courseId, progress, isCompleted);

      // Update user analytics
      await _updateUserAnalytics(courseId, timeSpent, isCompleted);

      // Send progress update to admin app
      _progressUpdateController.add({
        'type': 'progress_synced',
        'courseId': courseId,
        'lessonId': lessonId,
        'progress': progress,
        'isCompleted': isCompleted,
      });
    } catch (e) {
      // print('Error updating user progress: $e');
    }
  }

  Future<void> _updateEnrollmentProgress(
      String courseId, double progress, bool isCompleted) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Find enrollment
      final enrollmentQuery = await enrollmentsCollection
          .where('studentEmail', isEqualTo: user.email)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (enrollmentQuery.docs.isNotEmpty) {
        final enrollmentDoc = enrollmentQuery.docs.first;
        final enrollmentData = enrollmentDoc.data() as Map<String, dynamic>;

        // Calculate overall progress
        final lessons = enrollmentData['lessons'] as List<dynamic>? ?? [];
        double totalProgress = 0.0;
        int completedLessons = 0;

        for (final lesson in lessons) {
          if (lesson is Map<String, dynamic>) {
            totalProgress += lesson['watchPercent'] ?? 0.0;
            if (lesson['isCompleted'] == true) {
              completedLessons++;
            }
          }
        }

        final overallProgress =
            lessons.isNotEmpty ? totalProgress / lessons.length : 0.0;

        // Update enrollment
        await enrollmentDoc.reference.update({
          'progressPercent': overallProgress,
          'enrollmentStatus': overallProgress >= 100 ? 'Completed' : 'Active',
          'certificateStatus':
              overallProgress >= 70 ? 'Eligible' : 'Not Issued',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // print('Error updating enrollment progress: $e');
    }
  }

  Future<void> _updateUserAnalytics(
      String courseId, int timeSpent, bool isCompleted) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await usersCollection.doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final stats = userData['stats'] as Map<String, dynamic>? ?? {};

        final updatedStats = {
          'totalTimeSpent': (stats['totalTimeSpent'] ?? 0) + timeSpent,
          'totalLessonsCompleted':
              (stats['totalLessonsCompleted'] ?? 0) + (isCompleted ? 1 : 0),
          'lastLearningDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await usersCollection.doc(user.uid).update({
          'stats': {...stats, ...updatedStats},
        });
      }
    } catch (e) {
      // print('Error updating user analytics: $e');
    }
  }

  // ===== NOTIFICATION SYNCHRONIZATION =====

  Future<void> _setupNotificationListeners() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen for user notifications
    userNotificationsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final notificationData = change.doc.data() as Map<String, dynamic>;
        final notificationId = change.doc.id;

        _notificationController.add({
          'type': 'notification_updated',
          'notificationId': notificationId,
          'data': notificationData,
        });
      }
    });
  }

  Future<void> _initializeFCM() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          await _saveFCMToken(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((token) {
          _saveFCMToken(token);
        });

        // Set up message handlers
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleForegroundMessage(message);
        });

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
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('user_tokens').doc(user.uid).set({
        'userId': user.uid,
        'email': user.email,
        'fcmToken': token,
        'platform': 'flutter',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // print('Received foreground message: ${message.data}');

    // Add to local notifications
    _notificationController.add({
      'type': 'new_notification',
      'data': {
        'title': message.notification?.title ?? 'EduTiv',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'createdAt': DateTime.now().toIso8601String(),
      },
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    // print('Notification tapped: ${message.data}');

    // Handle navigation based on notification type
    final data = message.data;
    switch (data['type']) {
      case 'course_update':
        // Navigate to course details
        break;
      case 'new_lesson':
        // Navigate to lesson
        break;
      case 'certificate_ready':
        // Navigate to certificates
        break;
      default:
        // Default navigation
        break;
    }
  }

  // ===== ANALYTICS SYNCHRONIZATION =====

  Future<void> _setupAnalyticsListeners() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen for user analytics updates
    usersCollection.doc(user.uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        final stats = userData['stats'] as Map<String, dynamic>? ?? {};

        _analyticsController.add({
          'type': 'analytics_updated',
          'data': stats,
        });
      }
    });
  }

  // Get user analytics with admin app compatibility
  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userDoc = await usersCollection.doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final stats = userData['stats'] as Map<String, dynamic>? ?? {};

        return {
          'totalCoursesEnrolled': stats['totalCoursesEnrolled'] ?? 0,
          'totalCoursesCompleted': stats['totalCoursesCompleted'] ?? 0,
          'totalLessonsCompleted': stats['totalLessonsCompleted'] ?? 0,
          'totalTimeSpent': stats['totalTimeSpent'] ?? 0,
          'currentStreak': stats['currentStreak'] ?? 0,
          'longestStreak': stats['longestStreak'] ?? 0,
          'lastLearningDate': stats['lastLearningDate'],
          'averageScore': stats['averageScore'] ?? 0.0,
          'certificatesEarned': stats['certificatesEarned'] ?? 0,
          'achievements': stats['achievements'] ?? [],
          'categoryProgress': stats['categoryProgress'] ?? {},
        };
      }
      return {};
    } catch (e) {
      // print('Error getting user analytics: $e');
      return {};
    }
  }

  // Update user analytics
  Future<void> updateUserAnalytics(Map<String, dynamic> analytics) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await usersCollection.doc(user.uid).update({
        'stats': analytics,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send analytics update
      _analyticsController.add({
        'type': 'analytics_synced',
        'data': analytics,
      });
    } catch (e) {
      // print('Error updating user analytics: $e');
    }
  }

  // ===== UTILITY METHODS =====

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await userNotificationsCollection.doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final querySnapshot = await userNotificationsCollection
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      // print('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Sync user profile with admin app
  Future<void> syncUserProfile(Map<String, dynamic> profileData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await usersCollection.doc(user.uid).set({
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // print('Error syncing user profile: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _courseUpdateController.close();
    _progressUpdateController.close();
    _notificationController.close();
    _analyticsController.close();
  }
}
