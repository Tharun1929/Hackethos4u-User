import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../model/materials/materials_model.dart';

class VideoUploadService {
  static final VideoUploadService _instance = VideoUploadService._internal();
  factory VideoUploadService() => _instance;
  VideoUploadService._internal();

  static const String _videosKey = 'uploaded_videos';
  static const String _modulesKey = 'course_modules';

  /// Upload video to a specific module
  Future<bool> uploadVideo({
    required String courseId,
    required String moduleId,
    required String videoTitle,
    required String videoDescription,
    required String videoPath,
    required String thumbnailPath,
    int? moduleIndex,
    int? videoIndex,
    String? videoUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load existing videos
      final videosJson = prefs.getString(_videosKey);
      Map<String, dynamic> videos = {};
      if (videosJson != null) {
        videos = json.decode(videosJson);
      }

      // Create video ID
      final videoId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create video object
      final video = {
        'id': videoId,
        'title': videoTitle,
        'description': videoDescription,
        'courseId': courseId,
        'moduleId': moduleId,
        'moduleIndex': moduleIndex ?? 1,
        'videoIndex': videoIndex ?? 1,
        'videoPath': videoPath,
        'thumbnailPath': thumbnailPath,
        'videoUrl': videoUrl,
        'duration': '00:00', // Will be updated when video is processed
        'uploadDate': DateTime.now().toIso8601String(),
        'isProcessed': false,
        'isPublished': false,
        'metadata': {
          'fileSize': await _getFileSize(videoPath),
          'format': _getFileExtension(videoPath),
          'resolution': 'Unknown', // Will be updated during processing
        },
      };

      // Add to videos collection
      if (!videos.containsKey(courseId)) {
        videos[courseId] = {};
      }
      if (!videos[courseId].containsKey(moduleId)) {
        videos[courseId][moduleId] = [];
      }
      videos[courseId][moduleId].add(video);

      // Save updated videos
      await prefs.setString(_videosKey, json.encode(videos));

      // Update module structure
      await _updateModuleStructure(courseId, moduleId, video);

      return true;
    } catch (e) {
      print('Error uploading video: $e');
      return false;
    }
  }

