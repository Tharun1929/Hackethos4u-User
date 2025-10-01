import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  SharedPreferences? _prefs;

  // Cache keys
  static const String _coursesCacheKey = 'courses_cache';
  static const String _userProfileCacheKey = 'user_profile_cache';
  static const String _enrollmentsCacheKey = 'enrollments_cache';
  static const String _certificatesCacheKey = 'certificates_cache';
  static const String _notificationsCacheKey = 'notifications_cache';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Cache expiration times (in milliseconds)
  static const int _coursesCacheExpiry = 24 * 60 * 60 * 1000; // 24 hours
  static const int _userProfileCacheExpiry = 60 * 60 * 1000; // 1 hour
  static const int _enrollmentsCacheExpiry = 30 * 60 * 1000; // 30 minutes
  static const int _certificatesCacheExpiry = 24 * 60 * 60 * 1000; // 24 hours
  static const int _notificationsCacheExpiry = 15 * 60 * 1000; // 15 minutes

  // ===== INITIALIZATION =====

  /// Initialize offline service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Enable offline persistence
      // await _firestore.enablePersistence();

      // Set up offline settings
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      print('Error initializing offline service: $e');
    }
  }

  // ===== CONNECTIVITY CHECK =====

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if data is cached and not expired
  bool _isCacheValid(String cacheKey, int expiryTime) {
    try {
      final cacheData = _prefs?.getString(cacheKey);
      if (cacheData == null) return false;

      final data = jsonDecode(cacheData);
      final timestamp = data['timestamp'] as int?;
      if (timestamp == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      return (now - timestamp) < expiryTime;
    } catch (e) {
      return false;
    }
  }

  // ===== COURSES CACHING =====

  /// Cache courses data
  Future<void> cacheCourses(List<Map<String, dynamic>> courses) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': courses,
      };
      await _prefs?.setString(_coursesCacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching courses: $e');
    }
  }

  /// Get cached courses
  Future<List<Map<String, dynamic>>> getCachedCourses() async {
    try {
      if (!_isCacheValid(_coursesCacheKey, _coursesCacheExpiry)) {
        return [];
      }

      final cacheData = _prefs?.getString(_coursesCacheKey);
      if (cacheData == null) return [];

      final data = jsonDecode(cacheData);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } catch (e) {
      print('Error getting cached courses: $e');
      return [];
    }
  }

  /// Get courses with offline support
  Future<List<Map<String, dynamic>>> getCoursesWithOfflineSupport() async {
    try {
      final isOnline = await this.isOnline();

      if (isOnline) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('courses')
            .where('published', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        final courses = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        // Cache the data
        await cacheCourses(courses);

        return courses;
      } else {
        // Return cached data
        return await getCachedCourses();
      }
    } catch (e) {
      print('Error getting courses with offline support: $e');
      // Fallback to cached data
      return await getCachedCourses();
    }
  }

  // ===== USER PROFILE CACHING =====

  /// Cache user profile
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': profile,
      };
      await _prefs?.setString(_userProfileCacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching user profile: $e');
    }
  }

  /// Get cached user profile
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      if (!_isCacheValid(_userProfileCacheKey, _userProfileCacheExpiry)) {
        return null;
      }

      final cacheData = _prefs?.getString(_userProfileCacheKey);
      if (cacheData == null) return null;

      final data = jsonDecode(cacheData);
      return Map<String, dynamic>.from(data['data'] ?? {});
    } catch (e) {
      print('Error getting cached user profile: $e');
      return null;
    }
  }

  /// Get user profile with offline support
  Future<Map<String, dynamic>?> getUserProfileWithOfflineSupport() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final isOnline = await this.isOnline();

      if (isOnline) {
        // Fetch from Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final profile = {
            'id': doc.id,
            ...doc.data()!,
          };

          // Cache the data
          await cacheUserProfile(profile);

          return profile;
        }
        return null;
      } else {
        // Return cached data
        return await getCachedUserProfile();
      }
    } catch (e) {
      print('Error getting user profile with offline support: $e');
      // Fallback to cached data
      return await getCachedUserProfile();
    }
  }

  // ===== ENROLLMENTS CACHING =====

  /// Cache enrollments
  Future<void> cacheEnrollments(List<Map<String, dynamic>> enrollments) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': enrollments,
      };
      await _prefs?.setString(_enrollmentsCacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching enrollments: $e');
    }
  }

  /// Get cached enrollments
  Future<List<Map<String, dynamic>>> getCachedEnrollments() async {
    try {
      if (!_isCacheValid(_enrollmentsCacheKey, _enrollmentsCacheExpiry)) {
        return [];
      }

      final cacheData = _prefs?.getString(_enrollmentsCacheKey);
      if (cacheData == null) return [];

      final data = jsonDecode(cacheData);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } catch (e) {
      print('Error getting cached enrollments: $e');
      return [];
    }
  }

  /// Get enrollments with offline support
  Future<List<Map<String, dynamic>>> getEnrollmentsWithOfflineSupport() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final isOnline = await this.isOnline();

      if (isOnline) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('enrollments')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .orderBy('enrolledAt', descending: true)
            .get();

        final enrollments = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        // Cache the data
        await cacheEnrollments(enrollments);

        return enrollments;
      } else {
        // Return cached data
        return await getCachedEnrollments();
      }
    } catch (e) {
      print('Error getting enrollments with offline support: $e');
      // Fallback to cached data
      return await getCachedEnrollments();
    }
  }

  // ===== CERTIFICATES CACHING =====

  /// Cache certificates
  Future<void> cacheCertificates(
      List<Map<String, dynamic>> certificates) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': certificates,
      };
      await _prefs?.setString(_certificatesCacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching certificates: $e');
    }
  }

  /// Get cached certificates
  Future<List<Map<String, dynamic>>> getCachedCertificates() async {
    try {
      if (!_isCacheValid(_certificatesCacheKey, _certificatesCacheExpiry)) {
        return [];
      }

      final cacheData = _prefs?.getString(_certificatesCacheKey);
      if (cacheData == null) return [];

      final data = jsonDecode(cacheData);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } catch (e) {
      print('Error getting cached certificates: $e');
      return [];
    }
  }

  /// Get certificates with offline support
  Future<List<Map<String, dynamic>>> getCertificatesWithOfflineSupport() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final isOnline = await this.isOnline();

      if (isOnline) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('certificates')
            .where('userId', isEqualTo: user.uid)
            .orderBy('issuedAt', descending: true)
            .get();

        final certificates = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        // Cache the data
        await cacheCertificates(certificates);

        return certificates;
      } else {
        // Return cached data
        return await getCachedCertificates();
      }
    } catch (e) {
      print('Error getting certificates with offline support: $e');
      // Fallback to cached data
      return await getCachedCertificates();
    }
  }

  // ===== NOTIFICATIONS CACHING =====

  /// Cache notifications
  Future<void> cacheNotifications(
      List<Map<String, dynamic>> notifications) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': notifications,
      };
      await _prefs?.setString(_notificationsCacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching notifications: $e');
    }
  }

  /// Get cached notifications
  Future<List<Map<String, dynamic>>> getCachedNotifications() async {
    try {
      if (!_isCacheValid(_notificationsCacheKey, _notificationsCacheExpiry)) {
        return [];
      }

      final cacheData = _prefs?.getString(_notificationsCacheKey);
      if (cacheData == null) return [];

      final data = jsonDecode(cacheData);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } catch (e) {
      print('Error getting cached notifications: $e');
      return [];
    }
  }

  /// Get notifications with offline support
  Future<List<Map<String, dynamic>>>
      getNotificationsWithOfflineSupport() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final isOnline = await this.isOnline();

      if (isOnline) {
        // Fetch from Firestore
        final querySnapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();

        final notifications = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        // Cache the data
        await cacheNotifications(notifications);

        return notifications;
      } else {
        // Return cached data
        return await getCachedNotifications();
      }
    } catch (e) {
      print('Error getting notifications with offline support: $e');
      // Fallback to cached data
      return await getCachedNotifications();
    }
  }

  // ===== SYNC MANAGEMENT =====

  /// Mark last sync timestamp
  Future<void> markLastSync() async {
    try {
      await _prefs?.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error marking last sync: $e');
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSync() async {
    try {
      final timestamp = _prefs?.getInt(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      print('Error getting last sync: $e');
      return null;
    }
  }

  /// Check if sync is needed
  Future<bool> isSyncNeeded() async {
    try {
      final lastSync = await getLastSync();
      if (lastSync == null) return true;

      final now = DateTime.now();
      final difference = now.difference(lastSync);

      // Sync if more than 1 hour has passed
      return difference.inHours >= 1;
    } catch (e) {
      print('Error checking sync status: $e');
      return true;
    }
  }

  /// Force sync all data
  Future<void> forceSyncAll() async {
    try {
      final isOnline = await this.isOnline();
      if (!isOnline) return;

      // Sync all data types
      await getCoursesWithOfflineSupport();
      await getUserProfileWithOfflineSupport();
      await getEnrollmentsWithOfflineSupport();
      await getCertificatesWithOfflineSupport();
      await getNotificationsWithOfflineSupport();

      // Mark sync as completed
      await markLastSync();
    } catch (e) {
      print('Error force syncing all data: $e');
    }
  }

  // ===== CACHE MANAGEMENT =====

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      await _prefs?.remove(_coursesCacheKey);
      await _prefs?.remove(_userProfileCacheKey);
      await _prefs?.remove(_enrollmentsCacheKey);
      await _prefs?.remove(_certificatesCacheKey);
      await _prefs?.remove(_notificationsCacheKey);
      await _prefs?.remove(_lastSyncKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear expired cache
  Future<void> clearExpiredCache() async {
    try {
      final keys = [
        _coursesCacheKey,
        _userProfileCacheKey,
        _enrollmentsCacheKey,
        _certificatesCacheKey,
        _notificationsCacheKey,
      ];

      final expiries = [
        _coursesCacheExpiry,
        _userProfileCacheExpiry,
        _enrollmentsCacheExpiry,
        _certificatesCacheExpiry,
        _notificationsCacheExpiry,
      ];

      for (int i = 0; i < keys.length; i++) {
        if (!_isCacheValid(keys[i], expiries[i])) {
          await _prefs?.remove(keys[i]);
        }
      }
    } catch (e) {
      print('Error clearing expired cache: $e');
    }
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    try {
      int size = 0;
      final keys = [
        _coursesCacheKey,
        _userProfileCacheKey,
        _enrollmentsCacheKey,
        _certificatesCacheKey,
        _notificationsCacheKey,
      ];

      for (final key in keys) {
        final data = _prefs?.getString(key);
        if (data != null) {
          size += data.length;
        }
      }

      return size;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  // ===== OFFLINE QUEUE =====

  /// Queue action for when online
  Future<void> queueAction(String action, Map<String, dynamic> data) async {
    try {
      final queueKey = 'offline_queue';
      final existingQueue = _prefs?.getStringList(queueKey) ?? [];

      final actionData = {
        'action': action,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      existingQueue.add(jsonEncode(actionData));
      await _prefs?.setStringList(queueKey, existingQueue);
    } catch (e) {
      print('Error queuing action: $e');
    }
  }

  /// Process offline queue
  Future<void> processOfflineQueue() async {
    try {
      final isOnline = await this.isOnline();
      if (!isOnline) return;

      final queueKey = 'offline_queue';
      final queue = _prefs?.getStringList(queueKey) ?? [];

      if (queue.isEmpty) return;

      // Process each queued action
      for (final actionJson in queue) {
        try {
          final actionData = jsonDecode(actionJson);
          final action = actionData['action'] as String;
          final data = actionData['data'] as Map<String, dynamic>;

          // Process the action based on type
          await _processQueuedAction(action, data);
        } catch (e) {
          print('Error processing queued action: $e');
        }
      }

      // Clear the queue
      await _prefs?.remove(queueKey);
    } catch (e) {
      print('Error processing offline queue: $e');
    }
  }

  /// Process individual queued action
  Future<void> _processQueuedAction(
      String action, Map<String, dynamic> data) async {
    try {
      switch (action) {
        case 'update_progress':
          // Update course progress
          await _firestore
              .collection('enrollments')
              .doc(data['enrollmentId'])
              .update({
            'progress': data['progress'],
            'progressPercent': data['progressPercent'],
            'lastAccessed': FieldValue.serverTimestamp(),
          });
          break;
        case 'mark_lesson_complete':
          // Mark lesson as complete
          await _firestore
              .collection('userProgress')
              .doc(data['progressId'])
              .set(data, SetOptions(merge: true));
          break;
        // Add more action types as needed
      }
    } catch (e) {
      print('Error processing queued action $action: $e');
    }
  }
}
