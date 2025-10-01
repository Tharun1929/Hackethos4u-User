import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../model/user/user_model.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser?.isAuthenticated ?? false;
  bool get isGuest => _currentUser?.isGuest ?? true;

  // Initialize user provider
  Future<void> initialize() async {
    try {
      // Check Firebase Auth first
      final authService = AuthService();
      final firebaseUser = authService.currentUser;

      if (firebaseUser != null) {
        // User is authenticated with Firebase, create/update user model
        await _createUserFromFirebase(firebaseUser);
      } else {
        // No Firebase user, try to load from storage
        await _loadUserFromStorage();

        // If no valid user in storage, create guest user
        if (_currentUser == null || _currentUser!.isGuest) {
          _currentUser = UserModel.guest();
          notifyListeners();
        }
      }
    } catch (e) {
      // Error initializing user provider: $e
      _currentUser = UserModel.guest();
      notifyListeners();
    }
  }

  // Create user model from Firebase user
  Future<void> _createUserFromFirebase(User firebaseUser) async {
    try {
      final nameParts = firebaseUser.displayName?.split(' ') ?? ['User'];
      final firstname = nameParts.isNotEmpty ? nameParts.first : 'User';
      final lastname =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      _currentUser = UserModel(
        id: _currentUser?.id ?? 1, // Use existing ID or default
        firstname: firstname,
        lastname: lastname,
        email: firebaseUser.email,
        phone: firebaseUser.phoneNumber,
        profileImage: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime,
        enrolledCourses: _currentUser?.enrolledCourses ?? [],
        wishlistCourses: _currentUser?.wishlistCourses ?? [],
        preferences: _currentUser?.preferences ?? {},
        totalSpent: _currentUser?.totalSpent ?? 0.0,
        totalCourses: _currentUser?.totalCourses ?? 0,
        averageRating: _currentUser?.averageRating ?? 0.0,
        totalReviews: _currentUser?.totalReviews ?? 0,
      );

      await _saveUserToStorage();
      notifyListeners();
    } catch (e) {
      // Error creating user from Firebase: $e
    }
  }

  // Load user from local storage
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        final userJson = json.decode(userData);
        _currentUser = UserModel.fromJson(userJson);

        // Check if token is expired
        if (_currentUser!.tokenExpiry != null &&
            _currentUser!.tokenExpiry!.isBefore(DateTime.now())) {
          // Token expired, try to refresh
          await refreshToken();
        }
      } else {
        // No user data, create guest user
        _currentUser = UserModel.guest();
      }

      notifyListeners();
    } catch (e) {
      // Error loading user from storage: $e
      _currentUser = UserModel.guest();
      notifyListeners();
    }
  }

  // Save user to local storage
  Future<void> _saveUserToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        final userData = json.encode(_currentUser!.toJson());
        await prefs.setString('user_data', userData);
      }
    } catch (e) {
      // Error saving user to storage: $e
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final authService = AuthService();
      final result =
          await authService.signInWithEmailAndPassword(email, password);

      if (result != null) {
        // Create user model from Firebase user
        _currentUser = UserModel(
          id: _currentUser?.id, // keep existing local int id if any
          firstname: result.user?.displayName?.split(' ').first ?? '',
          lastname:
              result.user?.displayName?.split(' ').skip(1).join(' ') ?? '',
          email: result.user?.email,
          phone: result.user?.phoneNumber,
          createdAt: result.user?.metadata.creationTime,
          enrolledCourses: [],
          wishlistCourses: [],
          preferences: {},
          totalSpent: 0.0,
          totalCourses: 0,
          averageRating: 0.0,
          totalReviews: 0,
        );
        await _saveUserToStorage();
        // Mark logged in for splash routing
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Register user
  Future<bool> register({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final authService = AuthService();
      final result = await authService.signUpWithEmailAndPassword(
        email,
        password,
        '$firstname $lastname'.trim(),
      );

      if (result != null) {
        // Create user model from Firebase user
        _currentUser = UserModel(
          id: _currentUser?.id,
          firstname: firstname,
          lastname: lastname,
          email: email,
          phone: phone,
          createdAt: result.user?.metadata.creationTime,
          enrolledCourses: [],
          wishlistCourses: [],
          preferences: {},
          totalSpent: 0.0,
          totalCourses: 0,
          averageRating: 0.0,
          totalReviews: 0,
        );
        await _saveUserToStorage();
        // Mark logged in for splash routing
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Registration error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Login with Google
  Future<bool> loginWithGoogle(UserCredential userCredential) async {
    try {
      _setLoading(true);
      _clearError();

      // Create user model from Google user
      final user = userCredential.user;
      if (user != null) {
        final nameParts = user.displayName?.split(' ') ?? ['User'];
        final firstname = nameParts.isNotEmpty ? nameParts.first : 'User';
        final lastname =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        _currentUser = UserModel(
          id: _currentUser?.id,
          firstname: firstname,
          lastname: lastname,
          email: user.email,
          phone: user.phoneNumber,
          profileImage: user.photoURL,
          createdAt: user.metadata.creationTime,
          enrolledCourses: [],
          wishlistCourses: [],
          preferences: {},
          totalSpent: 0.0,
          totalCourses: 0,
          averageRating: 0.0,
          totalReviews: 0,
        );
        await _saveUserToStorage();
        // Mark logged in for splash routing
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Google login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Google login error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);

      // Sign out from Firebase
      final authService = AuthService();
      await authService.signOut();

      // Clear user data
      _currentUser = UserModel.guest();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.setBool('isLoggedIn', false);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      // Logout error: $e
      _setLoading(false);
    }
  }

  // Refresh token - not needed with Firebase Auth
  Future<bool> refreshToken() async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user != null) {
        // Firebase automatically handles token refresh
        return true;
      }
      return false;
    } catch (e) {
      // Token refresh error: $e
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? firstname,
    String? lastname,
    String? phone,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null) {
        _setError('No user logged in');
        _setLoading(false);
        return false;
      }

      // Update user model
      _currentUser = _currentUser!.copyWith(
        firstname: firstname ?? _currentUser!.firstname,
        lastname: lastname ?? _currentUser!.lastname,
        phone: phone ?? _currentUser!.phone,
        preferences: preferences ?? _currentUser!.preferences,
      );

      // Update in Firestore
      final authService = AuthService();
      await authService.updateUserProfile(_currentUser!);

      await _saveUserToStorage();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Profile update error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Upload profile image
  Future<bool> uploadProfileImage(String imagePath) async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null) {
        _setError('No user logged in');
        _setLoading(false);
        return false;
      }

      // Upload image to Firebase Storage
      final authService = AuthService();
      final imageUrl = await authService.uploadProfileImage(imagePath);

      if (imageUrl != null) {
        // Update user model
        _currentUser = _currentUser!.copyWith(
          profileImage: imageUrl,
        );

        await _saveUserToStorage();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Failed to upload image');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Image upload error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Add course to enrolled list
  Future<void> addEnrolledCourse(String courseId) async {
    _currentUser ??= UserModel.guest();
    _currentUser = _currentUser!.addEnrolledCourse(courseId);
    await _saveUserToStorage();
    notifyListeners();
  }

  // Add course to wishlist
  Future<void> addToWishlist(String courseId) async {
    _currentUser ??= UserModel.guest();
    _currentUser = _currentUser!.addToWishlist(courseId);
    await _saveUserToStorage();
    notifyListeners();
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String courseId) async {
    _currentUser ??= UserModel.guest();
    _currentUser = _currentUser!.removeFromWishlist(courseId);
    await _saveUserToStorage();
    notifyListeners();
  }

  // Update total spent
  Future<void> updateTotalSpent(double amount) async {
    _currentUser ??= UserModel.guest();
    _currentUser = _currentUser!.updateTotalSpent(amount);
    await _saveUserToStorage();
    notifyListeners();
  }

  // Update preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    _currentUser ??= UserModel.guest();
    _currentUser = _currentUser!.updatePreferences(preferences);
    await _saveUserToStorage();
    notifyListeners();
  }

  // Check if user can access course
  bool canAccessCourse(String courseId) {
    return _currentUser?.canAccessCourse(courseId) ?? false;
  }

  // Check if course is in wishlist
  bool isInWishlist(String courseId) {
    return _currentUser?.wishlistCourses?.contains(courseId) ?? false;
  }

  // Get user's enrolled courses
  List<String> get enrolledCourses => _currentUser?.enrolledCourses ?? [];

  // Get user's wishlist
  List<String> get wishlistCourses => _currentUser?.wishlistCourses ?? [];

  // Get user's total spent
  double get totalSpent => _currentUser?.totalSpent ?? 0.0;

  // Get user's total courses
  int get totalCourses => _currentUser?.totalCourses ?? 0;

  // Get user's average rating
  double get averageRating => _currentUser?.averageRating ?? 0.0;

  // Get user's total reviews
  int get totalReviews => _currentUser?.totalReviews ?? 0;

  // Update profile image
  Future<void> updateProfileImage(String imageUrl) async {
    try {
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(profileImage: imageUrl);
        await _saveUserToStorage();
        notifyListeners();
      }
    } catch (e) {
      // Error updating profile image: $e
      _setError('Failed to update profile image');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
}

// Result classes for auth operations
class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? error;
  final String? authToken;
  final String? refreshToken;
  final DateTime? tokenExpiry;

  AuthResult.success({
    this.user,
    this.authToken,
    this.refreshToken,
    this.tokenExpiry,
  })  : isSuccess = true,
        error = null;

  AuthResult.error(this.error)
      : isSuccess = false,
        user = null,
        authToken = null,
        refreshToken = null,
        tokenExpiry = null;
}

class ProfileUpdateResult {
  final bool isSuccess;
  final UserModel? user;
  final String? error;

  ProfileUpdateResult.success(this.user)
      : isSuccess = true,
        error = null;

  ProfileUpdateResult.error(this.error)
      : isSuccess = false,
        user = null;
}

class ImageUploadResult {
  final bool isSuccess;
  final String? imageUrl;
  final String? error;

  ImageUploadResult.success(this.imageUrl)
      : isSuccess = true,
        error = null;

  ImageUploadResult.error(this.error)
      : isSuccess = false,
        imageUrl = null;
}
