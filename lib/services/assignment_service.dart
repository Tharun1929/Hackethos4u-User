import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' as dart_io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_storage_service.dart';
// import 'robust_upload_service.dart';

/// Comprehensive assignment submission and management system
class AssignmentService {
  static final AssignmentService _instance = AssignmentService._internal();
  factory AssignmentService() => _instance;
  AssignmentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create assignment
  Future<String?> createAssignment({
    required String courseId,
    required String title,
    required String description,
    required DateTime dueDate,
    required int maxMarks,
    required List<String> allowedFileTypes,
    required int maxFileSize, // in MB
    String? instructions,
    List<String>? attachments,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final assignmentData = {
        'courseId': courseId,
        'title': title,
        'description': description,
        'instructions': instructions ?? '',
        'dueDate': dueDate,
        'maxMarks': maxMarks,
        'allowedFileTypes': allowedFileTypes,
        'maxFileSize': maxFileSize,
        'attachments': attachments ?? [],
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'submissionCount': 0,
      };

      final docRef =
          await _firestore.collection('assignments').add(assignmentData);
      // print('✅ Assignment created: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      // print('❌ Error creating assignment: $e');
      return null;
    }
  }

  /// Submit assignment
  Future<String?> submitAssignment({
    required String assignmentId,
    required String courseId,
    required String title,
    required String description,
    required List<dart_io.File> files,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get assignment details
      final assignmentDoc =
          await _firestore.collection('assignments').doc(assignmentId).get();
      if (!assignmentDoc.exists) {
        throw Exception('Assignment not found');
      }

      final assignmentData = assignmentDoc.data() as Map<String, dynamic>;
      final dueDate = (assignmentData['dueDate'] as Timestamp).toDate();
      final allowedFileTypes =
          List<String>.from(assignmentData['allowedFileTypes'] ?? []);
      final maxFileSize = assignmentData['maxFileSize'] as int;

      // Check if assignment is still open
      if (DateTime.now().isAfter(dueDate)) {
        throw Exception('Assignment deadline has passed');
      }

      // Validate files
      for (final file in files) {
        if (!await _validateFile(file, allowedFileTypes, maxFileSize)) {
          throw Exception('File validation failed');
        }
      }

      // Upload files
      final List<String> uploadedUrls = [];
      for (final file in files) {
        String? url;
        if (kIsWeb) {
          // For web, we need to handle file uploads differently
          throw Exception(
              'Web file upload not supported in this method. Use uploadBytes instead.');
        } else {
          url = await FirebaseStorageService.uploadDocument(
            documentFile: file,
            folder: 'assignments/$assignmentId',
          );
        }
        if (url != null) {
          uploadedUrls.add(url);
        } else {
          throw Exception('Failed to upload file: ${file.path}');
        }
      }

      // Create submission record
      final submissionData = {
        'assignmentId': assignmentId,
        'courseId': courseId,
        'studentId': user.uid,
        'studentName': user.displayName ?? 'Student',
        'studentEmail': user.email ?? '',
        'title': title,
        'description': description,
        'notes': notes ?? '',
        'files': uploadedUrls,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': null,
        'gradedAt': null,
        'gradedBy': null,
      };

      final docRef = await _firestore
          .collection('assignment_submissions')
          .add(submissionData);

      // Update assignment submission count
      await _firestore.collection('assignments').doc(assignmentId).update({
        'submissionCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print('✅ Assignment submitted: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      // print('❌ Error submitting assignment: $e');
      return null;
    }
  }

  /// Validate file
  Future<bool> _validateFile(
      dart_io.File file, List<String> allowedTypes, int maxSizeMB) async {
    try {
      // Check file size
      final fileSize = await file.length();
      final maxSizeBytes = maxSizeMB * 1024 * 1024;
      if (fileSize > maxSizeBytes) {
        // print('❌ File too large: ${fileSize ~/ (1024 * 1024)}MB > ${maxSizeMB}MB');
        return false;
      }

      // Check file type
      final extension = file.path.split('.').last.toLowerCase();
      if (!allowedTypes.contains(extension)) {
        // print('❌ File type not allowed: $extension');
        return false;
      }

      return true;
    } catch (e) {
      // print('❌ Error validating file: $e');
      return false;
    }
  }

  /// Grade assignment
  Future<bool> gradeAssignment({
    required String submissionId,
    required int grade,
    required String feedback,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get submission details
      final submissionDoc = await _firestore
          .collection('assignment_submissions')
          .doc(submissionId)
          .get();
      if (!submissionDoc.exists) {
        throw Exception('Submission not found');
      }

      final submissionData = submissionDoc.data() as Map<String, dynamic>;
      final maxMarks = await _getAssignmentMaxMarks(
          submissionData['assignmentId'] as String);

      if (grade > maxMarks) {
        throw Exception('Grade cannot exceed maximum marks');
      }

      // Update submission with grade
      await _firestore
          .collection('assignment_submissions')
          .doc(submissionId)
          .update({
        'grade': grade,
        'feedback': feedback,
        'status': 'graded',
        'gradedAt': FieldValue.serverTimestamp(),
        'gradedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print('✅ Assignment graded: $submissionId');
      return true;
    } catch (e) {
      // print('❌ Error grading assignment: $e');
      return false;
    }
  }

  /// Get assignment max marks
  Future<int> _getAssignmentMaxMarks(String assignmentId) async {
    try {
      final assignmentDoc =
          await _firestore.collection('assignments').doc(assignmentId).get();
      if (!assignmentDoc.exists) return 100;

      final data = assignmentDoc.data() as Map<String, dynamic>;
      return data['maxMarks'] as int? ?? 100;
    } catch (e) {
      // print('❌ Error getting assignment max marks: $e');
      return 100;
    }
  }

  /// Get assignments for course
  Future<List<Map<String, dynamic>>> getCourseAssignments(
      String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting course assignments: $e');
      return [];
    }
  }

  /// Get student submissions
  Future<List<Map<String, dynamic>>> getStudentSubmissions(
      String assignmentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: user.uid)
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting student submissions: $e');
      return [];
    }
  }

  /// Get all submissions for assignment (for instructors)
  Future<List<Map<String, dynamic>>> getAssignmentSubmissions(
      String assignmentId) async {
    try {
      final snapshot = await _firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting assignment submissions: $e');
      return [];
    }
  }

  /// Get assignment details
  Future<Map<String, dynamic>?> getAssignmentDetails(
      String assignmentId) async {
    try {
      final doc =
          await _firestore.collection('assignments').doc(assignmentId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return {...data, 'id': doc.id};
    } catch (e) {
      // print('❌ Error getting assignment details: $e');
      return null;
    }
  }

  /// Check if student has submitted
  Future<bool> hasStudentSubmitted(String assignmentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: user.uid)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // print('❌ Error checking submission status: $e');
      return false;
    }
  }

