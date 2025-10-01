import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'enhanced_certificate_service.dart';

class CertificateTriggerService {
  static final CertificateTriggerService _instance = CertificateTriggerService._internal();
  factory CertificateTriggerService() => _instance;
  CertificateTriggerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EnhancedCertificateService _certificateService = EnhancedCertificateService();

  /// Check and generate certificate when course progress is updated
  Future<void> checkAndGenerateCertificate({
    required String courseId,
    required double progressPercentage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get course details
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) return;

      final courseData = courseDoc.data() as Map<String, dynamic>;
      final courseTitle = courseData['title'] ?? 'Course';

      // Get user details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? userData['displayName'] ?? 'Student';

      // Check if certificate eligibility threshold is met
      final eligibilityThreshold = await _getCertificateEligibilityThreshold();
      
      if (progressPercentage >= eligibilityThreshold) {
        // Check if certificate already exists
        final existingCertificate = await _checkExistingCertificate(user.uid, courseId);
        
        if (existingCertificate == null) {
          // Generate new certificate
          final certificateUrl = await _certificateService.generateCertificate(
            courseId: courseId,
            courseTitle: courseTitle,
            userName: userName,
            completionPercentage: progressPercentage,
          );

          if (certificateUrl != null) {
            // Send notification to user
            await _sendCertificateNotification(user.uid, courseTitle, certificateUrl);
            
            // Update enrollment status
            await _updateEnrollmentStatus(user.uid, courseId, 'certificate_eligible');
          }
        }
      }
    } catch (e) {
      print('Error checking certificate generation: $e');
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

  /// Send notification to user about certificate
  Future<void> _sendCertificateNotification(String userId, String courseTitle, String certificateUrl) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Certificate Generated!',
        'message': 'Congratulations! Your certificate for "$courseTitle" has been generated.',
        'type': 'certificate',
        'data': {
          'courseTitle': courseTitle,
          'certificateUrl': certificateUrl,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending certificate notification: $e');
    }
  }

  /// Update enrollment status
  Future<void> _updateEnrollmentStatus(String userId, String courseId, String status) async {
    try {
      final query = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'certificateStatus': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating enrollment status: $e');
    }
  }

  /// Manually trigger certificate generation (for admin use)
  Future<bool> manuallyGenerateCertificate({
    required String userId,
    required String courseId,
  }) async {
    try {
      // Get course details
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) return false;

      final courseData = courseDoc.data() as Map<String, dynamic>;
      final courseTitle = courseData['title'] ?? 'Course';

      // Get user details
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? userData['displayName'] ?? 'Student';

      // Get user's progress for this course
      final progressQuery = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (progressQuery.docs.isEmpty) return false;

      final enrollmentData = progressQuery.docs.first.data();
      final progressPercentage = (enrollmentData['progressPercent'] ?? 0.0).toDouble();

      // Generate certificate
      final certificateUrl = await _certificateService.generateCertificate(
        courseId: courseId,
        courseTitle: courseTitle,
        userName: userName,
        completionPercentage: progressPercentage,
      );

      return certificateUrl != null;
    } catch (e) {
      print('Error manually generating certificate: $e');
      return false;
    }
  }

  /// Get certificate statistics for admin
  Future<Map<String, dynamic>> getCertificateStatistics() async {
    try {
      final certificatesQuery = await _firestore.collection('certificates').get();
      final totalCertificates = certificatesQuery.docs.length;

      // Group by course
      final courseStats = <String, int>{};
      final monthlyStats = <String, int>{};

      for (final doc in certificatesQuery.docs) {
        final data = doc.data();
        final courseId = data['courseId'] ?? 'Unknown';
        final createdAt = data['createdAt'] as Timestamp?;
        
        // Course stats
        courseStats[courseId] = (courseStats[courseId] ?? 0) + 1;
        
        // Monthly stats
        if (createdAt != null) {
          final month = '${createdAt.toDate().year}-${createdAt.toDate().month.toString().padLeft(2, '0')}';
          monthlyStats[month] = (monthlyStats[month] ?? 0) + 1;
        }
      }

      return {
        'totalCertificates': totalCertificates,
        'courseStats': courseStats,
        'monthlyStats': monthlyStats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting certificate statistics: $e');
      return {};
    }
  }
}
