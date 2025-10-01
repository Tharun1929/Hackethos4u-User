import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/course_plan_pdf_service.dart';
import '../../utils/app_theme.dart';

class CoursePlanScreen extends StatefulWidget {
  final Map<String, dynamic> courseData;

  const CoursePlanScreen({super.key, required this.courseData});

  @override
  State<CoursePlanScreen> createState() => _CoursePlanScreenState();
}

class _CoursePlanScreenState extends State<CoursePlanScreen> {
  final CoursePlanPDFService _pdfService = CoursePlanPDFService();
  bool _isGeneratingPDF = false;

  @override
  Widget build(BuildContext context) {
    final courseData = widget.courseData;
    final modules = (courseData['modules'] is List
        ? courseData['modules']
        : <dynamic>[]) as List<dynamic>;
    final whatYouLearn = (courseData['whatYouLearn'] is List
        ? (courseData['whatYouLearn'] as List).map((e) => e.toString()).toList()
        : <String>[]);
    final requirements = (courseData['requirements'] is List
        ? (courseData['requirements'] as List).map((e) => e.toString()).toList()
        : <String>[]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Plan'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isGeneratingPDF ? null : _generatePDF,
            tooltip: 'Generate PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isGeneratingPDF ? null : _sharePDF,
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Header
            _buildCourseHeader(courseData),

            const SizedBox(height: 24),

            // Course Overview
            _buildCourseOverview(courseData),

            const SizedBox(height: 24),

            // What You'll Learn
            if (whatYouLearn.isNotEmpty) ...[
              _buildWhatYouLearn(whatYouLearn),
              const SizedBox(height: 24),
            ],

            // Requirements
            if (requirements.isNotEmpty) ...[
              _buildRequirements(requirements),
              const SizedBox(height: 24),
            ],

            // Course Curriculum
            _buildCourseCurriculum(modules),

            const SizedBox(height: 24),

            // PDF Actions
            _buildPDFActions(courseData, modules, whatYouLearn, requirements),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader(Map<String, dynamic> courseData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HACKETHOS4U',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Course Plan & Syllabus',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            courseData['title'] ?? 'Course Title',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Instructor: ${courseData['instructor'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${(courseData['price'] ?? 0).toString()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseOverview(Map<String, dynamic> courseData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            courseData['description'] ?? 'No description available.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Course stats
          Row(
            children: [
              _buildStatCard('Level', courseData['level'] ?? 'Beginner'),
              const SizedBox(width: 12),
              _buildStatCard('Category', courseData['category'] ?? 'General'),
              const SizedBox(width: 12),
              _buildStatCard(
                  'Duration', '${_calculateTotalDuration(courseData)} hours'),
              const SizedBox(width: 12),
              _buildStatCard(
                  'Lessons', '${_calculateTotalLessons(courseData)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textHintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatYouLearn(List<String> whatYouLearn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'What You\'ll Learn',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...whatYouLearn.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.successColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRequirements(List<String> requirements) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: AppTheme.warningColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Requirements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...requirements.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.warningColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCourseCurriculum(List<dynamic> modules) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Course Curriculum',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...modules.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;
            final lessons = module['lessons'] as List<dynamic>? ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          module['title'] ?? 'Module ${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        '${lessons.length} lessons',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (lessons.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...lessons.take(3).map((lesson) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const SizedBox(width: 44),
                              Icon(Icons.play_circle_outline,
                                  color: AppTheme.primaryColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lesson['title'] ?? 'Lesson',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              Text(
                                lesson['duration'] ?? '5 min',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (lessons.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 44, top: 6),
                        child: Text(
                          '+ ${lessons.length - 3} more lessons',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPDFActions(
      Map<String, dynamic> courseData,
      List<dynamic> modules,
      List<String> whatYouLearn,
      List<String> requirements) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Download Course Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Get a detailed PDF version of this course plan to keep for reference or share with others.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPDF ? null : _generatePDF,
                  icon: _isGeneratingPDF
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label:
                      Text(_isGeneratingPDF ? 'Generating...' : 'Preview PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isGeneratingPDF ? null : _sharePDF,
                  icon: const Icon(Icons.share),
                  label: const Text('Share PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateTotalDuration(Map<String, dynamic> courseData) {
    final modules = courseData['modules'] as List<dynamic>? ?? [];
    int totalMinutes = 0;

    for (final module in modules) {
      final lessons = module['lessons'] as List<dynamic>? ?? [];
      for (final lesson in lessons) {
        final duration = lesson['duration']?.toString() ?? '5 min';
        final minutes =
            int.tryParse(duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;
        totalMinutes += minutes;
      }
    }

    return (totalMinutes / 60).ceil();
  }

  int _calculateTotalLessons(Map<String, dynamic> courseData) {
    final modules = courseData['modules'] as List<dynamic>? ?? [];
    int totalLessons = 0;

    for (final module in modules) {
      final lessons = module['lessons'] as List<dynamic>? ?? [];
      totalLessons += lessons.length;
    }

    return totalLessons;
  }

  Future<void> _generatePDF() async {
    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final courseData = widget.courseData;
      final modules = courseData['modules'] as List<dynamic>? ?? [];
      final whatYouLearn = (courseData['whatYouLearn'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final requirements = (courseData['requirements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      await _pdfService.showPDFPreview(
        courseId: courseData['id'] ?? '',
        courseTitle: courseData['title'] ?? 'Course',
        instructorName: courseData['instructor'] ?? 'Unknown',
        price: (courseData['price'] ?? 0).toDouble(),
        modules: modules.cast<Map<String, dynamic>>(),
        whatYouLearn: whatYouLearn,
        requirements: requirements,
        description: courseData['description'] ?? '',
        level: courseData['level'] ?? 'Beginner',
        category: courseData['category'] ?? 'General',
        totalDuration: _calculateTotalDuration(courseData),
        totalLessons: _calculateTotalLessons(courseData),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }

  Future<void> _sharePDF() async {
    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final courseData = widget.courseData;
      final modules = courseData['modules'] as List<dynamic>? ?? [];
      final whatYouLearn = (courseData['whatYouLearn'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final requirements = (courseData['requirements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      await _pdfService.sharePDF(
        courseId: courseData['id'] ?? '',
        courseTitle: courseData['title'] ?? 'Course',
        instructorName: courseData['instructor'] ?? 'Unknown',
        price: (courseData['price'] ?? 0).toDouble(),
        modules: modules.cast<Map<String, dynamic>>(),
        whatYouLearn: whatYouLearn,
        requirements: requirements,
        description: courseData['description'] ?? '',
        level: courseData['level'] ?? 'Beginner',
        category: courseData['category'] ?? 'General',
        totalDuration: _calculateTotalDuration(courseData),
        totalLessons: _calculateTotalLessons(courseData),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to share PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }
}
