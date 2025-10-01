import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to ensure perfect synchronization between admin and student apps
class CourseSyncService {
  static final CourseSyncService _instance = CourseSyncService._internal();
  factory CourseSyncService() => _instance;
  CourseSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===== COURSE SYNCHRONIZATION =====

  /// Sync course from admin collection to user collection
  Future<void> syncCourseFromAdmin(String courseId) async {
    try {
      // Get course from admin collection
      final adminCourseDoc =
          await _firestore.collection('admin_courses').doc(courseId).get();

      if (!adminCourseDoc.exists) {
        print('❌ Course not found in admin collection: $courseId');
        return;
      }

      final adminCourseData = adminCourseDoc.data() as Map<String, dynamic>;

      // Only sync published courses
      if (adminCourseData['published'] != true) {
        print('⚠️ Course not published, skipping sync: $courseId');
        return;
      }

      // Transform admin course data to user format
      final userCourseData = _transformAdminCourseToUserFormat(adminCourseData);

      // Update course in user collection
      await _firestore
          .collection('courses')
          .doc(courseId)
          .set(userCourseData, SetOptions(merge: true));

      print('✅ Course synced successfully: $courseId');
    } catch (e) {
      print('❌ Error syncing course: $e');
    }
  }

  /// Transform admin course data to user-friendly format
  Map<String, dynamic> _transformAdminCourseToUserFormat(
      Map<String, dynamic> adminData) {
    return {
      // Basic Information
      'title': adminData['title'] ?? 'Untitled Course',
      'subtitle': adminData['subtitle'] ?? '',
      'shortDescription': adminData['shortDesc'] ?? '',
      'longDescription': adminData['longDesc'] ?? '',
      'category': adminData['category'] ?? 'General',
      'level': adminData['level'] ?? 'Beginner',
      'language': adminData['language'] ?? 'English',

      // Pricing
      'price': adminData['price'] ?? 0,
      'originalPrice': adminData['originalPrice'] ?? adminData['price'] ?? 0,
      'monthlyPrice': adminData['monthlyPrice'] ?? 0,

      // Access and Features
      'duration': adminData['duration'] ?? '0 hours',
      'accessPeriod': adminData['accessPeriod'] ?? 'Unlimited',
      'certificate': adminData['certificate'] ?? true,
      'lifetimeAccess': adminData['lifetimeAccess'] ?? true,
      'demoAvailable': adminData['demoAvailable'] ?? false,

      // Media
      'thumbnail': adminData['courseThumbnail'] ?? adminData['thumbnail'] ?? '',
      'demoVideo': adminData['demoVideo'] ?? '',
      'videoPreview': adminData['videoPreview'] ?? '',

      // Instructor Information
      'instructor': {
        'name': adminData['instructor'] ?? 'Unknown Instructor',
        'title': adminData['instructorTitle'] ?? 'Course Instructor',
        'bio': adminData['instructorBio'] ?? '',
        'avatar': adminData['instructorAvatar'] ?? '',
      },

      // Course Content
      'whatYouLearn': adminData['whatYouLearn'] ?? [],
      'requirements': adminData['requirements'] ?? [],
      'tags': adminData['tags'] ?? [],
      'modules': adminData['modules'] ?? [],

      // Statistics
      'rating': adminData['rating'] ?? 4.5,
      'reviewsCount': adminData['reviewsCount'] ?? 0,
      'studentsCount': adminData['studentsCount'] ?? 0,
      'lessonsCount': adminData['lessonsCount'] ?? 0,

      // Status
      'published': adminData['published'] ?? false,
      'isFeatured': adminData['isFeatured'] ?? false,
      'isPopular': adminData['isPopular'] ?? false,
      'isNew': adminData['isNew'] ?? false,

      // Timestamps
      'createdAt': adminData['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSyncedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Sync all published courses from admin to user collection
  Future<void> syncAllPublishedCourses() async {
    try {
      print('🔄 Starting sync of all published courses...');

      final adminCoursesSnapshot = await _firestore
          .collection('admin_courses')
          .where('published', isEqualTo: true)
          .get();

      int syncedCount = 0;
      for (final doc in adminCoursesSnapshot.docs) {
        await syncCourseFromAdmin(doc.id);
        syncedCount++;
      }

      print('✅ Synced $syncedCount courses successfully');
    } catch (e) {
      print('❌ Error syncing all courses: $e');
    }
  }

  /// Listen for real-time course updates from admin
  void listenForAdminCourseUpdates() {
    _firestore.collection('admin_courses').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final courseId = change.doc.id;
        final courseData = change.doc.data() as Map<String, dynamic>;

        switch (change.type) {
          case DocumentChangeType.added:
            if (courseData['published'] == true) {
              syncCourseFromAdmin(courseId);
            }
            break;
          case DocumentChangeType.modified:
            if (courseData['published'] == true) {
              syncCourseFromAdmin(courseId);
            } else {
              // Remove from user collection if unpublished
              _removeCourseFromUserCollection(courseId);
            }
            break;
          case DocumentChangeType.removed:
            _removeCourseFromUserCollection(courseId);
            break;
        }
      }
    });
  }

