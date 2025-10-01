import 'package:flutter/material.dart';

class VideoRestrictionService {
  static final VideoRestrictionService _instance =
      VideoRestrictionService._internal();
  factory VideoRestrictionService() => _instance;
  VideoRestrictionService._internal();

  // Skipping restrictions
  static const int _maxSkipDuration = 10; // Maximum 10 seconds skip
  static const int _minWatchTime =
      30; // Minimum 30 seconds before allowing skip
  static const int _maxSkipsPerVideo = 3; // Maximum 3 skips per video

  // Track skipping behavior
  final Map<String, VideoSkipData> _videoSkipData = {};

  // Check if user can skip forward
  bool canSkipForward({
    required String videoId,
    required Duration currentPosition,
    required Duration totalDuration,
    required Duration watchTime,
  }) {
    final skipData = _videoSkipData[videoId] ?? VideoSkipData();

    // Check if minimum watch time is met
    if (watchTime.inSeconds < _minWatchTime) {
      return false;
    }

    // Check if maximum skips reached
    if (skipData.skipCount >= _maxSkipsPerVideo) {
      return false;
    }

    // Check if skip would exceed video duration
    final skipToPosition =
        currentPosition + const Duration(seconds: _maxSkipDuration);
    if (skipToPosition >= totalDuration) {
      return false;
    }

    return true;
  }

  // Check if user can skip backward
  bool canSkipBackward({
    required String videoId,
    required Duration currentPosition,
  }) {
    final skipData = _videoSkipData[videoId] ?? VideoSkipData();

    // Check if maximum skips reached
    if (skipData.skipCount >= _maxSkipsPerVideo) {
      return false;
    }

    // Check if skip would go before video start
    final skipToPosition =
        currentPosition - const Duration(seconds: _maxSkipDuration);
    if (skipToPosition < Duration.zero) {
      return false;
    }

    return true;
  }

  // Record a skip action
  void recordSkip(String videoId, SkipDirection direction) {
    final skipData = _videoSkipData[videoId] ?? VideoSkipData();
    skipData.skipCount++;
    skipData.lastSkipTime = DateTime.now();
    skipData.skipHistory.add(SkipRecord(
      direction: direction,
      timestamp: DateTime.now(),
    ));
    _videoSkipData[videoId] = skipData;
  }

  // Get skip data for a video
  VideoSkipData getSkipData(String videoId) {
    return _videoSkipData[videoId] ?? VideoSkipData();
  }

  // Reset skip data for a video
  void resetSkipData(String videoId) {
    _videoSkipData.remove(videoId);
  }

  // Get remaining skips for a video
  int getRemainingSkips(String videoId) {
    final skipData = _videoSkipData[videoId] ?? VideoSkipData();
    return _maxSkipsPerVideo - skipData.skipCount;
  }

  // Show skip restriction message
  static void showSkipRestrictionMessage(BuildContext context, String reason) {
    String message;
    IconData icon;
    Color color;

    switch (reason) {
      case 'min_watch_time':
        message = 'Watch at least 30 seconds before skipping';
        icon = Icons.timer;
        color = Colors.orange;
        break;
      case 'max_skips':
        message = 'Maximum 3 skips allowed per video';
        icon = Icons.block;
        color = Colors.red;
        break;
      case 'video_end':
        message = 'Cannot skip beyond video duration';
        icon = Icons.play_arrow;
        color = Colors.blue;
        break;
      default:
        message = 'Skipping is restricted';
        icon = Icons.info;
        color = Colors.grey;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Build skip restriction indicator
  static Widget buildSkipRestrictionIndicator(String videoId) {
    final service = VideoRestrictionService();
    final remainingSkips = service.getRemainingSkips(videoId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: remainingSkips > 0 ? Colors.blue[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: remainingSkips > 0 ? Colors.blue[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            remainingSkips > 0 ? Icons.fast_forward : Icons.block,
            color: remainingSkips > 0 ? Colors.blue[600] : Colors.red[600],
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            'Skips: $remainingSkips/3',
            style: TextStyle(
              color: remainingSkips > 0 ? Colors.blue[600] : Colors.red[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Check if user is trying to skip too frequently
  bool isSkippingTooFrequently(String videoId) {
    final skipData = _videoSkipData[videoId] ?? VideoSkipData();

    if (skipData.skipHistory.isEmpty) return false;

    final now = DateTime.now();
    final recentSkips = skipData.skipHistory
        .where(
          (skip) => now.difference(skip.timestamp).inSeconds < 10,
        )
        .length;

    return recentSkips >= 2; // More than 2 skips in 10 seconds
  }

  // Get skip statistics for analytics
  Map<String, dynamic> getSkipStatistics(String videoId) {
    final skipData = _videoSkipData[videoId] ?? VideoSkipData();

    return {
      'totalSkips': skipData.skipCount,
      'remainingSkips': getRemainingSkips(videoId),
      'lastSkipTime': skipData.lastSkipTime,
      'skipHistory': skipData.skipHistory
          .map((skip) => {
                'direction': skip.direction.toString(),
                'timestamp': skip.timestamp.toIso8601String(),
              })
          .toList(),
    };
  }
}

// Data classes for skip tracking
class VideoSkipData {
  int skipCount = 0;
  DateTime? lastSkipTime;
  List<SkipRecord> skipHistory = [];
}

class SkipRecord {
  final SkipDirection direction;
  final DateTime timestamp;

  SkipRecord({
    required this.direction,
    required this.timestamp,
  });
}

enum SkipDirection {
  forward,
  backward,
}
