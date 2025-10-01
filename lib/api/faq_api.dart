import 'package:dio/dio.dart';
import 'package:hackethos4u/model/faq/faq_model.dart';

class FaqAPI {
  static const String baseUrl =
      'https://api.example.com'; // Replace with your actual API URL

  // Added missing method
  static Future<List<FAQModel>> fetchAllFAQ() async {
    try {
      Response response = await Dio().get('$baseUrl/faq');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => FAQModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load FAQs');
      }
    } catch (e) {
      throw Exception('Failed to load FAQs: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllFaqs() async {
    try {
      Response response = await Dio().get('$baseUrl/faq');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load FAQs');
      }
    } catch (e) {
      throw Exception('Failed to load FAQs: $e');
    }
  }
}
