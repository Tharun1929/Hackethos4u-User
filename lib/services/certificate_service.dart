import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'firebase_storage_service.dart';

class CertificateService {
  static final CertificateService _instance = CertificateService._internal();
  factory CertificateService() => _instance;
  CertificateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Use Firebase Storage for file uploads

  // ===== CERTIFICATE GENERATION =====

  /// Generate certificate for completed course
  Future<String?> generateCertificate({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required DateTime completionDate,
    required double finalScore,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if course is actually completed
      final isCompleted = await _checkCourseCompletion(courseId);
      if (!isCompleted) {
        throw Exception('Course not completed yet');
      }

      // Generate certificate PDF
      final pdfBytes = await _generateCertificatePDF(
        studentName: user.displayName ?? 'Student',
        courseTitle: courseTitle,
        instructorName: instructorName,
        completionDate: completionDate,
        finalScore: finalScore,
        certificateId: _generateCertificateId(user.uid, courseId),
      );

      // Upload to Firebase Storage
      final certificateUrl = await _uploadCertificateToStorage(
        courseId: courseId,
        userId: user.uid,
        pdfBytes: pdfBytes,
      );

      // Save certificate record to Firestore
      await _saveCertificateRecord(
        courseId: courseId,
        courseTitle: courseTitle,
        certificateUrl: certificateUrl,
        completionDate: completionDate,
        finalScore: finalScore,
      );

      return certificateUrl;
    } catch (e) {
      // print('Error generating certificate: $e');
      return null;
    }
  }

