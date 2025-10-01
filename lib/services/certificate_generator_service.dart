import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'storage_service.dart';

class CertificateGeneratorService {
  // Asset path for provided certificate background image
  static const String _certificateTemplateAsset = 'assets/CERTIFICATE.jpg';

  // Generate certificate with user data
  static Future<String?> generateCertificate({
    required String userId,
    required String courseId,
    required String courseName,
    required String userName,
  }) async {
    try {
      // Generate unique certificate ID
      final certificateId = _generateCertificateId();
      final issueDate = DateTime.now();

      // Create certificate data
      final certificateData = {
        'certificateId': certificateId,
        'userId': userId,
        'courseId': courseId,
        'courseName': courseName,
        'userName': userName,
        'issueDate': issueDate,
        'issuedBy': 'HACKETHOS4U',
        'directorName': 'MANITEJA THAGARAM',
        'directorTitle': 'DIRECTOR & CEO',
        'companyLogo': '',
        'isValid': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save certificate data to Firestore
      await FirebaseFirestore.instance
          .collection('certificates')
          .add(certificateData);

      // Generate certificate image
      final certificateImageUrl = await _generateCertificateImage(
        certificateId: certificateId,
        courseName: courseName,
        userName: userName,
        issueDate: issueDate,
      );

      // Update certificate with image URL
      await FirebaseFirestore.instance
          .collection('certificates')
          .where('certificateId', isEqualTo: certificateId)
          .limit(1)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          querySnapshot.docs.first.reference.update({
            'certificateImageUrl': certificateImageUrl,
          });
        }
      });

      return certificateImageUrl;
    } catch (e) {
      // print('Error generating certificate: $e');
      return null;
    }
  }

  // Generate certificate image with text overlay
  static Future<String?> _generateCertificateImage({
    required String certificateId,
    required String courseName,
    required String userName,
    required DateTime issueDate,
  }) async {
    try {
      // 1) Load background certificate image from assets
      final bgBytes = await rootBundle.load(_certificateTemplateAsset);
      final Uint8List bgList = bgBytes.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bgList);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image bgImage = frameInfo.image;

      final double width = bgImage.width.toDouble();
      final double height = bgImage.height.toDouble();

      // 2) Prepare canvas
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw background
      final paint = Paint();
      canvas.drawImage(bgImage, const Offset(0, 0), paint);

      // Helper to draw text
      void drawText(String text, double x, double y, double fontSize,
          {FontWeight fontWeight = FontWeight.w600, Color color = Colors.black, TextAlign align = TextAlign.left}) {
        final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: align,
            maxLines: 2,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        )
          ..pushStyle(ui.TextStyle(color: color))
          ..addText(text);
        final ui.Paragraph paragraph = builder.build()
          ..layout(ui.ParagraphConstraints(width: width));

        double dx = x;
        if (align == TextAlign.center) {
          dx = x - (paragraph.maxIntrinsicWidth / 2);
        } else if (align == TextAlign.right) {
          dx = x - paragraph.maxIntrinsicWidth;
        }
        canvas.drawParagraph(paragraph, Offset(dx, y));
      }

      // 3) Overlay dynamic fields matching the provided template positions
      // Positions are relative; tuned for the provided image aspect
      // Title name (user name) – centered
      drawText(userName, width * 0.35, height * 0.42, width * 0.055,
          fontWeight: FontWeight.w700, color: const Color(0xFF982F2F));

      // Course name emphasized within the body line (render bold segment)
      drawText('In recognition of outstanding achievement and commitment to',
          width * 0.07, height * 0.49, width * 0.020,
          fontWeight: FontWeight.w500, color: const Color(0xFF333333));
      drawText('excellence in completing the', width * 0.07, height * 0.515,
          width * 0.020,
          fontWeight: FontWeight.w500, color: const Color(0xFF333333));
      drawText(courseName.toUpperCase(), width * 0.37, height * 0.515,
          width * 0.022,
          fontWeight: FontWeight.w800, color: const Color(0xFF000000));

      // Certificate ID (top-right corner similar to sample)
      drawText(certificateId, width * 0.92, height * 0.03, width * 0.018,
          fontWeight: FontWeight.w600, color: const Color(0xFF333333), align: TextAlign.right);

      // Director name & title near stamp area (bottom-left)
      drawText('MANITEJA THAGARAM', width * 0.11, height * 0.78, width * 0.018,
          fontWeight: FontWeight.w800, color: const Color(0xFF111111));
      drawText('DIRECTOR  &  CEO', width * 0.11, height * 0.805, width * 0.015,
          fontWeight: FontWeight.w600, color: const Color(0xFF982F2F));

      // Issue date (bottom-center area)
      drawText('ISSUED DATE:', width * 0.50, height * 0.80, width * 0.017,
          fontWeight: FontWeight.w800, color: const Color(0xFF111111));
      drawText(_formatDate(issueDate), width * 0.63, height * 0.802, width * 0.017,
          fontWeight: FontWeight.w700, color: const Color(0xFF982F2F));

      // 4) Finalize image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(bgImage.width, bgImage.height);
      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 5) Save to temp file and upload to Firebase Storage
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$certificateId.png';
      final file = io.File(filePath);
      await file.writeAsBytes(pngBytes);

      final storage = StorageService();
      final url = await storage.uploadImage(
        imagePath: filePath,
        folder: 'certificates',
        fileName: '$certificateId.png',
      );

      return url;
    } catch (e) {
      // print('Error generating certificate image: $e');
      return null;
    }
  }

  // Build certificate widget
  static Widget _buildCertificateWidget({
    required String certificateId,
    required String courseName,
    required String userName,
    required DateTime issueDate,
  }) {
    return Container(
      width: 800,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[900]!, Colors.blue[700]!],
              ),
            ),
            child: Row(
              children: [
                // Company Logo placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'H4U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HACKETHOS4U',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Certificate ID: $certificateId',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'CERTIFICATE OF COMPLETION',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'This is to certify that',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // User name with underline
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.blue[600]!,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'has successfully completed the course',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Course name
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      courseName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Issue date
                  Text(
                    'Issued on: ${_formatDate(issueDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Director signature
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Center(
                        child: Text(
                          'Signature',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'MANITEJA THAGARAM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'DIRECTOR & CEO',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                // Company info
                Column(
                  children: [
                    const Text(
                      'HACKETHOS4U',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Certified Learning Platform',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ISO 9001:2015 CERTIFIED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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

  // Note: retained for reference but no longer used. Generation now paints directly on the template.
  static Future<String?> _widgetToImage(Widget widget) async {
    return null;
  }

  // Generate unique certificate ID
  static String _generateCertificateId() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random =
        (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'H4U$year$month$day$random';
  }

  // Format date for display
  static String _formatDate(DateTime date) {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return '${date.day.toString().padLeft(2, '0')}TH ${months[date.month - 1]} ${date.year}';
  }

  // Get user certificates
  static Future<List<Map<String, dynamic>>> getUserCertificates(
      String userId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      // print('Error getting user certificates: $e');
      return [];
    }
  }

  // Verify certificate
  static Future<Map<String, dynamic>?> verifyCertificate(
      String certificateId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('certificates')
          .where('certificateId', isEqualTo: certificateId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return {
          'id': query.docs.first.id,
          ...query.docs.first.data(),
        };
      }
      return null;
    } catch (e) {
      // print('Error verifying certificate: $e');
      return null;
    }
  }
}
