import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../services/firebase_storage_service.dart';

class CourseContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get coursesCollection => _firestore.collection('courses');
  CollectionReference get lessonsCollection => _firestore.collection('lessons');
  CollectionReference get materialsCollection =>
      _firestore.collection('materials');
  CollectionReference get progressCollection =>
      _firestore.collection('user_progress');

  // ===== COURSE CONTENT MANAGEMENT =====

  // Add lesson to course
  Future<String> addLesson({
    required String courseId,
    required String title,
    required String description,
    required String videoUrl,
    required int order,
    required int duration,
    List<String>? materials,
  }) async {
    try {
      final lessonData = {
        'courseId': courseId,
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'order': order,
        'duration': duration, // in minutes
        'materials': materials ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await lessonsCollection.add(lessonData);

      // Update course with lesson count
      await coursesCollection.doc(courseId).update({
        'lessonCount': FieldValue.increment(1),
        'totalDuration': FieldValue.increment(duration),
      });

      return docRef.id;
    } catch (e) {
      // print('Error adding lesson: $e');
      rethrow;
    }
  }

  // Get course lessons
  Future<List<Map<String, dynamic>>> getCourseLessons(String courseId) async {
    try {
      final querySnapshot = await lessonsCollection
          .where('courseId', isEqualTo: courseId)
          .orderBy('order')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      // print('Error getting course lessons: $e');
      return [];
    }
  }

  // Get lesson by ID
  Future<Map<String, dynamic>?> getLessonById(String lessonId) async {
    try {
      final doc = await lessonsCollection.doc(lessonId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }
      return null;
    } catch (e) {
      // print('Error getting lesson: $e');
      return null;
    }
  }

  // Update lesson
  Future<void> updateLesson(String lessonId, Map<String, dynamic> data) async {
    try {
      await lessonsCollection.doc(lessonId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error updating lesson: $e');
      rethrow;
    }
  }

  // Delete lesson
  Future<void> deleteLesson(String lessonId) async {
    try {
      final lesson = await getLessonById(lessonId);
      if (lesson != null) {
        // Update course stats
        await coursesCollection.doc(lesson['courseId']).update({
          'lessonCount': FieldValue.increment(-1),
          'totalDuration': FieldValue.increment(-(lesson['duration'] ?? 0)),
        });
      }

      await lessonsCollection.doc(lessonId).delete();
    } catch (e) {
      // print('Error deleting lesson: $e');
      rethrow;
    }
  }

  // ===== MATERIAL MANAGEMENT =====

  // Upload course material
  Future<String> uploadMaterial({
    required String courseId,
    required String title,
    required String description,
    required File file,
    required String fileType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload file to Firebase Storage
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final downloadUrl = await FirebaseStorageService.uploadFile(
        file: file,
        folder: 'course_materials/$courseId',
        fileName: fileName,
      );

      // Save material metadata to Firestore
      final materialData = {
        'courseId': courseId,
        'title': title,
        'description': description,
        'fileUrl': downloadUrl,
        'fileName': fileName,
        'fileType': fileType,
        'fileSize': await file.length(),
        'uploadedBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await materialsCollection.add(materialData);
      return docRef.id;
    } catch (e) {
      // print('Error uploading material: $e');
      rethrow;
    }
  }

  // Get course materials
  Future<List<Map<String, dynamic>>> getCourseMaterials(String courseId) async {
    try {
      final querySnapshot = await materialsCollection
          .where('courseId', isEqualTo: courseId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      // print('Error getting course materials: $e');
      return [];
    }
  }

  // Delete material
  Future<void> deleteMaterial(String materialId) async {
    try {
      final material = await materialsCollection.doc(materialId).get();
      if (material.exists) {
        final data = material.data() as Map<String, dynamic>;

        // Delete from Firebase Storage
        await FirebaseStorageService.deleteFile(data['fileUrl']);

        // Delete from Firestore
        await materialsCollection.doc(materialId).delete();
      }
    } catch (e) {
      // print('Error deleting material: $e');
      rethrow;
    }
  }

  // ===== USER PROGRESS TRACKING =====

  // Update lesson progress
  Future<void> updateLessonProgress({
    required String courseId,
    required String lessonId,
    required double progress, // 0.0 to 1.0
    required bool isCompleted,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final progressData = {
        'userId': user.uid,
        'courseId': courseId,
        'lessonId': lessonId,
        'progress': progress,
        'isCompleted': isCompleted,
        'lastAccessed': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await progressCollection
          .doc('${user.uid}_$lessonId')
          .set(progressData, SetOptions(merge: true));
    } catch (e) {
      // print('Error updating lesson progress: $e');
    }
  }

  // Get user progress for course
  Future<Map<String, dynamic>> getUserCourseProgress(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final querySnapshot = await progressCollection
          .where('userId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: courseId)
          .get();

      final lessons = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      // Calculate overall progress
      double totalProgress = 0.0;
      int completedLessons = 0;
      int totalLessons = lessons.length;

      for (final lesson in lessons) {
        totalProgress += lesson['progress'] ?? 0.0;
        if (lesson['isCompleted'] == true) {
          completedLessons++;
        }
      }

      final overallProgress =
          totalLessons > 0 ? totalProgress / totalLessons : 0.0;

      return {
        'lessons': lessons,
        'overallProgress': overallProgress,
        'completedLessons': completedLessons,
        'totalLessons': totalLessons,
      };
    } catch (e) {
      // print('Error getting user progress: $e');
      return {};
    }
  }

  // Get lesson progress
  Future<Map<String, dynamic>?> getLessonProgress(String lessonId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await progressCollection.doc('${user.uid}_$lessonId').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }
      return null;
    } catch (e) {
      // print('Error getting lesson progress: $e');
      return null;
    }
  }

  // ===== COURSE COMPLETION =====

  // Mark course as completed
  Future<void> markCourseCompleted(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update enrollment status
      final enrollmentQuery = await _firestore
          .collection('enrollments')
          .where('studentEmail', isEqualTo: user.email)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (enrollmentQuery.docs.isNotEmpty) {
        await enrollmentQuery.docs.first.reference.update({
          'progressPercent': 100.0,
          'completedAt': FieldValue.serverTimestamp(),
          'certificateStatus': 'Issued',
        });
      }

      // Update user stats
      await _firestore.collection('users').doc(user.uid).update({
        'stats.coursesCompleted': FieldValue.increment(1),
        'stats.totalProgress': FieldValue.increment(100.0),
      });
    } catch (e) {
      // print('Error marking course completed: $e');
    }
  }

  // ===== CERTIFICATE GENERATION =====

  // Generate certificate for completed course
  Future<String?> generateCertificate(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Check if course is completed
      final progress = await getUserCourseProgress(courseId);
      if (progress['overallProgress'] < 1.0) {
        throw Exception('Course not completed');
      }

      // Generate certificate URL (in real app, this would call a certificate generation service)
      final certificateUrl =
          'https://example.com/certificates/${user.uid}_$courseId.pdf';

      // Update enrollment with certificate
      final enrollmentQuery = await _firestore
          .collection('enrollments')
          .where('studentEmail', isEqualTo: user.email)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (enrollmentQuery.docs.isNotEmpty) {
        await enrollmentQuery.docs.first.reference.update({
          'certificateUrl': certificateUrl,
          'certificateIssuedAt': FieldValue.serverTimestamp(),
        });
      }

      return certificateUrl;
    } catch (e) {
      // print('Error generating certificate: $e');
      return null;
    }
  }
}