  /// Get all videos for a course
  Future<List<Map<String, dynamic>>> getCourseVideos(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getString(_videosKey);

      if (videosJson != null) {
        final Map<String, dynamic> videos = json.decode(videosJson);
        final List<Map<String, dynamic>> courseVideos = [];

        if (videos.containsKey(courseId)) {
          for (final moduleVideos in videos[courseId].values) {
            if (moduleVideos is List) {
              courseVideos.addAll(moduleVideos.cast<Map<String, dynamic>>());
            }
          }
        }

        // Sort by module index and video index
        courseVideos.sort((a, b) {
          final moduleCompare =
              (a['moduleIndex'] ?? 0).compareTo(b['moduleIndex'] ?? 0);
          if (moduleCompare != 0) return moduleCompare;
          return (a['videoIndex'] ?? 0).compareTo(b['videoIndex'] ?? 0);
        });

        return courseVideos;
      }

      return [];
    } catch (e) {
      print('Error getting course videos: $e');
      return [];
    }
  }

  /// Get videos for a specific module
  Future<List<Map<String, dynamic>>> getModuleVideos(
      String courseId, String moduleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getString(_videosKey);

      if (videosJson != null) {
        final Map<String, dynamic> videos = json.decode(videosJson);

        if (videos.containsKey(courseId) &&
            videos[courseId].containsKey(moduleId)) {
          final List<dynamic> moduleVideos = videos[courseId][moduleId];
          return moduleVideos.cast<Map<String, dynamic>>();
        }
      }

      return [];
    } catch (e) {
      print('Error getting module videos: $e');
      return [];
    }
  }

  /// Update video metadata
  Future<bool> updateVideoMetadata({
    required String courseId,
    required String moduleId,
    required String videoId,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getString(_videosKey);

      if (videosJson != null) {
        final Map<String, dynamic> videos = json.decode(videosJson);

        if (videos.containsKey(courseId) &&
            videos[courseId].containsKey(moduleId)) {
          final List<dynamic> moduleVideos = videos[courseId][moduleId];

          for (int i = 0; i < moduleVideos.length; i++) {
            if (moduleVideos[i]['id'] == videoId) {
              moduleVideos[i].addAll(metadata);
              moduleVideos[i]['lastUpdated'] = DateTime.now().toIso8601String();
              break;
            }
          }

          await prefs.setString(_videosKey, json.encode(videos));
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error updating video metadata: $e');
      return false;
    }
  }

  /// Delete video
  Future<bool> deleteVideo({
    required String courseId,
    required String moduleId,
    required String videoId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getString(_videosKey);

      if (videosJson != null) {
        final Map<String, dynamic> videos = json.decode(videosJson);

        if (videos.containsKey(courseId) &&
            videos[courseId].containsKey(moduleId)) {
          final List<dynamic> moduleVideos = videos[courseId][moduleId];

          // Find and remove video
          moduleVideos.removeWhere((video) => video['id'] == videoId);

          // Delete file if exists
          final video = moduleVideos.firstWhere(
            (v) => v['id'] == videoId,
            orElse: () => null,
          );

          if (video != null && video['videoPath'] != null) {
            final file = File(video['videoPath']);
            if (await file.exists()) {
              await file.delete();
            }
          }

          await prefs.setString(_videosKey, json.encode(videos));
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error deleting video: $e');
      return false;
    }
  }

  /// Publish/unpublish video
  Future<bool> toggleVideoPublish({
    required String courseId,
    required String moduleId,
    required String videoId,
    required bool isPublished,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getString(_videosKey);

      if (videosJson != null) {
        final Map<String, dynamic> videos = json.decode(videosJson);

        if (videos.containsKey(courseId) &&
            videos[courseId].containsKey(moduleId)) {
          final List<dynamic> moduleVideos = videos[courseId][moduleId];

          for (int i = 0; i < moduleVideos.length; i++) {
            if (moduleVideos[i]['id'] == videoId) {
              moduleVideos[i]['isPublished'] = isPublished;
              moduleVideos[i]['lastUpdated'] = DateTime.now().toIso8601String();
              break;
            }
          }

          await prefs.setString(_videosKey, json.encode(videos));
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error toggling video publish: $e');
      return false;
    }
  }

  /// Reorder videos in a module
  Future<bool> reorderVideos({
    required String courseId,
    required String moduleId,
    required List<String> videoIds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getString(_videosKey);

      if (videosJson != null) {
        final Map<String, dynamic> videos = json.decode(videosJson);

        if (videos.containsKey(courseId) &&
            videos[courseId].containsKey(moduleId)) {
          final List<dynamic> moduleVideos = videos[courseId][moduleId];

          // Create new ordered list
          final List<dynamic> orderedVideos = [];
          for (final videoId in videoIds) {
            final video = moduleVideos.firstWhere(
              (v) => v['id'] == videoId,
              orElse: () => null,
            );
            if (video != null) {
              video['videoIndex'] = orderedVideos.length + 1;
              orderedVideos.add(video);
            }
          }

          videos[courseId][moduleId] = orderedVideos;
          await prefs.setString(_videosKey, json.encode(videos));
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error reordering videos: $e');
      return false;
    }
  }

  /// Get video statistics
  Future<Map<String, dynamic>> getVideoStats(String courseId) async {
    try {
      final videos = await getCourseVideos(courseId);

      int totalVideos = videos.length;
      int publishedVideos =
          videos.where((v) => v['isPublished'] == true).length;
      int processedVideos =
          videos.where((v) => v['isProcessed'] == true).length;
      int totalDuration = 0; // Will be calculated from video durations

      return {
        'totalVideos': totalVideos,
        'publishedVideos': publishedVideos,
        'processedVideos': processedVideos,
        'totalDuration': totalDuration,
        'uploadProgress': processedVideos / totalVideos,
      };
    } catch (e) {
      print('Error getting video stats: $e');
      return {};
    }
  }

  /// Update module structure when video is added
  Future<void> _updateModuleStructure(
    String courseId,
    String moduleId,
    Map<String, dynamic> video,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modulesJson = prefs.getString(_modulesKey);

      Map<String, dynamic> modules = {};
      if (modulesJson != null) {
        modules = json.decode(modulesJson);
      }

      if (!modules.containsKey(courseId)) {
        modules[courseId] = [];
      }

      // Find or create module
      Map<String, dynamic>? module;
      for (final m in modules[courseId]) {
        if (m['id'] == moduleId) {
          module = m;
          break;
        }
      }

      if (module == null) {
        module = {
          'id': moduleId,
          'title': 'Module ${video['moduleIndex']}',
          'description': 'Module description',
          'videos': [],
          'createdDate': DateTime.now().toIso8601String(),
        };
        modules[courseId].add(module);
      }

      // Add video to module
      if (!module.containsKey('videos')) {
        module['videos'] = [];
      }
      module['videos'].add({
        'id': video['id'],
        'title': video['title'],
        'description': video['description'],
        'duration': video['duration'],
        'isPublished': video['isPublished'],
      });

      await prefs.setString(_modulesKey, json.encode(modules));
    } catch (e) {
      print('Error updating module structure: $e');
    }
  }

  /// Get file size in bytes
  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error getting file size: $e');
      return 0;
    }
  }

  /// Get file extension
  String _getFileExtension(String filePath) {
    try {
      return filePath.split('.').last.toLowerCase();
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get local videos (for demo purposes)
  Future<List<Materials>> getLocalVideos() async {
    // This would typically scan the device for video files
    // For now, return empty list
    return [];
  }

  /// Validate video file
  Future<bool> validateVideoFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final extension = _getFileExtension(filePath);
      final validExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];

      if (!validExtensions.contains(extension)) {
        return false;
      }

      final fileSize = await file.length();
      const maxSize = 500 * 1024 * 1024; // 500MB limit

      if (fileSize > maxSize) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating video file: $e');
      return false;
    }
  }

  /// Process video (extract metadata, generate thumbnails, etc.)
  Future<bool> processVideo({
    required String courseId,
    required String moduleId,
    required String videoId,
  }) async {
    try {
      // This would typically involve:
      // 1. Extracting video metadata (duration, resolution, etc.)
      // 2. Generating thumbnails
      // 3. Compressing video if needed
      // 4. Uploading to cloud storage
      // 5. Updating video metadata

      // For now, just mark as processed
      await updateVideoMetadata(
        courseId: courseId,
        moduleId: moduleId,
        videoId: videoId,
        metadata: {
          'isProcessed': true,
          'processedDate': DateTime.now().toIso8601String(),
          'duration': '10:30', // Mock duration
          'resolution': '1920x1080', // Mock resolution
        },
      );

      return true;
    } catch (e) {
      print('Error processing video: $e');
      return false;
    }
  }

  /// Get upload progress for a video
  Future<double> getUploadProgress(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getString(_videosKey);

      if (videosJson != null) {
        final Map<String, dynamic> videos = json.decode(videosJson);

        for (final courseVideos in videos.values) {
          for (final moduleVideos in courseVideos.values) {
            for (final video in moduleVideos) {
              if (video['id'] == videoId) {
                if (video['isProcessed'] == true) {
                  return 1.0;
                } else if (video['isUploaded'] == true) {
                  return 0.5;
                } else {
                  return 0.0;
                }
              }
            }
          }
        }
      }

      return 0.0;
    } catch (e) {
      print('Error getting upload progress: $e');
      return 0.0;
    }
  }

  /// Pick video from gallery
  Future<String?> pickVideoFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      return video?.path;
    } catch (e) {
      print('Error picking video from gallery: $e');
      return null;
    }
  }

  /// Record video with camera
  Future<String?> recordVideoWithCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.camera);
      return video?.path;
    } catch (e) {
      print('Error recording video with camera: $e');
      return null;
    }
  }

  /// Create video material
  Future<bool> createVideoMaterial({
    required String courseId,
    required String moduleId,
    required String title,
    required String description,
    required String videoPath,
    String? thumbnailPath,
  }) async {
    try {
      final videoId = 'video_${DateTime.now().millisecondsSinceEpoch}';

      final videoData = {
        'id': videoId,
        'title': title,
        'description': description,
        'videoPath': videoPath,
        'thumbnailPath': thumbnailPath,
        'duration': '00:00:00',
        'size': 0,
        'uploadDate': DateTime.now().toIso8601String(),
        'isUploaded': false,
        'isProcessed': false,
        'status': 'pending',
      };

      await addVideoToCourse(courseId, moduleId, videoData);
      return true;
    } catch (e) {
      print('Error creating video material: $e');
      return false;
    }
  }

  /// Add video to curriculum
  Future<bool> addVideoToCurriculum({
    required String courseId,
    required String moduleId,
    required String videoId,
    required int position,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final curriculumJson = prefs.getString('curriculum_$courseId');

      Map<String, dynamic> curriculum = {};
      if (curriculumJson != null) {
        curriculum = json.decode(curriculumJson);
      }

      if (curriculum[moduleId] == null) {
        curriculum[moduleId] = [];
      }

      curriculum[moduleId].insert(position, videoId);
      await prefs.setString('curriculum_$courseId', json.encode(curriculum));

      return true;
    } catch (e) {
      print('Error adding video to curriculum: $e');
      return false;
    }
  }

  /// Delete video from curriculum
  Future<bool> deleteVideoFromCurriculum({
    required String courseId,
    required String moduleId,
    required String videoId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final curriculumJson = prefs.getString('curriculum_$courseId');

      if (curriculumJson != null) {
        Map<String, dynamic> curriculum = json.decode(curriculumJson);

        if (curriculum[moduleId] != null) {
          curriculum[moduleId].remove(videoId);
          await prefs.setString(
              'curriculum_$courseId', json.encode(curriculum));
        }
      }

      // Also remove from videos storage
      await removeVideoFromCourse(courseId, moduleId, videoId);

      return true;
    } catch (e) {
      print('Error deleting video from curriculum: $e');
      return false;
    }
  }

  /// Add video to course
  Future<bool> addVideoToCourse(
      String courseId, String moduleId, Map<String, dynamic> videoData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getString(_videosKey);

      Map<String, dynamic> videos = {};
      if (videosJson != null) {
        videos = json.decode(videosJson);
      }

      if (!videos.containsKey(courseId)) {
        videos[courseId] = {};
      }
      if (!videos[courseId].containsKey(moduleId)) {
        videos[courseId][moduleId] = [];
      }

      videos[courseId][moduleId].add(videoData);
      await prefs.setString(_videosKey, json.encode(videos));

      return true;
    } catch (e) {
      print('Error adding video to course: $e');
      return false;
    }
  }

  /// Remove video from course
  Future<bool> removeVideoFromCourse(
      String courseId, String moduleId, String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getString(_videosKey);

      if (videosJson != null) {
        Map<String, dynamic> videos = json.decode(videosJson);

        if (videos.containsKey(courseId) &&
            videos[courseId].containsKey(moduleId)) {
          videos[courseId][moduleId]
              .removeWhere((video) => video['id'] == videoId);
          await prefs.setString(_videosKey, json.encode(videos));
        }
      }

      return true;
    } catch (e) {
      print('Error removing video from course: $e');
      return false;
    }
  }
}
