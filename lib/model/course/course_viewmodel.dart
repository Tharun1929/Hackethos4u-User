import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hackethos4u/model/course/course_model.dart';
import 'package:hackethos4u/model/review/review_model.dart';
import 'package:hackethos4u/services/data_sync_service.dart';

class CourseViewModel extends ChangeNotifier {
  bool isLoading = false;
  bool isLoading2 = false;
  List<CourseModel> _allCourse = [];
  List<CourseModel> get allCourse => _allCourse;
  CourseModel? _courseData;
  CourseModel? get courseData => _courseData;
  List<Review> _allReview = [];
  List<Review> get allReview => _allReview;

  final DataSyncService _dataSyncService = DataSyncService();

  Future<List<Review>>? getAllReviewByCourseId(int courseId) async {
    // Load reviews from Firestore if present (optional collection `reviews` under course)
    final doc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId.toString())
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> reviews = (data['reviews'] as List<dynamic>?) ?? [];
      _allReview = reviews
          .map((r) => Review(
                id: _toInt(r['id']) ?? 0,
                rating: (r['rating'] is num)
                    ? (r['rating'] as num).toDouble()
                    : double.tryParse('${r['rating']}') ?? 0.0,
                review: r['review']?.toString() ?? '',
              ))
          .toList();
      return _allReview;
    }
    _allReview = [];
    return _allReview;
  }

  Future<CourseModel> getCourseById(int id) async {
    isLoading = true;
    notifyListeners();

    try {
      // Use data sync service for better field mapping
      final courseData = await _dataSyncService.getCourseById(id.toString());

      if (courseData == null) {
        isLoading = false;
        notifyListeners();
        throw Exception('Course not found');
      }

      _courseData = CourseModel.fromJson(_convertCourseDoc(courseData));
      isLoading = false;
      notifyListeners();
      return _courseData!;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      throw Exception('Error loading course: $e');
    }
  }

  Future<List<CourseModel>> searchCourseByName(String query) async {
    final col = FirebaseFirestore.instance.collection('courses');
    Query<Map<String, dynamic>> q = col;
    if (query.isNotEmpty) {
      q = col
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z');
    }
    final snap = await q.get();
    _allCourse = snap.docs.map((d) {
      final raw = d.data();
      final fallbackId = int.tryParse(d.id);
      final id = _toInt(raw['id']) ?? fallbackId;
      return CourseModel.fromJson(_convertCourseDoc({'id': id, ...raw}));
    }).toList();
    return _allCourse;
  }

  Future<Review> createReview(
      int enrolledCourseId, int rating, String review) async {
    final ref = FirebaseFirestore.instance
        .collection('courses')
        .doc(enrolledCourseId.toString());
    await ref.set({
      'reviews': FieldValue.arrayUnion([
        {
          'id': DateTime.now().millisecondsSinceEpoch,
          'rating': rating,
          'review': review,
          'createdAt': DateTime.now().toIso8601String(),
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return Review(id: 0, rating: rating.toDouble(), review: review);
  }

  Future enrollCourse(int userId, int courseId) async {
    await FirebaseFirestore.instance.collection('enrollments').add({
      'userId': userId,
      'courseId': courseId.toString(),
      'enrollmentStatus': 'Active',
      'progressPercent': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return {"success": true, "message": "Enrolled successfully"};
  }

  // Load all courses from Firestore
  Future<List<CourseModel>> getAllCourse() async {
    final snap = await FirebaseFirestore.instance.collection('courses').get();
    _allCourse = snap.docs.map((d) {
      final raw = d.data();
      final fallbackId = int.tryParse(d.id);
      final id = _toInt(raw['id']) ?? fallbackId;
      return CourseModel.fromJson(_convertCourseDoc({'id': id, ...raw}));
    }).toList();
    return _allCourse;
  }

  Future<List<dynamic>> getAllCategory() async {
    final snap = await FirebaseFirestore.instance.collection('courses').get();
    final set = <String>{};
    for (final d in snap.docs) {
      final cat = (d.data()['category'] ?? '').toString();
      if (cat.isNotEmpty) set.add(cat);
    }
    int i = 1;
    return set.map((c) => {"id": i++, "name": c}).toList();
  }

  // Map Firestore course doc to CourseModel JSON shape used by UI
  Map<String, dynamic> _convertCourseDoc(Map<String, dynamic> doc) {
    return {
      'id': doc['id'],
      'course_name': doc['title'] ?? doc['course_name'],
      'course_image': doc['thumbnail'] ?? doc['course_image'],
      'description': doc['longDesc'] ?? doc['description'],
      'total_video': (doc['modules'] is List)
          ? (doc['modules'] as List).fold<int>(
              0,
              (sum, m) =>
                  sum + (((m as Map?)?['submodules'] as List?)?.length ?? 0))
          : doc['total_video'],
      'total_times': doc['duration'] ?? doc['total_times'],
      'rating': (doc['rating'] ?? 4.5) * 1.0,
      'price': _tryParseDouble(doc['price']) ?? 0.0,
      'instructor': doc['instructor'] ?? '',
      'duration': doc['duration'] ?? '',
      'students_count': doc['studentsCount'] ?? 0,
    };
  }

  double? _tryParseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
