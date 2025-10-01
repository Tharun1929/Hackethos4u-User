import 'package:flutter/material.dart';
import '../services/admin_user_bridge_service.dart';

class AdminSyncStatusWidget extends StatefulWidget {
  final bool showDetails;
  final VoidCallback? onRefresh;

  const AdminSyncStatusWidget({
    super.key,
    this.showDetails = false,
    this.onRefresh,
  });

  @override
  State<AdminSyncStatusWidget> createState() => _AdminSyncStatusWidgetState();
}

class _AdminSyncStatusWidgetState extends State<AdminSyncStatusWidget> {
  final AdminUserBridgeService _bridgeService = AdminUserBridgeService();
  bool _isConnected = false;
  String _lastUpdate = 'Never';
  String _syncStatus = 'Disconnected';
  Color _statusColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _initializeSync();
  }

  Future<void> _initializeSync() async {
    try {
      await _bridgeService.initialize();
      _listenToUpdates();
      setState(() {
        _isConnected = true;
        _syncStatus = 'Connected';
        _statusColor = Colors.green;
        _lastUpdate = DateTime.now().toString().substring(0, 19);
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _syncStatus = 'Error: $e';
        _statusColor = Colors.red;
      });
    }
  }

  void _listenToUpdates() {
    // Listen to course updates
    _bridgeService.getCourseUpdates().listen((update) {
      setState(() {
        _lastUpdate = DateTime.now().toString().substring(0, 19);
      });

      // Show notification for important updates
      if (update['type'] == 'admin_course_added') {
        _showUpdateNotification('New course added by admin!');
      } else if (update['type'] == 'admin_course_updated') {
        _showUpdateNotification('Course updated by admin!');
      }
    });

    // Listen to user updates
    _bridgeService.getUserUpdates().listen((update) {
      setState(() {
        _lastUpdate = DateTime.now().toString().substring(0, 19);
      });

      if (update['type'] == 'admin_user_updated') {
        _showUpdateNotification('Your profile was updated by admin!');
      }
    });

    // Listen to enrollment updates
    _bridgeService.getEnrollmentUpdates().listen((update) {
      setState(() {
        _lastUpdate = DateTime.now().toString().substring(0, 19);
      });

      if (update['type'] == 'admin_enrollment_added') {
        _showUpdateNotification('New enrollment added by admin!');
      }
    });

    // Listen to notifications
    _bridgeService.getNotifications().listen((notification) {
      setState(() {
        _lastUpdate = DateTime.now().toString().substring(0, 19);
      });

      if (notification['type'] == 'admin_notification_added') {
        _showUpdateNotification('New notification from admin!');
      }
    });
  }

  void _showUpdateNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to appropriate screen
          },
        ),
      ),
    );
  }

  Future<void> _refreshSync() async {
    setState(() {
      _syncStatus = 'Refreshing...';
      _statusColor = Colors.orange;
    });

    try {
      await _bridgeService.initialize();
      setState(() {
        _isConnected = true;
        _syncStatus = 'Connected';
        _statusColor = Colors.green;
        _lastUpdate = DateTime.now().toString().substring(0, 19);
      });

      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _syncStatus = 'Error: $e';
        _statusColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.1),
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
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Admin Sync Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _refreshSync,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh sync',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Row
          Row(
            children: [
              Icon(
                _isConnected ? Icons.check_circle : Icons.error,
                color: _statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _syncStatus,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Last Update Row
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Last update: $_lastUpdate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
            ],
          ),

          if (widget.showDetails) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Detailed Status
            _buildDetailRow('Course Updates', 'Active'),
            _buildDetailRow('User Updates', 'Active'),
            _buildDetailRow('Enrollment Updates', 'Active'),
            _buildDetailRow('Notifications', 'Active'),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected
                        ? () {
                            // Send test sync
                            _bridgeService.sendFeedbackToAdmin({
                              'type': 'sync_test',
                              'message': 'User app sync test',
                              'timestamp': DateTime.now().toIso8601String(),
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Test sync sent to admin!')),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Test Sync'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isConnected
                        ? () {
                            // View sync logs
                            _showSyncLogs();
                          }
                        : null,
                    icon: const Icon(Icons.list),
                    label: const Text('View Logs'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Logs'),
        content: const SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              Text('Recent sync activities will be displayed here.'),
              SizedBox(height: 16),
              Text(
                'This feature shows real-time synchronization between admin and user apps.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bridgeService.dispose();
    super.dispose();
  }
}
