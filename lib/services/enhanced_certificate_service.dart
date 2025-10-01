import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

class EnhancedCertificateService {
  static final EnhancedCertificateService _instance = EnhancedCertificateService._internal();
  factory EnhancedCertificateService() => _instance;
  EnhancedCertificateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Certificate template asset path
  static const String _certificateTemplateAsset = 'assets/certificate.png';

  /// Generate certificate for completed course and persist Firestore record
  /// Returns the PDF download URL.
  Future<String?> generateCertificate({
    required String courseId,
    required String courseTitle,
    required String userName,
    required double completionPercentage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check certificate eligibility threshold
      final eligibilityThreshold = await _getCertificateEligibilityThreshold();
      if (completionPercentage < eligibilityThreshold) {
        throw Exception('Course completion percentage ($completionPercentage%) is below the required threshold ($eligibilityThreshold%)');
      }

      // Check if certificate already exists
      final existingCertificate = await _checkExistingCertificate(user.uid, courseId);
      if (existingCertificate != null) {
        return existingCertificate['certificateImageUrl'];
      }

      // Generate unique certificate number: <COURSE>-<YYYYMMDDHHMMSS>-<RND4>
      final certificateNumber = _generateCertificateNumber(
        courseCode: courseId,
      );
      final issueDate = DateTime.now();
      final username = user.email ?? user.uid.substring(0, 8);

      // Create certificate data
      final certificateData = {
        // Required fields (spec)
        'user_id': user.uid,
        'course_id': courseId,
        'certificate_number': certificateNumber,
        'issue_date': issueDate,
        // Convenience/meta
        'userName': userName,
        'username': username,
        'courseTitle': courseTitle,
        'completionPercentage': completionPercentage,
        'status': 'valid',
        'issuedBy': 'HACKETHOS4U',
        'directorName': 'MANITEJA THAGARAM',
        'directorTitle': 'DIRECTOR & CEO',
        'companyLocation': 'HYDERABAD',
        'isValid': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Generate certificate image using the PNG/JPG template for preview
      final certificateImageUrl = await _generateCertificateImageWithTemplate(
        certificateNumber: certificateNumber,
        userName: userName,
        username: username,
        courseTitle: courseTitle,
        issueDate: issueDate,
      );

      // Update certificate data with image URL
      if (certificateImageUrl != null) {
        certificateData['certificateImageUrl'] = certificateImageUrl;
      }

      // Save preliminary certificate doc
      final certRef = await _firestore.collection('certificates').add(certificateData);

      // Generate PDF version over the template image with placeholders
      final pdfUrl = await _generateCertificatePDF(
        certificateNumber: certificateNumber,
        userName: userName,
        username: username,
        courseTitle: courseTitle,
        issueDate: issueDate,
      );

      // Update certificate with file_path (PDF) and image URL
      await certRef.update({
        'file_path': pdfUrl,
        if (certificateImageUrl != null) 'certificateImageUrl': certificateImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return certificateImageUrl;
    } catch (e) {
      print('Error generating certificate: $e');
      return null;
    }
  }

  /// Generate certificate image using template
  Future<String?> _generateCertificateImageWithTemplate({
    required String certificateNumber,
    required String userName,
    required String username,
    required String courseTitle,
    required DateTime issueDate,
  }) async {
    try {
      // Load your PNG template from assets
      final bgBytes = await rootBundle.load(_certificateTemplateAsset);
      final Uint8List bgList = bgBytes.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bgList);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image bgImage = frameInfo.image;

      final double width = bgImage.width.toDouble();
      final double height = bgImage.height.toDouble();

      // Prepare canvas
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw background template
      final paint = Paint();
      canvas.drawImage(bgImage, const Offset(0, 0), paint);

      // Text styling based on your template
      final textStyle = TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: 'serif',
      );

      final nameStyle = TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFDC143C), // Red color for name
        fontFamily: 'serif',
      );

      final courseStyle = TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: 'serif',
      );

