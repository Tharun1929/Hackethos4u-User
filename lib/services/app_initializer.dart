import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'real_time_sync_service.dart';
import 'notification_manager.dart';
import 'enrollment_manager.dart';
import 'community_service.dart';
import 'profile_manager.dart';
import 'payment_service.dart';
// import 'robust_upload_service.dart';

/// Comprehensive app initialization service
class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Initialize all app services
  Future<bool> initializeApp() async {
    if (_isInitialized) return true;
    if (_isInitializing) return false;

    _isInitializing = true;

    try {
      // print('🚀 Starting app initialization...');

      // Initialize Firebase services
      await _initializeFirebaseServices();

      // Initialize core services
      await _initializeCoreServices();

      // Initialize user-specific services
      await _initializeUserServices();

      // Initialize real-time services
      await _initializeRealTimeServices();

      _isInitialized = true;
      _isInitializing = false;

      // print('✅ App initialization completed successfully');
      return true;
    } catch (e) {
      // print('❌ App initialization failed: $e');
      _isInitializing = false;
      return false;
    }
  }

  /// Initialize Firebase services
  Future<void> _initializeFirebaseServices() async {
    try {
      // print('🔧 Initializing Firebase services...');

      // Initialize Firestore
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Initialize Auth
      await _auth.authStateChanges().first;

      // print('✅ Firebase services initialized');
    } catch (e) {
      // print('❌ Error initializing Firebase services: $e');
      rethrow;
    }
  }

  /// Initialize core services
  Future<void> _initializeCoreServices() async {
    try {
      // print('🔧 Initializing core services...');

      // Upload service not needed; uploads go via Firebase Storage

      // Initialize payment service
      await PaymentService().initialize();

      // print('✅ Core services initialized');
    } catch (e) {
      // print('❌ Error initializing core services: $e');
      rethrow;
    }
  }

  /// Initialize user-specific services
  Future<void> _initializeUserServices() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // print('⚠️ No user logged in, skipping user-specific services');
        return;
      }

      // print('🔧 Initializing user-specific services...');

      // Initialize profile manager
      await _initializeProfileManager(user);

      // Initialize enrollment manager
      await _initializeEnrollmentManager();

      // Initialize assignment service
      await _initializeAssignmentService();

      // print('✅ User-specific services initialized');
    } catch (e) {
      // print('❌ Error initializing user-specific services: $e');
      rethrow;
    }
  }

  /// Initialize real-time services
  Future<void> _initializeRealTimeServices() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // print('⚠️ No user logged in, skipping real-time services');
        return;
      }

      // print('🔧 Initializing real-time services...');

      // Initialize real-time sync
      await RealTimeSyncService().initialize(
        onCoursesUpdated: _onCoursesUpdated,
        onEnrollmentsUpdated: _onEnrollmentsUpdated,
        onNotificationsUpdated: _onNotificationsUpdated,
        onAssignmentsUpdated: _onAssignmentsUpdated,
      );

      // Initialize notification manager
      await NotificationManager().initialize();

      // Initialize community service
      await CommunityService().initialize(
        onMessagesUpdated: _onMessagesUpdated,
        onForumsUpdated: _onForumsUpdated,
        onPostsUpdated: _onPostsUpdated,
      );

      // print('✅ Real-time services initialized');
    } catch (e) {
      // print('❌ Error initializing real-time services: $e');
      rethrow;
    }
  }

  /// Initialize profile manager
  Future<void> _initializeProfileManager(User user) async {
    try {
      // Check if profile exists
      final profile = await ProfileManager().getUserProfile(user.uid);

      if (profile == null) {
        // Create new profile
        await ProfileManager().createUserProfile(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          phoneNumber: user.phoneNumber,
        );
        // print('✅ User profile created');
      } else {
        // Update last login
        await ProfileManager().updateLastLogin(user.uid);
        // print('✅ User profile updated');
      }
    } catch (e) {
      // print('❌ Error initializing profile manager: $e');
    }
  }

  /// Initialize enrollment manager
  Future<void> _initializeEnrollmentManager() async {
    try {
      await EnrollmentManager().initialize(
        onEnrollmentsUpdated: _onEnrollmentsUpdated,
        onProgressUpdated: _onProgressUpdated,
      );
      // print('✅ Enrollment manager initialized');
    } catch (e) {
      // print('❌ Error initializing enrollment manager: $e');
    }
  }

  /// Initialize assignment service
  Future<void> _initializeAssignmentService() async {
    try {
      // Assignment service doesn't need initialization
      // print('✅ Assignment service initialized');
    } catch (e) {
      // print('❌ Error initializing assignment service: $e');
    }
  }

  /// Handle courses updated
  void _onCoursesUpdated(List<Map<String, dynamic>> courses) {
    // print('📚 Courses updated: ${courses.length} courses');
    // Handle courses update (e.g., update UI state)
  }

  /// Handle enrollments updated
  void _onEnrollmentsUpdated(List<Map<String, dynamic>> enrollments) {
    // print('🎓 Enrollments updated: ${enrollments.length} enrollments');
    // Handle enrollments update (e.g., update UI state)
  }

  /// Handle notifications updated
  void _onNotificationsUpdated(List<Map<String, dynamic>> notifications) {
    // print('🔔 Notifications updated: ${notifications.length} notifications');
    // Handle notifications update (e.g., update UI state)
  }

  /// Handle assignments updated
  void _onAssignmentsUpdated(List<Map<String, dynamic>> assignments) {
    // print('📝 Assignments updated: ${assignments.length} assignments');
    // Handle assignments update (e.g., update UI state)
  }

  /// Handle messages updated
  void _onMessagesUpdated(List<Map<String, dynamic>> messages) {
    // print('💬 Messages updated: ${messages.length} messages');
    // Handle messages update (e.g., update UI state)
  }

  /// Handle forums updated
  void _onForumsUpdated(List<Map<String, dynamic>> forums) {
    // print('📋 Forums updated: ${forums.length} forums');
    // Handle forums update (e.g., update UI state)
  }

  /// Handle posts updated
  void _onPostsUpdated(List<Map<String, dynamic>> posts) {
    // print('📝 Posts updated: ${posts.length} posts');
    // Handle posts update (e.g., update UI state)
  }

  /// Handle progress updated
  void _onProgressUpdated(List<Map<String, dynamic>> progress) {
    // print('📊 Progress updated: ${progress.length} progress records');
    // Handle progress update (e.g., update UI state)
  }

  /// Reinitialize app (useful when user logs in/out)
  Future<bool> reinitializeApp() async {
    try {
      // print('🔄 Reinitializing app...');

      // Dispose existing services
      await _disposeServices();

      // Reset initialization state
      _isInitialized = false;
      _isInitializing = false;

      // Reinitialize
      return await initializeApp();
    } catch (e) {
      // print('❌ Error reinitializing app: $e');
      return false;
    }
  }

  /// Dispose all services
  Future<void> _disposeServices() async {
    try {
      // print('🧹 Disposing services...');

      RealTimeSyncService().dispose();
      NotificationManager().dispose();
      EnrollmentManager().dispose();
      CommunityService().dispose();
      PaymentService().dispose();

      // print('✅ Services disposed');
    } catch (e) {
      // print('❌ Error disposing services: $e');
    }
  }

  /// Get app status
  Map<String, dynamic> getAppStatus() {
    return {
      'isInitialized': _isInitialized,
      'isInitializing': _isInitializing,
      'userLoggedIn': _auth.currentUser != null,
      'userId': _auth.currentUser?.uid,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if app is ready
  bool get isAppReady => _isInitialized && !_isInitializing;

  /// Get initialization progress
  double get initializationProgress {
    if (_isInitialized) return 1.0;
    if (_isInitializing) return 0.5;
    return 0.0;
  }

  /// Force sync all data
  Future<void> forceSyncAllData() async {
    try {
      if (!_isInitialized) {
        // print('⚠️ App not initialized, cannot sync data');
        return;
      }

      // print('🔄 Force syncing all data...');
      await RealTimeSyncService().forceSyncAllData();
      // print('✅ Data sync completed');
    } catch (e) {
      // print('❌ Error force syncing data: $e');
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      if (!_isInitialized) {
        return {'error': 'App not initialized'};
      }

      return await RealTimeSyncService().getSyncStatus();
    } catch (e) {
      // print('❌ Error getting sync status: $e');
      return {'error': e.toString()};
    }
  }

  /// Dispose app
  Future<void> dispose() async {
    try {
      // print('🧹 Disposing app...');
      await _disposeServices();
      _isInitialized = false;
      _isInitializing = false;
      // print('✅ App disposed');
    } catch (e) {
      // print('❌ Error disposing app: $e');
    }
  }
}
