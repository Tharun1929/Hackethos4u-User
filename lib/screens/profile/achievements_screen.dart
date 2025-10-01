import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Map<String, dynamic>> achievements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final achievementsQuery = await FirebaseFirestore.instance
          .collection('userAchievements')
          .doc(uid)
          .collection('achievements')
          .orderBy('earnedAt', descending: true)
          .get();

      setState(() {
        achievements = achievementsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'title': data['title'] ?? 'Achievement',
            'desc': data['description'] ?? 'Great job!',
            'points': data['points'] ?? 0,
            'icon': _getAchievementIcon(data['type']),
            'color': _getAchievementColor(data['type']),
            'date': data['earnedAt'] != null
                ? (data['earnedAt'] as Timestamp)
                    .toDate()
                    .toIso8601String()
                    .split('T')[0]
                : DateTime.now().toIso8601String().split('T')[0],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      // print('Error loading achievements: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  IconData _getAchievementIcon(String? type) {
    switch (type) {
      case 'course_completion':
        return Icons.emoji_events;
      case 'streak':
        return Icons.local_fire_department;
      case 'first_lesson':
        return Icons.school;
      case 'certificate':
        return Icons.verified;
      case 'perfect_score':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getAchievementColor(String? type) {
    switch (type) {
      case 'course_completion':
        return Colors.amber;
      case 'streak':
        return Colors.redAccent;
      case 'first_lesson':
        return Colors.blue;
      case 'certificate':
        return Colors.green;
      case 'perfect_score':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        centerTitle: true,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : achievements.isEmpty
              ? _buildEmptyState(theme)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(theme, achievements),
                    const SizedBox(height: 16),
                    ...achievements.map((a) => _buildAchievementItem(theme, a)),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Achievements Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start learning to earn your first achievement!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            icon: const Icon(Icons.explore),
            label: const Text('Explore Courses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, List<Map<String, dynamic>> items) {
    final totalPoints =
        items.fold<int>(0, (sum, e) => sum + (e['points'] as int));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.emoji_events, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Points', style: theme.textTheme.bodySmall),
                Text('$totalPoints',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text('${items.length} badges', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(ThemeData theme, Map<String, dynamic> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: (a['color'] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(a['icon'] as IconData, color: a['color'] as Color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['title'] as String,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(a['desc'] as String, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  a['date'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: (a['color'] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Text('+${a['points']}',
                style: TextStyle(
                    color: a['color'] as Color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
