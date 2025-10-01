import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Real-time synchronization service for keeping admin and user apps in sync
class RealTimeSyncService {
  static final RealTimeSyncService _instance = RealTimeSyncService._internal();
  factory RealTimeSyncService() => _instance;
  RealTimeSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _coursesSubscription;
  StreamSubscription<QuerySnapshot>? _enrollmentsSubscription;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  StreamSubscription<QuerySnapshot>? _assignmentsSubscription;

  // Callbacks
  Function(List<Map<String, dynamic>>)? _onCoursesUpdated;
  Function(List<Map<String, dynamic>>)? _onEnrollmentsUpdated;
  Function(List<Map<String, dynamic>>)? _onNotificationsUpdated;
  Function(List<Map<String, dynamic>>)? _onAssignmentsUpdated;

  bool _isInitialized = false;

  /// Initialize real-time synchronization
  Future<void> initialize({
    Function(List<Map<String, dynamic>>)? onCoursesUpdated,
    Function(List<Map<String, dynamic>>)? onEnrollmentsUpdated,
    Function(List<Map<String, dynamic>>)? onNotificationsUpdated,
    Function(List<Map<String, dynamic>>)? onAssignmentsUpdated,
  }) async {
    if (_isInitialized) return;

    _onCoursesUpdated = onCoursesUpdated;
    _onEnrollmentsUpdated = onEnrollmentsUpdated;
    _onNotificationsUpdated = onNotificationsUpdated;
    _onAssignmentsUpdated = onAssignmentsUpdated;

    // Start listening to real-time updates
    await _startCoursesListener();
    await _startEnrollmentsListener();
    await _startNotificationsListener();
    await _startAssignmentsListener();

    _isInitialized = true;
    // print('✅ RealTimeSyncService initialized successfully');
  }

  /// Start listening to courses updates
  Future<void> _startCoursesListener() async {
    try {
      _coursesSubscription =
          _firestore.collection('courses').snapshots().listen((snapshot) {
        final courses = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        // print('📚 Courses updated: ${courses.length} courses');
        _onCoursesUpdated?.call(courses);
      });

      // print('✅ Courses listener started');
    } catch (e) {
      // print('❌ Error starting courses listener: $e');
    }
  }

  /// Start listening to enrollments updates
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

  /// Start listening to notifications updates
  Future<void> _startNotificationsListener() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _notificationsSubscription = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        final notifications = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        // print('🔔 Notifications updated: ${notifications.length} notifications');
        _onNotificationsUpdated?.call(notifications);
      });

      // print('✅ Notifications listener started');
    } catch (e) {
      // print('❌ Error starting notifications listener: $e');
    }
  }

  /// Start listening to assignments updates
  Future<void> _startAssignmentsListener() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _assignmentsSubscription = _firestore
          .collection('assignments')
          .where('assignedTo', arrayContains: user.uid)
          .snapshots()
          .listen((snapshot) {
        final assignments = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        // print('📝 Assignments updated: ${assignments.length} assignments');
        _onAssignmentsUpdated?.call(assignments);
      });

      // print('✅ Assignments listener started');
    } catch (e) {
      // print('❌ Error starting assignments listener: $e');
    }
  }

  /// Sync course data between admin and user apps
  Future<void> syncCourseData(String courseId) async {
    try {
      // Get course from admin collection
      final adminCourseDoc =
          await _firestore.collection('admin_courses').doc(courseId).get();

      if (!adminCourseDoc.exists) {
        // print('❌ Course not found in admin collection: $courseId');
        return;
      }

      final adminCourseData = adminCourseDoc.data() as Map<String, dynamic>;

      // Update course in user collection
      await _firestore
          .collection('courses')
          .doc(courseId)
          .set(adminCourseData, SetOptions(merge: true));

      // print('✅ Course data synced: $courseId');
    } catch (e) {
      // print('❌ Error syncing course data: $e');
    }
  }

  /// Sync enrollment data
  Future<void> syncEnrollmentData(String enrollmentId) async {
    try {
      // Get enrollment from admin collection
      final adminEnrollmentDoc = await _firestore
          .collection('admin_enrollments')
          .doc(enrollmentId)
          .get();

      if (!adminEnrollmentDoc.exists) {
        // print('❌ Enrollment not found in admin collection: $enrollmentId');
        return;
      }

      final adminEnrollmentData =
          adminEnrollmentDoc.data() as Map<String, dynamic>;

      // Update enrollment in user collection
      await _firestore
          .collection('enrollments')
          .doc(enrollmentId)
          .set(adminEnrollmentData, SetOptions(merge: true));

      // print('✅ Enrollment data synced: $enrollmentId');
    } catch (e) {
      // print('❌ Error syncing enrollment data: $e');
    }
  }

  /// Force sync all data
  Future<void> forceSyncAllData() async {
    try {
      // print('🔄 Starting force sync of all data...');

      // Sync all courses
      final coursesSnapshot =
          await _firestore.collection('admin_courses').get();
      for (final doc in coursesSnapshot.docs) {
        await syncCourseData(doc.id);
      }

      // Sync all enrollments for current user
      final user = _auth.currentUser;
      if (user != null) {
        final enrollmentsSnapshot = await _firestore
            .collection('admin_enrollments')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (final doc in enrollmentsSnapshot.docs) {
          await syncEnrollmentData(doc.id);
        }
      }

      // print('✅ Force sync completed successfully');
    } catch (e) {
      // print('❌ Error during force sync: $e');
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final coursesCount = await _firestore
          .collection('courses')
          .get()
          .then((snapshot) => snapshot.docs.length);
      final enrollmentsCount = await _firestore
          .collection('enrollments')
          .get()
          .then((snapshot) => snapshot.docs.length);
      final notificationsCount = await _firestore
          .collection('notifications')
          .get()
          .then((snapshot) => snapshot.docs.length);
      final assignmentsCount = await _firestore
          .collection('assignments')
          .get()
          .then((snapshot) => snapshot.docs.length);

      return {
        'courses': coursesCount,
        'enrollments': enrollmentsCount,
        'notifications': notificationsCount,
        'assignments': assignmentsCount,
        'lastSync': DateTime.now().toIso8601String(),
        'isInitialized': _isInitialized,
      };
    } catch (e) {
      // print('❌ Error getting sync status: $e');
      return {
        'error': e.toString(),
        'isInitialized': _isInitialized,
      };
    }
  }

  /// Dispose resources
  void dispose() {
    _coursesSubscription?.cancel();
    _enrollmentsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _assignmentsSubscription?.cancel();
    _isInitialized = false;
    // print('✅ RealTimeSyncService disposed');
  }
}
