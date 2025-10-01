import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Comprehensive notification management system
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  StreamSubscription<QuerySnapshot>? _notificationStream;

  /// Initialize notification system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Start listening to Firestore notifications
      await _startNotificationListener();

      _isInitialized = true;
      // print('✅ NotificationManager initialized successfully');
    } catch (e) {
      // print('❌ Error initializing NotificationManager: $e');
    }
  }

  /// Start listening to Firestore notifications
  Future<void> _startNotificationListener() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _notificationStream = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        for (final doc in snapshot.docs) {
          final notification = doc.data();
          // print('🔔 New notification: ${notification['title']}');
        }
      });

      // print('✅ Notification listener started');
    } catch (e) {
      // print('❌ Error starting notification listener: $e');
    }
  }

  /// Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    String? targetId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type ?? 'general',
        'targetId': targetId,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('notifications').add(notificationData);
      // print('✅ Notification sent to user: $userId');
    } catch (e) {
      // print('❌ Error sending notification: $e');
    }
  }

  /// Send course-related notification
  Future<void> sendCourseNotification({
    required String userId,
    required String courseId,
    required String courseTitle,
    required String type,
    String? message,
  }) async {
    String title;
    String body;

    switch (type) {
      case 'enrolled':
        title = 'Course Enrolled';
        body = 'You have been enrolled in "$courseTitle"';
        break;
      case 'completed':
        title = 'Course Completed';
        body = 'Congratulations! You have completed "$courseTitle"';
        break;
      case 'certificate':
        title = 'Certificate Ready';
        body = 'Your certificate for "$courseTitle" is ready for download';
        break;
      case 'assignment':
        title = 'New Assignment';
        body = 'New assignment available for "$courseTitle"';
        break;
      default:
        title = 'Course Update';
        body = message ?? 'Update for "$courseTitle"';
    }

    await sendNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'course',
      targetId: courseId,
      data: {
        'courseId': courseId,
        'courseTitle': courseTitle,
        'notificationType': type,
      },
    );
  }

  /// Send payment notification
  Future<void> sendPaymentNotification({
    required String userId,
    required String courseTitle,
    required double amount,
    required String status,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'success':
        title = 'Payment Successful';
        body =
            'Payment of ₹${amount.toStringAsFixed(2)} for "$courseTitle" was successful';
        break;
      case 'failed':
        title = 'Payment Failed';
        body =
            'Payment of ₹${amount.toStringAsFixed(2)} for "$courseTitle" failed';
        break;
      case 'refunded':
        title = 'Payment Refunded';
        body =
            'Payment of ₹${amount.toStringAsFixed(2)} for "$courseTitle" has been refunded';
        break;
      default:
        title = 'Payment Update';
        body =
            'Update for payment of ₹${amount.toStringAsFixed(2)} for "$courseTitle"';
    }

    await sendNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'payment',
      data: {
        'courseTitle': courseTitle,
        'amount': amount,
        'status': status,
      },
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      // print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      // print('✅ All notifications marked as read');
    } catch (e) {
      // print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      // print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Get notifications for user
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      // print('✅ All notifications cleared');
    } catch (e) {
      // print('❌ Error clearing notifications: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationStream?.cancel();
    _isInitialized = false;
    // print('✅ NotificationManager disposed');
  }
}
