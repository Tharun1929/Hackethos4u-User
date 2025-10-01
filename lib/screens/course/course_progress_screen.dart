import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CourseProgressScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const CourseProgressScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseProgressScreen> createState() => _CourseProgressScreenState();
}

class _CourseProgressScreenState extends State<CourseProgressScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _courseProgress;
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  int _certificateEligibility = 70; // Default percentage

  @override
  void initState() {
    super.initState();
    _loadCourseProgress();
    _loadCertificateSettings();
  }

  Future<void> _loadCertificateSettings() async {
    try {
      final settingsDoc = await FirebaseFirestore.instance
          .collection('appSettings')
          .doc('settings')
          .get();

      if (settingsDoc.exists) {
        final settings = settingsDoc.data()!;
        setState(() {
          _certificateEligibility = settings['certificateEligibility'] ?? 70;
        });
      }
    } catch (e) {
      // print('Error loading certificate settings: $e');
    }
  }

  Future<void> _loadCourseProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load course progress
      final progressDoc = await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(user.uid)
          .collection('courses')
          .doc(widget.courseId)
          .get();

      if (progressDoc.exists) {
        setState(() {
          _courseProgress = progressDoc.data();
        });
      }

      // Load course videos
      final videosQuery = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('videos')
          .orderBy('order', descending: false)
          .get();

      // Load user's video progress
      final videoProgressQuery = await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(user.uid)
          .collection('videos')
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      final videoProgressMap = {
        for (var doc in videoProgressQuery.docs)
          doc.data()['videoId']: doc.data()
      };

      setState(() {
        _videos = videosQuery.docs.map((doc) {
          final videoData = doc.data();
          final videoId = doc.id;
          final progress = videoProgressMap[videoId];

          return {
            'id': videoId,
            'title': videoData['title'] ?? 'Untitled Video',
            'duration': videoData['duration'] ?? 0,
            'order': videoData['order'] ?? 0,
            'thumbnail': videoData['thumbnail'] ?? '',
            'isWatched': progress?['hasWatched'] ?? false,
            'watchTime': progress?['watchTime'] ?? 0,
            'progressPercentage': progress?['progressPercentage'] ?? 0.0,
            'lastWatched': progress?['lastWatched'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      // print('Error loading course progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Course Progress'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_courseProgress != null &&
              _courseProgress!['isCompleted'] == true)
            IconButton(
              onPressed: _showCertificate,
              icon: const Icon(Icons.emoji_events),
              tooltip: 'View Certificate',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressOverview(),
                  const SizedBox(height: 16),
                  _buildCertificateRequirements(),
                  const SizedBox(height: 24),
                  _buildVideosList(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressOverview() {
    final progress = _courseProgress?['progressPercentage'] ?? 0.0;
    final watchedVideos = _courseProgress?['watchedVideos'] ?? 0;
    final totalVideos = _courseProgress?['totalVideos'] ?? _videos.length;
    final isCompleted = _courseProgress?['isCompleted'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.courseTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Complete',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '$watchedVideos of $totalVideos videos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : Colors.blue[600]!,
                ),
                minHeight: 8,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _buildStatCard(
                icon: Icons.play_circle_outline,
                label: 'Videos Watched',
                value: watchedVideos.toString(),
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.timer_outlined,
                label: 'Total Duration',
                value: _formatTotalDuration(),
                color: Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${_courseProgress?['streakDays'] ?? 0} days',
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateRequirements() {
    final progress = _courseProgress?['progressPercentage'] ?? 0.0;
    final progressPercentage = (progress * 100).round();
    final isEligible = progressPercentage >= _certificateEligibility;
    final hasCertificate = _courseProgress?['hasCertificate'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEligible ? Colors.green : Colors.orange,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCertificate ? Icons.emoji_events : Icons.school,
                color: hasCertificate
                    ? Colors.amber
                    : (isEligible ? Colors.green : Colors.orange),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasCertificate
                      ? 'Certificate Earned!'
                      : 'Certificate Requirements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        hasCertificate ? Colors.amber[700] : Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasCertificate) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Congratulations! You\'ve earned a certificate for completing $progressPercentage% of this course.',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Progress towards certificate
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Complete $progressPercentage% of course',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '$_certificateEligibility% required',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isEligible ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isEligible ? Colors.green : Colors.orange,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isEligible
                      ? 'You\'re eligible for a certificate! Complete the course to receive it.'
                      : 'Complete ${_certificateEligibility - progressPercentage}% more to be eligible for a certificate.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isEligible ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideosList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Videos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._videos.map((video) => _buildVideoItem(video)),
      ],
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    final isWatched = video['isWatched'] ?? false;
    final progressPercentage = video['progressPercentage'] ?? 0.0;
    final watchTime = video['watchTime'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWatched ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Video thumbnail/icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color:
                  isWatched ? Colors.green.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: isWatched
                ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                : const Icon(Icons.play_circle_outline,
                    color: Colors.grey, size: 24),
          ),

          const SizedBox(width: 16),

          // Video info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isWatched ? Colors.green[700] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(Duration(seconds: video['duration'])),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (watchTime > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Watched: ${_formatDuration(Duration(seconds: watchTime))}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Progress indicator
          Column(
            children: [
              if (progressPercentage > 0 && !isWatched) ...[
                CircularProgressIndicator(
                  value: progressPercentage,
                  strokeWidth: 3,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progressPercentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                  ),
                ),
              ] else if (isWatched) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(height: 4),
                const Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showCertificate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 8),
            Text('Course Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Congratulations! You have successfully completed this course.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Certificate of Completion',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'This certificate is available in your profile',
                    style: TextStyle(fontSize: 12),
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
              // Navigate to certificates screen
              Get.snackbar(
                'Certificate',
                'Certificate feature coming soon!',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
            child: const Text('View Certificate'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatTotalDuration() {
    final totalSeconds = _videos.fold<int>(
        0, (sum, video) => sum + (video['duration'] as int? ?? 0));
    return _formatDuration(Duration(seconds: totalSeconds));
  }
}
