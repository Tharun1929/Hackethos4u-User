import 'dart:io' as dart_io;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ===== FILE UPLOAD =====

  /// Upload file to Firebase Storage
  Future<String?> uploadFile({
    required String filePath,
    required String folder,
    String? fileName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final lower = filePath.toLowerCase();
      String subfolder = 'misc';
      SettableMetadata metadata =
          SettableMetadata(contentType: 'application/octet-stream');
      if (lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.gif')) {
        subfolder = 'images';
        metadata = SettableMetadata(contentType: 'image/jpeg');
      } else if (lower.endsWith('.mp4') ||
          lower.endsWith('.avi') ||
          lower.endsWith('.mov')) {
        subfolder = 'videos';
        metadata = SettableMetadata(contentType: 'video/mp4');
      } else if (lower.endsWith('.pdf')) {
        subfolder = 'documents';
        metadata = SettableMetadata(contentType: 'application/pdf');
      }

      final name = fileName ?? filePath.split('/').last;
      final ref = _storage.ref().child(
          '$folder/$subfolder/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$name');

      if (kIsWeb) {
        // For web, we need to handle file uploads differently
        throw Exception(
            'Web file upload not supported in this method. Use uploadBytes instead.');
      } else {
        final file = dart_io.File(filePath);
        if (!await file.exists()) {
          throw Exception('File does not exist');
        }
        final task = await ref.putFile(file, metadata);
        return await task.ref.getDownloadURL();
      }
    } catch (e) {
      // print('Error uploading file: $e');
      return null;
    }
  }

  /// Upload image file
  Future<String?> uploadImage({
    required String imagePath,
    String? folder = 'images',
    String? fileName,
  }) async {
    return uploadFile(
      filePath: imagePath,
      folder: folder ?? 'images',
      fileName: fileName,
    );
  }

  /// Upload document file
  Future<String?> uploadDocument({
    required String documentPath,
    String? folder = 'documents',
    String? fileName,
  }) async {
    return uploadFile(
      filePath: documentPath,
      folder: folder ?? 'documents',
      fileName: fileName,
    );
  }

  /// Upload video file
  Future<String?> uploadVideo({
    required String videoPath,
    String? folder = 'videos',
    String? fileName,
  }) async {
    return uploadFile(
      filePath: videoPath,
      folder: folder ?? 'videos',
      fileName: fileName,
    );
  }

  // ===== FILE DOWNLOAD =====

  /// Download file from URL
  Future<String?> downloadFile({
    required String fileUrl,
    String? fileName,
  }) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to download file');
      }

      if (kIsWeb) {
        // For web, return the URL directly as we can't save files locally
        return fileUrl;
      } else {
        final directory =
            await path_provider.getApplicationDocumentsDirectory();
        final finalFileName = fileName ??
            '${DateTime.now().millisecondsSinceEpoch}_downloaded_file';
        final file = dart_io.File('${directory.path}/$finalFileName');

        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      // print('Error downloading file: $e');
      return null;
    }
  }

  /// Download image file
  Future<String?> downloadImage({
    required String imageUrl,
    String? fileName,
  }) async {
    return downloadFile(
      fileUrl: imageUrl,
      fileName:
          fileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  /// Download document file
  Future<String?> downloadDocument({
    required String documentUrl,
    String? fileName,
  }) async {
    return downloadFile(
      fileUrl: documentUrl,
      fileName:
          fileName ?? 'document_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ===== FILE MANAGEMENT =====

  /// Delete file from Firebase Storage (by URL)
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      // print('Error deleting file: $e');
      return false;
    }
  }

  /// Get file metadata from URL (basic)
  Future<Map<String, dynamic>?> getFileMetadata(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final fileName =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
      return {
        'name': fileName,
        'url': fileUrl,
      };
    } catch (e) {
      // print('Error getting file metadata: $e');
      return null;
    }
  }

  /// List files in a folder (not implemented for client-only; prefer Firestore tracking)
  Future<List<String>> listFiles(String folder) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // print('Warning: Listing files via client SDK is not supported here. Track in Firestore.');
      return [];
    } catch (e) {
      // print('Error listing files: $e');
      return [];
    }
  }

  // ===== LOCAL STORAGE =====

  /// Get local documents directory
  Future<String> getDocumentsDirectory() async {
    final directory = await path_provider.getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get local temporary directory
  Future<String> getTemporaryDirPath() async {
    final directory = await path_provider.getTemporaryDirectory();
    return directory.path;
  }

  /// Get local cache directory
  Future<String> getCacheDirectory() async {
    final directory = await path_provider.getApplicationCacheDirectory();
    return directory.path;
  }

  /// Check if file exists locally
  Future<bool> fileExists(String filePath) async {
    final file = dart_io.File(filePath);
    return await file.exists();
  }

  /// Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      if (kIsWeb) {
        // For web, we can't get file size from path
        return 0;
      } else {
        final file = dart_io.File(filePath);
        if (await file.exists()) {
          return await file.length();
        }
        return 0;
      }
    } catch (e) {
      // print('Error getting file size: $e');
      return 0;
    }
  }

  /// Delete local file
  Future<bool> deleteLocalFile(String filePath) async {
    try {
      if (kIsWeb) {
        // For web, we can't delete local files
        return false;
      } else {
        final file = dart_io.File(filePath);
        if (await file.exists()) {
          await file.delete();
          return true;
        }
        return false;
      }
    } catch (e) {
      // print('Error deleting local file: $e');
      return false;
    }
  }

  /// Clear local cache
  Future<bool> clearLocalCache() async {
    try {
      final cacheDir = await getCacheDirectory();
      final dir = dart_io.Directory(cacheDir);

      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }

      return true;
    } catch (e) {
      // print('Error clearing local cache: $e');
      return false;
    }
  }

  // ===== STORAGE STATISTICS =====

  /// Get storage usage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data() as Map<String, dynamic>;
      final storageStats =
          userData['storageStats'] as Map<String, dynamic>? ?? {};

      return {
        'totalFiles': storageStats['totalFiles'] ?? 0,
        'totalSize': storageStats['totalSize'] ?? 0,
        'imagesCount': storageStats['imagesCount'] ?? 0,
        'documentsCount': storageStats['documentsCount'] ?? 0,
        'videosCount': storageStats['videosCount'] ?? 0,
        'lastUpdated': storageStats['lastUpdated'],
      };
    } catch (e) {
      // print('Error getting storage stats: $e');
      return {};
    }
  }

  /// Update storage statistics
  Future<void> updateStorageStats({
    required String fileType,
    required int fileSize,
    required bool isAdding,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final storageStats =
          userData['storageStats'] as Map<String, dynamic>? ?? {};

      final totalFiles =
          (storageStats['totalFiles'] ?? 0) + (isAdding ? 1 : -1);
      final totalSize =
          (storageStats['totalSize'] ?? 0) + (isAdding ? fileSize : -fileSize);

      final typeCountKey = '${fileType}Count';
      final typeCount = (storageStats[typeCountKey] ?? 0) + (isAdding ? 1 : -1);

      await _firestore.collection('users').doc(user.uid).update({
        'storageStats.totalFiles': totalFiles,
        'storageStats.totalSize': totalSize,
        'storageStats.$typeCountKey': typeCount,
        'storageStats.lastUpdated': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error updating storage stats: $e');
    }
  }

  // ===== FILE VALIDATION =====

  /// Validate file type
  bool isValidFileType(String filePath, List<String> allowedTypes) {
    final extension = filePath.split('.').last.toLowerCase();
    return allowedTypes.contains(extension);
  }

  /// Validate file size
  bool isValidFileSize(int fileSize, int maxSizeInBytes) {
    return fileSize <= maxSizeInBytes;
  }

  /// Get file extension
  String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  /// Get file name without extension
  String getFileNameWithoutExtension(String filePath) {
    final fileName = filePath.split('/').last;
    return fileName.split('.').first;
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
