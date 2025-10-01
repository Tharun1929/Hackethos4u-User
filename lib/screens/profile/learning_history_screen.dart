import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LearningHistoryScreen extends StatefulWidget {
  const LearningHistoryScreen({super.key});

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen> {
  String _filter = 'All';
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filter == 'All'
        ? _history
        : _history.where((e) => e['type'] == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning History'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        centerTitle: true,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Course', child: Text('Courses')),
                      DropdownMenuItem(
                          value: 'Webinar', child: Text('Webinars')),
                    ],
                    onChanged: (v) => setState(() => _filter = v ?? 'All'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No learning history yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) =>
                            _buildHistoryItem(theme, filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadHistory() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _loading = false;
        });
        return;
      }
      // Fetch progress events (example schema)
      final q = await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(uid)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final items = q.docs.map((d) {
        final m = d.data();
        return {
          'title': m['courseTitle'] ?? 'Course',
          'lesson': m['lessonTitle'] ?? 'Lesson',
          'date': (m['timestamp'] as Timestamp?)
                  ?.toDate()
                  .toIso8601String()
                  .split('T')
                  .first ??
              '',
          'duration': (m['durationMinutes'] as num?)?.toInt() ?? 0,
          'progress':
              ((m['progress'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
          'type': (m['type'] as String?) ?? 'Course',
        };
      }).toList();

      setState(() {
        _history = items;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildHistoryItem(ThemeData theme, Map<String, dynamic> item) {
    final progress = (item['progress'] as num).toDouble();
    final progressPercent = (progress * 100).round();
    final duration = item['duration'] as int;
    final type = item['type'] as String;
    final title = item['title'] as String;
    final lesson = item['lesson'] as String;
    final date = item['date'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Could navigate to specific lesson or course
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon, title, and date
              Row(
                children: [
                  // Activity icon with type-based color
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getActivityTypeColor(type).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getActivityTypeIcon(type),
                      color: _getActivityTypeColor(type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and lesson
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Date
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$progressPercent%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getActivityTypeColor(type),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.dividerColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getActivityTypeColor(type)),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom info row
              Row(
                children: [
                  // Duration
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$duration min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getActivityTypeColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getActivityTypeColor(type),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Continue button
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActivityTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Colors.blue;
      case 'quiz':
        return Colors.orange;
      case 'assignment':
        return Colors.purple;
      case 'course':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_fill;
      case 'quiz':
        return Icons.quiz;
      case 'assignment':
        return Icons.assignment;
      case 'course':
        return Icons.school;
      default:
        return Icons.play_circle_fill;
    }
  }
}
