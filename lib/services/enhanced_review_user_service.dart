import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnhancedReviewUserService {
  static final EnhancedReviewUserService _instance =
      EnhancedReviewUserService._internal();
  factory EnhancedReviewUserService() => _instance;
  EnhancedReviewUserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit a review
  Future<bool> submitReview({
    required String courseId,
    required String courseTitle,
    required double rating,
    required String reviewText,
    List<String> tags = const [],
    bool isAnonymous = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user already reviewed this course
      final existingReview = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        throw Exception('You have already reviewed this course');
      }

      final reviewData = {
        'courseId': courseId,
        'courseTitle': courseTitle,
        'userId': user.uid,
        'userName': isAnonymous ? 'Anonymous' : (user.displayName ?? 'Anonymous'),
        'userEmail': user.email ?? '',
        'userAvatar': isAnonymous ? null : user.photoURL,
        'rating': rating,
        'comment': reviewText,
        'tags': tags,
        'isApproved': false, // Requires admin approval
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'flags': [],
        'isAnonymous': isAnonymous,
        'helpfulCount': 0,
        'helpfulBy': [],
        'isReported': false,
        'reports': [],
        'adminNotes': null,
      };

      await _firestore.collection('reviews').add(reviewData);
      return true;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }

  /// Update a review
  Future<bool> updateReview({
    required String reviewId,
    double? rating,
    String? reviewText,
    List<String>? tags,
    bool? isAnonymous,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user owns this review
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) return false;

      final reviewData = reviewDoc.data() as Map<String, dynamic>;
      if (reviewData['userId'] != user.uid) {
        throw Exception('You can only edit your own reviews');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'isApproved': false, // Reset approval status
      };

      if (rating != null) updateData['rating'] = rating;
      if (reviewText != null) updateData['comment'] = reviewText;
      if (tags != null) updateData['tags'] = tags;
      if (isAnonymous != null) {
        updateData['isAnonymous'] = isAnonymous;
        updateData['userName'] = isAnonymous ? 'Anonymous' : (user.displayName ?? 'Anonymous');
        updateData['userAvatar'] = isAnonymous ? null : user.photoURL;
      }

      await _firestore.collection('reviews').doc(reviewId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user owns this review
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) return false;

      final reviewData = reviewDoc.data() as Map<String, dynamic>;
      if (reviewData['userId'] != user.uid) {
        throw Exception('You can only delete your own reviews');
      }

      await _firestore.collection('reviews').doc(reviewId).delete();
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markReviewHelpful(String reviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) return false;

      final reviewData = reviewDoc.data() as Map<String, dynamic>;
      final helpfulBy = List<String>.from(reviewData['helpfulBy'] ?? []);

      if (helpfulBy.contains(user.uid)) {
        // User already marked as helpful, remove it
        await _firestore.collection('reviews').doc(reviewId).update({
          'helpfulBy': FieldValue.arrayRemove([user.uid]),
          'helpfulCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Mark as helpful
        await _firestore.collection('reviews').doc(reviewId).update({
          'helpfulBy': FieldValue.arrayUnion([user.uid]),
          'helpfulCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error marking review helpful: $e');
      return false;
    }
  }

  /// Report a review
  Future<bool> reportReview({
    required String reviewId,
    required String reason,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user already reported this review
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) return false;

      final reviewData = reviewDoc.data() as Map<String, dynamic>;
      final reports = List<String>.from(reviewData['reports'] ?? []);

      if (reports.contains(user.uid)) {
        throw Exception('You have already reported this review');
      }

      // Add report
      await _firestore.collection('reviews').doc(reviewId).update({
        'reports': FieldValue.arrayUnion([user.uid]),
        'isReported': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create report record
      await _firestore.collection('review_reports').add({
        'reviewId': reviewId,
        'reason': reason,
        'description': description,
        'reporterId': user.uid,
        'reporterName': user.displayName ?? 'Anonymous',
        'reporterEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return true;
    } catch (e) {
      print('Error reporting review: $e');
      return false;
    }
  }

  /// Get course reviews
  Future<List<Map<String, dynamic>>> getCourseReviews({
    required String courseId,
    int limit = 20,
    String? lastDocumentId,
    String sortBy = 'createdAt', // 'createdAt', 'rating', 'helpfulCount'
    bool ascending = false,
  }) async {
    try {
      Query query = _firestore
          .collection('reviews')
          .where('courseId', isEqualTo: courseId)
          .where('isApproved', isEqualTo: true)
          .orderBy(sortBy, descending: !ascending)
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('reviews')
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      print('Error getting course reviews: $e');
      return [];
    }
  }

  /// Get user's reviews
  Future<List<Map<String, dynamic>>> getUserReviews({
    String? userId,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      final targetUserId = userId ?? _auth.currentUser?.uid;
      if (targetUserId == null) throw Exception('User not authenticated');

      Query query = _firestore
          .collection('reviews')
          .where('userId', isEqualTo: targetUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('reviews')
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      print('Error getting user reviews: $e');
      return [];
    }
  }

  /// Get recent reviews
  Future<List<Map<String, dynamic>>> getRecentReviews({
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection('reviews')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('reviews')
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      print('Error getting recent reviews: $e');
      return [];
    }
  }

  /// Get top rated courses
  Future<List<Map<String, dynamic>>> getTopRatedCourses({int limit = 10}) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('isApproved', isEqualTo: true)
          .get();

      Map<String, List<double>> courseRatings = {};
      Map<String, String> courseTitles = {};

      for (final doc in reviewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final courseId = data['courseId'] as String?;
        final courseTitle = data['courseTitle'] as String?;
        final rating = (data['rating'] ?? 0.0).toDouble();

        if (courseId != null && courseTitle != null) {
          courseRatings.putIfAbsent(courseId, () => []);
          courseRatings[courseId]!.add(rating);
          courseTitles[courseId] = courseTitle;
        }
      }

      List<Map<String, dynamic>> topCourses = [];
      courseRatings.forEach((courseId, ratings) {
        final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
        topCourses.add({
          'courseId': courseId,
          'courseTitle': courseTitles[courseId],
          'averageRating': averageRating,
          'reviewCount': ratings.length,
        });
      });

      topCourses.sort((a, b) => b['averageRating'].compareTo(a['averageRating']));
      return topCourses.take(limit).toList();
    } catch (e) {
      print('Error getting top rated courses: $e');
      return [];
    }
  }

  /// Get course review statistics
  Future<Map<String, dynamic>> getCourseReviewStats(String courseId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('courseId', isEqualTo: courseId)
          .where('isApproved', isEqualTo: true)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      double totalRating = 0;
      int reviewCount = 0;

      for (final doc in reviewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = (data['rating'] ?? 0.0).toDouble();
        final ratingInt = rating.round();
        if (ratingInt >= 1 && ratingInt <= 5) {
          ratingDistribution[ratingInt] = (ratingDistribution[ratingInt] ?? 0) + 1;
        }
        totalRating += rating;
        reviewCount++;
      }

      final averageRating = totalRating / reviewCount;

      return {
        'totalReviews': reviewCount,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      print('Error getting course review stats: $e');
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  /// Check if user can review course
  Future<Map<String, dynamic>> checkReviewEligibility(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'canReview': false,
          'reason': 'User not authenticated',
        };
      }

      // Check if user already reviewed this course
      final existingReview = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        return {
          'canReview': false,
          'reason': 'You have already reviewed this course',
          'existingReviewId': existingReview.docs.first.id,
        };
      }

      // Check if user is enrolled in the course
      final enrollment = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (enrollment.docs.isEmpty) {
        return {
          'canReview': false,
          'reason': 'You must be enrolled in this course to review it',
        };
      }

      return {
        'canReview': true,
        'reason': 'You can review this course',
      };
    } catch (e) {
      print('Error checking review eligibility: $e');
      return {
        'canReview': false,
        'reason': 'Error checking eligibility',
      };
    }
  }

  /// Search reviews
  Future<List<Map<String, dynamic>>> searchReviews({
    required String query,
    String? courseId,
    double? minRating,
    double? maxRating,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore
          .collection('reviews')
          .where('isApproved', isEqualTo: true)
          .limit(limit);

      if (courseId != null) {
        firestoreQuery = firestoreQuery.where('courseId', isEqualTo: courseId);
      }
      if (minRating != null) {
        firestoreQuery = firestoreQuery.where('rating', isGreaterThanOrEqualTo: minRating);
      }
      if (maxRating != null) {
        firestoreQuery = firestoreQuery.where('rating', isLessThanOrEqualTo: maxRating);
      }

      final snapshot = await firestoreQuery.get();
      List<Map<String, dynamic>> results = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final comment = data['comment']?.toString().toLowerCase() ?? '';
        final courseTitle = data['courseTitle']?.toString().toLowerCase() ?? '';
        final userName = data['userName']?.toString().toLowerCase() ?? '';

        if (comment.contains(query.toLowerCase()) ||
            courseTitle.contains(query.toLowerCase()) ||
            userName.contains(query.toLowerCase())) {
          results.add({...data, 'id': doc.id});
        }
      }

      // Sort by relevance
      results.sort((a, b) {
        final aComment = a['comment']?.toString().toLowerCase() ?? '';
        final bComment = b['comment']?.toString().toLowerCase() ?? '';
        final aTitle = a['courseTitle']?.toString().toLowerCase() ?? '';
        final bTitle = b['courseTitle']?.toString().toLowerCase() ?? '';

        final aScore = (aComment.contains(query.toLowerCase()) ? 2 : 0) +
            (aTitle.contains(query.toLowerCase()) ? 1 : 0);
        final bScore = (bComment.contains(query.toLowerCase()) ? 2 : 0) +
            (bTitle.contains(query.toLowerCase()) ? 1 : 0);

        return bScore.compareTo(aScore);
      });

      return results.take(limit).toList();
    } catch (e) {
      print('Error searching reviews: $e');
      return [];
    }
  }
}
