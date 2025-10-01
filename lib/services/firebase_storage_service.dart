import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'dart:io' as dart_io;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static String _inferContentType(String fileName) {
    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  /// Upload file to Firebase Storage
  static Future<String?> uploadFile({
    required dart_io.File file,
    String? folder = 'hackethos4u/files',
    String? fileName,
    Map<String, String>? metadata,
  }) async {
    try {
      final name = fileName ??
          (kIsWeb
              ? 'file_${DateTime.now().millisecondsSinceEpoch}'
              : p.basename(file.path));
      final path = [folder ?? 'hackethos4u/files', name]
          .where((e) => e.isNotEmpty)
          .join('/');
      final ref = _storage.ref(path);

      final fileMetadata = SettableMetadata(
        contentType: _inferContentType(name),
        customMetadata: metadata,
      );

      final task = await ref.putFile(file, fileMetadata);
      final url = await task.ref.getDownloadURL();
      return url;
    } catch (e) {
      // print('Error uploading file: $e');
      return null;
    }
  }

  /// Upload file from bytes (for web)
  static Future<String?> uploadFileFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    String? folder = 'hackethos4u/files',
    Map<String, String>? metadata,
  }) async {
    try {
      final path = [folder ?? 'hackethos4u/files', fileName]
          .where((e) => e.isNotEmpty)
          .join('/');
      final ref = _storage.ref(path);

      final uploadMetadata = SettableMetadata(
        contentType: _inferContentType(fileName),
        customMetadata: metadata,
      );

      final task = await ref.putData(fileBytes, uploadMetadata);
      final url = await task.ref.getDownloadURL();
      return url;
    } catch (e) {
      // print('Error uploading file from bytes: $e');
      return null;
    }
  }

  /// Upload image file
  static Future<String?> uploadImage({
    required dart_io.File imageFile,
    String? folder = 'hackethos4u/images',
    String? fileName,
    Map<String, String>? metadata,
  }) async {
    return uploadFile(
      file: imageFile,
      folder: folder,
      fileName: fileName,
      metadata: metadata,
    );
  }

  /// Upload image from bytes (for web)
  static Future<String?> uploadImageFromBytes({
    required Uint8List imageBytes,
    required String fileName,
    String? folder = 'hackethos4u/images',
    Map<String, String>? metadata,
  }) async {
    return uploadFileFromBytes(
      fileBytes: imageBytes,
      fileName: fileName,
      folder: folder,
      metadata: metadata,
    );
  }

  /// Upload video file
  static Future<String?> uploadVideo({
    required dart_io.File videoFile,
    String? folder = 'hackethos4u/videos',
    String? fileName,
    Map<String, String>? metadata,
  }) async {
    return uploadFile(
      file: videoFile,
      folder: folder,
      fileName: fileName,
      metadata: metadata,
    );
  }

  /// Upload document file
  static Future<String?> uploadDocument({
    required dart_io.File documentFile,
    String? folder = 'hackethos4u/documents',
    String? fileName,
    Map<String, String>? metadata,
  }) async {
    return uploadFile(
      file: documentFile,
      folder: folder,
      fileName: fileName,
      metadata: metadata,
    );
  }

  /// Delete file from Firebase Storage
  static Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      // print('Error deleting file: $e');
      return false;
    }
  }

  /// Get download URL for a file path
  static Future<String?> getDownloadURL(String path) async {
    try {
      final ref = _storage.ref(path);
      return await ref.getDownloadURL();
    } catch (e) {
      // print('Error getting download URL: $e');
      return null;
    }
  }
}
