import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewCertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _reviews => _firestore.collection('reviews');
  CollectionReference get _enrollments => _firestore.collection('enrollments');

  Future<Map<String, dynamic>?> checkCertificateEligibility(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Check enrollment and progress
      final enrollmentQuery = await _enrollments
          .where('studentEmail', isEqualTo: user.email)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      bool courseCompleted = false;
      double progressPercentage = 0.0;
      bool reviewWritten = false;

      if (enrollmentQuery.docs.isNotEmpty) {
        final data = enrollmentQuery.docs.first.data() as Map<String, dynamic>;
        courseCompleted = (data['progressPercent'] ?? 0.0) >= 100.0 ||
            (data['enrollmentStatus'] == 'Completed');
        progressPercentage = (data['progressPercent'] is num)
            ? (data['progressPercent'] as num).toDouble()
            : 0.0;
      }

      // Check if user has written a review for this course
      final reviewQuery = await _reviews
          .where('courseId', isEqualTo: courseId)
          .where('studentEmail', isEqualTo: user.email)
          .limit(1)
          .get();
      reviewWritten = reviewQuery.docs.isNotEmpty;

      final canUnlock = courseCompleted && reviewWritten;
      final reason = canUnlock
          ? 'You are eligible to unlock your certificate.'
          : !courseCompleted
              ? 'Complete the course to unlock your certificate.'
              : 'Write a review to unlock your certificate.';

      return {
        'canUnlock': canUnlock,
        'reason': reason,
        'requirements': {
          'courseCompleted': courseCompleted,
          'progressPercentage': progressPercentage,
          'reviewWritten': reviewWritten,
        },
      };
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCourseReviews({
    required String courseId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _reviews
          .where('courseId', isEqualTo: courseId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
          'userName': data['studentName'] ?? data['userName'],
          'userAvatar': data['userAvatar'],
          'rating': data['rating'],
          'reviewText': data['comment'] ?? data['reviewText'] ?? data['review'],
          'tags': data['tags'] ?? [],
          'helpfulCount': data['helpful'] ?? data['helpfulCount'] ?? 0,
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> submitReview({
    required String courseId,
    required String courseTitle,
    required int rating,
    required String reviewText,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final data = {
        'courseId': courseId,
        'courseTitle': courseTitle,
        'rating': rating,
        'comment': reviewText,
        'tags': tags ?? <String>[],
        'studentName': user.displayName ?? 'Anonymous',
        'studentEmail': user.email ?? '',
        'status': 'Pending',
        'helpful': 0,
        'reported': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _reviews.add(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markReviewHelpful(String reviewId) async {
    try {
      await _reviews.doc(reviewId).update({
        'helpful': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  Future<bool> reportReview(String reviewId, {String reason = 'unspecified'}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await _firestore.collection('community_reports').add({
        'contentId': reviewId,
        'contentType': 'review',
        'reason': reason,
        'reportedBy': user.uid,
        'reportedByEmail': user.email ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _reviews.doc(reviewId).update({'reported': true});
      return true;
    } catch (_) {
      return false;
    }
  }
}