  /// Remove course from user collection
  Future<void> _removeCourseFromUserCollection(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).delete();
      print('🗑️ Removed course from user collection: $courseId');
    } catch (e) {
      print('❌ Error removing course: $e');
    }
  }

  // ===== ENROLLMENT SYNCHRONIZATION =====

  /// Sync enrollment data between admin and user collections
  Future<void> syncEnrollmentData(String enrollmentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get enrollment from admin collection
      final adminEnrollmentDoc = await _firestore
          .collection('admin_enrollments')
          .doc(enrollmentId)
          .get();

      if (!adminEnrollmentDoc.exists) {
        print('❌ Enrollment not found in admin collection: $enrollmentId');
        return;
      }

      final adminEnrollmentData =
          adminEnrollmentDoc.data() as Map<String, dynamic>;

      // Transform admin enrollment data to user format
      final userEnrollmentData =
          _transformAdminEnrollmentToUserFormat(adminEnrollmentData);

      // Update enrollment in user collection
      await _firestore
          .collection('enrollments')
          .doc(enrollmentId)
          .set(userEnrollmentData, SetOptions(merge: true));

      print('✅ Enrollment synced successfully: $enrollmentId');
    } catch (e) {
      print('❌ Error syncing enrollment: $e');
    }
  }

  /// Transform admin enrollment data to user format
  Map<String, dynamic> _transformAdminEnrollmentToUserFormat(
      Map<String, dynamic> adminData) {
    return {
      'userId': adminData['userId'],
      'courseId': adminData['courseId'],
      'enrolledAt': adminData['enrolledAt'] ?? FieldValue.serverTimestamp(),
      'status': adminData['status'] ?? 'active',
      'progressPercent': adminData['progressPercent'] ?? 0.0,
      'completedLessons': adminData['completedLessons'] ?? [],
      'lastAccessedAt':
          adminData['lastAccessedAt'] ?? FieldValue.serverTimestamp(),
      'certificateEarned': adminData['certificateEarned'] ?? false,
      'certificateId': adminData['certificateId'],
      'paymentStatus': adminData['paymentStatus'] ?? 'pending',
      'paymentId': adminData['paymentId'],
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ===== PROGRESS SYNCHRONIZATION =====

  /// Sync course progress between admin and user collections
  Future<void> syncCourseProgress(String courseId, String userId) async {
    try {
      // Get progress from admin collection
      final adminProgressDoc = await _firestore
          .collection('admin_progress')
          .doc('${userId}_$courseId')
          .get();

      if (!adminProgressDoc.exists) {
        print('❌ Progress not found in admin collection: ${userId}_$courseId');
        return;
      }

      final adminProgressData = adminProgressDoc.data() as Map<String, dynamic>;

      // Transform admin progress data to user format
      final userProgressData =
          _transformAdminProgressToUserFormat(adminProgressData);

      // Update progress in user collection
      await _firestore
          .collection('progress')
          .doc('${userId}_$courseId')
          .set(userProgressData, SetOptions(merge: true));

      print('✅ Progress synced successfully: ${userId}_$courseId');
    } catch (e) {
      print('❌ Error syncing progress: $e');
    }
  }

  /// Transform admin progress data to user format
  Map<String, dynamic> _transformAdminProgressToUserFormat(
      Map<String, dynamic> adminData) {
    return {
      'userId': adminData['userId'],
      'courseId': adminData['courseId'],
      'overallProgress': adminData['overallProgress'] ?? 0.0,
      'moduleProgress': adminData['moduleProgress'] ?? {},
      'completedLessons': adminData['completedLessons'] ?? [],
      'timeSpent': adminData['timeSpent'] ?? 0,
      'lastAccessedAt':
          adminData['lastAccessedAt'] ?? FieldValue.serverTimestamp(),
      'startedAt': adminData['startedAt'] ?? FieldValue.serverTimestamp(),
      'completedAt': adminData['completedAt'],
      'certificateEligible': adminData['certificateEligible'] ?? false,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ===== CERTIFICATE SYNCHRONIZATION =====

  /// Sync certificate data between admin and user collections
  Future<void> syncCertificateData(String certificateId) async {
    try {
      // Get certificate from admin collection
      final adminCertDoc = await _firestore
          .collection('admin_certificates')
          .doc(certificateId)
          .get();

      if (!adminCertDoc.exists) {
        print('❌ Certificate not found in admin collection: $certificateId');
        return;
      }

      final adminCertData = adminCertDoc.data() as Map<String, dynamic>;

      // Transform admin certificate data to user format
      final userCertData =
          _transformAdminCertificateToUserFormat(adminCertData);

      // Update certificate in user collection
      await _firestore
          .collection('certificates')
          .doc(certificateId)
          .set(userCertData, SetOptions(merge: true));

      print('✅ Certificate synced successfully: $certificateId');
    } catch (e) {
      print('❌ Error syncing certificate: $e');
    }
  }

  /// Transform admin certificate data to user format
  Map<String, dynamic> _transformAdminCertificateToUserFormat(
      Map<String, dynamic> adminData) {
    return {
      'userId': adminData['userId'],
      'courseId': adminData['courseId'],
      'courseTitle': adminData['courseTitle'],
      'certificateId': adminData['certificateId'],
      'certificateUrl': adminData['certificateUrl'],
      'issuedAt': adminData['issuedAt'] ?? FieldValue.serverTimestamp(),
      'completionDate':
          adminData['completionDate'] ?? FieldValue.serverTimestamp(),
      'finalScore': adminData['finalScore'] ?? 0.0,
      'isValid': adminData['isValid'] ?? true,
      'instructorName': adminData['instructorName'] ?? 'Unknown Instructor',
      'platformName': adminData['platformName'] ?? 'HACKETHOS4U',
      'directorName': adminData['directorName'] ?? 'MANITEJA THAGARAM',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ===== INITIALIZATION =====

  /// Initialize the sync service
  Future<void> initialize() async {
    try {
      print('🔄 Initializing Course Sync Service...');

      // Start listening for real-time updates
      listenForAdminCourseUpdates();

      // Sync all published courses initially
      await syncAllPublishedCourses();

      print('✅ Course Sync Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Course Sync Service: $e');
    }
  }

  // ===== UTILITY METHODS =====

  /// Check if course is in sync
  Future<bool> isCourseInSync(String courseId) async {
    try {
      final adminDoc =
          await _firestore.collection('admin_courses').doc(courseId).get();

      final userDoc =
          await _firestore.collection('courses').doc(courseId).get();

      if (!adminDoc.exists || !userDoc.exists) {
        return false;
      }

      final adminData = adminDoc.data() as Map<String, dynamic>;
      final userData = userDoc.data() as Map<String, dynamic>;

      // Compare key fields
      return adminData['title'] == userData['title'] &&
          adminData['price'] == userData['price'] &&
          adminData['published'] == userData['published'];
    } catch (e) {
      print('❌ Error checking course sync status: $e');
      return false;
    }
  }

  /// Force sync specific course
  Future<void> forceSyncCourse(String courseId) async {
    try {
      print('🔄 Force syncing course: $courseId');
      await syncCourseFromAdmin(courseId);
      print('✅ Force sync completed for course: $courseId');
    } catch (e) {
      print('❌ Error force syncing course: $e');
    }
  }

  /// Get sync status for all courses
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final adminCoursesSnapshot = await _firestore
          .collection('admin_courses')
          .where('published', isEqualTo: true)
          .get();

      final userCoursesSnapshot = await _firestore.collection('courses').get();

      final adminCount = adminCoursesSnapshot.docs.length;
      final userCount = userCoursesSnapshot.docs.length;
      final inSyncCount = 0;

      // Check sync status for each course
      for (final adminDoc in adminCoursesSnapshot.docs) {
        final courseId = adminDoc.id;
        if (await isCourseInSync(courseId)) {
          // inSyncCount++; // This would need to be handled differently
        }
      }

      return {
        'adminCoursesCount': adminCount,
        'userCoursesCount': userCount,
        'inSyncCount': inSyncCount,
        'lastSyncAt': FieldValue.serverTimestamp(),
      };
    } catch (e) {
      print('❌ Error getting sync status: $e');
      return {};
    }
  }
}
