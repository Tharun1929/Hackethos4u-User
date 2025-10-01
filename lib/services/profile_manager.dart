import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' as dart_io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_storage_service.dart';
// import 'robust_upload_service.dart';

/// Comprehensive user profile management system
class ProfileManager {
  static final ProfileManager _instance = ProfileManager._internal();
  factory ProfileManager() => _instance;
  ProfileManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection('user_profiles').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return {...data, 'id': doc.id};
    } catch (e) {
      // print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Create user profile
  Future<bool> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? location,
    String? website,
    List<String>? interests,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final profileData = {
        'userId': userId,
        'email': email,
        'displayName': displayName ?? '',
        'photoUrl': photoUrl ?? '',
        'phoneNumber': phoneNumber ?? '',
        'bio': bio ?? '',
        'location': location ?? '',
        'website': website ?? '',
        'interests': interests ?? [],
        'preferences': preferences ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'isVerified': false,
        'lastLogin': FieldValue.serverTimestamp(),
        'loginCount': 1,
      };

      await _firestore.collection('user_profiles').doc(userId).set(profileData);
      // print('✅ User profile created: $userId');
      return true;
    } catch (e) {
      // print('❌ Error creating user profile: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? location,
    String? website,
    String? phoneNumber,
    List<String>? interests,
    Map<String, dynamic>? preferences,
    bool? isPublic,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (location != null) updateData['location'] = location;
      if (website != null) updateData['website'] = website;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (interests != null) updateData['interests'] = interests;
      if (preferences != null) updateData['preferences'] = preferences;
      if (isPublic != null) updateData['isPublic'] = isPublic;

      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update(updateData);

      // Update Firebase Auth profile
      if (displayName != null) {
        await _auth.currentUser?.updateDisplayName(displayName);
      }

      // print('✅ User profile updated: $userId');
      return true;
    } catch (e) {
      // print('❌ Error updating user profile: $e');
      return false;
    }
  }

  /// Upload profile picture
  Future<String?> uploadProfilePicture(dart_io.File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload image via Firebase Storage
      String? imageUrl;
      if (kIsWeb) {
        // For web, we need to handle file uploads differently
        throw Exception(
            'Web file upload not supported in this method. Use uploadBytes instead.');
      } else {
        imageUrl = await FirebaseStorageService.uploadImage(
          imageFile: imageFile,
          folder: 'profile_pictures',
          fileName:
              'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      if (imageUrl != null) {
        // Update profile with new photo URL
        await _firestore.collection('user_profiles').doc(user.uid).update({
          'photoUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update Firebase Auth photo URL
        await _auth.currentUser?.updatePhotoURL(imageUrl);

        // print('✅ Profile picture uploaded: $imageUrl');
        return imageUrl;
      }

      return null;
    } catch (e) {
      // print('❌ Error uploading profile picture: $e');
      return null;
    }
  }

  /// Delete profile picture
  Future<bool> deleteProfilePicture() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update profile to remove photo URL
      await _firestore.collection('user_profiles').doc(user.uid).update({
        'photoUrl': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth photo URL
      await _auth.currentUser?.updatePhotoURL(null);

      // print('✅ Profile picture deleted');
      return true;
    } catch (e) {
      // print('❌ Error deleting profile picture: $e');
      return false;
    }
  }

  /// Update user preferences
  Future<bool> updatePreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print('✅ User preferences updated: $userId');
      return true;
    } catch (e) {
      // print('❌ Error updating preferences: $e');
      return false;
    }
  }

  /// Add interest
  Future<bool> addInterest(String userId, String interest) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).update({
        'interests': FieldValue.arrayUnion([interest]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print('✅ Interest added: $interest');
      return true;
    } catch (e) {
      // print('❌ Error adding interest: $e');
      return false;
    }
  }

  /// Remove interest
  Future<bool> removeInterest(String userId, String interest) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).update({
        'interests': FieldValue.arrayRemove([interest]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print('✅ Interest removed: $interest');
      return true;
    } catch (e) {
      // print('❌ Error removing interest: $e');
      return false;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get enrollment count
      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .get();

      // Get completed courses count
      final completedCoursesSnapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Get certificates count
      final certificatesSnapshot = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .get();

      // Get assignments submitted count
      final assignmentsSnapshot = await _firestore
          .collection('assignment_submissions')
          .where('studentId', isEqualTo: userId)
          .get();

      // Get community posts count
      final postsSnapshot = await _firestore
          .collection('community_posts')
          .where('authorId', isEqualTo: userId)
          .get();

      return {
        'totalEnrollments': enrollmentsSnapshot.docs.length,
        'completedCourses': completedCoursesSnapshot.docs.length,
        'certificatesEarned': certificatesSnapshot.docs.length,
        'assignmentsSubmitted': assignmentsSnapshot.docs.length,
        'communityPosts': postsSnapshot.docs.length,
        'completionRate': enrollmentsSnapshot.docs.isNotEmpty
            ? (completedCoursesSnapshot.docs.length /
                enrollmentsSnapshot.docs.length *
                100)
            : 0.0,
      };
    } catch (e) {
      // print('❌ Error getting user stats: $e');
      return {
        'totalEnrollments': 0,
        'completedCourses': 0,
        'certificatesEarned': 0,
        'assignmentsSubmitted': 0,
        'communityPosts': 0,
        'completionRate': 0.0,
      };
    }
  }

  /// Get user activity
  Future<List<Map<String, dynamic>>> getUserActivity(String userId,
      {int limit = 50}) async {
    try {
      final activities = <Map<String, dynamic>>[];

      // Get recent enrollments
      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .orderBy('enrolledAt', descending: true)
          .limit(10)
          .get();

      for (final doc in enrollmentsSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'enrollment',
          'title': 'Enrolled in ${data['courseTitle']}',
          'description': 'You enrolled in a new course',
          'timestamp': data['enrolledAt'],
          'data': data,
        });
      }

      // Get recent certificates
      final certificatesSnapshot = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      for (final doc in certificatesSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'certificate',
          'title': 'Certificate earned for ${data['courseTitle']}',
          'description': 'You earned a certificate',
          'timestamp': data['createdAt'],
          'data': data,
        });
      }

      // Get recent assignments
      final assignmentsSnapshot = await _firestore
          .collection('assignment_submissions')
          .where('studentId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .limit(10)
          .get();

      for (final doc in assignmentsSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'assignment',
          'title': 'Assignment submitted: ${data['title']}',
          'description': 'You submitted an assignment',
          'timestamp': data['submittedAt'],
          'data': data,
        });
      }

      // Sort by timestamp
      activities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return activities.take(limit).toList();
    } catch (e) {
      // print('❌ Error getting user activity: $e');
      return [];
    }
  }

  /// Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      // Note: This is a basic search. For production, consider using Algolia or similar
      final snapshot = await _firestore
          .collection('user_profiles')
          .where('isPublic', isEqualTo: true)
          .get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();

      // Filter by query
      return users.where((user) {
        final name = (user['displayName'] as String? ?? '').toLowerCase();
        final bio = (user['bio'] as String? ?? '').toLowerCase();
        final location = (user['location'] as String? ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) ||
            bio.contains(searchQuery) ||
            location.contains(searchQuery);
      }).toList();
    } catch (e) {
      // print('❌ Error searching users: $e');
      return [];
    }
  }

  /// Follow user
  Future<bool> followUser(String userId, String targetUserId) async {
    try {
      // Add to following list
      await _firestore.collection('user_profiles').doc(userId).update({
        'following': FieldValue.arrayUnion([targetUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to followers list
      await _firestore.collection('user_profiles').doc(targetUserId).update({
        'followers': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print('✅ User followed: $targetUserId');
      return true;
    } catch (e) {
      // print('❌ Error following user: $e');
      return false;
    }
  }

  /// Unfollow user
  Future<bool> unfollowUser(String userId, String targetUserId) async {
    try {
      // Remove from following list
      await _firestore.collection('user_profiles').doc(userId).update({
        'following': FieldValue.arrayRemove([targetUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from followers list
      await _firestore.collection('user_profiles').doc(targetUserId).update({
        'followers': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print('✅ User unfollowed: $targetUserId');
      return true;
    } catch (e) {
      // print('❌ Error unfollowing user: $e');
      return false;
    }
  }

  /// Get followers
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final profileDoc =
          await _firestore.collection('user_profiles').doc(userId).get();
      if (!profileDoc.exists) return [];

      final data = profileDoc.data() as Map<String, dynamic>;
      final followers = List<String>.from(data['followers'] ?? []);

      if (followers.isEmpty) return [];

      final followersSnapshot = await _firestore
          .collection('user_profiles')
          .where(FieldPath.documentId, whereIn: followers)
          .get();

      return followersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting followers: $e');
      return [];
    }
  }

  /// Get following
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final profileDoc =
          await _firestore.collection('user_profiles').doc(userId).get();
      if (!profileDoc.exists) return [];

      final data = profileDoc.data() as Map<String, dynamic>;
      final following = List<String>.from(data['following'] ?? []);

      if (following.isEmpty) return [];

      final followingSnapshot = await _firestore
          .collection('user_profiles')
          .where(FieldPath.documentId, whereIn: following)
          .get();

      return followingSnapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting following: $e');
      return [];
    }
  }

  /// Delete user profile
  Future<bool> deleteUserProfile(String userId) async {
    try {
      // Delete profile document
      await _firestore.collection('user_profiles').doc(userId).delete();

      // Delete user's enrollments
      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in enrollmentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // print('✅ User profile deleted: $userId');
      return true;
    } catch (e) {
      // print('❌ Error deleting user profile: $e');
      return false;
    }
  }

  /// Update last login
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'loginCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('❌ Error updating last login: $e');
    }
  }
}