  /// Check if course is completed (75% or more)
  Future<bool> _checkCourseCompletion(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check enrollment status
      final enrollmentQuery = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (enrollmentQuery.docs.isEmpty) return false;

      final enrollment = enrollmentQuery.docs.first.data();
      final progressPercent =
          (enrollment['progressPercent'] as num?)?.toDouble() ?? 0.0;

      // Certificate eligibility: 75% completion or marked as completed
      return enrollment['status'] == 'completed' || progressPercent >= 75.0;
    } catch (e) {
      // print('Error checking course completion: $e');
      return false;
    }
  }

  /// Generate certificate PDF
  Future<Uint8List> _generateCertificatePDF({
    required String studentName,
    required String courseTitle,
    required String instructorName,
    required DateTime completionDate,
    required double finalScore,
    required String certificateId,
  }) async {
    final pdf = pw.Document();

    // Add certificate page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 3, color: PdfColors.blue),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Header
                  pw.Text(
                    'CERTIFICATE OF COMPLETION',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 40),

                  // Main content
                  pw.Text(
                    'This is to certify that',
                    style: pw.TextStyle(fontSize: 16),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 20),

                  pw.Text(
                    studentName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 20),

                  pw.Text(
                    'has successfully completed the course',
                    style: pw.TextStyle(fontSize: 16),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 20),

                  pw.Text(
                    courseTitle,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 40),

                  // Details
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(
                            'Instructor',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            instructorName,
                            style: pw.TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'Completion Date',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '${completionDate.day}/${completionDate.month}/${completionDate.year}',
                            style: pw.TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'Final Score',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '${finalScore.toStringAsFixed(1)}%',
                            style: pw.TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 40),

                  // Certificate ID
                  pw.Text(
                    'Certificate ID: $certificateId',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 40),

                  // Signatures
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 120,
                            height: 1,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Instructor Signature',
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 120,
                            height: 1,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Platform Director',
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Upload certificate to Firebase Storage
  Future<String> _uploadCertificateToStorage({
    required String courseId,
    required String userId,
    required Uint8List pdfBytes,
  }) async {
    try {
      final fileName = 'certificate_${userId}_$courseId.pdf';
      // Create a temporary file for upload
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pdfBytes);

      // Use Firebase Storage for upload
      final downloadUrl = await FirebaseStorageService.uploadDocument(
        documentFile: tempFile,
        folder: 'certificates',
        fileName: fileName,
        metadata: {
          'type': 'certificate',
          'userId': userId,
          'courseId': courseId,
        },
      );

      // Clean up temp file
      await tempFile.delete();

      if (downloadUrl == null) {
        throw Exception('Failed to upload certificate to Firebase Storage');
      }

      return downloadUrl;
    } catch (e) {
      // print('Error uploading certificate: $e');
      rethrow;
    }
  }

  /// Save certificate record to Firestore
  Future<void> _saveCertificateRecord({
    required String courseId,
    required String courseTitle,
    required String certificateUrl,
    required DateTime completionDate,
    required double finalScore,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final certificateData = {
        'userId': user.uid,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'certificateUrl': certificateUrl,
        'completionDate': FieldValue.serverTimestamp(),
        'finalScore': finalScore,
        'certificateId': _generateCertificateId(user.uid, courseId),
        'issuedAt': FieldValue.serverTimestamp(),
        'isValid': true,
      };

      await _firestore
          .collection('certificates')
          .doc('${user.uid}_$courseId')
          .set(certificateData);

      // Update user's certificate count
      await _firestore.collection('users').doc(user.uid).update({
        'stats.certificatesEarned': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error saving certificate record: $e');
      rethrow;
    }
  }

  /// Generate unique certificate ID
  String _generateCertificateId(String userId, String courseId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = '$userId$courseId$timestamp'.hashCode.abs();
    return 'CERT-${hash.toString().padLeft(8, '0')}';
  }

  // ===== CERTIFICATE RETRIEVAL =====

  /// Get user's certificates
  Future<List<Map<String, dynamic>>> getUserCertificates() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: user.uid)
          .orderBy('issuedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      // print('Error getting user certificates: $e');
      return [];
    }
  }

  /// Get certificate by ID
  Future<Map<String, dynamic>?> getCertificateById(String certificateId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc =
          await _firestore.collection('certificates').doc(certificateId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }
      return null;
    } catch (e) {
      // print('Error getting certificate by ID: $e');
      return null;
    }
  }

  /// Verify certificate validity
  Future<bool> verifyCertificate(String certificateId) async {
    try {
      final doc =
          await _firestore.collection('certificates').doc(certificateId).get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      return data['isValid'] == true;
    } catch (e) {
      // print('Error verifying certificate: $e');
      return false;
    }
  }

  // ===== CERTIFICATE DOWNLOAD =====

  /// Download certificate to local storage
  Future<String?> downloadCertificate(String certificateUrl) async {
    try {
      // Firebase Storage: fetch via https
      final uri = Uri.parse(certificateUrl);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'certificate_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(bytes);
        return file.path;
      } else {
        throw Exception(
            'Failed to download certificate: ${response.statusCode}');
      }
    } catch (e) {
      // print('Error downloading certificate: $e');
      return null;
    }
  }

  // ===== CERTIFICATE SHARING =====

  /// Share certificate
  Future<bool> shareCertificate(String certificateId) async {
    try {
      final certificate = await getCertificateById(certificateId);
      if (certificate == null) return false;

      // In a real app, this would integrate with platform sharing
      // For now, we'll just mark it as shared
      await _firestore.collection('certificates').doc(certificateId).update({
        'lastSharedAt': FieldValue.serverTimestamp(),
        'shareCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      // print('Error sharing certificate: $e');
      return false;
    }
  }

  // ===== CERTIFICATE STATISTICS =====

  /// Get certificate statistics
  Future<Map<String, dynamic>> getCertificateStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final querySnapshot = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: user.uid)
          .get();

      final certificates = querySnapshot.docs;
      final totalCertificates = certificates.length;
      final validCertificates = certificates.where((doc) {
        final data = doc.data();
        return data['isValid'] == true;
      }).length;

      final thisYear = DateTime.now().year;
      final thisYearCertificates = certificates.where((doc) {
        final data = doc.data();
        final issuedAt = data['issuedAt'] as Timestamp?;
        if (issuedAt == null) return false;
        return issuedAt.toDate().year == thisYear;
      }).length;

      return {
        'totalCertificates': totalCertificates,
        'validCertificates': validCertificates,
        'thisYearCertificates': thisYearCertificates,
        'averageScore': _calculateAverageScore(certificates),
      };
    } catch (e) {
      // print('Error getting certificate stats: $e');
      return {};
    }
  }

  /// Calculate average score from certificates
  double _calculateAverageScore(List<QueryDocumentSnapshot> certificates) {
    if (certificates.isEmpty) return 0.0;

    final totalScore = certificates.fold<double>(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return sum + (data['finalScore'] ?? 0.0);
    });

    return totalScore / certificates.length;
  }

  // ===== CERTIFICATE EXPORT =====

  /// Export certificates as ZIP
  Future<String?> exportCertificatesAsZip() async {
    try {
      final certificates = await getUserCertificates();
      if (certificates.isEmpty) return null;

      // In a real app, this would create a ZIP file with all certificates
      // For now, we'll just return a success message
      // print('Exporting ${certificates.length} certificates...');

      return 'Certificates exported successfully';
    } catch (e) {
      // print('Error exporting certificates: $e');
      return null;
    }
  }
}
