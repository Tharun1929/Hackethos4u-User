import 'package:hackethos4u/model/course/course_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hackethos4u/api/user_api.dart';

class WishlistViewModel extends ChangeNotifier {
  final List<CourseModel> _wishlistedCourses = [];
  bool _isLoading = false;

  List<CourseModel> get wishlistedCourses => _wishlistedCourses;
  bool get isLoading => _isLoading;

  // Load wishlist from local storage
  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Prefer server wishlist if available; fallback to local cache
      final userId = 'me';
      final token = '';
      try {
        final serverWishlist = await UserAPI.getUserWishlist(userId, token);
        _wishlistedCourses
          ..clear()
          ..addAll(serverWishlist.map((e) => CourseModel.fromJson(e)));
        await _saveWishlist();
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        final wishlistData = prefs.getString('wishlist') ?? '[]';
        final List<dynamic> jsonList = json.decode(wishlistData);
        _wishlistedCourses
          ..clear()
          ..addAll(jsonList.map((e) => CourseModel.fromJson(e)));
      }
    } catch (e) {
      // Error loading wishlist: $e
      // Load some mock data if there's an error
      _loadMockWishlist();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add course to wishlist
  Future<void> addToWishlist(CourseModel course) async {
    if (!_wishlistedCourses.any((c) => c.id == course.id)) {
      _wishlistedCourses.add(course);
      await _saveWishlist();
      notifyListeners();
    }
  }

  // Remove course from wishlist
  Future<void> removeFromWishlist(CourseModel course) async {
    _wishlistedCourses.removeWhere((c) => c.id == course.id);
    await _saveWishlist();
    notifyListeners();
  }

  // Clear all wishlist
  Future<void> clearWishlist() async {
    _wishlistedCourses.clear();
    await _saveWishlist();
    notifyListeners();
  }

  // Check if course is in wishlist
  bool isInWishlist(int courseId) {
    return _wishlistedCourses.any((course) => course.id == courseId);
  }

  // Save wishlist to local storage
  Future<void> _saveWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList =
          _wishlistedCourses.map((course) => course.toJson()).toList();
      await prefs.setString('wishlist', json.encode(jsonList));
    } catch (e) {
      // Error saving wishlist: $e
    }
  }

  // Load mock wishlist data for demonstration
  void _loadMockWishlist() {
    _wishlistedCourses.clear();
    // Will be populated from real data
  }
}
