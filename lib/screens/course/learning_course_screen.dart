import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../services/data_sync_service.dart';
import '../../services/progress_service.dart';
import '../../services/course_access_service.dart';
import '../../theme/app_theme.dart';

class LearningCourseScreen extends StatefulWidget {
  final String? courseId;
  const LearningCourseScreen({super.key, this.courseId});

  @override
  State<LearningCourseScreen> createState() => _LearningCourseScreenState();
}

class _LearningCourseScreenState extends State<LearningCourseScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedModuleIndex = 0;
  int _selectedLessonIndex = 0;

  Map<String, dynamic> _courseData = {};
  bool _loading = true;
  bool _hasAccess = false;
  bool _accessExpired = false;

  // Video Player State
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoLoading = false;
  bool _isVideoPlaying = false;
  bool _showVideoControls = true;
  bool _isFullScreen = false;
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  double _videoProgress = 0.0;
  DateTime _lastProgressSaveAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _hasMarkedCompletedForCurrentLesson = false;

  // Services
  final CourseAccessService _courseAccessService = CourseAccessService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCourse();
    _checkAccess();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      // Get current lesson video URL
      final modules = _courseData['modules'] as List<dynamic>? ?? [];
      if (modules.isNotEmpty && _selectedModuleIndex < modules.length) {
        final module = modules[_selectedModuleIndex] as Map<String, dynamic>;
        final lessons = module['lessons'] as List<dynamic>? ?? [];
        if (lessons.isNotEmpty && _selectedLessonIndex < lessons.length) {
          final lesson = lessons[_selectedLessonIndex] as Map<String, dynamic>;
          final videoUrl = lesson['videoUrl'];
          if (videoUrl != null && videoUrl.isNotEmpty) {
            final courseId = (_courseData['id'] ?? '').toString();
            final lessonId = (lesson['id'] ?? '').toString();
            if (courseId.isNotEmpty && lessonId.isNotEmpty) {
              await _loadVideo(
                videoUrl,
                courseId: courseId,
                lessonId: lessonId,
              );
            } else {
              await _loadVideo(videoUrl, courseId: '', lessonId: '');
            }
          }
        }
      }
    } catch (e) {
      // print('Error initializing video player: $e');
    }
  }

  Future<void> _loadVideo(String videoUrl, {required String courseId, required String lessonId}) async {
    try {
      setState(() {
        _isVideoLoading = true;
      });

      // Dispose previous controller
      await _videoController?.dispose();
      _chewieController?.dispose();

      // Create new controller
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showOptions: false,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryColor,
          backgroundColor: Colors.grey[300]!,
          bufferedColor: Colors.grey[200]!,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading video',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Add listener for video state changes
      _videoController!.addListener(_videoListener);

      // Attempt resume from last saved playback position
      try {
        if (courseId.isNotEmpty && lessonId.isNotEmpty) {
          final last = await ProgressService()
              .getLastPlayback(courseId: courseId, videoId: lessonId);
          if (last != null) {
            final int posMs = (last['positionMs'] ?? 0) as int;
            final int durMs = (last['durationMs'] ?? 0) as int;
            if (durMs > 0) {
              final double pct = posMs / durMs;
              // Seek if at least 3s in and not near completion
              if (posMs > 3000 && pct < 0.95) {
                await _videoController!.seekTo(Duration(milliseconds: posMs));
              }
            }
          }
        }
      } catch (_) {}

      setState(() {
        _isVideoLoading = false;
      });
    } catch (e) {
      setState(() {
        _isVideoLoading = false;
      });
      // print('Error loading video: $e');
    }
  }

  void _videoListener() async {
    if (mounted && _videoController != null) {
      setState(() {
        _videoPosition = _videoController!.value.position;
        _videoDuration = _videoController!.value.duration;
        _isVideoPlaying = _videoController!.value.isPlaying;
        if (_videoDuration.inMilliseconds > 0) {
          _videoProgress =
              _videoPosition.inMilliseconds / _videoDuration.inMilliseconds;
        }
      });

      // Auto-mark completion once when reaching 98% to avoid duplicates
      if (_videoDuration.inMilliseconds > 0 && !_hasMarkedCompletedForCurrentLesson) {
        final double pct = _videoProgress.clamp(0.0, 1.0);
        if (pct >= 0.98) {
          _hasMarkedCompletedForCurrentLesson = true;
          try {
            final courseId = (_courseData['id'] ?? '').toString();
            final currentLesson = _getCurrentLesson();
            final lessonId = (currentLesson?['id'] ?? '').toString();
            if (courseId.isNotEmpty && lessonId.isNotEmpty) {
              await ProgressService().updateVideoProgress(
                courseId: courseId,
                videoId: lessonId,
                progress: 1.0,
                isCompleted: true,
              );
            }
          } catch (_) {}

          // If near the end, advance to next lesson automatically
          final remaining = _videoDuration - _videoPosition;
          if (remaining.inSeconds <= 2) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _nextLesson();
            });
          }
        }
      }

      // Save playback + progress every ~10s
      final now = DateTime.now();
      if (_videoDuration.inMilliseconds > 0 &&
          now.difference(_lastProgressSaveAt).inSeconds >= 10) {
        _lastProgressSaveAt = now;
        try {
          final courseId = (_courseData['id'] ?? '').toString();
          final currentLesson = _getCurrentLesson();
          final lessonId = (currentLesson?['id'] ?? '').toString();
          if (courseId.isNotEmpty && lessonId.isNotEmpty) {
            final progress = _videoProgress.clamp(0.0, 1.0);
            ProgressService().updateVideoProgress(
              courseId: courseId,
              videoId: lessonId,
              progress: progress,
              isCompleted: progress >= 0.8,
            );
            ProgressService().saveLastPlayback(
              courseId: courseId,
              videoId: lessonId,
              positionMs: _videoPosition.inMilliseconds,
              durationMs: _videoDuration.inMilliseconds,
            );
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _checkAccess() async {
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      final courseId = (args?['courseId'] ?? args?['id'] ?? '0').toString();

      final hasAccess = await _courseAccessService.hasCourseAccess(courseId);

      // Check if access has expired
      final user = _auth.currentUser;
      if (user != null) {
        final enrollmentDoc = await FirebaseFirestore.instance
            .collection('enrollments')
            .doc('${user.uid}_$courseId')
            .get();

        if (enrollmentDoc.exists) {
          final enrollmentData = enrollmentDoc.data()!;
          final accessExpired = enrollmentData['accessExpired'] ?? false;

          setState(() {
            _hasAccess = hasAccess;
            _accessExpired = accessExpired;
          });

          if (!hasAccess || accessExpired) {
            _showAccessDeniedDialog();
          }
        }
      }
    } catch (e) {
      // print('Error checking access: $e');
    }
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Access Denied'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your access to this course has expired or you don\'t have permission to view it.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contact support or renew your access to continue learning.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to course list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCourse() async {
    setState(() {
      _loading = true;
    });
    final courseId = widget.courseId ?? '0';
    try {
      final dataSync = DataSyncService();
      final course = await dataSync.getCourseById(courseId);
      if (course != null) {
        _courseData = {
          'id': course['id'].toString(),
          'title': course['title'] ?? course['courseName'] ?? 'Course',
          'thumbnail': course['thumbnail'] ?? course['courseImage'],
          'description': course['description'] ?? '',
          'modules': (course['modules'] as List<dynamic>? ?? [])
              .asMap()
              .entries
              .map((moduleEntry) {
            final int moduleIndex = moduleEntry.key;
            final Map<String, dynamic> m =
                (moduleEntry.value as Map<String, dynamic>);
            final sub = (m['submodules'] as List<dynamic>? ?? []);
            return {
              'id': m['id']?.toString() ?? 'module_${moduleIndex + 1}',
              'title': m['title'] ?? '',
              'duration': m['duration'] ?? '',
              'lessonCount': sub.length,
              'completedLessons': 0,
              'isCompleted': false,
              'lessons': sub.asMap().entries.map((entry) {
                final int lessonIndex = entry.key;
                final Map<String, dynamic> s =
                    (entry.value as Map<String, dynamic>);
                final String generatedId =
                    '${moduleIndex + 1}_${lessonIndex + 1}';
                return {
                  'id': s['id']?.toString() ?? generatedId,
                  'title': s['title'] ?? '',
                  'duration': s['duration'] ?? 0,
                  'type': s['type'] ?? 'video',
                  'isCompleted': s['isCompleted'] ?? false,
                  'videoUrl': s['videoUrl'] ?? '',
                };
              }).toList(),
            };
          }).toList(),
        };
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 800; // tablet/desktop

    if (!_hasAccess && !_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Access')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 48),
              const SizedBox(height: 12),
              const Text('Please enroll to access this course'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/course', arguments: _courseData['id']),
                child: const Text('Go to course page'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isWide
            ? Column(
                children: [
                  _buildHeader(theme),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildVideoSection(theme),
                        ),
                        Expanded(
                          flex: 1,
                          child: _buildCourseContentSection(theme),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _buildMobileLayout(theme),
      ),
    );
  }

  // Enhanced Header with premium design
  Widget _buildEnhancedHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.95),
            Colors.black.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _courseData['title'] ?? 'Course',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_getCurrentLesson() != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _getCurrentLesson()!['title'] ?? 'Lesson',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _toggleVideoControls,
                icon: Icon(
                  _showVideoControls ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                  size: 20,
                ),
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _toggleFullScreen,
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 20,
                ),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Video Section with premium styling
  Widget _buildEnhancedVideoSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 220,
              child: _isVideoLoading
                  ? _buildEnhancedLoadingState()
                  : _chewieController != null
                      ? _buildEnhancedVideoPlayer()
                      : _buildEnhancedNoVideoPlaceholder(),
            ),
            _buildEnhancedLessonBar(theme),
          ],
        ),
      ),
    );
  }

  // Enhanced Loading State
  Widget _buildEnhancedLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we prepare your lesson',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Video Player with better controls
  Widget _buildEnhancedVideoPlayer() {
    return GestureDetector(
      onTap: _toggleVideoControls,
      child: Stack(
        children: [
          // Video Player
          Center(
            child: Chewie(controller: _chewieController!),
          ),

          // Enhanced Custom Overlay Controls
          if (_showVideoControls) _buildEnhancedVideoControls(),

          // Enhanced Progress Indicator
          _buildEnhancedVideoProgressIndicator(),
        ],
      ),
    );
  }

  // Enhanced Video Controls
  Widget _buildEnhancedVideoControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEnhancedVideoProgressBar(),
            _buildEnhancedVideoControlButtons(),
          ],
        ),
      ),
    );
  }

  // Enhanced Progress Bar
  Widget _buildEnhancedVideoProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            _formatDuration(_videoPosition),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primaryColor,
                inactiveTrackColor: Colors.grey[600],
                thumbColor: AppTheme.primaryColor,
                overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _videoPosition.inMilliseconds.toDouble(),
                max: _videoDuration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  final position = Duration(milliseconds: value.toInt());
                  _videoController?.seekTo(position);
                },
              ),
            ),
          ),
          Text(
            _formatDuration(_videoDuration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Control Buttons
  Widget _buildEnhancedVideoControlButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.skip_previous,
            onPressed: _previousLesson,
            size: 24,
          ),
          _buildControlButton(
            icon: _isVideoPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            onPressed: _togglePlayPause,
            size: 48,
            isPrimary: true,
          ),
          _buildControlButton(
            icon: Icons.skip_next,
            onPressed: _nextLesson,
            size: 24,
          ),
          _buildControlButton(
            icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            onPressed: _toggleFullScreen,
            size: 24,
          ),
        ],
      ),
    );
  }

  // Control Button Builder
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 24,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary
            ? AppTheme.primaryColor.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isPrimary ? 30 : 20),
        border: isPrimary
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
            : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: size,
        ),
        padding: EdgeInsets.all(isPrimary ? 12 : 8),
      ),
    );
  }

  // Enhanced Progress Indicator
  Widget _buildEnhancedVideoProgressIndicator() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_filled,
              color: AppTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${(_videoProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced No Video Placeholder
  Widget _buildEnhancedNoVideoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white.withOpacity(0.8),
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select a lesson to start watching',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose from the curriculum below to begin your learning journey',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Lesson Bar
  Widget _buildEnhancedLessonBar(ThemeData theme) {
    final current = _getCurrentLesson();
    final hasPrev =
        _findPreviousLesson(_selectedModuleIndex, _selectedLessonIndex) != null;
    final hasNext =
        _findNextLesson(_selectedModuleIndex, _selectedLessonIndex) != null;
    final nextInfo =
        _findNextLesson(_selectedModuleIndex, _selectedLessonIndex);
    final Map<String, dynamic>? nextLesson =
        nextInfo != null ? nextInfo['lesson'] as Map<String, dynamic>? : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current != null
                      ? (current['title'] ?? 'Current lesson')
                      : 'Select a lesson',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(_videoPosition)} / ${_formatDuration(_videoDuration)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (nextLesson != null) ...[
            Container(
              margin: const EdgeInsets.only(right: 12),
              constraints: const BoxConstraints(maxWidth: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Up next',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextLesson['title'] ?? 'Next lesson',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    _formatLessonDurationDynamic(nextLesson['duration']),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          _buildNavigationButton(
            icon: Icons.arrow_back_ios_new,
            label: 'Previous',
            onPressed: hasPrev ? _previousLesson : null,
            isEnabled: hasPrev,
          ),
          const SizedBox(width: 8),
          _buildNavigationButton(
            icon: Icons.arrow_forward_ios,
            label: 'Next',
            onPressed: hasNext ? _nextLesson : null,
            isEnabled: hasNext,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  // Navigation Button Builder
  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isEnabled,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? (isPrimary ? AppTheme.primaryColor : Colors.grey[100])
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: isEnabled && isPrimary
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isEnabled
                      ? (isPrimary ? Colors.white : Colors.grey[700])
                      : Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEnabled
                        ? (isPrimary ? Colors.white : Colors.grey[700])
                        : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for new UI
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _courseData['title'] ?? 'Course',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_getCurrentLesson() != null)
                  Text(
                    _getCurrentLesson()!['title'] ?? 'Lesson',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggleVideoControls,
            icon: Icon(
              _showVideoControls ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: _toggleFullScreen,
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 250,
              child: _isVideoLoading
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey[900]!,
                            Colors.grey[800]!,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading video...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _chewieController != null
                      ? _buildVideoPlayer()
                      : _buildNoVideoPlaceholder(),
            ),
            _buildStickyLessonBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyLessonBar(ThemeData theme) {
    final current = _getCurrentLesson();
    final hasPrev =
        _findPreviousLesson(_selectedModuleIndex, _selectedLessonIndex) != null;
    final hasNext =
        _findNextLesson(_selectedModuleIndex, _selectedLessonIndex) != null;
    final nextInfo =
        _findNextLesson(_selectedModuleIndex, _selectedLessonIndex);
    final Map<String, dynamic>? nextLesson =
        nextInfo != null ? nextInfo['lesson'] as Map<String, dynamic>? : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current != null
                      ? (current['title'] ?? 'Current lesson')
                      : 'Select a lesson',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDuration(_videoPosition)} / ${_formatDuration(_videoDuration)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (nextLesson != null) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              constraints: const BoxConstraints(maxWidth: 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Up next',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextLesson['title'] ?? 'Next lesson',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    _formatLessonDurationDynamic(nextLesson['duration']),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          TextButton.icon(
            onPressed: hasPrev ? _previousLesson : null,
            icon: const Icon(Icons.arrow_back_ios_new, size: 16),
            label: const Text('Previous'),
            style: TextButton.styleFrom(
              foregroundColor:
                  hasPrev ? theme.colorScheme.primary : Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: hasNext ? _nextLesson : null,
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  hasNext ? theme.colorScheme.primary : Colors.grey[300],
              foregroundColor: hasNext ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLessonDurationDynamic(dynamic duration) {
    try {
      if (duration == null) return '';
      if (duration is int) {
        return _formatDuration(Duration(seconds: duration));
      }
      if (duration is String) {
        // Accept already formatted like '10:05' or '1:02:33'
        if (duration.contains(':')) return duration;
        final maybeInt = int.tryParse(duration);
        if (maybeInt != null) {
          return _formatDuration(Duration(seconds: maybeInt));
        }
      }
      return duration.toString();
    } catch (_) {
      return '';
    }
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _toggleVideoControls,
      child: Stack(
        children: [
          // Video Player
          Center(
            child: Chewie(controller: _chewieController!),
          ),

          // Custom Overlay Controls
          if (_showVideoControls) _buildCustomVideoControls(),

          // Progress Indicator
          _buildVideoProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildCustomVideoControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVideoProgressBar(),
            _buildVideoControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            _formatDuration(_videoPosition),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primaryColor,
                inactiveTrackColor: Colors.grey[600],
                thumbColor: AppTheme.primaryColor,
                overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                trackHeight: 3,
              ),
              child: Slider(
                value: _videoPosition.inMilliseconds.toDouble(),
                max: _videoDuration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  final position = Duration(milliseconds: value.toInt());
                  _videoController?.seekTo(position);
                },
              ),
            ),
          ),
          Text(
            _formatDuration(_videoDuration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControlButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _previousLesson,
            icon: const Icon(Icons.skip_previous, color: Colors.white),
          ),
          IconButton(
            onPressed: _togglePlayPause,
            icon: Icon(
              _isVideoPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
          IconButton(
            onPressed: _nextLesson,
            icon: const Icon(Icons.skip_next, color: Colors.white),
          ),
          IconButton(
            onPressed: _toggleFullScreen,
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoProgressIndicator() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${(_videoProgress * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNoVideoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white.withOpacity(0.7),
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a lesson to start watching',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose from the modules below to begin your learning journey',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseContentSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCourseContentHeader(),
          Expanded(
            child: _buildCourseModulesList(),
          ),
        ],
      ),
    );
  }

  // Enhanced Mobile layout with premium Udemy-like design
  Widget _buildMobileLayout(ThemeData theme) {
    return Stack(
      children: [
        // Column with header and video on top
        Column(
          children: [
            _buildEnhancedHeader(theme),
            // Enhanced Video Section
            _buildEnhancedVideoSection(theme),
          ],
        ),
        // Enhanced Draggable curriculum with premium design
        DraggableScrollableSheet(
          initialChildSize: 0.48,
          minChildSize: 0.25,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Enhanced Grab handle with gradient
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[400]!, Colors.grey[300]!],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Enhanced Course Info Header
                  _buildCourseInfoHeader(theme),

                  // Enhanced Tabs with better styling
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: theme.colorScheme.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.playlist_play, size: 18),
                              SizedBox(width: 6),
                              Text('Curriculum'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.note_alt, size: 18),
                              SizedBox(width: 6),
                              Text('Notes'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open, size: 18),
                              SizedBox(width: 6),
                              Text('Resources'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Enhanced Curriculum with better scrolling
                        NotificationListener<OverscrollIndicatorNotification>(
                          onNotification: (n) {
                            n.disallowIndicator();
                            return false;
                          },
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: _buildEnhancedCurriculumTab(),
                            ),
                          ),
                        ),
                        // Enhanced Notes
                        _buildEnhancedNotesTab(),
                        // Enhanced Resources
                        _buildEnhancedResourcesTab(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Enhanced Course Info Header
  Widget _buildCourseInfoHeader(ThemeData theme) {
    final modules = _courseData['modules'] as List<dynamic>? ?? [];
    final totalLessons = _getTotalLessons();
    final completedLessons = _calcCompletedLessons();
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Course Title and Progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _courseData['title'] ?? 'Course',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedLessons of $totalLessons lessons completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Complete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedLessons lessons completed',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${totalLessons - completedLessons} remaining',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Curriculum Tab
  Widget _buildEnhancedCurriculumTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final modules = _courseData['modules'] as List<dynamic>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index] as Map<String, dynamic>;
        return _buildEnhancedModuleCard(module, index);
      },
    );
  }

  // Enhanced Module Card
  Widget _buildEnhancedModuleCard(
      Map<String, dynamic> module, int moduleIndex) {
    final theme = Theme.of(context);
    final isExpanded = _selectedModuleIndex == moduleIndex;
    final lessons = (module['lessons'] as List<dynamic>);
    final completed =
        lessons.where((l) => (l as Map)['isCompleted'] == true).length;
    final progress = lessons.isNotEmpty ? completed / lessons.length : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Module Header
          InkWell(
            onTap: () {
              setState(() {
                _selectedModuleIndex = isExpanded ? -1 : moduleIndex;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isExpanded
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.05),
                          theme.colorScheme.primary.withOpacity(0.02)
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: module['isCompleted']
                          ? LinearGradient(
                              colors: [Colors.green[600]!, Colors.green[500]!])
                          : LinearGradient(colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.8)
                            ]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (module['isCompleted']
                                  ? Colors.green
                                  : theme.colorScheme.primary)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      module['isCompleted'] ? Icons.check : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module['title'] ?? 'Module ${moduleIndex + 1}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${module['lessonCount']} lessons • ${module['duration'] ?? '0 min'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: module['isCompleted']
                              ? Colors.green[50]
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: module['isCompleted']
                                ? Colors.green[200]!
                                : Colors.blue[200]!,
                          ),
                        ),
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: module['isCompleted']
                                ? Colors.green[700]
                                : Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Enhanced Progress Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completed/${lessons.length} lessons',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        module['isCompleted'] ? 'Completed' : 'In Progress',
                        style: TextStyle(
                          fontSize: 13,
                          color: module['isCompleted']
                              ? Colors.green[600]
                              : Colors.blue[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        module['isCompleted']
                            ? Colors.green[600]!
                            : theme.colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Enhanced Lessons List (if expanded)
          if (isExpanded) ...[
            const Divider(height: 1),
            ...lessons.asMap().entries.map((entry) {
              final lessonIndex = entry.key;
              final lesson = entry.value;
              return _buildEnhancedLessonTile(lesson, moduleIndex, lessonIndex);
            }),
          ],
        ],
      ),
    );
  }

  // Enhanced Lesson Tile
  Widget _buildEnhancedLessonTile(
      Map<String, dynamic> lesson, int moduleIndex, int lessonIndex) {
    final theme = Theme.of(context);
    final isSelected = moduleIndex == _selectedModuleIndex &&
        lessonIndex == _selectedLessonIndex;

    return InkWell(
      onTap: () => _selectLesson(moduleIndex, lessonIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : lesson['isCompleted']
                  ? Colors.green.withOpacity(0.03)
                  : null,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: lesson['isCompleted']
                    ? Colors.green
                    : isSelected
                        ? theme.colorScheme.primary
                        : _getLessonTypeColor(lesson['type']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: lesson['isCompleted'] || isSelected
                    ? null
                    : Border.all(
                        color: _getLessonTypeColor(lesson['type'])
                            .withOpacity(0.3),
                        width: 1,
                      ),
              ),
              child: Icon(
                lesson['isCompleted']
                    ? Icons.check
                    : _getLessonIcon(lesson['type']),
                color: lesson['isCompleted'] || isSelected
                    ? Colors.white
                    : _getLessonTypeColor(lesson['type']),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson['title'] ?? 'Lesson ${lessonIndex + 1}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: lesson['isCompleted']
                          ? Colors.grey[600]
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatLessonDurationDynamic(lesson['duration'])} • ${_getLessonTypeText(lesson['type'])}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (lesson['isCompleted'])
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              )
            else if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 18,
                ),
              )
            else
              Icon(
                Icons.play_circle_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // Enhanced Notes Tab
  Widget _buildEnhancedNotesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.note_add,
              size: 56,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Take notes while learning to help you remember key concepts',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Add note functionality
                },
                borderRadius: BorderRadius.circular(16),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Add Note',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Resources Tab
  Widget _buildEnhancedResourcesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildEnhancedResourceCard(
          'Course Materials',
          'Download course slides, code examples, and additional resources',
          Icons.folder,
          Colors.blue,
        ),
        _buildEnhancedResourceCard(
          'Community Forum',
          'Connect with other students and ask questions',
          Icons.forum,
          Colors.green,
        ),
        _buildEnhancedResourceCard(
          'Instructor Office Hours',
          'Join live Q&A sessions with the instructor',
          Icons.schedule,
          Colors.orange,
        ),
        _buildEnhancedResourceCard(
          'Certificate',
          'Download your course completion certificate',
          Icons.verified,
          Colors.purple,
        ),
      ],
    );
  }

  // Enhanced Resource Card
  Widget _buildEnhancedResourceCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseContentHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.playlist_play, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Course content',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const Spacer(),
          Text(
            '${_getTotalLessons()} lessons',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseModulesList() {
    final modules = _courseData['modules'] as List<dynamic>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: modules.length,
      itemBuilder: (context, moduleIndex) {
        final module = modules[moduleIndex] as Map<String, dynamic>;
        final isExpanded = moduleIndex == _selectedModuleIndex;
        final lessons = module['lessons'] as List<dynamic>? ?? [];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isExpanded ? Colors.grey[800] : Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            border: isExpanded
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
          child: Column(
            children: [
              // Module Header
              ListTile(
                leading: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
                title: Text(
                  module['title'] ?? 'Module ${moduleIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${lessons.length} lessons',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing: Text(
                  '${_getModuleProgress(moduleIndex)}%',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _selectedModuleIndex = -1;
                    } else {
                      _selectedModuleIndex = moduleIndex;
                    }
                  });
                },
              ),

              // Lessons List
              if (isExpanded)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: lessons.asMap().entries.map((entry) {
                      final lessonIndex = entry.key;
                      final lesson = entry.value as Map<String, dynamic>;
                      final isSelected = moduleIndex == _selectedModuleIndex &&
                          lessonIndex == _selectedLessonIndex;
                      final isCompleted = _getLessonProgress(lesson) >= 0.8;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: isSelected
                              ? Border.all(
                                  color: AppTheme.primaryColor, width: 1)
                              : null,
                        ),
                        child: ListTile(
                          leading: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : isSelected
                                    ? Icons.play_circle_filled
                                    : Icons.play_circle_outline,
                            color: isCompleted
                                ? Colors.green
                                : isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey[400],
                          ),
                          title: Text(
                            lesson['title'] ?? 'Lesson ${lessonIndex + 1}',
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[300],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            _formatDuration(Duration(
                              seconds: lesson['duration'] ?? 0,
                            )),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          trailing: isCompleted
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () => _selectLesson(moduleIndex, lessonIndex),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Control methods
  void _toggleVideoControls() {
    setState(() {
      _showVideoControls = !_showVideoControls;
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _togglePlayPause() {
    if (_videoController != null) {
      if (_isVideoPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  void _previousLesson() {
    final modules = _courseData['modules'] as List<dynamic>? ?? [];
    if (modules.isNotEmpty && _selectedModuleIndex < modules.length) {
      final module = modules[_selectedModuleIndex] as Map<String, dynamic>;
      final lessons = module['lessons'] as List<dynamic>? ?? [];

      if (_selectedLessonIndex > 0) {
        _selectLesson(_selectedModuleIndex, _selectedLessonIndex - 1);
      } else if (_selectedModuleIndex > 0) {
        final prevModule =
            modules[_selectedModuleIndex - 1] as Map<String, dynamic>;
        final prevLessons = prevModule['lessons'] as List<dynamic>? ?? [];
        if (prevLessons.isNotEmpty) {
          _selectLesson(_selectedModuleIndex - 1, prevLessons.length - 1);
        }
      }
    }
  }

  void _nextLesson() {
    final modules = _courseData['modules'] as List<dynamic>? ?? [];
    if (modules.isNotEmpty && _selectedModuleIndex < modules.length) {
      final module = modules[_selectedModuleIndex] as Map<String, dynamic>;
      final lessons = module['lessons'] as List<dynamic>? ?? [];

      if (_selectedLessonIndex < lessons.length - 1) {
        _selectLesson(_selectedModuleIndex, _selectedLessonIndex + 1);
      } else if (_selectedModuleIndex < modules.length - 1) {
        _selectLesson(_selectedModuleIndex + 1, 0);
      }
    }
  }

  void _selectLesson(int moduleIndex, int lessonIndex) {
    // Reset per-lesson state and dispose controllers safely
    _hasMarkedCompletedForCurrentLesson = false;
    _videoController?.removeListener(_videoListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    setState(() {
      _selectedModuleIndex = moduleIndex;
      _selectedLessonIndex = lessonIndex;
    });

    final modules = _courseData['modules'] as List<dynamic>? ?? [];
    if (modules.isNotEmpty && moduleIndex < modules.length) {
      final module = modules[moduleIndex] as Map<String, dynamic>;
      final lessons = module['lessons'] as List<dynamic>? ?? [];
      if (lessons.isNotEmpty && lessonIndex < lessons.length) {
        final lesson = lessons[lessonIndex] as Map<String, dynamic>;
        final videoUrl = lesson['videoUrl'];
        if (videoUrl != null && videoUrl.isNotEmpty) {
          final courseId = (_courseData['id'] ?? '').toString();
          final lessonId = (lesson['id'] ?? '').toString();
          _loadVideo(
            videoUrl,
            courseId: courseId,
            lessonId: lessonId,
          );
        }
      }
    }
  }

  // Helper methods
  Map<String, dynamic>? _getCurrentLesson() {
    final modules = _courseData['modules'] as List<dynamic>? ?? [];
    if (modules.isNotEmpty && _selectedModuleIndex < modules.length) {
      final module = modules[_selectedModuleIndex] as Map<String, dynamic>;
      final lessons = module['lessons'] as List<dynamic>? ?? [];
      if (lessons.isNotEmpty && _selectedLessonIndex < lessons.length) {
        return lessons[_selectedLessonIndex] as Map<String, dynamic>;
      }
    }
    return null;
  }

  int _getTotalLessons() {
    final modules = _courseData['modules'] as List<dynamic>? ?? [];
    int total = 0;
    for (final module in modules) {
      final lessons =
          (module as Map<String, dynamic>)['lessons'] as List<dynamic>? ?? [];
      total += lessons.length;
    }
    return total;
  }

  double _getModuleProgress(int moduleIndex) {
    final modules = _courseData['modules'] as List<dynamic>? ?? [];
    if (modules.isNotEmpty && moduleIndex < modules.length) {
      final module = modules[moduleIndex] as Map<String, dynamic>;
      final lessons = module['lessons'] as List<dynamic>? ?? [];
      if (lessons.isEmpty) return 0.0;

      double totalProgress = 0.0;
      for (final lesson in lessons) {
        totalProgress += _getLessonProgress(lesson as Map<String, dynamic>);
      }
      return (totalProgress / lessons.length) * 100;
    }
    return 0.0;
  }

  double _getLessonProgress(Map<String, dynamic> lesson) {
    // This would typically come from your progress tracking service
    return lesson['progress'] ?? 0.0;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  int _calcTotalLessons() {
    final modules = (_courseData['modules'] as List<dynamic>? ?? []);
    int total = 0;
    for (final m in modules) {
      total += ((m as Map)['lessons'] as List).length;
    }
    return total;
  }

  int _calcCompletedLessons() {
    final modules = (_courseData['modules'] as List<dynamic>? ?? []);
    int total = 0;
    for (final m in modules) {
      total += ((m as Map)['lessons'] as List)
          .where((l) => (l as Map)['isCompleted'] == true)
          .length;
    }
    return total;
  }

  Widget _buildCurriculumTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        // Enhanced Progress Header with Glassmorphism
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Course Progress',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_courseData['completedLessons']} of ${_courseData['totalLessons']} lessons completed',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${(_courseData['progress'] * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Complete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_courseData['completedLessons']} lessons completed',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_courseData['remainingDuration']} remaining',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _courseData['progress'],
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Enhanced Modules List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: (_courseData['modules'] as List<dynamic>? ?? []).length,
            itemBuilder: (context, index) {
              final module = (_courseData['modules'] as List<dynamic>)[index]
                  as Map<String, dynamic>;
              return _buildEnhancedModuleCard(module, index);
            },
          ),
        ),
      ],
    );
  }

  Color _getLessonTypeColor(String type) {
    switch (type) {
      case 'video':
        return Colors.blue[600]!;
      case 'quiz':
        return Colors.orange[600]!;
      case 'assignment':
        return Colors.purple[600]!;
      case 'reading':
        return Colors.green[600]!;
      default:
        return Colors.blue[600]!;
    }
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_arrow;
      case 'quiz':
        return Icons.quiz;
      case 'assignment':
        return Icons.assignment;
      case 'reading':
        return Icons.book;
      default:
        return Icons.play_arrow;
    }
  }

  String _getLessonTypeText(String type) {
    switch (type) {
      case 'video':
        return 'Video';
      case 'quiz':
        return 'Quiz';
      case 'assignment':
        return 'Assignment';
      case 'reading':
        return 'Reading';
      default:
        return 'Video';
    }
  }

  void _openLesson(
      Map<String, dynamic> lesson, int moduleIndex, int lessonIndex) {
    // Navigate to integrated Player + Curriculum screen for video lessons
    if (lesson['type'] == 'video') {
      Get.toNamed('/coursePlayer', arguments: {
        'courseData': _courseData,
        'moduleIndex': moduleIndex,
        'lessonIndex': lessonIndex,
      });
    } else if (lesson['type'] == 'quiz') {
      Get.toNamed('/quiz', arguments: {
        'lesson': lesson,
        'course': _courseData,
      });
    } else if (lesson['type'] == 'assignment') {
      Get.toNamed('/assignment', arguments: {
        'lesson': lesson,
        'course': _courseData,
      });
    }
  }

  bool _hasNext(int moduleIndex, int lessonIndex) {
    final modules = _courseData['modules'] as List<dynamic>? ?? [];
    if (modules.isEmpty || moduleIndex >= modules.length || moduleIndex < 0) {
      return false;
    }
    final lessonsInModule = (modules[moduleIndex]
            as Map<String, dynamic>)['lessons'] as List<dynamic>? ??
        [];
    if (lessonIndex + 1 < lessonsInModule.length) return true;
    if (moduleIndex + 1 < modules.length) {
      final nextModuleLessons = (modules[moduleIndex + 1]
              as Map<String, dynamic>)['lessons'] as List<dynamic>? ??
          [];
      return nextModuleLessons.isNotEmpty;
    }
    return false;
  }

  Map<String, dynamic>? _findNextLesson(int moduleIndex, int lessonIndex) {
    final modules = _courseData['modules'] as List<dynamic>? ?? [];
    if (modules.isEmpty || moduleIndex >= modules.length || moduleIndex < 0) {
      return null;
    }
    final lessonsInModule = (modules[moduleIndex]
            as Map<String, dynamic>)['lessons'] as List<dynamic>? ??
        [];
    if (lessonIndex + 1 < lessonsInModule.length) {
      return {
        'lesson': lessonsInModule[lessonIndex + 1] as Map<String, dynamic>,
        'moduleIndex': moduleIndex,
        'lessonIndex': lessonIndex + 1,
      };
    }
    if (moduleIndex + 1 < modules.length) {
      final nextModuleLessons = (modules[moduleIndex + 1]
              as Map<String, dynamic>)['lessons'] as List<dynamic>? ??
          [];
      if (nextModuleLessons.isNotEmpty) {
        return {
          'lesson': nextModuleLessons[0] as Map<String, dynamic>,
          'moduleIndex': moduleIndex + 1,
          'lessonIndex': 0,
        };
      }
    }
    return null;
  }

  Map<String, dynamic>? _findPreviousLesson(int moduleIndex, int lessonIndex) {
    final modules = _courseData['modules'] as List<dynamic>? ?? [];
    if (modules.isEmpty || moduleIndex >= modules.length || moduleIndex < 0) {
      return null;
    }
    if (lessonIndex - 1 >= 0) {
      final lessonsInModule = (modules[moduleIndex]
              as Map<String, dynamic>)['lessons'] as List<dynamic>? ??
          [];
      if (lessonIndex - 1 < lessonsInModule.length) {
        return {
          'lesson': lessonsInModule[lessonIndex - 1] as Map<String, dynamic>,
          'moduleIndex': moduleIndex,
          'lessonIndex': lessonIndex - 1,
        };
      }
    }
    if (moduleIndex - 1 >= 0) {
      final prevModuleLessons = (modules[moduleIndex - 1]
              as Map<String, dynamic>)['lessons'] as List<dynamic>? ??
          [];
      if (prevModuleLessons.isNotEmpty) {
        final lastIdx = prevModuleLessons.length - 1;
        return {
          'lesson': prevModuleLessons[lastIdx] as Map<String, dynamic>,
          'moduleIndex': moduleIndex - 1,
          'lessonIndex': lastIdx,
        };
      }
    }
    return null;
  }

  Widget _buildNotesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.note_add,
              size: 48,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Take notes while learning to help you remember key concepts',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Add note functionality
                },
                borderRadius: BorderRadius.circular(12),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Note',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildResourceCard(
          'Course Materials',
          'Download course slides, code examples, and additional resources',
          Icons.folder,
          Colors.blue,
        ),
        _buildResourceCard(
          'Community Forum',
          'Connect with other students and ask questions',
          Icons.forum,
          Colors.green,
        ),
        _buildResourceCard(
          'Instructor Office Hours',
          'Join live Q&A sessions with the instructor',
          Icons.schedule,
          Colors.orange,
        ),
        _buildResourceCard(
          'Certificate',
          'Download your course completion certificate',
          Icons.verified,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildResourceCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    );
  }
}
