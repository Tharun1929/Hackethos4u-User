import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/qa/qa_model.dart';
import '../utils/constants.dart';

class QAApi {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String qaEndpoint = '/api/qa';

  // Get all questions with filters
  static Future<List<QuestionModel>> getQuestions({
    QAFilterModel? filter,
    int page = 1,
    int limit = 20,
  }) async {
    // Always hit backend; disable mock path

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (filter != null) {
        if (filter.searchQuery != null) {
          queryParams['search'] = filter.searchQuery!;
        }
        if (filter.filterBy != null) {
          queryParams['filter'] = filter.filterBy!;
        }
        if (filter.sortBy != null) {
          queryParams['sort'] = filter.sortBy!;
        }
        if (filter.courseId != null) {
          queryParams['courseId'] = filter.courseId!;
        }
        if (filter.authorId != null) {
          queryParams['authorId'] = filter.authorId!;
        }
        if (filter.isAnswered != null) {
          queryParams['isAnswered'] = filter.isAnswered.toString();
        }
        if (filter.isResolved != null) {
          queryParams['isResolved'] = filter.isResolved.toString();
        }
        if (filter.dateFrom != null) {
          queryParams['dateFrom'] = filter.dateFrom!.toIso8601String();
        }
        if (filter.dateTo != null) {
          queryParams['dateTo'] = filter.dateTo!.toIso8601String();
        }
      }

      final uri = Uri.parse('$baseUrl$qaEndpoint/questions')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> questionsJson = data['data'] ?? [];

        return questionsJson
            .map((json) => QuestionModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching questions: $e');
    }
  }

