import 'package:dio/dio.dart';

class CourseAPI {
  static const String baseUrl =
      'https://api.example.com'; // Replace with your actual API URL

  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      Response response = await Dio().get('$baseUrl/course');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load courses');
      }
    } catch (e) {
      throw Exception('Failed to load courses: $e');
    }
  }

  static Future<Map<String, dynamic>> getCourseById(String id) async {
    try {
      Response response = await Dio().get('$baseUrl/course/$id');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load course');
      }
    } catch (e) {
      throw Exception('Failed to load course: $e');
    }
  }

  // Added missing method
  static Future<Map<String, dynamic>> fetchCourseById(int id) async {
    try {
      Response response = await Dio().get('$baseUrl/course/$id');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load course');
      }
    } catch (e) {
      throw Exception('Failed to load course: $e');
    }
  }

  // Added missing method
  static Future<List<Map<String, dynamic>>> fetchAllReviewFromCourseId(
      int courseId) async {
    try {
      Response response = await Dio().get('$baseUrl/course/$courseId/reviews');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  // Added missing method
  static Future<List<Map<String, dynamic>>> searchCourseByName(
      String query) async {
    try {
      Response response = await Dio().get('$baseUrl/course/search?q=$query');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to search courses');
      }
    } catch (e) {
      throw Exception('Failed to search courses: $e');
    }
  }

  // Added missing method
  static Future<Map<String, dynamic>> createReview(
      int enrolledCourseId, int rating, String review) async {
    try {
      Response response = await Dio().post(
        '$baseUrl/course/review',
        data: {
          'enrolledCourseId': enrolledCourseId,
          'rating': rating,
          'review': review,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to create review');
      }
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // Added missing method
  static Future<Map<String, dynamic>> enrollCourse(
      int userId, int courseId) async {
    try {
      Response response = await Dio().post(
        '$baseUrl/course/$courseId/enroll',
        data: {
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to enroll in course');
      }
    } catch (e) {
      throw Exception('Failed to enroll in course: $e');
    }
  }

  // Added missing method
  static Future<Map<String, dynamic>> updateCourseProgress(
      int enrolledCourseId, int materialId) async {
    try {
      Response response = await Dio().put(
        '$baseUrl/course/progress',
        data: {
          'enrolledCourseId': enrolledCourseId,
          'materialId': materialId,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update progress');
      }
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  static Future<Map<String, dynamic>> enrollCourseWithToken(
      String courseId, String token) async {
    try {
      Response response = await Dio().post(
        '$baseUrl/course/$courseId/enroll',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to enroll in course');
      }
    } catch (e) {
      throw Exception('Failed to enroll in course: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProgress(
      String courseId, String lessonId, String token) async {
    try {
      Response response = await Dio().put(
        '$baseUrl/course/$courseId/lesson/$lessonId/complete',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update progress');
      }
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> searchCourses(String query) async {
    try {
      Response response = await Dio().get('$baseUrl/course/search/$query');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to search courses');
      }
    } catch (e) {
      throw Exception('Failed to search courses: $e');
    }
  }

  static Future<Map<String, dynamic>> addToWishlist(
      String courseId, String token) async {
    try {
      Response response = await Dio().post(
        '$baseUrl/course/$courseId/wishlist',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to add to wishlist');
      }
    } catch (e) {
      throw Exception('Failed to add to wishlist: $e');
    }
  }

  static Future<Map<String, dynamic>> removeFromWishlist(
      String courseId, String token) async {
    try {
      Response response = await Dio().put(
        '$baseUrl/course/$courseId/wishlist',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to remove from wishlist');
      }
    } catch (e) {
      throw Exception('Failed to remove from wishlist: $e');
    }
  }
}
