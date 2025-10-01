import 'package:dio/dio.dart';
import 'package:hackethos4u/model/course/enrolled_course_model.dart';
import 'package:hackethos4u/model/profile/user_model.dart';
import 'package:hackethos4u/model/request/request_model.dart';

class UserAPI {
  static const String baseUrl =
      'https://api.example.com'; // Replace with your actual API URL

  // Added missing method
  static Future<UserModel> fetchUserById(int id) async {
    try {
      Response response = await Dio().get('$baseUrl/user/$id');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load user');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  // Added missing method
  static Future<UserModel> updateProfile(int specializationId) async {
    try {
      Response response = await Dio().put(
        '$baseUrl/user/profile',
        data: {
          'specializationId': specializationId,
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Added missing method
  static Future<UserModel> changePassword(
      String currentPassword, String newPassword) async {
    try {
      Response response = await Dio().put(
        '$baseUrl/user/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Failed to change password');
      }
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Added missing method
  static Future<List<EnrolledCourseModel>> fetchEnrolledCourse() async {
    try {
      Response response = await Dio().get('$baseUrl/user/enrolled-courses');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => EnrolledCourseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load enrolled courses');
      }
    } catch (e) {
      throw Exception('Failed to load enrolled courses: $e');
    }
  }

  // Added missing method
  static Future<RequestModel> requestForm(
      int userId, String title, int categoryId, String requestType) async {
    try {
      Response response = await Dio().post(
        '$baseUrl/user/request',
        data: {
          'userId': userId,
          'title': title,
          'categoryId': categoryId,
          'requestType': requestType,
        },
      );

      if (response.statusCode == 200) {
        return RequestModel.fromJson(response.data);
      } else {
        throw Exception('Failed to submit request');
      }
    } catch (e) {
      throw Exception('Failed to submit request: $e');
    }
  }

  // Added missing method
  static Future<EnrolledCourseModel> fetchEnrolledById(
      int enrolledCourseId) async {
    try {
      Response response =
          await Dio().get('$baseUrl/user/enrolled-course/$enrolledCourseId');

      if (response.statusCode == 200) {
        return EnrolledCourseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load enrolled course');
      }
    } catch (e) {
      throw Exception('Failed to load enrolled course: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      Response response = await Dio().get('$baseUrl/user');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserById(
      String id, String token) async {
    try {
      Response response = await Dio().get(
        '$baseUrl/user/$id',
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
        throw Exception('Failed to load user');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUser(
      String id, Map<String, dynamic> userData, String token) async {
    try {
      Response response = await Dio().put(
        '$baseUrl/user/$id',
        data: userData,
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
        throw Exception('Failed to update user');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  static Future<Map<String, dynamic>> updatePassword(String id,
      String currentPassword, String newPassword, String token) async {
    try {
      Response response = await Dio().put(
        '$baseUrl/user/$id/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
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
        throw Exception('Failed to update password');
      }
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserEnrollments(
      String id, String token) async {
    try {
      Response response = await Dio().get(
        '$baseUrl/user/$id/enrollments',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load enrollments');
      }
    } catch (e) {
      throw Exception('Failed to load enrollments: $e');
    }
  }

  static Future<Map<String, dynamic>> uploadProfileImage(
      String id, String imagePath, String token) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      Response response = await Dio().post(
        '$baseUrl/user/$id/profile-image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to upload profile image');
      }
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserWishlist(
      String id, String token) async {
    try {
      Response response = await Dio().get(
        '$baseUrl/user/$id/wishlist',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load wishlist');
      }
    } catch (e) {
      throw Exception('Failed to load wishlist: $e');
    }
  }
}