  // Mock data for development
  static List<QuestionModel> _getMockQuestions(
      QAFilterModel? filter, int page, int limit) {
    final mockQuestions = [
      QuestionModel(
        id: '1',
        title: 'How to implement authentication in Flutter?',
        content:
            'I\'m building a Flutter app and need to implement user authentication. What\'s the best approach?',
        authorId: 'user1',
        authorName: 'John Doe',
        authorAvatar: 'assets/hackethos4u_logo.png',
        courseId: 'course1',
        courseName: 'Flutter Development',
        isAnswered: true,
        isResolved: true,
        votes: 15,
        answerCount: 3,
        tags: ['flutter', 'authentication', 'firebase'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      QuestionModel(
        id: '2',
        title: 'State management with Provider vs Bloc',
        content:
            'What are the differences between Provider and Bloc for state management in Flutter?',
        authorId: 'user2',
        authorName: 'Jane Smith',
        authorAvatar: 'assets/hackethos4u_logo.png',
        courseId: 'course1',
        courseName: 'Flutter Development',
        isAnswered: true,
        isResolved: false,
        votes: 8,
        answerCount: 2,
        tags: ['flutter', 'state-management', 'provider', 'bloc'],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      QuestionModel(
        id: '3',
        title: 'Best practices for API integration',
        content:
            'What are the best practices for integrating REST APIs in Flutter applications?',
        authorId: 'user3',
        authorName: 'Mike Johnson',
        authorAvatar: 'assets/hackethos4u_logo.png',
        courseId: 'course2',
        courseName: 'Mobile App Development',
        isAnswered: false,
        isResolved: false,
        votes: 5,
        answerCount: 0,
        tags: ['flutter', 'api', 'rest', 'http'],
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      QuestionModel(
        id: '4',
        title: 'How to handle image uploads?',
        content:
            'I need to implement image upload functionality in my Flutter app. Any recommendations?',
        authorId: 'user4',
        authorName: 'Sarah Wilson',
        authorAvatar: 'assets/hackethos4u_logo.png',
        courseId: 'course1',
        courseName: 'Flutter Development',
        isAnswered: true,
        isResolved: true,
        votes: 12,
        answerCount: 4,
        tags: ['flutter', 'image-upload', 'file-handling'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      QuestionModel(
        id: '5',
        title: 'Navigation patterns in Flutter',
        content:
            'What are the recommended navigation patterns for complex Flutter applications?',
        authorId: 'user5',
        authorName: 'Alex Brown',
        authorAvatar: 'assets/hackethos4u_logo.png',
        courseId: 'course2',
        courseName: 'Mobile App Development',
        isAnswered: true,
        isResolved: false,
        votes: 7,
        answerCount: 2,
        tags: ['flutter', 'navigation', 'routing'],
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ];

    // Apply filters if provided
    List<QuestionModel> filteredQuestions =
        List<QuestionModel>.from(mockQuestions);

    if (filter != null) {
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        filteredQuestions = filteredQuestions
            .where((q) =>
                q.title
                    .toLowerCase()
                    .contains(filter.searchQuery!.toLowerCase()) ||
                q.content
                    .toLowerCase()
                    .contains(filter.searchQuery!.toLowerCase()))
            .toList();
      }

      if (filter.filterBy != null) {
        switch (filter.filterBy!) {
          case 'Unanswered':
            filteredQuestions =
                filteredQuestions.where((q) => !q.isAnswered).toList();
            break;
          case 'Answered':
            filteredQuestions =
                filteredQuestions.where((q) => q.isAnswered).toList();
            break;
          case 'Resolved':
            filteredQuestions =
                filteredQuestions.where((q) => q.isResolved).toList();
            break;
          case 'Unresolved':
            filteredQuestions =
                filteredQuestions.where((q) => !q.isResolved).toList();
            break;
        }
      }

      if (filter.courseId != null) {
        filteredQuestions = filteredQuestions
            .where((q) => q.courseId == filter.courseId)
            .toList();
      }
    }

    // Apply pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= filteredQuestions.length) {
      return [];
    }

    return filteredQuestions.sublist(
        startIndex,
        endIndex > filteredQuestions.length
            ? filteredQuestions.length
            : endIndex);
  }

  // Get question by ID with answers
  static Future<QuestionModel> getQuestionById(String questionId) async {
    try {
      final uri = Uri.parse('$baseUrl$qaEndpoint/questions/$questionId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return QuestionModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to load question: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching question: $e');
    }
  }

  // Create new question
  static Future<QuestionModel> createQuestion(
      CreateQuestionModel question) async {
    try {
      final uri = Uri.parse('$baseUrl$qaEndpoint/questions');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
        body: json.encode(question.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return QuestionModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to create question: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating question: $e');
    }
  }

  // Update question
  static Future<QuestionModel> updateQuestion(
      String questionId, Map<String, dynamic> updates) async {
    try {
      final uri = Uri.parse('$baseUrl$qaEndpoint/questions/$questionId');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return QuestionModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to update question: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating question: $e');
    }
  }

  // Delete question
  static Future<bool> deleteQuestion(String questionId) async {
    try {
      final uri = Uri.parse('$baseUrl$qaEndpoint/questions/$questionId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting question: $e');
    }
  }

  // Vote on question
  static Future<bool> voteQuestion(String questionId, bool isUpvote) async {
    try {
      final uri = Uri.parse('$baseUrl$qaEndpoint/questions/$questionId/vote');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
        body: json.encode({
          'vote': isUpvote ? 1 : -1,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error voting on question: $e');
    }
  }

  // Create answer
  static Future<AnswerModel> createAnswer(CreateAnswerModel answer) async {
    try {
      final uri = Uri.parse('$baseUrl$qaEndpoint/answers');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
        body: json.encode(answer.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AnswerModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to create answer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating answer: $e');
    }
  }

  // Update answer
  static Future<AnswerModel> updateAnswer(
      String answerId, Map<String, dynamic> updates) async {
    try {
      final uri = Uri.parse('$baseUrl$qaEndpoint/answers/$answerId');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AnswerModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to update answer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating answer: $e');
    }
  }

  // Delete answer
  static Future<bool> deleteAnswer(String answerId) async {
    try {
      final uri = Uri.parse('$baseUrl$qaEndpoint/answers/$answerId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting answer: $e');
    }
  }

  // Vote on answer
  static Future<bool> voteAnswer(String answerId, bool isUpvote) async {
    try {
      final uri = Uri.parse('$baseUrl$qaEndpoint/answers/$answerId/vote');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
        body: json.encode({
          'vote': isUpvote ? 1 : -1,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error voting on answer: $e');
    }
  }

  // Accept answer
  static Future<bool> acceptAnswer(String answerId) async {
    try {
      final uri = Uri.parse('$baseUrl$qaEndpoint/answers/$answerId/accept');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error accepting answer: $e');
    }
  }

  // Mark question as resolved
  static Future<bool> resolveQuestion(String questionId) async {
    try {
      final uri =
          Uri.parse('$baseUrl$qaEndpoint/questions/$questionId/resolve');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error resolving question: $e');
    }
  }

  // Get user's questions
  static Future<List<QuestionModel>> getUserQuestions(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri =
          Uri.parse('$baseUrl$qaEndpoint/users/$userId/questions').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> questionsJson = data['data'] ?? [];

        return questionsJson
            .map((json) => QuestionModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to load user questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user questions: $e');
    }
  }

  // Get course questions
  static Future<List<QuestionModel>> getCourseQuestions(
    String courseId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri =
          Uri.parse('$baseUrl$qaEndpoint/courses/$courseId/questions').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> questionsJson = data['data'] ?? [];

        return questionsJson
            .map((json) => QuestionModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to load course questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching course questions: $e');
    }
  }
}
