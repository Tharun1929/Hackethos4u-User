import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/progress_service.dart';
import '../../model/progress/progress_model.dart';
import '../../utils/app_theme.dart';

class MyCourseScreen extends StatefulWidget {
  const MyCourseScreen({super.key});

  @override
  State<MyCourseScreen> createState() => _MyCourseScreenState();
}

class _MyCourseScreenState extends State<MyCourseScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  // Populated from ProgressService
  final List<Map<String, dynamic>> _enrolledCourses = [];

  final List<String> _filters = [
    'All',
    'In Progress',
    'Completed',
    'Recently Viewed'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    try {
      final service = ProgressService();
      final List<CourseProgress> courses = await service.getEnrolledCourses();
      setState(() {
        _enrolledCourses
          ..clear()
          ..addAll(courses.map((c) => {
                'id': c.courseId,
                'title': c.courseTitle,
                'instructor': c.instructor,
                'thumbnail': c.courseImage,
                'progress': c.overallProgress,
                'completedLessons': c.completedLessons,
                'totalLessons': c.totalLessons,
                'lastAccessed': c.lastAccessed.millisecondsSinceEpoch,
                'rating': 4.5,
                'certificateEligible': c.overallProgress >= 1.0,
                // Simple gradients; could vary by course/category
                'gradient': [
                  const Color(0xFF6A11CB),
                  const Color(0xFF2575FC),
                ],
                // Optional next lesson text
                'nextLesson': c.currentLesson,
                'nextLessonDuration': '',
              }));
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCourses {
    List<Map<String, dynamic>> filtered = _enrolledCourses;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((course) =>
              course['title']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              course['instructor']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply category filter
    switch (_selectedFilter) {
      case 'In Progress':
        filtered = filtered
            .where((course) => course['progress'] > 0 && course['progress'] < 1)
            .toList();
        break;
      case 'Completed':
        filtered = filtered.where((course) => course['progress'] >= 1).toList();
        break;
      case 'Recently Viewed':
        filtered.sort((a, b) => b['lastAccessed'].compareTo(a['lastAccessed']));
        filtered = filtered.take(5).toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.cardColor,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.borderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
            ),
          ),
          title: const Text(
            'My Learning',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  // Download certificates
                },
                icon: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            labelColor: Colors.black87,
            unselectedLabelColor: AppTheme.textHintColor,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Enhanced Search and Filter Bar with Glassmorphism
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Enhanced Search Bar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search your courses...',
                        hintStyle: TextStyle(color: AppTheme.textHintColor),
                        prefixIcon: Icon(Icons.search, color: AppTheme.textHintColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Enhanced Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters
                          .map((filter) => Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildFilterChip(filter, theme),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Course List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveCoursesTab(),
                  _buildCompletedCoursesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, ThemeData theme) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8)
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.borderColor,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCoursesTab() {
    final activeCourses =
        _filteredCourses.where((course) => course['progress'] < 1).toList();

    if (activeCourses.isEmpty) {
      return _buildEmptyState(
        'No courses enrolled yet',
        'Enroll in courses to start your learning journey!\nBrowse our course catalog to get started.',
        Icons.school_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: activeCourses.length,
      itemBuilder: (context, index) {
        final course = activeCourses[index];
        return _buildEnhancedCourseCard(course, true);
      },
    );
  }

  Widget _buildCompletedCoursesTab() {
    final completedCourses =
        _filteredCourses.where((course) => course['progress'] >= 1).toList();

    if (completedCourses.isEmpty) {
      return _buildEmptyState(
        'No completed courses',
        'Complete a course to see it here',
        Icons.celebration,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: completedCourses.length,
      itemBuilder: (context, index) {
        final course = completedCourses[index];
        return _buildEnhancedCourseCard(course, false);
      },
    );
  }

  Widget _buildEnhancedCourseCard(Map<String, dynamic> course, bool isActive) {
    final theme = Theme.of(context);
    final List<Color> gradientColors = course['gradient'] as List<Color>;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Course Thumbnail with Glassmorphism
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background Pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: BackgroundPatternPainter(),
                        ),
                      ),
                      // Center Icon
                      const Center(
                        child: Icon(
                          Icons.school_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Overlay with Glassmorphism
                if (isActive)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${(course['progress'] * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Certificate Badge with Glassmorphism
                if (course['certificateEligible'] && !isActive)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Certificate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Enhanced Course Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: AppTheme.warningColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            course['rating'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Instructor
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      course['instructor'],
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textHintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Enhanced Progress Section
                if (isActive) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${course['completedLessons']}/${course['totalLessons']} lessons',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textHintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(course['progress'] * 100).round()}% complete',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textHintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: course['progress'],
                            backgroundColor: AppTheme.borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Next Lesson Info
                if (isActive && course['nextLesson'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.05),
                          theme.colorScheme.primary.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next: ${course['nextLesson']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                course['nextLessonDuration'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textHintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Enhanced Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              // Navigate to the last playback (continue learning)
                              final progress = await ProgressService()
                                  .getLastPlaybackLegacy(
                                      course['id'].toString());
                              if (progress != null) {
                                Get.toNamed(
                                  '/enhancedVideoPlayer',
                                  arguments: {
                                    'courseId': course['id'],
                                    'lessonTitle': course['nextLesson'] ??
                                        course['lastWatched'] ??
                                        course['title'],
                                    'videoUrl': course['videoUrl'] ??
                                        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                                    'requiredProgress': 70.0,
                                    'hasNextLesson': true,
                                    'hasPreviousLesson': true,
                                  },
                                );
                              } else {
                                Get.toNamed('/learningCourse',
                                    arguments: course['id']);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Text(
                                isActive
                                    ? 'Continue Learning'
                                    : 'Review Course',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (course['certificateEligible'] && !isActive)
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Get.toNamed('/certificateDetail',
                                    arguments: course);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  'View Certificate',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.borderColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppTheme.textHintColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textHintColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Get.toNamed('/explore');
                },
                borderRadius: BorderRadius.circular(12),
                child: const Center(
                  child: Text(
                    'Browse Courses',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for background pattern
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw diagonal lines
    for (int i = 0; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(0, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
