import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Comprehensive course enrollment management system
class EnrollmentManager {
  static final EnrollmentManager _instance = EnrollmentManager._internal();
  factory EnrollmentManager() => _instance;
  EnrollmentManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _enrollmentsSubscription;
  StreamSubscription<QuerySnapshot>? _progressSubscription;

  // Callbacks
  Function(List<Map<String, dynamic>>)? _onEnrollmentsUpdated;
  Function(List<Map<String, dynamic>>)? _onProgressUpdated;

  bool _isInitialized = false;

  /// Initialize enrollment manager
  Future<void> initialize({
    Function(List<Map<String, dynamic>>)? onEnrollmentsUpdated,
    Function(List<Map<String, dynamic>>)? onProgressUpdated,
  }) async {
    if (_isInitialized) return;

    _onEnrollmentsUpdated = onEnrollmentsUpdated;
    _onProgressUpdated = onProgressUpdated;

    // Start listening to real-time updates
    await _startEnrollmentsListener();
    await _startProgressListener();

    _isInitialized = true;
    // print('✅ EnrollmentManager initialized successfully');
  }

  /// Start listening to enrollments
  Future<void> _startEnrollmentsListener() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _enrollmentsSubscription = _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        final enrollments = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        // print('🎓 Enrollments updated: ${enrollments.length} enrollments');
        _onEnrollmentsUpdated?.call(enrollments);
      });

      // print('✅ Enrollments listener started');
    } catch (e) {
      // print('❌ Error starting enrollments listener: $e');
    }
  }

  /// Start listening to progress updates
  Future<void> _startProgressListener() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _progressSubscription = _firestore
          .collection('course_progress')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        final progress = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        // print('📊 Progress updated: ${progress.length} progress records');
        _onProgressUpdated?.call(progress);
      });

      // print('✅ Progress listener started');
    } catch (e) {
      // print('❌ Error starting progress listener: $e');
    }
  }

  /// Enroll in course
  Future<String?> enrollInCourse({
    required String courseId,
    required String courseTitle,
    required double coursePrice,
    String? paymentId,
    String? couponCode,
    double? discountAmount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if already enrolled
      final existingEnrollment =
          await _checkExistingEnrollment(courseId, user.uid);
      if (existingEnrollment != null) {
        // print('⚠️ User already enrolled in course: $courseId');
        return existingEnrollment;
      }

      // Get course details
      final courseDoc =
          await _firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) {
        throw Exception('Course not found');
      }

      final courseData = courseDoc.data() as Map<String, dynamic>;

      // Create enrollment record
      final enrollmentData = {
        'courseId': courseId,
        'courseTitle': courseTitle,
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'userName': user.displayName ?? 'Student',
        'enrolledAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'progress': 0.0,
        'completedLessons': 0,
        'totalLessons': courseData['totalLessons'] ?? 0,
        'timeSpent': 0, // in minutes
        'lastAccessed': FieldValue.serverTimestamp(),
        'certificateEarned': false,
        'certificateUrl': null,
        'paymentId': paymentId,
        'coursePrice': coursePrice,
        'discountAmount': discountAmount ?? 0.0,
        'couponCode': couponCode,
        'enrollmentType': paymentId != null ? 'paid' : 'free',
        'accessExpiresAt':
            DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef =
          await _firestore.collection('enrollments').add(enrollmentData);

      // Create initial progress record
      await _createInitialProgress(courseId, user.uid);

      // Update course enrollment count
      await _updateCourseEnrollmentCount(courseId);

      // Send notification
      await _sendEnrollmentNotification(user.uid, courseTitle);

      // print('✅ Course enrollment created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      // print('❌ Error enrolling in course: $e');
      return null;
    }
  }

  /// Check existing enrollment
  Future<String?> _checkExistingEnrollment(
      String courseId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      // print('❌ Error checking existing enrollment: $e');
      return null;
    }
  }

  /// Create initial progress record
  Future<void> _createInitialProgress(String courseId, String userId) async {
    try {
      final progressData = {
        'courseId': courseId,
        'userId': userId,
        'overallProgress': 0.0,
        'lessonsCompleted': 0,
        'totalLessons': 0,
        'timeSpent': 0,
        'lastLessonId': null,
        'lastAccessed': FieldValue.serverTimestamp(),
        'completedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('course_progress').add(progressData);
      // print('✅ Initial progress record created');
    } catch (e) {
      // print('❌ Error creating initial progress: $e');
    }
  }

  /// Update course enrollment count
  Future<void> _updateCourseEnrollmentCount(String courseId) async {
    try {
      final enrollmentCount = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('status', isEqualTo: 'active')
          .get()
          .then((snapshot) => snapshot.docs.length);

      await _firestore.collection('courses').doc(courseId).update({
        'enrollmentCount': enrollmentCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print('✅ Course enrollment count updated: $enrollmentCount');
    } catch (e) {
      // print('❌ Error updating course enrollment count: $e');
    }
  }

  /// Send enrollment notification
  Future<void> _sendEnrollmentNotification(
      String userId, String courseTitle) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Course Enrolled',
        'body': 'You have been enrolled in "$courseTitle"',
        'type': 'enrollment',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('❌ Error sending enrollment notification: $e');
    }
  }

  /// Check if user is enrolled
  Future<bool> isUserEnrolled(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // print('❌ Error checking enrollment status: $e');
      return false;
    }
  }

  /// Get user enrollments
  Future<List<Map<String, dynamic>>> getUserEnrollments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .orderBy('enrolledAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting user enrollments: $e');
      return [];
    }
  }

  /// Get enrollment details
  Future<Map<String, dynamic>?> getEnrollmentDetails(
      String enrollmentId) async {
    try {
      final doc =
          await _firestore.collection('enrollments').doc(enrollmentId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return {...data, 'id': doc.id};
    } catch (e) {
      // print('❌ Error getting enrollment details: $e');
      return null;
    }
  }

  /// Update course progress
  Future<bool> updateProgress({
    required String courseId,
    required String lessonId,
    required double progress,
    required int timeSpent, // in minutes
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update enrollment progress
      await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: user.uid)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final enrollmentId = snapshot.docs.first.id;
          _firestore.collection('enrollments').doc(enrollmentId).update({
            'progress': progress,
            'lastAccessed': FieldValue.serverTimestamp(),
            'timeSpent': FieldValue.increment(timeSpent),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Update course progress
      await _firestore
          .collection('course_progress')
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: user.uid)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final progressId = snapshot.docs.first.id;
          _firestore.collection('course_progress').doc(progressId).update({
            'overallProgress': progress,
            'lastLessonId': lessonId,
            'lastAccessed': FieldValue.serverTimestamp(),
            'timeSpent': FieldValue.increment(timeSpent),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Check if course is completed
      if (progress >= 100.0) {
        await _markCourseCompleted(courseId, user.uid);
      }

      // print('✅ Course progress updated: $progress%');
      return true;
    } catch (e) {
      // print('❌ Error updating course progress: $e');
      return false;
    }
  }

  /// Mark course as completed
  Future<void> _markCourseCompleted(String courseId, String userId) async {
    try {
      // Update enrollment status
      await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: userId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final enrollmentId = snapshot.docs.first.id;
          _firestore.collection('enrollments').doc(enrollmentId).update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Update course progress
      await _firestore
          .collection('course_progress')
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: userId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final progressId = snapshot.docs.first.id;
          _firestore.collection('course_progress').doc(progressId).update({
            'overallProgress': 100.0,
            'completedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Send completion notification
      await _sendCompletionNotification(userId, courseId);

      // print('✅ Course marked as completed: $courseId');
    } catch (e) {
      // print('❌ Error marking course as completed: $e');
    }
  }

  /// Send completion notification
  Future<void> _sendCompletionNotification(
      String userId, String courseId) async {
    try {
      // Get course title
      final courseDoc =
          await _firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) return;

      final courseData = courseDoc.data() as Map<String, dynamic>;
      final courseTitle = courseData['title'] ?? 'Course';

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Course Completed',
        'body': 'Congratulations! You have completed "$courseTitle"',
        'type': 'completion',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('❌ Error sending completion notification: $e');
    }
  }

  /// Get course progress
  Future<Map<String, dynamic>?> getCourseProgress(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('course_progress')
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return {...data, 'id': snapshot.docs.first.id};
      }
      return null;
    } catch (e) {
      // print('❌ Error getting course progress: $e');
      return null;
    }
  }

  /// Unenroll from course
  Future<bool> unenrollFromCourse(String enrollmentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get enrollment details
      final enrollmentDoc =
          await _firestore.collection('enrollments').doc(enrollmentId).get();
      if (!enrollmentDoc.exists) return false;

      final enrollmentData = enrollmentDoc.data() as Map<String, dynamic>;
      if (enrollmentData['userId'] != user.uid) {
        throw Exception('Not authorized to unenroll from this course');
      }

      // Update enrollment status
      await _firestore.collection('enrollments').doc(enrollmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update course enrollment count
      final courseId = enrollmentData['courseId'] as String;
      await _updateCourseEnrollmentCount(courseId);

      // print('✅ Unenrolled from course: $enrollmentId');
      return true;
    } catch (e) {
      // print('❌ Error unenrolling from course: $e');
      return false;
    }
  }

  /// Get enrollment statistics
  Future<Map<String, dynamic>> getEnrollmentStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .get();

      final totalEnrollments = enrollmentsSnapshot.docs.length;
      final activeEnrollments = enrollmentsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;
      final completedEnrollments = enrollmentsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      return {
        'totalEnrollments': totalEnrollments,
        'activeEnrollments': activeEnrollments,
        'completedEnrollments': completedEnrollments,
        'completionRate': totalEnrollments > 0
            ? (completedEnrollments / totalEnrollments * 100)
            : 0.0,
      };
    } catch (e) {
      // print('❌ Error getting enrollment stats: $e');
      return {};
    }
  }

  /// Dispose resources
  void dispose() {
    _enrollmentsSubscription?.cancel();
    _progressSubscription?.cancel();
    _isInitialized = false;
    // print('✅ EnrollmentManager disposed');
  }
}
