import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class CourseData {
  static final FirestoreService _firestoreService = FirestoreService();

  // No fallback courses - show "coming soon" message when no courses are available

  static final List<Map<String, dynamic>> categories = [
    {
      'name': 'All',
      'icon': Icons.all_inclusive,
      'color': Colors.blue,
    },
    {
      'name': 'Web Development',
      'icon': Icons.web,
      'color': Colors.orange,
    },
    {
      'name': 'Programming',
      'icon': Icons.code,
      'color': Colors.green,
    },
    {
      'name': 'Design',
      'icon': Icons.design_services,
      'color': Colors.purple,
    },
    {
      'name': 'Marketing',
      'icon': Icons.trending_up,
      'color': Colors.red,
    },
    {
      'name': 'Mobile Development',
      'icon': Icons.phone_android,
      'color': Colors.indigo,
    },
    {
      'name': 'Cloud Computing',
      'icon': Icons.cloud,
      'color': Colors.teal,
    },
    {
      'name': 'Cybersecurity',
      'icon': Icons.security,
      'color': Colors.deepOrange,
    },
  ];

  // Get all courses from Firestore
  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      final courses = await _firestoreService.getPublishedCourses();
      return courses; // Return empty list if no courses found
    } catch (e) {
      // print('Error getting courses from Firestore: $e');
      return []; // Return empty list on error
    }
  }

  // Get courses by category
  static Future<List<Map<String, dynamic>>> getCoursesByCategory(
      String category) async {
    try {
      final allCourses = await getAllCourses();
      if (category == 'All') return allCourses;
      return allCourses
          .where((course) => course['category'] == category)
          .toList();
    } catch (e) {
      // print('Error getting courses by category: $e');
      return [];
    }
  }

  // Search courses
  static Future<List<Map<String, dynamic>>> searchCourses(String query) async {
    try {
      final allCourses = await getAllCourses();
      final lowercaseQuery = query.toLowerCase();

      return allCourses.where((course) {
        final title = course['title'].toString().toLowerCase();
        final instructor =
            course['instructor']?['name']?.toString().toLowerCase() ?? '';
        final category = course['category'].toString().toLowerCase();
        final tags = (course['tags'] as List? ?? []).join(' ').toLowerCase();

        return title.contains(lowercaseQuery) ||
            instructor.contains(lowercaseQuery) ||
            category.contains(lowercaseQuery) ||
            tags.contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      // print('Error searching courses: $e');
      return [];
    }
  }

  // Get popular courses
  static Future<List<Map<String, dynamic>>> getPopularCourses() async {
    try {
      final allCourses = await getAllCourses();
      return allCourses.where((course) => course['isPopular'] == true).toList();
    } catch (e) {
      // print('Error getting popular courses: $e');
      return [];
    }
  }

  // Get new courses
  static Future<List<Map<String, dynamic>>> getNewCourses() async {
    try {
      final allCourses = await getAllCourses();
      return allCourses.where((course) => course['isNew'] == true).toList();
    } catch (e) {
      // print('Error getting new courses: $e');
      return [];
    }
  }

  // Get continue learning courses (user's enrolled courses)
  static Future<List<Map<String, dynamic>>> getContinueLearningCourses() async {
    try {
      final enrollments = await _firestoreService.getUserEnrollments();
      final enrolledCourseIds = enrollments.map((e) => e['courseId']).toList();

      if (enrolledCourseIds.isEmpty) {
        return [];
      }

      final allCourses = await getAllCourses();
      return allCourses
          .where((course) => enrolledCourseIds.contains(course['id']))
          .toList();
    } catch (e) {
      // print('Error getting continue learning courses: $e');
      return [];
    }
  }

  // Get course by ID
  static Future<Map<String, dynamic>?> getCourseById(String id) async {
    try {
      return await _firestoreService.getCourseById(id);
    } catch (e) {
      // print('Error getting course by ID: $e');
      return null;
    }
  }

  // Stream of published courses for real-time updates
  static Stream<List<Map<String, dynamic>>> getPublishedCoursesStream() {
    return _firestoreService.publishedCoursesStream();
  }

  // Stream of user enrollments for real-time updates
  static Stream<List<Map<String, dynamic>>> getUserEnrollmentsStream() {
    return _firestoreService.userEnrollmentsStream();
  }
}
