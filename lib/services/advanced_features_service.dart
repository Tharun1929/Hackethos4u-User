import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdvancedFeaturesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Offline Support
  static const String _offlineDataKey = 'offline_data';
  static const String _offlineCoursesKey = 'offline_courses';
  static const String _offlineProgressKey = 'offline_progress';

  // Gamification
  static const String _userAchievementsKey = 'user_achievements';
  static const String _userPointsKey = 'user_points';
  static const String _userStreakKey = 'user_streak';

  // Advanced Search
  static const String _searchHistoryKey = 'search_history';
  static const String _userPreferencesKey = 'user_preferences';

  // Offline Data Management
  Future<void> cacheDataForOffline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;

      if (user != null) {
        // Cache user's enrolled courses
        final enrollments = await _firestore
            .collection('enrollments')
            .where('userId', isEqualTo: user.uid)
            .get();

        final courseIds = enrollments.docs
            .map((doc) => doc.data()['courseId'] as String)
            .toList();

        if (courseIds.isNotEmpty) {
          final courses = await _firestore
              .collection('courses')
              .where(FieldPath.documentId, whereIn: courseIds)
              .get();

          final coursesData = courses.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();

          await prefs.setString(_offlineCoursesKey, json.encode(coursesData));
        }

        // Cache user progress
        final progress = await _firestore
            .collection('user_progress')
            .where('userId', isEqualTo: user.uid)
            .get();

        final progressData = progress.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();

        await prefs.setString(_offlineProgressKey, json.encode(progressData));

        // Cache timestamp
        await prefs.setInt(
            'last_cache_time', DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      // print('Error caching data for offline: $e');
    }
  }

  Future<Map<String, dynamic>> getOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final coursesData = prefs.getString(_offlineCoursesKey);
      final progressData = prefs.getString(_offlineProgressKey);

      return {
        'courses': coursesData != null ? json.decode(coursesData) : [],
        'progress': progressData != null ? json.decode(progressData) : [],
        'isOffline': true,
        'lastSync': prefs.getInt('last_cache_time'),
      };
    } catch (e) {
      // print('Error getting offline data: $e');
      return {
        'courses': [],
        'progress': [],
        'isOffline': true,
        'lastSync': null
      };
    }
  }

  Future<void> syncOfflineData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final progressData = prefs.getString(_offlineProgressKey);

      if (progressData != null) {
        final progress = json.decode(progressData) as List;

        for (final progressItem in progress) {
          await _firestore
              .collection('user_progress')
              .doc(progressItem['id'])
              .set(progressItem, SetOptions(merge: true));
        }
      }

      // Clear offline data after sync
      await prefs.remove(_offlineProgressKey);
    } catch (e) {
      // print('Error syncing offline data: $e');
    }
  }

  // Advanced Search with Filters
  Future<List<Map<String, dynamic>>> advancedSearch({
    required String query,
    String? category,
    String? level,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    int? maxDuration,
    List<String>? tags,
    String? instructor,
    bool? isFree,
  }) async {
    try {
      Query coursesQuery = _firestore.collection('courses');

      // Apply filters
      if (category != null) {
        coursesQuery = coursesQuery.where('category', isEqualTo: category);
      }
      if (level != null) {
        coursesQuery = coursesQuery.where('level', isEqualTo: level);
      }
      if (minPrice != null) {
        coursesQuery =
            coursesQuery.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        coursesQuery =
            coursesQuery.where('price', isLessThanOrEqualTo: maxPrice);
      }
      if (minRating != null) {
        coursesQuery =
            coursesQuery.where('rating', isGreaterThanOrEqualTo: minRating);
      }
      if (isFree != null && isFree) {
        coursesQuery = coursesQuery.where('price', isEqualTo: 0);
      }

      final querySnapshot = await coursesQuery.get();

      List<Map<String, dynamic>> results = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Apply additional filters that can't be done in Firestore
        bool matchesQuery = data['title']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            data['description']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());

        if (maxDuration != null) {
          final duration = _parseDuration(data['duration'] ?? '');
          if (duration > maxDuration) continue;
        }

        if (tags != null && tags.isNotEmpty) {
          final courseTags = List<String>.from(data['tags'] ?? []);
          if (!tags.any((tag) => courseTags.contains(tag))) continue;
        }

        if (instructor != null) {
          if (!data['instructor']
              .toString()
              .toLowerCase()
              .contains(instructor.toLowerCase())) {
            continue;
          }
        }

        if (matchesQuery) {
          results.add({
            'id': doc.id,
            ...data,
          });
        }
      }

      // Save search history
      await _saveSearchHistory(query);

      return results;
    } catch (e) {
      // print('Error in advanced search: $e');
      return [];
    }
  }

  int _parseDuration(String duration) {
    // Parse duration string like "8 weeks", "10 hours", etc.
    final parts = duration.split(' ');
    if (parts.length >= 2) {
      final value = int.tryParse(parts[0]) ?? 0;
      final unit = parts[1].toLowerCase();

      switch (unit) {
        case 'hours':
        case 'hour':
          return value;
        case 'weeks':
        case 'week':
          return value * 7 * 24; // Convert to hours
        case 'days':
        case 'day':
          return value * 24; // Convert to hours
        default:
          return value;
      }
    }
    return 0;
  }

  Future<void> _saveSearchHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_searchHistoryKey) ?? [];

      if (!history.contains(query)) {
        history.insert(0, query);
        if (history.length > 10) {
          history.removeLast();
        }
        await prefs.setStringList(_searchHistoryKey, history);
      }
    } catch (e) {
      // print('Error saving search history: $e');
    }
  }

  Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      // print('Error getting search history: $e');
      return [];
    }
  }

  // Gamification System
  Future<void> awardPoints(String userId, int points, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(points),
        'totalPointsEarned': FieldValue.increment(points),
        'lastPointsEarned': FieldValue.serverTimestamp(),
      });

      // Log points transaction
      await _firestore.collection('point_transactions').add({
        'userId': userId,
        'points': points,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'earned',
      });

      // Check for level up
      await _checkLevelUp(userId);
    } catch (e) {
      // print('Error awarding points: $e');
    }
  }

  Future<void> _checkLevelUp(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData != null) {
        final currentPoints = userData['points'] ?? 0;
        final currentLevel = userData['level'] ?? 1;

        // Level thresholds (points needed for each level)
        final levelThresholds = [
          0,
          100,
          300,
          600,
          1000,
          1500,
          2100,
          2800,
          3600,
          4500
        ];

        for (int i = levelThresholds.length - 1; i >= 0; i--) {
          if (currentPoints >= levelThresholds[i] && currentLevel < i + 1) {
            await _levelUp(userId, i + 1);
            break;
          }
        }
      }
    } catch (e) {
      // print('Error checking level up: $e');
    }
  }

  Future<void> _levelUp(String userId, int newLevel) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'level': newLevel,
        'levelUpDate': FieldValue.serverTimestamp(),
      });

      // Award level up bonus
      final bonus = newLevel * 50;
      await awardPoints(userId, bonus, 'Level Up Bonus!');

      // Create achievement
      await _createAchievement(
          userId, 'Level Up', 'Reached Level $newLevel', '🎉');
    } catch (e) {
      // print('Error leveling up: $e');
    }
  }

  Future<void> _createAchievement(
      String userId, String title, String description, String icon) async {
    try {
      await _firestore.collection('achievements').add({
        'userId': userId,
        'title': title,
        'description': description,
        'icon': icon,
        'earnedAt': FieldValue.serverTimestamp(),
        'type': 'level_up',
      });
    } catch (e) {
      // print('Error creating achievement: $e');
    }
  }

  Future<void> updateStreak(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData != null) {
        final lastLogin = userData['lastLogin'] as Timestamp?;
        final currentStreak = userData['currentStreak'] ?? 0;
        final longestStreak = userData['longestStreak'] ?? 0;

        final now = DateTime.now();
        final lastLoginDate = lastLogin?.toDate();

        if (lastLoginDate != null) {
          final daysDifference = now.difference(lastLoginDate).inDays;

          if (daysDifference == 1) {
            // Consecutive day
            final newStreak = currentStreak + 1;
            await _firestore.collection('users').doc(userId).update({
              'currentStreak': newStreak,
              'longestStreak':
                  newStreak > longestStreak ? newStreak : longestStreak,
              'lastLogin': FieldValue.serverTimestamp(),
            });

            // Award streak bonus
            if (newStreak % 7 == 0) {
              await awardPoints(userId, 100, 'Weekly Streak Bonus!');
            }
          } else if (daysDifference > 1) {
            // Streak broken
            await _firestore.collection('users').doc(userId).update({
              'currentStreak': 1,
              'lastLogin': FieldValue.serverTimestamp(),
            });
          }
        } else {
          // First login
          await _firestore.collection('users').doc(userId).update({
            'currentStreak': 1,
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // print('Error updating streak: $e');
    }
  }

  // Video Quality Management
  Future<Map<String, dynamic>> getVideoQualityOptions(String videoUrl) async {
    // Simulate different quality options
    return {
      'qualities': [
        {'label': 'Auto', 'value': 'auto', 'bitrate': 'auto'},
        {'label': '1080p', 'value': '1080p', 'bitrate': '5000kbps'},
        {'label': '720p', 'value': '720p', 'bitrate': '2500kbps'},
        {'label': '480p', 'value': '480p', 'bitrate': '1000kbps'},
        {'label': '360p', 'value': '360p', 'bitrate': '600kbps'},
      ],
      'currentQuality': 'auto',
      'adaptiveBitrate': true,
    };
  }

  Future<void> setVideoQuality(String userId, String quality) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'videoQuality': quality,
        'lastQualityUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error setting video quality: $e');
    }
  }

  // User Preferences
  Future<void> saveUserPreferences(
      String userId, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'preferences': preferences,
        'lastPreferencesUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error saving user preferences: $e');
    }
  }

  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      return userData?['preferences'] ??
          {
            'theme': 'light',
            'notifications': true,
            'autoPlay': false,
            'downloadQuality': '720p',
            'language': 'en',
            'accessibility': {
              'highContrast': false,
              'largeText': false,
              'screenReader': false,
            },
          };
    } catch (e) {
      // print('Error getting user preferences: $e');
      return {};
    }
  }

  // Performance Optimization
  Future<void> preloadCourseData(String courseId) async {
    try {
      // Preload course content
      await _firestore.collection('courses').doc(courseId).get();

      // Preload modules
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .get();

      // Preload lessons
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('lessons')
          .get();
    } catch (e) {
      // print('Error preloading course data: $e');
    }
  }

  // Analytics and Insights
  Future<Map<String, dynamic>> getLearningInsights(String userId) async {
    try {
      final progressQuery = await _firestore
          .collection('user_progress')
          .where('userId', isEqualTo: userId)
          .get();

      final progressData = progressQuery.docs.map((doc) => doc.data()).toList();

      // Calculate insights
      double totalProgress = 0;
      int totalLessons = 0;
      int completedLessons = 0;
      int totalTimeSpent = 0;

      for (final progress in progressData) {
        totalProgress += (progress['progress'] ?? 0).toDouble();
        totalLessons += ((progress['totalLessons'] ?? 0) as num).toInt();
        completedLessons +=
            ((progress['completedLessons'] ?? 0) as num).toInt();
        totalTimeSpent += ((progress['timeSpent'] ?? 0) as num).toInt();
      }

      final averageProgress =
          progressData.isNotEmpty ? totalProgress / progressData.length : 0;
      final completionRate =
          totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0;

      return {
        'averageProgress': averageProgress,
        'completionRate': completionRate,
        'totalTimeSpent': totalTimeSpent,
        'totalCourses': progressData.length,
        'completedLessons': completedLessons,
        'totalLessons': totalLessons,
        'learningStreak': await _getLearningStreak(userId),
        'recommendations': await _getPersonalizedRecommendations(userId),
      };
    } catch (e) {
      // print('Error getting learning insights: $e');
      return {};
    }
  }

  Future<int> _getLearningStreak(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      return userData?['currentStreak'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _getPersonalizedRecommendations(
      String userId) async {
    try {
      // Get user's learning history
      final progressQuery = await _firestore
          .collection('user_progress')
          .where('userId', isEqualTo: userId)
          .get();

      final enrolledCourseIds = progressQuery.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toList();

      // Get courses in similar categories
      final enrolledCourses = await _firestore
          .collection('courses')
          .where(FieldPath.documentId, whereIn: enrolledCourseIds)
          .get();

      final categories = enrolledCourses.docs
          .map((doc) => doc.data()['category'] as String)
          .toSet()
          .toList();

      // Get recommended courses
      final recommendations = await _firestore
          .collection('courses')
          .where('category', whereIn: categories)
          .where('isPublished', isEqualTo: true)
          .limit(10)
          .get();

      return recommendations.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      // print('Error getting personalized recommendations: $e');
      return [];
    }
  }
}
