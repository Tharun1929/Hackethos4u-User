import 'package:flutter/foundation.dart';
import '../model/course/course_data.dart';
import '../services/firestore_service.dart';

class CourseProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  String _selectedPrice = 'All';

  // Getters
  List<Map<String, dynamic>> get courses => _courses;
  List<Map<String, dynamic>> get filteredCourses => _filteredCourses;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedLevel => _selectedLevel;
  String get selectedPrice => _selectedPrice;

  // Initialize the provider
  Future<void> initialize() async {
    await loadCourses();
  }

  // Load courses from Firestore
  Future<void> loadCourses() async {
    _setLoading(true);
    try {
      // First try to load from Firestore
      final firestoreCourses = await _firestoreService.getPublishedCourses();

      if (firestoreCourses.isNotEmpty) {
        _courses = firestoreCourses;
      } else {
        // Fallback to local data if Firestore is empty
        _courses = await CourseData.getAllCourses();
      }

      _applyFilters();
      notifyListeners();
    } catch (e) {
      // Error loading courses: $e
      // Fallback to local data on error
      _courses = await CourseData.getAllCourses();
      _applyFilters();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Search courses
  void searchCourses(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Filter by level
  void filterByLevel(String level) {
    _selectedLevel = level;
    _applyFilters();
    notifyListeners();
  }

  // Filter by price
  void filterByPrice(String price) {
    _selectedPrice = price;
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _selectedLevel = 'All';
    _selectedPrice = 'All';
    _applyFilters();
    notifyListeners();
  }

  // Apply all filters
  void _applyFilters() {
    _filteredCourses = _courses.where((course) {
      // Category filter
      if (_selectedCategory != 'All' &&
          course['category'] != _selectedCategory) {
        return false;
      }

      // Level filter
      if (_selectedLevel != 'All' && course['level'] != _selectedLevel) {
        return false;
      }

      // Price filter
      if (_selectedPrice != 'All') {
        final price = course['price'] ?? 0.0;
        switch (_selectedPrice) {
          case 'Free':
            if (price > 0) return false;
            break;
          case 'Under ₹1000':
            if (price >= 1000) return false;
            break;
          case '₹1000 - ₹5000':
            if (price < 1000 || price > 5000) return false;
            break;
          case 'Above ₹5000':
            if (price <= 5000) return false;
            break;
        }
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final title = course['title']?.toString().toLowerCase() ?? '';
        final instructor =
            course['instructor']?['name']?.toString().toLowerCase() ?? '';
        final category = course['category']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        if (!title.contains(query) &&
            !instructor.contains(query) &&
            !category.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Get course by ID
  Future<Map<String, dynamic>?> getCourseById(String id) async {
    try {
      // First try Firestore
      final firestoreCourse = await _firestoreService.getCourseById(id);
      if (firestoreCourse != null) {
        return firestoreCourse;
      }

      // Fallback to local data
      return _courses.firstWhere((course) => course['id'] == id);
    } catch (e) {
      // Error getting course by ID: $e
      return null;
    }
  }

  // Get featured courses
  List<Map<String, dynamic>> getFeaturedCourses() {
    return _courses.where((course) => course['isPopular'] == true).toList();
  }

  // Get new courses
  List<Map<String, dynamic>> getNewCourses() {
    return _courses.where((course) => course['isNew'] == true).toList();
  }

  // Get courses by category
  List<Map<String, dynamic>> getCoursesByCategory(String category) {
    return _courses.where((course) => course['category'] == category).toList();
  }

  // Get all categories
  List<String> getCategories() {
    final categories =
        _courses.map((course) => course['category']?.toString() ?? '').toSet();
    return ['All', ...categories.where((cat) => cat.isNotEmpty)];
  }

  // Get all levels
  List<String> getLevels() {
    final levels =
        _courses.map((course) => course['level']?.toString() ?? '').toSet();
    return ['All', ...levels.where((level) => level.isNotEmpty)];
  }

  // Get price ranges
  List<String> getPriceRanges() {
    return ['All', 'Free', 'Under ₹1000', '₹1000 - ₹5000', 'Above ₹5000'];
  }

  // Refresh courses
  Future<void> refreshCourses() async {
    await loadCourses();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get course statistics
  Map<String, dynamic> getCourseStats() {
    final totalCourses = _courses.length;
    final freeCourses =
        _courses.where((course) => (course['price'] ?? 0.0) == 0).length;
    final paidCourses = totalCourses - freeCourses;
    final totalStudents = _courses.fold<int>(
        0, (sum, course) => sum + (course['students'] as int? ?? 0));
    final averageRating = _courses.fold<double>(
            0.0, (sum, course) => sum + (course['rating'] as double? ?? 0.0)) /
        totalCourses;

    return {
      'totalCourses': totalCourses,
      'freeCourses': freeCourses,
      'paidCourses': paidCourses,
      'totalStudents': totalStudents,
      'averageRating': averageRating.isNaN ? 0.0 : averageRating,
    };
  }
}