  /// Get assignment statistics
  Future<Map<String, dynamic>> getAssignmentStats(String assignmentId) async {
    try {
      final submissionsSnapshot = await _firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      final totalSubmissions = submissionsSnapshot.docs.length;
      final gradedSubmissions = submissionsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'graded')
          .length;

      double averageGrade = 0.0;
      if (gradedSubmissions > 0) {
        final totalGrade = submissionsSnapshot.docs
            .where((doc) => doc.data()['grade'] != null)
            .fold(0, (sum, doc) => sum + (doc.data()['grade'] as int? ?? 0));
        averageGrade = totalGrade / gradedSubmissions;
      }

      return {
        'totalSubmissions': totalSubmissions,
        'gradedSubmissions': gradedSubmissions,
        'pendingSubmissions': totalSubmissions - gradedSubmissions,
        'averageGrade': averageGrade,
      };
    } catch (e) {
      // print('❌ Error getting assignment stats: $e');
      return {
        'totalSubmissions': 0,
        'gradedSubmissions': 0,
        'pendingSubmissions': 0,
        'averageGrade': 0.0,
      };
    }
  }

  /// Delete assignment
  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      // Delete assignment
      await _firestore.collection('assignments').doc(assignmentId).delete();

      // Delete all submissions
      final submissionsSnapshot = await _firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      final batch = _firestore.batch();
      for (final doc in submissionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // print('✅ Assignment deleted: $assignmentId');
      return true;
    } catch (e) {
      // print('❌ Error deleting assignment: $e');
      return false;
    }
  }

  /// Update assignment
  Future<bool> updateAssignment({
    required String assignmentId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? maxMarks,
    List<String>? allowedFileTypes,
    int? maxFileSize,
    String? instructions,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (dueDate != null) updateData['dueDate'] = dueDate;
      if (maxMarks != null) updateData['maxMarks'] = maxMarks;
      if (allowedFileTypes != null) {
        updateData['allowedFileTypes'] = allowedFileTypes;
      }
      if (maxFileSize != null) updateData['maxFileSize'] = maxFileSize;
      if (instructions != null) updateData['instructions'] = instructions;

      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update(updateData);
      // print('✅ Assignment updated: $assignmentId');
      return true;
    } catch (e) {
      // print('❌ Error updating assignment: $e');
      return false;
    }
  }
}
