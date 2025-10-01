import 'package:dio/dio.dart';

class CategoryAPI {
  static const String baseUrl =
      'https://api.example.com'; // Replace with your actual API URL

  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      Response response = await Dio().get('$baseUrl/category');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }
}