      final dateStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFDC143C), // Red color for date
        fontFamily: 'serif',
      );

      // Position text elements based on your template layout
      // Student name
      final nameTextPainter = TextPainter(
        text: TextSpan(text: userName, style: nameStyle),
        textDirection: TextDirection.ltr,
      );
      nameTextPainter.layout();
      nameTextPainter.paint(
        canvas,
        Offset(
          (width - nameTextPainter.width) / 2,
          height * 0.35, // Adjust based on your template
        ),
      );

      // Course name
      final courseTextPainter = TextPainter(
        text: TextSpan(text: courseTitle.toUpperCase(), style: courseStyle),
        textDirection: TextDirection.ltr,
      );
      courseTextPainter.layout();
      courseTextPainter.paint(
        canvas,
        Offset(
          (width - courseTextPainter.width) / 2,
          height * 0.45, // Adjust based on your template
        ),
      );

      // Issue date
      final formattedDate = _formatDate(issueDate);
      final dateTextPainter = TextPainter(
        text: TextSpan(text: formattedDate, style: dateStyle),
        textDirection: TextDirection.ltr,
      );
      dateTextPainter.layout();
      dateTextPainter.paint(
        canvas,
        Offset(
          width * 0.75, // Right side position
          height * 0.85, // Bottom position
        ),
      );

      // Certificate number (top right)
      final idStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        fontFamily: 'monospace',
      );
      final idTextPainter = TextPainter(
        text: TextSpan(text: certificateNumber, style: idStyle),
        textDirection: TextDirection.ltr,
      );
      idTextPainter.layout();
      idTextPainter.paint(
        canvas,
        Offset(
          width * 0.75, // Top right
          height * 0.05, // Top position
        ),
      );

      // Username (bottom-left subtle)
      final usernameStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0x99000000),
        fontFamily: 'monospace',
      );
      final usernamePainter = TextPainter(
        text: TextSpan(text: username, style: usernameStyle),
        textDirection: TextDirection.ltr,
      );
      usernamePainter.layout();
      usernamePainter.paint(
        canvas,
        Offset(
          width * 0.08,
          height * 0.90,
        ),
      );

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(width.toInt(), height.toInt());
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Upload to Firebase Storage
      final ref = _storage.ref().child('certificates/$certificateNumber.png');
      final uploadTask = ref.putData(pngBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error generating certificate image: $e');
      return null;
    }
  }

  /// Generate PDF version using the background template and placeholders
  Future<String?> _generateCertificatePDF({
    required String certificateNumber,
    required String userName,
    required String username,
    required String courseTitle,
    required DateTime issueDate,
  }) async {
    try {
      final pdf = pw.Document();

      // Load template image from assets
      final bytes = await rootBundle.load(_certificateTemplateAsset);
      final image = pw.MemoryImage(bytes.buffer.asUint8List());
      final verifyUrl = 'https://myapp.com/verify?cert=$certificateNumber';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Background template
                pw.Positioned.fill(
                  child: pw.Image(image, fit: pw.BoxFit.cover),
                ),
                // Overlay texts replacing placeholders
                pw.Positioned(
                  left: 0,
                  right: 0,
                  top: PdfPageFormat.a4.availableHeight * 0.35,
                  child: pw.Center(
                    child: pw.Text(
                      userName,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red,
                      ),
                    ),
                  ),
                ),
                pw.Positioned(
                  left: 0,
                  right: 0,
                  top: PdfPageFormat.a4.availableHeight * 0.45,
                  child: pw.Center(
                    child: pw.Text(
                      courseTitle.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ),
                pw.Positioned(
                  right: PdfPageFormat.a4.availableWidth * 0.10,
                  bottom: PdfPageFormat.a4.availableHeight * 0.10,
                  child: pw.Text(
                    _formatDate(issueDate),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                ),
                pw.Positioned(
                  right: PdfPageFormat.a4.availableWidth * 0.10,
                  top: PdfPageFormat.a4.availableHeight * 0.05,
                  child: pw.Text(
                    certificateNumber,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.Positioned(
                  left: PdfPageFormat.a4.availableWidth * 0.10,
                  bottom: PdfPageFormat.a4.availableHeight * 0.08,
                  child: pw.Text(
                    username,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                // QR code bottom-right
                pw.Positioned(
                  right: PdfPageFormat.a4.availableWidth * 0.08,
                  bottom: PdfPageFormat.a4.availableHeight * 0.06,
                  child: pw.Container(
                    width: 80,
                    height: 80,
                    padding: const pw.EdgeInsets.all(4),
                    color: PdfColors.white,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: verifyUrl,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Convert to bytes
      final pdfBytes = await pdf.save();

      // Upload to Firebase Storage
      final ref = _storage.ref().child('certificates/$certificateNumber.pdf');
      final uploadTask = ref.putData(pdfBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error generating certificate PDF: $e');
      return null;
    }
  }

  /// Get certificate eligibility threshold from admin settings
  Future<double> _getCertificateEligibilityThreshold() async {
    try {
      final doc = await _firestore.collection('appSettings').doc('app_settings').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['certificateEligibility'] ?? 75.0).toDouble();
      }
      return 75.0; // Default threshold
    } catch (e) {
      return 75.0; // Default threshold
    }
  }

  /// Check if certificate already exists
  Future<Map<String, dynamic>?> _checkExistingCertificate(String userId, String courseId) async {
    try {
      final query = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generate unique certificate number
  String _generateCertificateNumber({required String courseCode}) {
    final now = DateTime.now();
    final ts = '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}${now.second.toString().padLeft(2,'0')}';
    final rand = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();
    final shortCourse = courseCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final trimmed = shortCourse.length > 6 ? shortCourse.substring(0,6) : shortCourse;
    return 'H4U-$trimmed-$ts-$rand';
  }

  /// Format date for certificate
  String _formatDate(DateTime date) {
    final months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    
    return '${day}${_getOrdinalSuffix(day)} $month $year';
  }

  /// Get ordinal suffix for day
  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'TH';
    }
    switch (day % 10) {
      case 1:
        return 'ST';
      case 2:
        return 'ND';
      case 3:
        return 'RD';
      default:
        return 'TH';
    }
  }

  /// Get user's certificates
  Future<List<Map<String, dynamic>>> getUserCertificates(String userId) async {
    try {
      final query = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Error getting user certificates: $e');
      return [];
    }
  }

  /// Download certificate as PDF
  Future<String?> downloadCertificateAsPDF(String certificateId) async {
    try {
      final query = await _firestore
          .collection('certificates')
          .where('certificateId', isEqualTo: certificateId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        return data['certificatePdfUrl'];
      }
      return null;
    } catch (e) {
      print('Error downloading certificate PDF: $e');
      return null;
    }
  }

  /// Verify certificate validity
  Future<bool> verifyCertificate(String certificateId) async {
    try {
      final query = await _firestore
          .collection('certificates')
          .where('certificateId', isEqualTo: certificateId)
          .where('isValid', isEqualTo: true)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error verifying certificate: $e');
      return false;
    }
  }
}
