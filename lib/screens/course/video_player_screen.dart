import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/security_service.dart';
import '../../services/firestore_service.dart';
import '../../services/course_access_service.dart';
import '../../services/security_restriction_service.dart';
import '../../services/video_restriction_service.dart';
import '../../utils/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> videoData;

  const VideoPlayerScreen({super.key, required this.videoData});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // Video Controllers
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  // UI State
  final bool _showControls = true;
  bool _isFullScreen = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Duration _maxAllowedPosition = Duration.zero; // anti-skip until 70%
  bool _showSkipBlockedToast = false;

  // Demo Mode
  bool _isDemoMode = false;
  final int _demoTimeLimit = 5 * 60; // 5 minutes in seconds
  bool _demoTimeExceeded = false;
  Timer? _demoTimer;

  // Progress and Certificate
  double _progressPercentage = 0.0;
  bool _hasWatched = false;
  int _watchTime = 0;
  int _streakDays = 0;

  // UI Controllers
  final TextEditingController _noteController = TextEditingController();
  final List<Map<String, dynamic>> _notes = [];
  final List<Map<String, dynamic>> _bookmarks = [];

  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CourseAccessService _courseAccessService = CourseAccessService();
  final SecurityRestrictionService _securityService =
      SecurityRestrictionService();
  final VideoRestrictionService _videoRestrictionService =
      VideoRestrictionService();

  @override
  void initState() {
    super.initState();
    _checkDemoMode();
    _checkCourseAccess();
    _initializePlayer();
    _enableSecurity();
    _loadUserProgress();
    _loadUserStreak();
    _loadNotes();
    _loadBookmarks();
  }

  Future<void> _enableSecurity() async {
    await SecurityService.enableForSensitiveScreen();

    // Enable screen recording and screenshot restrictions for paid content
    if (!_isDemoMode) {
      await _securityService.enableRestrictions();
      SecurityRestrictionService.logSecurityEvent(
          'Video player security enabled');
    }
  }

  Future<void> _checkCourseAccess() async {
    try {
      final courseId = widget.videoData['courseId'];
      final lessonId = widget.videoData['lessonId'];

      if (courseId != null && lessonId != null) {
        final hasAccess =
            await _courseAccessService.hasLessonAccess(courseId, lessonId);

        if (!hasAccess && !_isDemoMode) {
          _showAccessDeniedDialog();
        }
      }
    } catch (e) {
      // print('Error checking course access: $e');
    }
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('Access Denied'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You don\'t have access to this lesson. Please complete the previous lessons or enroll in the course.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete previous lessons to unlock this content.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
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
              Navigator.pop(context); // Go back to course
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SecurityService.disableForNormalScreen();
    _securityService.disableRestrictions();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _noteController.dispose();
    _demoTimer?.cancel();
    super.dispose();
  }

  Future<String?> _generateBasicCertificate({
    required String userId,
    required dynamic courseId,
    required String courseName,
    required String userName,
  }) async {
    try {
      // Basic certificate generation - you can implement your own logic here
      // For now, return a placeholder URL
      return 'https://example.com/certificates/${userId}_$courseId.pdf';
    } catch (e) {
      print('Error generating certificate: $e');
      return null;
    }
  }

  void _checkDemoMode() {
    // Check if this is a demo video
    _isDemoMode = widget.videoData['isPreview'] == true ||
        widget.videoData['isDemo'] == true ||
        (widget.videoData['title']?.toString().toLowerCase().contains('demo') ??
            false);

    if (_isDemoMode) {
      _startDemoTimer();
    }
  }

  void _startDemoTimer() {
    _demoTimer = Timer(Duration(seconds: _demoTimeLimit), () {
      if (mounted) {
        setState(() {
          _demoTimeExceeded = true;
        });
        _showDemoTimeUpDialog();
      }
    });
  }

  void _showDemoTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer_off, color: AppTheme.warningColor),
            const SizedBox(width: 8),
            const Text('Demo Time Up!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your 5-minute demo has ended. Enroll now to continue learning with full access!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Get lifetime access to all course content, certificates, and community features.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to enrollment/payment
              Get.toNamed('/payment', arguments: {
                'courseId': widget.videoData['courseId'],
                'courseTitle': widget.videoData['courseTitle'],
                'price': widget.videoData['price'],
                'instructor': widget.videoData['instructor'],
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enroll Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializePlayer() async {
    try {
      final videoUrl = widget.videoData['videoUrl'] ?? widget.videoData['url'];
      if (videoUrl == null || videoUrl.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showOptions: false,
        showControlsOnInitialize: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryColor,
          // handleColor: AppTheme.primaryColor, // Not supported in this version
          backgroundColor: AppTheme.borderColor,
          bufferedColor: AppTheme.borderColor.withOpacity(0.5),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        autoInitialize: true,
      );

      _videoPlayerController.addListener(_videoListener);
      _videoPlayerController.addListener(_updateProgress);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // print('Error initializing video player: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _currentPosition = _videoPlayerController.value.position;
        _totalDuration = _videoPlayerController.value.duration;
        _isPlaying = _videoPlayerController.value.isPlaying;
      });

      // Anti-skip enforcement for paid content until 70% watched
      if (!_isDemoMode && _totalDuration.inMilliseconds > 0) {
        final double progress =
            _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;

        // Track furthest watched point
        if (_currentPosition > _maxAllowedPosition) {
          _maxAllowedPosition = _currentPosition;
        }

        // If user jumps ahead beyond allowed window before 70%, snap back
        if (progress < 0.7) {
          final bool jumpedAhead = _currentPosition >
              (_maxAllowedPosition + const Duration(seconds: 2));
          if (jumpedAhead) {
            _videoPlayerController.seekTo(_maxAllowedPosition);
            if (!_showSkipBlockedToast) {
              _showSkipBlockedToast = true;
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please watch at least 70% before skipping ahead'),
                      duration: Duration(seconds: 2),
                    ),
                  )
                  .closed
                  .then((_) => _showSkipBlockedToast = false);
            }
          }
        } else {
          // After 70%, lift the gate entirely
          if (_maxAllowedPosition < _totalDuration) {
            _maxAllowedPosition = _totalDuration;
          }
        }
      }
    }
  }

  void _updateProgress() {
    if (!mounted) return;

    final position = _videoPlayerController.value.position;
    final duration = _videoPlayerController.value.duration;

    if (duration.inMilliseconds > 0) {
      final progress = position.inMilliseconds / duration.inMilliseconds;

      // Update watch time every 10 seconds
      if (position.inSeconds % 10 == 0 && position.inSeconds > _watchTime) {
        _watchTime = position.inSeconds;
        _saveProgress(progress);
      }

      // Mark as watched when 80% complete
      if (progress >= 0.8 && !_hasWatched) {
        _hasWatched = true;
        _markAsWatched();
      }
    }
  }

  Future<void> _saveProgress(double progress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final courseId = widget.videoData['courseId'];
      final videoId = widget.videoData['id'] ?? widget.videoData['lessonId'];

      if (courseId == null || videoId == null) return;

      // Save video progress
      await _firestoreService.userProgressCollection
          .doc(user.uid)
          .collection('videos')
          .doc(videoId)
          .set({
        'videoId': videoId,
        'courseId': courseId,
        'progress': progress,
        'watchTime': _watchTime,
        'lastWatchedAt': FieldValue.serverTimestamp(),
        'hasWatched': _hasWatched,
      }, SetOptions(merge: true));

      // Update course progress
      await _updateCourseProgress(courseId);
    } catch (e) {
      // print('Error saving progress: $e');
    }
  }

  Future<void> _markAsWatched() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final courseId = widget.videoData['courseId'];
      final videoId = widget.videoData['id'] ?? widget.videoData['lessonId'];

      if (courseId == null || videoId == null) return;

      // Mark video as watched
      await _firestoreService.userProgressCollection
          .doc(user.uid)
          .collection('videos')
          .doc(videoId)
          .set({
        'hasWatched': true,
        'watchedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update course progress
      await _updateCourseProgress(courseId);

      // Update learning streak
      await _updateStreak();
    } catch (e) {
      // print('Error marking as watched: $e');
    }
  }

  Future<void> _updateCourseProgress(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get all videos in the course
      final videosQuery = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('videos')
          .get();

      // Get user's video progress
      final videoProgressQuery = await _firestoreService.userProgressCollection
          .doc(user.uid)
          .collection('videos')
          .where('courseId', isEqualTo: courseId)
          .get();

      final totalVideos = videosQuery.docs.length;
      final watchedVideos = videoProgressQuery.docs
          .where((doc) => doc.data()['hasWatched'] == true)
          .length;

      final progressPercentage =
          totalVideos > 0 ? (watchedVideos / totalVideos) * 100 : 0.0;

      // Update course progress
      await _firestoreService.userProgressCollection
          .doc(user.uid)
          .collection('courses')
          .doc(courseId)
          .set({
        'courseId': courseId,
        'progressPercentage': progressPercentage,
        'watchedVideos': watchedVideos,
        'totalVideos': totalVideos,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _progressPercentage = progressPercentage;
      });

      // Check for certificate eligibility
      await _checkAndGenerateCertificate(courseId, progressPercentage);
    } catch (e) {
      // print('Error updating course progress: $e');
    }
  }

  Future<void> _updateStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final streakDoc = await _firestoreService.userProgressCollection
          .doc(user.uid)
          .collection('meta')
          .doc('learningStreak')
          .get();

      if (streakDoc.exists) {
        final streakData = streakDoc.data()!;
        final lastActiveDate = streakData['lastActiveDate'] as String?;
        final currentStreak = streakData['currentStreak'] ?? 0;

        if (lastActiveDate == todayStr) {
          // Already updated today
          return;
        }

        final lastActive =
            lastActiveDate != null ? DateTime.parse(lastActiveDate) : null;
        final daysDifference =
            lastActive != null ? today.difference(lastActive).inDays : 1;

        int newStreak = currentStreak;
        if (daysDifference == 1) {
          // Consecutive day
          newStreak++;
        } else if (daysDifference > 1) {
          // Streak broken
          newStreak = 1;
        }

        await _firestoreService.userProgressCollection
            .doc(user.uid)
            .collection('meta')
            .doc('learningStreak')
            .set({
          'currentStreak': newStreak,
          'lastActiveDate': todayStr,
          'totalDays': (streakData['totalDays'] ?? 0) + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        setState(() {
          _streakDays = newStreak;
        });
      } else {
        // First time learning
        await _firestoreService.userProgressCollection
            .doc(user.uid)
            .collection('meta')
            .doc('learningStreak')
            .set({
          'currentStreak': 1,
          'lastActiveDate': todayStr,
          'totalDays': 1,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _streakDays = 1;
        });
      }
    } catch (e) {
      // print('Error updating streak: $e');
    }
  }

  Future<void> _loadUserProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final courseId = widget.videoData['courseId'];
      if (courseId == null) return;

      final progressDoc = await _firestoreService.userProgressCollection
          .doc(user.uid)
          .collection('courses')
          .doc(courseId)
          .get();

      if (progressDoc.exists) {
        final progressData = progressDoc.data()!;
        final progressPercentage = progressData['progressPercentage'] ?? 0.0;

        // Check if user is eligible for certificate
        await _checkAndGenerateCertificate(courseId, progressPercentage);
      }
    } catch (e) {
      // print('Error loading user progress: $e');
    }
  }

  Future<void> _checkAndGenerateCertificate(
      String courseId, double courseProgress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get certificate eligibility percentage from admin settings
      final settingsDoc = await FirebaseFirestore.instance
          .collection('appSettings')
          .doc('settings')
          .get();

      final certificateEligibility = settingsDoc.exists
          ? (settingsDoc.data()?['certificateEligibility'] ?? 70)
          : 70;

      // Check if user meets the eligibility requirement
      if (courseProgress >= certificateEligibility) {
        // Check if certificate already exists
        final existingCertQuery = await FirebaseFirestore.instance
            .collection('certificates')
            .where('userId', isEqualTo: user.uid)
            .where('courseId', isEqualTo: courseId)
            .get();

        if (existingCertQuery.docs.isEmpty) {
          // Generate certificate
          await _generateCertificate(courseId, courseProgress);
        }
      }
    } catch (e) {
      // print('Error checking certificate eligibility: $e');
    }
  }

  Future<void> _generateCertificate(
      String courseId, double courseProgress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating your certificate...'),
            ],
          ),
        ),
      );

      // Get course details
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();

      if (!courseDoc.exists) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Course not found');
        return;
      }

      final courseData = courseDoc.data()!;
      final courseName = courseData['title'] ?? 'Course';
      final userName = user.displayName ?? user.email ?? 'Student';

      // Generate certificate using basic certificate service
      final certificateUrl = await _generateBasicCertificate(
        userId: user.uid,
        courseId: courseId,
        courseName: courseName,
        userName: userName,
      );

      Navigator.pop(context); // Close loading dialog

      if (certificateUrl != null) {
        // Update user progress to mark certificate as earned
        await FirebaseFirestore.instance
            .collection('userProgress')
            .doc(user.uid)
            .collection('courses')
            .doc(courseId)
            .set({
          'hasCertificate': true,
          'certificateEarnedAt': FieldValue.serverTimestamp(),
          'certificateUrl': certificateUrl,
        }, SetOptions(merge: true));

        _showSuccessSnackBar(
            '🎉 Congratulations! Your certificate has been generated!');
        _showCertificateDialog(certificateUrl);
      } else {
        _showErrorSnackBar('Failed to generate certificate. Please try again.');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      // print('Error generating certificate: $e');
      _showErrorSnackBar('Error generating certificate: $e');
    }
  }

  void _showCertificateDialog(String certificateUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 8),
            Text('Certificate Earned!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Congratulations! You have successfully completed the course and earned your certificate.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your certificate is now available in your profile.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.toNamed('/certificates');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Certificate'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadUserStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final streakDoc = await _firestoreService.userProgressCollection
          .doc(user.uid)
          .collection('meta')
          .doc('learningStreak')
          .get();

      if (streakDoc.exists) {
        final streakData = streakDoc.data()!;
        setState(() {
          _streakDays = streakData['currentStreak'] ?? 0;
        });
      }
    } catch (e) {
      // print('Error loading user streak: $e');
    }
  }

  Future<void> _loadNotes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final videoId = widget.videoData['id'] ?? widget.videoData['lessonId'];
      if (videoId == null) return;

      final notesQuery = await _firestoreService.userProgressCollection
          .doc(user.uid)
          .collection('notes')
          .where('videoId', isEqualTo: videoId)
          .orderBy('timestamp', descending: false)
          .get();

      setState(() {
        _notes
          ..clear()
          ..addAll(notesQuery.docs
              .map((doc) => doc.data())
              .cast<Map<String, dynamic>>());
      });
    } catch (e) {
      // print('Error loading notes: $e');
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final videoId = widget.videoData['id'] ?? widget.videoData['lessonId'];
      if (videoId == null) return;

      final bookmarksQuery = await _firestoreService.userProgressCollection
          .doc(user.uid)
          .collection('bookmarks')
          .where('videoId', isEqualTo: videoId)
          .orderBy('timestamp', descending: false)
          .get();

      setState(() {
        _bookmarks
          ..clear()
          ..addAll(bookmarksQuery.docs
              .map((doc) => doc.data())
              .cast<Map<String, dynamic>>());
      });
    } catch (e) {
      // print('Error loading bookmarks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : _chewieController != null
                      ? _buildVideoPlayer()
                      : const Center(
                          child: Text(
                            'Video not available',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
            ),
            if (_showControls) _buildControlsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.8),
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
                  widget.videoData['title'] ?? 'Video Title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_isDemoMode)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'DEMO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!_isDemoMode) SecurityRestrictionService.buildSecurityIndicator(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      children: [
        // Video Player
        Center(
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const Text('Video not available',
                  style: TextStyle(color: Colors.white)),
        ),

        // Security Overlay (for paid content)
        if (!_isDemoMode) SecurityRestrictionService.buildSecurityOverlay(),

        // Skip Restriction Indicator
        if (!_isDemoMode) _buildSkipRestrictionIndicator(),

        // Custom Overlay Controls
        if (_showControls) _buildCustomControls(),
      ],
    );
  }

  Widget _buildSkipRestrictionIndicator() {
    final videoId =
        widget.videoData['id'] ?? widget.videoData['lessonId'] ?? 'unknown';
    return Positioned(
      top: 10,
      left: 10,
      child: VideoRestrictionService.buildSkipRestrictionIndicator(videoId),
    );
  }

  Widget _buildCustomControls() {
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
            if (_isDemoMode) _buildDemoTimeIndicator(),
            _buildProgressBar(),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoTimeIndicator() {
    final remainingTime = _demoTimeLimit - _currentPosition.inSeconds;
    final minutes = (remainingTime / 60).floor();
    final seconds = remainingTime % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.timer, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Demo Time: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} remaining',
            style: TextStyle(
              color: AppTheme.warningColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.toNamed('/payment', arguments: {
                'courseId': widget.videoData['courseId'],
                'courseTitle': widget.videoData['courseTitle'],
                'price': widget.videoData['price'],
                'instructor': widget.videoData['instructor'],
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Enroll Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: VideoProgressIndicator(
        _videoPlayerController,
        // Disable scrubbing for paid content until threshold is reached
        allowScrubbing: _isDemoMode,
        colors: VideoProgressColors(
          playedColor: AppTheme.primaryColor,
          // handleColor: AppTheme.primaryColor, // Not supported in this version
          backgroundColor: AppTheme.borderColor,
          bufferedColor: AppTheme.borderColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: _isPlaying ? _pauseVideo : _playVideo,
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
            style: const TextStyle(color: Colors.white),
          ),
          const Spacer(),
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

  Widget _buildControlsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notes and Bookmarks tabs would go here
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _playVideo() {
    _videoPlayerController.play();
  }

  void _pauseVideo() {
    _videoPlayerController.pause();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
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
}
