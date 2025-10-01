import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';

class LearningStreakScreen extends StatefulWidget {
  const LearningStreakScreen({super.key});

  @override
  State<LearningStreakScreen> createState() => _LearningStreakScreenState();
}

class _LearningStreakScreenState extends State<LearningStreakScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _streakData;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load streak data
      final streakDoc = await FirebaseFirestore.instance
          .collection('userStreaks')
          .doc(user.uid)
          .get();

      if (streakDoc.exists) {
        setState(() {
          _streakData = streakDoc.data();
        });
      }

      // Load recent activity
      final activityQuery = await FirebaseFirestore.instance
          .collection('user_progress')
          .doc(user.uid)
          .collection('videos')
          .orderBy('lastWatched', descending: true)
          .limit(30)
          .get();

      setState(() {
        _recentActivity = activityQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'videoTitle': data['videoTitle'] ?? 'Unknown Video',
            'lastWatched': data['lastWatched'],
            'progressPercentage': data['progressPercentage'] ?? 0.0,
            'hasWatched': data['hasWatched'] ?? false,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      // print('Error loading streak data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Learning Streak'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStreakOverview(),
                  const SizedBox(height: 24),
                  _buildStreakCalendar(),
                  const SizedBox(height: 24),
                  _buildRecentActivity(),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakOverview() {
    final currentStreak = _streakData?['currentStreak'] ?? 0;
    final longestStreak = _streakData?['longestStreak'] ?? 0;
    final lastActive = _streakData?['lastActive'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fire emoji and streak count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 16),
              Text(
                '$currentStreak',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            currentStreak == 1 ? 'Day Streak' : 'Days Streak',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Longest Streak',
                '$longestStreak days',
                Icons.trending_up,
              ),
              _buildStatItem(
                'Last Active',
                _formatLastActive(lastActive),
                Icons.schedule,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Motivational message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getMotivationalMessage(currentStreak),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCalendar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Calendar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Calendar grid (simplified - showing last 30 days)
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final days = List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      final isToday = date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;
      final hasActivity = _hasActivityOnDate(date);

      return {
        'date': date,
        'isToday': isToday,
        'hasActivity': hasActivity,
        'dayNumber': date.day,
      };
    });

    return Column(
      children: [
        // Week day headers
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),

        const SizedBox(height: 8),

        // Calendar grid
        ...List.generate(5, (weekIndex) {
          final weekDays = days.skip(weekIndex * 7).take(7).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: weekDays.map((day) {
                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: (day['hasActivity'] as bool? ?? false)
                            ? Colors.orange[400]
                            : (day['isToday'] as bool? ?? false)
                                ? Colors.blue[100]
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: (day['isToday'] as bool? ?? false)
                            ? Border.all(color: Colors.blue[400]!, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          day['dayNumber'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: (day['isToday'] as bool? ?? false)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: (day['hasActivity'] as bool? ?? false)
                                ? Colors.white
                                : (day['isToday'] as bool? ?? false)
                                    ? Colors.blue[700]
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(Colors.orange[400]!, 'Learning Day'),
            _buildLegendItem(Colors.blue[100]!, 'Today'),
            _buildLegendItem(Colors.grey[100]!, 'No Activity'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentActivity.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No recent activity',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ..._recentActivity
                .take(10)
                .map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final lastWatched = activity['lastWatched'] as Timestamp?;
    final timeAgo = lastWatched != null
        ? _getTimeAgo(lastWatched.toDate())
        : 'Unknown time';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity['hasWatched'] ? Colors.green : Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              activity['hasWatched'] ? Icons.check : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['videoTitle'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (activity['hasWatched'])
            const Icon(Icons.check_circle, color: Colors.green, size: 16)
          else
            Text(
              '${(activity['progressPercentage'] * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  bool _hasActivityOnDate(DateTime date) {
    // Check if there's any activity on this date
    return _recentActivity.any((activity) {
      final lastWatched = activity['lastWatched'] as Timestamp?;
      if (lastWatched == null) return false;

      final activityDate = lastWatched.toDate();
      return activityDate.day == date.day &&
          activityDate.month == date.month &&
          activityDate.year == date.year;
    });
  }

  String _formatLastActive(dynamic lastActive) {
    if (lastActive == null) return 'Never';

    final lastActiveDate = (lastActive as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(lastActiveDate);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
    return '${(difference.inDays / 30).floor()} months ago';
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  String _getMotivationalMessage(int streak) {
    if (streak == 0) return 'Start your learning journey today!';
    if (streak < 3) return 'Great start! Keep the momentum going!';
    if (streak < 7) return 'You\'re building a great habit!';
    if (streak < 30) return 'Amazing consistency! You\'re on fire!';
    if (streak < 100) return 'Incredible dedication! You\'re unstoppable!';
    return 'Legendary streak! You\'re a learning champion!';
  }
}
