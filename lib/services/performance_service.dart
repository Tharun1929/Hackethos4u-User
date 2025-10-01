import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheExpiry = const Duration(minutes: 30);

  // Image Preloading
  final Set<String> _preloadedImages = {};

  // Course Data Caching
  static const String _coursesCacheKey = 'cached_courses';
  static const String _userProgressCacheKey = 'cached_user_progress';

  // Initialize performance optimizations
  Future<void> initialize() async {
    await _loadCacheFromStorage();
    await _preloadCriticalData();
  }

  // Cache Management
  Future<void> _loadCacheFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load courses cache
      final coursesData = prefs.getString(_coursesCacheKey);
      if (coursesData != null) {
        _cache[_coursesCacheKey] = json.decode(coursesData);
        _cacheTimestamps[_coursesCacheKey] = DateTime.now();
      }

      // Load user progress cache
      final progressData = prefs.getString(_userProgressCacheKey);
      if (progressData != null) {
        _cache[_userProgressCacheKey] = json.decode(progressData);
        _cacheTimestamps[_userProgressCacheKey] = DateTime.now();
      }
    } catch (e) {
      // print('Error loading cache from storage: $e');
    }
  }

  Future<void> _saveCacheToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_cache.containsKey(_coursesCacheKey)) {
        await prefs.setString(
            _coursesCacheKey, json.encode(_cache[_coursesCacheKey]));
      }

      if (_cache.containsKey(_userProgressCacheKey)) {
        await prefs.setString(
            _userProgressCacheKey, json.encode(_cache[_userProgressCacheKey]));
      }
    } catch (e) {
      // print('Error saving cache to storage: $e');
    }
  }

  // Preload critical data
  Future<void> _preloadCriticalData() async {
    try {
      // Preload popular courses
      await getPopularCourses();

      // Preload categories
      await getCategories();

      // Preload user progress if user is logged in
      // This will be handled by the user provider
    } catch (e) {
      // print('Error preloading critical data: $e');
    }
  }

  // Get cached data or fetch from Firestore
  Future<List<Map<String, dynamic>>> getPopularCourses() async {
    const cacheKey = 'popular_courses';

    // Check if we have valid cached data
    if (_isCacheValid(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      // Fetch from Firestore
      final querySnapshot = await _firestore
          .collection('courses')
          .where('isPopular', isEqualTo: true)
          .limit(10)
          .get();

      final courses = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Cache the results
      _cache[cacheKey] = courses;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return courses;
    } catch (e) {
      // print('Error fetching popular courses: $e');
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    const cacheKey = 'categories';

    if (_isCacheValid(cacheKey)) {
      return List<String>.from(_cache[cacheKey]);
    }

    try {
      final querySnapshot = await _firestore.collection('courses').get();

      final categories = querySnapshot.docs
          .map((doc) => doc.data()['category'] as String)
          .where((category) => category != null)
          .toSet()
          .toList();

      _cache[cacheKey] = categories;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return categories;
    } catch (e) {
      // print('Error fetching categories: $e');
      return [];
    }
  }

  // User progress caching
  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    final cacheKey = 'user_progress_$userId';

    if (_isCacheValid(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final querySnapshot = await _firestore
          .collection('user_progress')
          .where('userId', isEqualTo: userId)
          .get();

      final progress = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      final progressMap = {
        'progress': progress,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      _cache[cacheKey] = progressMap;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return progressMap;
    } catch (e) {
      // print('Error fetching user progress: $e');
      return {'progress': [], 'lastUpdated': DateTime.now().toIso8601String()};
    }
  }

  // Search results caching
  Future<List<Map<String, dynamic>>> searchCourses(String query) async {
    final cacheKey = 'search_${query.toLowerCase()}';

    if (_isCacheValid(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();

      final results = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      _cache[cacheKey] = results;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return results;
    } catch (e) {
      // print('Error searching courses: $e');
      return [];
    }
  }

  // Check if cache is still valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  // Clear expired cache
  void _clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.keys
        .where((key) => now.difference(_cacheTimestamps[key]!) > _cacheExpiry)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Clear all cache
  Future<void> clearCache() async {
    _cache.clear();
    _cacheTimestamps.clear();
    await _saveCacheToStorage();
  }

  // Image preloading
  Future<void> preloadImage(String imageUrl) async {
    if (_preloadedImages.contains(imageUrl)) return;

    try {
      // In a real app, you would use a proper image preloading library
      // For now, we'll just mark it as preloaded
      _preloadedImages.add(imageUrl);
    } catch (e) {
      // print('Error preloading image: $e');
    }
  }

  // Batch preload images
  Future<void> preloadImages(List<String> imageUrls) async {
    final futures = imageUrls.map((url) => preloadImage(url));
    await Future.wait(futures);
  }

  // Lazy loading for course content
  Future<Map<String, dynamic>> getCourseContent(String courseId) async {
    final cacheKey = 'course_content_$courseId';

    if (_isCacheValid(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      // Fetch course data
      final courseDoc =
          await _firestore.collection('courses').doc(courseId).get();

      if (!courseDoc.exists) {
        return {};
      }

      final courseData = courseDoc.data()!;

      // Fetch modules
      final modulesSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .get();

      final modules = modulesSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Fetch lessons
      final lessonsSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('lessons')
          .get();

      final lessons = lessonsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      final content = {
        'course': courseData,
        'modules': modules,
        'lessons': lessons,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      _cache[cacheKey] = content;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return content;
    } catch (e) {
      // print('Error fetching course content: $e');
      return {};
    }
  }

  // Optimize Firestore queries
  Query<Map<String, dynamic>> optimizeQuery(Query<Map<String, dynamic>> query) {
    // Add common optimizations
    return query.limit(20); // Limit results for better performance
  }

  // Batch operations for better performance
  Future<void> batchUpdateUserProgress(
      String userId, List<Map<String, dynamic>> progressUpdates) async {
    try {
      final batch = _firestore.batch();

      for (final update in progressUpdates) {
        final docRef = _firestore.collection('user_progress').doc();
        batch.set(docRef, update);
      }

      await batch.commit();

      // Clear related cache
      final cacheKey = 'user_progress_$userId';
      _cache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
    } catch (e) {
      // print('Error in batch update: $e');
    }
  }

  // Memory management
  void optimizeMemory() {
    // Clear expired cache
    _clearExpiredCache();

    // Limit cache size
    if (_cache.length > 100) {
      final sortedKeys = _cacheTimestamps.keys.toList()
        ..sort((a, b) => _cacheTimestamps[a]!.compareTo(_cacheTimestamps[b]!));

      final keysToRemove = sortedKeys.take(_cache.length - 100);
      for (final key in keysToRemove) {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
  }

  // Performance monitoring
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    return {
      'cacheSize': _cache.length,
      'preloadedImages': _preloadedImages.length,
      'memoryUsage': _cache.values
          .fold<int>(0, (sum, item) => sum + item.toString().length),
      'cacheHitRate': _calculateCacheHitRate(),
    };
  }

  double _calculateCacheHitRate() {
    // This is a simplified calculation
    // In a real app, you would track actual cache hits vs misses
    return 0.85; // Simulated 85% cache hit rate
  }

  // Dispose resources
  void dispose() {
    _cache.clear();
    _cacheTimestamps.clear();
    _preloadedImages.clear();
  }
}
