import 'package:dio/dio.dart';

class AuthAPI {
  static const String baseUrl =
      'https://api.example.com'; // Replace with your actual API URL

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      Response response = await Dio().post(
        '$baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Added missing method
  static Future<Map<String, dynamic>> getWhoLogin() async {
    try {
      Response response = await Dio().get(
        '$baseUrl/auth/who-login',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get current user');
      }
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      Response response = await Dio().post(
        '$baseUrl/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      Response response = await Dio().get(
        '$baseUrl/auth/profile',
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
        throw Exception('Failed to get profile');
      }
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }
}
