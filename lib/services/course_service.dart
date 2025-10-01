import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/course/course_model.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all courses
  Future<List<CourseModel>> getAllCourses() async {
    try {
      final querySnapshot = await _firestore.collection('courses').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CourseModel.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      // print('Error getting courses: $e');
      return [];
    }
  }

  // Get course by ID
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return CourseModel.fromJson({...data, 'id': doc.id});
      }
      return null;
    } catch (e) {
      // print('Error getting course: $e');
      return null;
    }
  }

  // Get popular courses
  Future<List<CourseModel>> getPopularCourses() async {
    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .where('isPopular', isEqualTo: true)
          .limit(10)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CourseModel.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      // print('Error getting popular courses: $e');
      return [];
    }
  }

  // Get courses by category
  Future<List<CourseModel>> getCoursesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .where('category', isEqualTo: category)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CourseModel.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      // print('Error getting courses by category: $e');
      return [];
    }
  }

  // Search courses
  Future<List<CourseModel>> searchCourses(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query\uf8ff')
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CourseModel.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      // print('Error searching courses: $e');
      return [];
    }
  }

  // Get user enrolled courses
  Future<List<CourseModel>> getUserEnrolledCourses(String userId) async {
    try {
      final enrollmentsQuery = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .get();

      final courseIds = enrollmentsQuery.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toList();

      if (courseIds.isEmpty) return [];

      final coursesQuery = await _firestore
          .collection('courses')
          .where(FieldPath.documentId, whereIn: courseIds)
          .get();

      return coursesQuery.docs.map((doc) {
        final data = doc.data();
        return CourseModel.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      // print('Error getting user enrolled courses: $e');
      return [];
    }
  }

  // Get course progress
  Future<Map<String, dynamic>> getCourseProgress(
      String userId, String courseId) async {
    try {
      final progressQuery = await _firestore
          .collection('user_progress')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (progressQuery.docs.isEmpty) {
        return {
          'progress': 0.0,
          'completedLessons': 0,
          'totalLessons': 0,
          'lastAccessed': null,
        };
      }

      final progressData = progressQuery.docs.first.data();
      return {
        'progress': progressData['progress'] ?? 0.0,
        'completedLessons': progressData['completedLessons'] ?? 0,
        'totalLessons': progressData['totalLessons'] ?? 0,
        'lastAccessed': progressData['lastAccessed'],
      };
    } catch (e) {
      // print('Error getting course progress: $e');
      return {
        'progress': 0.0,
        'completedLessons': 0,
        'totalLessons': 0,
        'lastAccessed': null,
      };
    }
  }
}
