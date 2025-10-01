import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hackethos4u/model/course/enrolled_course_model.dart';
import 'package:hackethos4u/model/faq/faq_model.dart';
import 'package:hackethos4u/model/profile/user_model.dart';
import 'package:hackethos4u/model/request/request_model.dart';
import 'package:flutter/material.dart';
import 'package:hackethos4u/api/user_api.dart';

class ProfileViewModel extends ChangeNotifier {
  bool isLoading = true;
  bool isFaqLoading = true;
  bool isLoadingData = true;

  List<EnrolledCourseModel> _enrolledCourse = [];
  List<EnrolledCourseModel> get enrolledCourse => _enrolledCourse;

  List<EnrolledCourseModel> _finishedCourse = [];
  List<EnrolledCourseModel> get finishedCourse => _finishedCourse;

  List<FAQModel> _allFAQ = [];
  List<FAQModel> get allFAQ => _allFAQ;

  late UserModel _userData;
  UserModel get userData => _userData;

  // Add userProfile getter for profile screen
  UserModel? get userProfile => _userData;

  late EnrolledCourseModel _enrolledCourseData;
  EnrolledCourseModel get enrolledCourseData => _enrolledCourseData;

  File? _reportData;
  File get reportData => _reportData!;

  // Add loadUserProfile method for profile screen
  Future<void> loadUserProfile() async {
    try {
      isLoading = true;
      notifyListeners();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        isLoading = false;
        notifyListeners();
        throw Exception('Not authenticated');
      }

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      _userData = UserModel(
        id: 1,
        name: (data['name'] ??
                FirebaseAuth.instance.currentUser?.displayName ??
                'Student')
            .toString(),
        email: (data['email'] ??
                FirebaseAuth.instance.currentUser?.email ??
                'student@edutiv.com')
            .toString(),
        profilePicture: data['avatarUrl'],
        location: data['location'] ?? 'Unknown',
        enrolledCourses: data['enrolledCourses'] ?? 0,
        certificates: data['certificates'] ?? 0,
        hoursLearned: (data['hoursLearned'] as num?)?.toInt() ?? 0,
        averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      );

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      // If there's an error, create a default user profile
      _userData = UserModel(
        id: 1,
        name: 'Student',
        email: 'student@edutiv.com',
        profilePicture: null,
        location: 'New York, USA',
        enrolledCourses: 5,
        certificates: 3,
        hoursLearned: 120,
        averageRating: 4.5,
      );
      notifyListeners();
    }
  }

  Future<UserModel> getUserById(int id) async {
    // Keep for compatibility, returns current user
    await loadUserProfile();
    return _userData;
  }

  Future<UserModel> updateProfile(int specializationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'specializationId': specializationId,
    }, SetOptions(merge: true));
    await loadUserProfile();
    return _userData;
  }

  Future<UserModel> getWhoLogin() async {
    await loadUserProfile();
    return _userData;
  }

  Future<UserModel> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final updated = await UserAPI.changePassword(currentPassword, newPassword);
      _userData = updated;
      notifyListeners();
      return _userData;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<EnrolledCourseModel>> getEnrolledCourse() async {
    try {
      _enrolledCourse = await UserAPI.fetchEnrolledCourse();
      notifyListeners();
      return _enrolledCourse;
    } catch (e) {
      rethrow;
    }
  }

  Future<RequestModel> requestForm(
      int userId, String title, int categoryId, String requestType) async {
    final request = await UserAPI.requestForm(userId, title, categoryId, requestType);
    notifyListeners();
    return request;
  }

  Future<List<FAQModel>> getAllFAQ() async {
    isFaqLoading = true;
    try {
      // Temporarily reuse enrolled courses FAQ if API not available; otherwise, replace with real FAQ API
      // Keeping structure; integrate FAQ API when backend is ready
      _allFAQ = [];
      isFaqLoading = false;
      notifyListeners();
      return _allFAQ;
    } catch (e) {
      isFaqLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<EnrolledCourseModel> getEnrolledById(int enrolledCourseId) async {
    isLoadingData = true;
    _enrolledCourseData = await UserAPI.fetchEnrolledById(enrolledCourseId);
    isLoadingData = false;
    notifyListeners();
    return _enrolledCourseData;
  }

  Future<List<EnrolledCourseModel>> getFinishedCourse() async {
    final done = enrolledCourse.where((e) => e.progress == 100).toList();
    _finishedCourse = done;
    // notifyListeners();
    return done;
  }

  Future<EnrolledCourseModel> updateCourseProgress(
      int enrolledCourseId, int materialId) async {
    // Until backend endpoint exists, keep returning latest fetched data
    return _enrolledCourseData;
  }
}
