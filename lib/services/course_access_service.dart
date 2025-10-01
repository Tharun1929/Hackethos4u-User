import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class CourseAccessService {
  static final CourseAccessService _instance = CourseAccessService._internal();
  factory CourseAccessService() => _instance;
  CourseAccessService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _fs = FirestoreService();

  // Check if user has access to a course
  Future<bool> hasCourseAccess(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check enrollment
      final enrollmentDoc = await _firestore
          .collection('enrollments')
          .doc('${user.uid}_$courseId')
          .get();

      if (!enrollmentDoc.exists) return false;

      final enrollmentData = enrollmentDoc.data()!;

      // Check if enrollment is active
      final isActive = enrollmentData['isActive'] ?? false;
      if (!isActive) return false;

      // Check access period (90 days)
      final enrolledAt = enrollmentData['enrolledAt']?.toDate();
      if (enrolledAt != null) {
        final accessExpiry = enrolledAt.add(const Duration(days: 90));
        if (DateTime.now().isAfter(accessExpiry)) {
          // Access expired, update enrollment status
          await _firestore
              .collection('enrollments')
              .doc('${user.uid}_$courseId')
              .update({
            'isActive': false,
            'accessExpired': true,
            'expiredAt': FieldValue.serverTimestamp(),
          });
          return false;
        }
      }

      return true;
    } catch (e) {
      // print('Error checking course access: $e');
      return false;
    }
  }

  // Check if user has access to a specific lesson
  Future<bool> hasLessonAccess(String courseId, String lessonId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // First check if user has course access
      final hasCourseAccess = await this.hasCourseAccess(courseId);
      if (!hasCourseAccess) return false;

      // Get course data to check lesson prerequisites
      final courseData = await _getCourseData(courseId);
      if (courseData == null) return false;

      // Find the lesson and check if it's unlocked
      for (final module in courseData['modules'] as List<dynamic>) {
        final lessons = module['lessons'] as List<dynamic>? ?? module['submodules'] as List<dynamic>? ?? [];
        for (final lesson in lessons) {
          if (lesson['id'] == lessonId) {
            return lesson['isUnlocked'] == true;
          }
        }
      }

      return false;
    } catch (e) {
      // print('Error checking lesson access: $e');
      return false;
    }
  }

  // Enroll user in course (after payment)
  Future<bool> enrollUserInCourse({
    required String courseId,
    required String courseTitle,
    required double amount,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Create enrollment record
      await _firestore
          .collection('enrollments')
          .doc('${user.uid}_$courseId')
          .set({
        'userId': user.uid,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'enrolledAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'accessExpiry': DateTime.now().add(const Duration(days: 90)),
        'paymentAmount': amount,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'progress': 0.0,
        'completedLessons': [],
        'lastAccessed': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Unlock first module and first lesson
      await _unlockCourseContent(user.uid, courseId);

      // Update user stats
      await _firestore.collection('users').doc(user.uid).update({
        'stats.enrolledCourses': FieldValue.increment(1),
        'stats.totalSpent': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      // print('Error enrolling user in course: $e');
      return false;
    }
  }

  // Unlock course content progressively
  Future<void> _unlockCourseContent(String userId, String courseId) async {
    try {
      // Get course data
      final courseData = await _getCourseData(courseId);
      if (courseData == null) return;

      // Unlock first module and first lesson
      final modules = courseData['modules'] as List<dynamic>;
      if (modules.isNotEmpty) {
        final firstModule = modules[0];
        final lessons = firstModule['lessons'] as List<dynamic>;

        if (lessons.isNotEmpty) {
          // Unlock first lesson
          await _firestore
              .collection('user_progress')
              .doc(userId)
              .collection('courses')
              .doc(courseId)
              .set({
            'courseId': courseId,
            'unlockedModules': [firstModule['id']],
            'unlockedLessons': [lessons[0]['id']],
            'currentModule': firstModule['id'],
            'currentLesson': lessons[0]['id'],
            'progress': 0.0,
            'lastAccessed': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      // print('Error unlocking course content: $e');
    }
  }

  // Unlock next lesson when current lesson is completed
  Future<void> unlockNextLesson(
      String courseId, String completedLessonId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get course data
      final courseData = await _getCourseData(courseId);
      if (courseData == null) return;

      // Find next lesson to unlock
      String? nextLessonId;
      String? nextModuleId;

      final modules = courseData['modules'] as List<dynamic>;
      bool foundCompleted = false;

      for (final module in modules) {
        final lessons = module['lessons'] as List<dynamic>;

        for (int i = 0; i < lessons.length; i++) {
          if (foundCompleted && i < lessons.length) {
            nextLessonId = lessons[i]['id'];
            nextModuleId = module['id'];
            break;
          }

          if (lessons[i]['id'] == completedLessonId) {
            foundCompleted = true;
            if (i + 1 < lessons.length) {
              nextLessonId = lessons[i + 1]['id'];
              nextModuleId = module['id'];
              break;
            }
          }
        }

        if (nextLessonId != null) break;
      }

      // If no next lesson in current module, unlock first lesson of next module
      if (nextLessonId == null) {
        for (int i = 0; i < modules.length; i++) {
          final module = modules[i];
          final lessons = module['lessons'] as List<dynamic>;

          if (lessons.isNotEmpty) {
            bool isCurrentModule = false;
            for (final lesson in lessons) {
              if (lesson['id'] == completedLessonId) {
                isCurrentModule = true;
                break;
              }
            }

            if (isCurrentModule && i + 1 < modules.length) {
              final nextModule = modules[i + 1];
              final nextModuleLessons = nextModule['lessons'] as List<dynamic>;
              if (nextModuleLessons.isNotEmpty) {
                nextLessonId = nextModuleLessons[0]['id'];
                nextModuleId = nextModule['id'];
                break;
              }
            }
          }
        }
      }

      // Update user progress with next lesson
      if (nextLessonId != null && nextModuleId != null) {
        await _firestore
            .collection('user_progress')
            .doc(user.uid)
            .collection('courses')
            .doc(courseId)
            .update({
          'unlockedLessons': FieldValue.arrayUnion([nextLessonId]),
          'unlockedModules': FieldValue.arrayUnion([nextModuleId]),
          'currentLesson': nextLessonId,
          'currentModule': nextModuleId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // print('Error unlocking next lesson: $e');
    }
  }

  // Get course data from Firestore
  Future<Map<String, dynamic>?> _getCourseData(String courseId) async {
    try {
      return await _fs.getCourseById(courseId);
    } catch (e) {
      // print('Error getting course data: $e');
      return null;
    }
  }

  // Check if course access has expired
  Future<bool> isCourseAccessExpired(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return true;

      final enrollmentDoc = await _firestore
          .collection('enrollments')
          .doc('${user.uid}_$courseId')
          .get();

      if (!enrollmentDoc.exists) return true;

      final enrollmentData = enrollmentDoc.data()!;
      final enrolledAt = enrollmentData['enrolledAt']?.toDate();

      if (enrolledAt != null) {
        final accessExpiry = enrolledAt.add(const Duration(days: 90));
        return DateTime.now().isAfter(accessExpiry);
      }

      return true;
    } catch (e) {
      // print('Error checking course access expiry: $e');
      return true;
    }
  }

  // Get user's enrolled courses
  Future<List<Map<String, dynamic>>> getUserEnrolledCourses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('enrolledAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      // print('Error getting user enrolled courses: $e');
      return [];
    }
  }

  // Get course enrollment status
  Future<Map<String, dynamic>?> getCourseEnrollmentStatus(
      String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final enrollmentDoc = await _firestore
          .collection('enrollments')
          .doc('${user.uid}_$courseId')
          .get();

      if (!enrollmentDoc.exists) return null;

      return {
        'id': enrollmentDoc.id,
        ...enrollmentDoc.data()!,
      };
    } catch (e) {
      // print('Error getting course enrollment status: $e');
      return null;
    }
  }
}
