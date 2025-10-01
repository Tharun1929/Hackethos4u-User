import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Safely convert Firestore Timestamp/String/DateTime to DateTime
  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.tryParse(value);
      } catch (_) {
        return null;
      }
    }
    if (value is Map<String, dynamic>) {
      final seconds = value['seconds'] ?? value['_seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    return null;
  }

  // Collection references
  CollectionReference get coursesCollection => _firestore.collection('courses');
  CollectionReference get enrollmentsCollection =>
      _firestore.collection('enrollments');
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get userProgressCollection =>
      _firestore.collection('user_progress');

  // ===== COURSE OPERATIONS =====

  // Get all published courses
  Future<List<Map<String, dynamic>>> getPublishedCourses() async {
    try {
      final querySnapshot =
          await coursesCollection.where('published', isEqualTo: true).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
          // Convert admin app course structure to user app structure
          'instructor': {
            'name': data['instructor'] ?? 'Unknown Instructor',
          },
          // pass-through fields if present
          'subtitle': data['subtitle'] ?? data['subTitle'] ?? '',
          'description': data['description'] ?? '',
          'whatYouLearn': (data['whatYouLearn'] is List
              ? data['whatYouLearn']
              : data['what_you_learn'] is List
                  ? data['what_you_learn']
                  : <dynamic>[]),
          'requirements': (data['requirements'] is List
              ? data['requirements']
              : <dynamic>[]),
          'modules': (data['modules'] is List
              ? data['modules']
              : data['sections'] is List
                  ? data['sections']
                  : <dynamic>[]),
          'videoPreview': data['videoPreview'] ?? data['previewVideo'] ?? '',
          'language': data['language'] ?? 'English',
          'certificate': data['certificate'] ?? true,
          'lifetimeAccess': data['lifetimeAccess'] ?? true,
          'price': (data['price'] is num)
              ? (data['price'] as num).toDouble()
              : (data['price'] is String)
                  ? double.tryParse((data['price'] as String)
                          .replaceAll(RegExp(r'[^0-9\.]'), '')) ??
                      0.0
                  : 0.0,
          'originalPrice': (data['originalPrice'] is num)
              ? (data['originalPrice'] as num).toDouble()
              : (data['originalPrice'] is String)
                  ? double.tryParse((data['originalPrice'] as String)
                          .replaceAll(RegExp(r'[^0-9\.]'), '')) ??
                      ((data['price'] is num)
                          ? (data['price'] as num).toDouble() * 2
                          : 0.0)
                  : ((data['price'] is num)
                      ? (data['price'] as num).toDouble() * 2
                      : 0.0),
          'rating': data['rating'] ?? 4.5, // Default rating
          'reviewsCount': data['reviewsCount'] ?? 0,
          'students': data['students'] ?? 1000, // Default student count
          'isNew': () {
            final created = _toDateTime(data['createdAt']);
            if (created == null) return false;
            return DateTime.now().difference(created).inDays < 30;
          }(),
          'isPopular': true, // Default popular status
          'tags': data['category'] != null ? [data['category']] : <dynamic>[],
          'level': 'Beginner', // Default level
          'duration': data['duration'] ?? '10 hours',
          // Prefer Cloudinary/network URL; avoid asset fallback on web
          'thumbnail': (data['thumbnail'] is String &&
                  (data['thumbnail'] as String).isNotEmpty)
              ? data['thumbnail']
              : 'assets/default_pp.png',
        };
      }).toList();
    } catch (e) {
      // print('Error getting published courses: $e');
      return [];
    }
  }

  // Get course by ID
  Future<Map<String, dynamic>?> getCourseById(String id) async {
    try {
      final doc = await coursesCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Try to fetch full instructor details if instructorId present
        Map<String, dynamic>? instructorObj;
        final dynamic instructorIdRaw = data['instructorId'];
        if (instructorIdRaw != null && instructorIdRaw.toString().isNotEmpty) {
          try {
            final instDoc = await _firestore.collection('instructors')
                .doc(instructorIdRaw.toString()).get();
            if (instDoc.exists) {
              instructorObj = instDoc.data() as Map<String, dynamic>;
            }
          } catch (_) {
            // ignore and fall back
          }
        }

        instructorObj ??= {
          'name': (data['instructor'] ?? data['instructorName'] ?? 'Unknown Instructor').toString(),
          'title': data['instructorTitle'] ?? '',
          'avatar': data['instructorAvatar'],
        };

        return {
          ...data,
          'id': doc.id,
          'instructor': instructorObj,
          'subtitle': data['subtitle'] ?? data['subTitle'] ?? '',
          'description': data['description'] ?? '',
          'whatYouLearn': (data['whatYouLearn'] is List
              ? data['whatYouLearn']
              : data['what_you_learn'] is List
                  ? data['what_you_learn']
                  : <dynamic>[]),
          'requirements': (data['requirements'] is List
              ? data['requirements']
              : <dynamic>[]),
          'modules': (data['modules'] is List
              ? data['modules']
              : data['sections'] is List
                  ? data['sections']
                  : <dynamic>[]),
          'videoPreview': data['videoPreview'] ?? data['previewVideo'] ?? '',
          'language': data['language'] ?? 'English',
          'certificate': data['certificate'] ?? true,
          'lifetimeAccess': data['lifetimeAccess'] ?? true,
          'price': (data['price'] is num)
              ? (data['price'] as num).toDouble()
              : (data['price'] is String)
                  ? double.tryParse((data['price'] as String)
                          .replaceAll(RegExp(r'[^0-9\.]'), '')) ??
                      0.0
                  : 0.0,
          'originalPrice': (data['originalPrice'] is num)
              ? (data['originalPrice'] as num).toDouble()
              : (data['originalPrice'] is String)
                  ? double.tryParse((data['originalPrice'] as String)
                          .replaceAll(RegExp(r'[^0-9\.]'), '')) ??
                      ((data['price'] is num)
                          ? (data['price'] as num).toDouble() * 2
                          : 0.0)
                  : ((data['price'] is num)
                      ? (data['price'] as num).toDouble() * 2
                      : 0.0),
          'rating': data['rating'] ?? 4.5,
          'reviewsCount': data['reviewsCount'] ?? 0,
          'students': data['students'] ?? 1000,
          'isNew': () {
            final created = _toDateTime(data['createdAt']);
            if (created == null) return false;
            return DateTime.now().difference(created).inDays < 30;
          }(),
          'isPopular': true,
          'tags': data['category'] != null ? [data['category']] : <dynamic>[],
          'level': 'Beginner',
          'duration': data['duration'] ?? '10 hours',
          'thumbnail': (data['thumbnail'] is String &&
                  (data['thumbnail'] as String).isNotEmpty)
              ? data['thumbnail']
              : 'assets/default_pp.png',
        };
      }
      return null;
    } catch (e) {
      // print('Error getting course: $e');
      return null;
    }
  }

  // ===== ENROLLMENT OPERATIONS =====

  // Create enrollment
  Future<bool> createEnrollment(
      String courseId, String courseTitle, double amount) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // print('User not authenticated');
        return false;
      }

      final enrollmentData = {
        'studentName': user.displayName ?? 'User',
        'studentEmail': user.email ?? '',
        'courseId': courseId,
        'courseTitle': courseTitle,
        'enrollmentDate': FieldValue.serverTimestamp(),
        'accessEndDate':
            DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'progressPercent': 0.0,
        'enrollmentStatus': 'Active',
        'certificateStatus': 'Not Issued',
        'lessons': [],
        'courseMCQResults': [],
        'moduleMCQProgress': [],
        'overallMCQScore': 0.0,
        'totalMCQsAttempted': 0,
        'totalMCQsCorrect': 0,
        'amount': amount,
        'paymentStatus': 'Completed',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await enrollmentsCollection.add(enrollmentData);
      // print('Enrollment created successfully');
      return true;
    } catch (e) {
      // print('Error creating enrollment: $e');
      return false;
    }
  }

  // Check if user is enrolled in course
  Future<bool> isUserEnrolled(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final querySnapshot = await enrollmentsCollection
          .where('studentEmail', isEqualTo: user.email)
          .where('courseId', isEqualTo: courseId)
          .where('enrollmentStatus', isEqualTo: 'Active')
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // print('Error checking enrollment: $e');
      return false;
    }
  }

  // Get user enrollments
  Future<List<Map<String, dynamic>>> getUserEnrollments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await enrollmentsCollection
          .where('studentEmail', isEqualTo: user.email)
          .where('enrollmentStatus', isEqualTo: 'Active')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      // print('Error getting user enrollments: $e');
      return [];
    }
  }

  // ===== USER OPERATIONS =====

  // Create or update user profile
  Future<void> createUserProfile(Map<String, dynamic> userData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await usersCollection.doc(user.uid).set({
        ...userData,
        'id': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // print('Error creating user profile: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await usersCollection.doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }
      return null;
    } catch (e) {
      // print('Error getting user profile: $e');
      return null;
    }
  }

  // ===== REAL-TIME LISTENERS =====

  // Stream of published courses
  Stream<List<Map<String, dynamic>>> publishedCoursesStream() {
    return coursesCollection
        .where('published', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
          'instructor': {
            'name': data['instructor'] ?? 'Unknown Instructor',
          },
          'rating': 4.5,
          'students': 1000,
          'isNew': () {
            final created = _toDateTime(data['createdAt']);
            if (created == null) return false;
            return DateTime.now().difference(created).inDays < 30;
          }(),
          'isPopular': true,
          'tags': data['category'] != null ? [data['category']] : <dynamic>[],
          'level': 'Beginner',
          'duration': data['duration'] ?? '10 hours',
          'thumbnail': data['thumbnail'] ?? 'assets/backend_ilust.jpg',
        };
      }).toList();
    });
  }

  // Stream of user enrollments
  Stream<List<Map<String, dynamic>>> userEnrollmentsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return enrollmentsCollection
        .where('studentEmail', isEqualTo: user.email)
        .where('enrollmentStatus', isEqualTo: 'Active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    });
  }

  // ===== CATEGORY OPERATIONS =====

  // Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final querySnapshot = await _firestore.collection('categories').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      // Return default categories if Firestore fails
      return [
        {
          'id': 'web-development',
          'name': 'Web Development',
          'icon': 'web',
          'color': '#2196F3',
          'courseCount': 0,
          'description': 'Learn modern web technologies',
          'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=400&h=300&fit=crop',
        },
        {
          'id': 'mobile-development',
          'name': 'Mobile Development',
          'icon': 'phone_android',
          'color': '#4CAF50',
          'courseCount': 0,
          'description': 'Build iOS and Android apps',
          'image': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=400&h=300&fit=crop',
        },
        {
          'id': 'data-science',
          'name': 'Data Science',
          'icon': 'analytics',
          'color': '#FF9800',
          'courseCount': 0,
          'description': 'Master data analysis and ML',
          'image': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&h=300&fit=crop',
        },
        {
          'id': 'cybersecurity',
          'name': 'Cybersecurity',
          'icon': 'security',
          'color': '#F44336',
          'courseCount': 0,
          'description': 'Learn security best practices',
          'image': 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=400&h=300&fit=crop',
        },
      ];
    }
  }

  // ===== LEARNING PATH OPERATIONS =====

  // Get all learning paths
  Future<List<Map<String, dynamic>>> getLearningPaths() async {
    try {
      final querySnapshot = await _firestore.collection('learning_paths').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      // Return default learning paths if Firestore fails
      return [
        {
          'id': 'full-stack-developer',
          'title': 'Full Stack Developer',
          'description': 'Master both frontend and backend development',
          'courses': ['HTML/CSS', 'JavaScript', 'React', 'Node.js', 'Database Design'],
          'duration': '6 months',
          'level': 'Beginner to Advanced',
          'color': '#2196F3',
          'icon': 'code',
        },
        {
          'id': 'data-scientist',
          'title': 'Data Scientist',
          'description': 'Learn data analysis, statistics, and machine learning',
          'courses': ['Python', 'Statistics', 'SQL', 'Machine Learning', 'Deep Learning'],
          'duration': '8 months',
          'level': 'Intermediate to Advanced',
          'color': '#FF9800',
          'icon': 'analytics',
        },
        {
          'id': 'mobile-app-developer',
          'title': 'Mobile App Developer',
          'description': 'Build native and cross-platform mobile applications',
          'courses': ['Flutter', 'React Native', 'iOS Development', 'Android Development'],
          'duration': '5 months',
          'level': 'Beginner to Intermediate',
          'color': '#4CAF50',
          'icon': 'phone_android',
        },
      ];
    }
  }
}
