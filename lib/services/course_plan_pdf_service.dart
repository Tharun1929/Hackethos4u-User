import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CoursePlanPDFService {
  static final CoursePlanPDFService _instance =
      CoursePlanPDFService._internal();
  factory CoursePlanPDFService() => _instance;
  CoursePlanPDFService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate course plan PDF
  Future<Uint8List> generateCoursePlanPDF({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required double price,
    required List<Map<String, dynamic>> modules,
    required List<String> whatYouLearn,
    required List<String> requirements,
    required String description,
    required String level,
    required String category,
    required int totalDuration,
    required int totalLessons,
  }) async {
    try {
      final pdf = pw.Document();

      // Add course plan page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              _buildHeader(courseTitle, instructorName, price),
              pw.SizedBox(height: 30),
              _buildCourseOverview(
                  description, level, category, totalDuration, totalLessons),
              pw.SizedBox(height: 30),
              _buildWhatYouLearn(whatYouLearn),
              pw.SizedBox(height: 30),
              _buildRequirements(requirements),
              pw.SizedBox(height: 30),
              _buildCourseCurriculum(modules),
              pw.SizedBox(height: 30),
              _buildFooter(),
            ];
          },
        ),
      );

      return await pdf.save();
    } catch (e) {
      // print('Error generating course plan PDF: $e');
      rethrow;
    }
  }

  // Build PDF header
  pw.Widget _buildHeader(
      String courseTitle, String instructorName, double price) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Company Logo/Title
          pw.Row(
            children: [
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue600,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'H4U',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'HACKETHOS4U',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'Course Plan & Syllabus',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.blue600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Course Title
          pw.Text(
            courseTitle,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),

          pw.SizedBox(height: 8),

          // Instructor and Price
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Instructor: $instructorName',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Generated on: ${_formatDate(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build course overview section
  pw.Widget _buildCourseOverview(String description, String level,
      String category, int totalDuration, int totalLessons) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Course Overview',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),

          pw.SizedBox(height: 12),

          pw.Text(
            description,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
              lineSpacing: 1.5,
            ),
          ),

          pw.SizedBox(height: 16),

          // Course stats
          pw.Row(
            children: [
              _buildStatCard('Level', level),
              pw.SizedBox(width: 16),
              _buildStatCard('Category', category),
              pw.SizedBox(width: 16),
              _buildStatCard('Duration', '$totalDuration hours'),
              pw.SizedBox(width: 16),
              _buildStatCard('Lessons', '$totalLessons'),
            ],
          ),
        ],
      ),
    );
  }

  // Build stat card
  pw.Widget _buildStatCard(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue600,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build what you'll learn section
  pw.Widget _buildWhatYouLearn(List<String> whatYouLearn) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.green200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Icon(
                pw.IconData(0xe156), // Check icon
                color: PdfColors.green600,
                size: 20,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'What You\'ll Learn',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          ...whatYouLearn.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 6,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green600,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        item,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.green700,
                          lineSpacing: 1.3,
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

  // Build requirements section
  pw.Widget _buildRequirements(List<String> requirements) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.orange200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Icon(
                pw.IconData(0xe88a), // Info icon
                color: PdfColors.orange600,
                size: 20,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Requirements',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          ...requirements.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 6,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange600,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        item,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.orange700,
                          lineSpacing: 1.3,
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

  // Build course curriculum section
  pw.Widget _buildCourseCurriculum(List<Map<String, dynamic>> modules) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.purple200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Icon(
                pw.IconData(0xe8f5), // Book icon
                color: PdfColors.purple600,
                size: 20,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Course Curriculum',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          ...modules.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;
            final lessons = module['lessons'] as List<dynamic>? ?? [];

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.purple300, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 24,
                        height: 24,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.purple600,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '${index + 1}',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Text(
                          module['title'] ?? 'Module ${index + 1}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.purple800,
                          ),
                        ),
                      ),
                      pw.Text(
                        '${lessons.length} lessons',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.purple600,
                        ),
                      ),
                    ],
                  ),
                  if (lessons.isNotEmpty) ...[
                    pw.SizedBox(height: 12),
                    ...lessons.take(3).map((lesson) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            children: [
                              pw.SizedBox(width: 36),
                              pw.Icon(
                                pw.IconData(0xe039), // Play icon
                                color: PdfColors.purple500,
                                size: 12,
                              ),
                              pw.SizedBox(width: 8),
                              pw.Expanded(
                                child: pw.Text(
                                  lesson['title'] ?? 'Lesson',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    color: PdfColors.purple700,
                                  ),
                                ),
                              ),
                              pw.Text(
                                lesson['duration'] ?? '5 min',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.purple500,
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (lessons.length > 3)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 36, top: 4),
                        child: pw.Text(
                          '+ ${lessons.length - 3} more lessons',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.purple500,
                            fontStyle: pw.FontStyle.italic,
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

  // Build footer
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Ready to Start Learning?',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Visit our platform to enroll in this course and start your learning journey today!',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue600,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'Enroll Now',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Text(
            'HACKETHOS4U - Empowering Learning Through Technology',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey500,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Show PDF preview
  Future<void> showPDFPreview({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required double price,
    required List<Map<String, dynamic>> modules,
    required List<String> whatYouLearn,
    required List<String> requirements,
    required String description,
    required String level,
    required String category,
    required int totalDuration,
    required int totalLessons,
  }) async {
    try {
      final pdfBytes = await generateCoursePlanPDF(
        courseId: courseId,
        courseTitle: courseTitle,
        instructorName: instructorName,
        price: price,
        modules: modules,
        whatYouLearn: whatYouLearn,
        requirements: requirements,
        description: description,
        level: level,
        category: category,
        totalDuration: totalDuration,
        totalLessons: totalLessons,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: '${courseTitle}_Course_Plan.pdf',
      );
    } catch (e) {
      // print('Error showing PDF preview: $e');
      Get.snackbar(
        'Error',
        'Failed to generate PDF preview: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Share PDF
  Future<void> sharePDF({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required double price,
    required List<Map<String, dynamic>> modules,
    required List<String> whatYouLearn,
    required List<String> requirements,
    required String description,
    required String level,
    required String category,
    required int totalDuration,
    required int totalLessons,
  }) async {
    try {
      final pdfBytes = await generateCoursePlanPDF(
        courseId: courseId,
        courseTitle: courseTitle,
        instructorName: instructorName,
        price: price,
        modules: modules,
        whatYouLearn: whatYouLearn,
        requirements: requirements,
        description: description,
        level: level,
        category: category,
        totalDuration: totalDuration,
        totalLessons: totalLessons,
      );

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${courseTitle}_Course_Plan.pdf');
      await file.writeAsBytes(pdfBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this course plan: $courseTitle',
        subject: 'Course Plan - $courseTitle',
      );
    } catch (e) {
      // print('Error sharing PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to share PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Download PDF
  Future<void> downloadPDF({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required double price,
    required List<Map<String, dynamic>> modules,
    required List<String> whatYouLearn,
    required List<String> requirements,
    required String description,
    required String level,
    required String category,
    required int totalDuration,
    required int totalLessons,
  }) async {
    try {
      final pdfBytes = await generateCoursePlanPDF(
        courseId: courseId,
        courseTitle: courseTitle,
        instructorName: instructorName,
        price: price,
        modules: modules,
        whatYouLearn: whatYouLearn,
        requirements: requirements,
        description: description,
        level: level,
        category: category,
        totalDuration: totalDuration,
        totalLessons: totalLessons,
      );

      // Save to downloads directory
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final file =
            File('${downloadsDir.path}/${courseTitle}_Course_Plan.pdf');
        await file.writeAsBytes(pdfBytes);

        Get.snackbar(
          'Success',
          'PDF downloaded to Downloads folder',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Fallback to temporary directory
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${courseTitle}_Course_Plan.pdf');
        await file.writeAsBytes(pdfBytes);

        Get.snackbar(
          'Success',
          'PDF saved to temporary folder',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // print('Error downloading PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to download PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
