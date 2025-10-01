import 'package:dio/dio.dart';
import '../utils/constants.dart';

class CommunityAPI {
  static const String baseUrl = ApiConstants.baseUrl;

  // Get all community channels/rooms
  static Future<List<Map<String, dynamic>>> getChannels() async {
    try {
      Response response = await Dio().get(
        '$baseUrl${AppConstants.communityEndpoint}/channels',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception('Failed to get channels');
      }
    } catch (e) {
      throw Exception('Failed to get channels: $e');
    }
  }

  // Get messages for a specific channel
  static Future<List<Map<String, dynamic>>> getMessages(
    String channelId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      Response response = await Dio().get(
        '$baseUrl${AppConstants.communityEndpoint}/channels/$channelId/messages',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception('Failed to get messages');
      }
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  // Send a message to a channel
  static Future<Map<String, dynamic>> sendMessage(
    String channelId,
    String message, {
    String? imagePath,
    String? filePath,
    String? fileName,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'message': message,
        'channel_id': channelId,
      });

      if (imagePath != null) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(imagePath),
          ),
        );
      }

      if (filePath != null) {
        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(filePath, filename: fileName),
          ),
        );
      }

      Response response = await Dio().post(
        '$baseUrl${AppConstants.communityEndpoint}/messages',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
          },
        ),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get channel participants
  static Future<List<Map<String, dynamic>>> getParticipants(
      String channelId) async {
    try {
      Response response = await Dio().get(
        '$baseUrl${AppConstants.communityEndpoint}/channels/$channelId/participants',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception('Failed to get participants');
      }
    } catch (e) {
      throw Exception('Failed to get participants: $e');
    }
  }

  // Join a channel
  static Future<Map<String, dynamic>> joinChannel(String channelId) async {
    try {
      Response response = await Dio().post(
        '$baseUrl${AppConstants.communityEndpoint}/channels/$channelId/join',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to join channel');
      }
    } catch (e) {
      throw Exception('Failed to join channel: $e');
    }
  }

  // Leave a channel
  static Future<Map<String, dynamic>> leaveChannel(String channelId) async {
    try {
      Response response = await Dio().post(
        '$baseUrl${AppConstants.communityEndpoint}/channels/$channelId/leave',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to leave channel');
      }
    } catch (e) {
      throw Exception('Failed to leave channel: $e');
    }
  }

  // Create a new channel
  static Future<Map<String, dynamic>> createChannel({
    required String name,
    required String description,
    bool isPrivate = false,
    String? courseId,
  }) async {
    try {
      Response response = await Dio().post(
        '$baseUrl${AppConstants.communityEndpoint}/channels',
        data: {
          'name': name,
          'description': description,
          'is_private': isPrivate,
          'course_id': courseId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create channel');
      }
    } catch (e) {
      throw Exception('Failed to create channel: $e');
    }
  }

  // Get user's joined channels
  static Future<List<Map<String, dynamic>>> getJoinedChannels() async {
    try {
      Response response = await Dio().get(
        '$baseUrl${AppConstants.communityEndpoint}/channels/joined',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception('Failed to get joined channels');
      }
    } catch (e) {
      throw Exception('Failed to get joined channels: $e');
    }
  }

  // Mark messages as read
  static Future<Map<String, dynamic>> markMessagesAsRead(
      String channelId) async {
    try {
      Response response = await Dio().post(
        '$baseUrl${AppConstants.communityEndpoint}/channels/$channelId/read',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to mark messages as read');
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Get unread message count
  static Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      Response response = await Dio().get(
        '$baseUrl${AppConstants.communityEndpoint}/messages/unread-count',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get unread count');
      }
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  // Search messages
  static Future<List<Map<String, dynamic>>> searchMessages(
    String channelId,
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Response response = await Dio().get(
        '$baseUrl${AppConstants.communityEndpoint}/channels/$channelId/search',
        queryParameters: {
          'q': query,
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception('Failed to search messages');
      }
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  // Report a message
  static Future<Map<String, dynamic>> reportMessage(
    String messageId,
    String reason,
  ) async {
    try {
      Response response = await Dio().post(
        '$baseUrl${AppConstants.communityEndpoint}/messages/$messageId/report',
        data: {
          'reason': reason,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to report message');
      }
    } catch (e) {
      throw Exception('Failed to report message: $e');
    }
  }

  // Delete a message (only for message owner or admin)
  static Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    try {
      Response response = await Dio().delete(
        '$baseUrl${AppConstants.communityEndpoint}/messages/$messageId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to delete message');
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Edit a message (only for message owner)
  static Future<Map<String, dynamic>> editMessage(
    String messageId,
    String newText,
  ) async {
    try {
      Response response = await Dio().put(
        '$baseUrl${AppConstants.communityEndpoint}/messages/$messageId',
        data: {
          'message': newText,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to edit message');
      }
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  // Get channel statistics
  static Future<Map<String, dynamic>> getChannelStats(String channelId) async {
    try {
      Response response = await Dio().get(
        '$baseUrl${AppConstants.communityEndpoint}/channels/$channelId/stats',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get channel stats');
      }
    } catch (e) {
      throw Exception('Failed to get channel stats: $e');
    }
  }

  // Get online users count
  static Future<Map<String, dynamic>> getOnlineUsersCount(
      String channelId) async {
    try {
      Response response = await Dio().get(
        '$baseUrl${AppConstants.communityEndpoint}/channels/$channelId/online-count',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConstants.token}',
            ...AppConstants.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get online users count');
      }
    } catch (e) {
      throw Exception('Failed to get online users count: $e');
    }
  }
}
