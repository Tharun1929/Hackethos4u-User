import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'data_sync_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DataSyncService _dataSyncService = DataSyncService();

  // Collection references
  CollectionReference get notificationsCollection =>
      _firestore.collection('notifications');
  CollectionReference get userNotificationsCollection =>
      _firestore.collection('user_notifications');

  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      await _requestPermission();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      _setupMessageHandlers();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // print('Notification service initialized successfully');
    } catch (e) {
      // print('Error initializing notification service: $e');
    }
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // print('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      // print('Error requesting permission: $e');
    }
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
        // print('FCM Token: $token');
      }
    } catch (e) {
      // print('Error getting FCM token: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('user_tokens').doc(user.uid).set({
        'userId': user.uid,
        'email': user.email,
        'fcmToken': token,
        'platform': 'flutter',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error saving FCM token: $e');
    }
  }

  // Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // print('Got a message whilst in the foreground!');
      // print('Message data: ${message.data}');

      if (message.notification != null) {
        // print('Message also contained a notification: ${message.notification}');
        _handleForegroundMessage(message);
      }
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // print('App opened from notification: ${message.data}');
      _handleNotificationTap(message);
    });

    // Handle initial message when app is launched from notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        // print('App launched from notification: ${message.data}');
        _handleNotificationTap(message);
      }
    });
  }

  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      // Store notification in Firestore
      _storeNotification(message);

      // You can show a custom in-app notification here
      // print('Showing in-app notification: ${message.notification?.title}');
    } catch (e) {
      // print('Error handling foreground message: $e');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;

      // Handle different notification types
      switch (data['type']) {
        case 'course_update':
          _handleCourseUpdateNotification(data);
          break;
        case 'new_course':
          _handleNewCourseNotification(data);
          break;
        case 'payment_success':
          _handlePaymentSuccessNotification(data);
          break;
        case 'general':
        default:
          _handleGeneralNotification(data);
          break;
      }
    } catch (e) {
      // print('Error handling notification tap: $e');
    }
  }

  // Store notification in Firestore
  Future<void> _storeNotification(RemoteMessage message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final notificationData = {
        'userId': user.uid,
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'type': message.data['type'] ?? 'general',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'fcmMessageId': message.messageId,
      };

      await notificationsCollection.add(notificationData);
    } catch (e) {
      // print('Error storing notification: $e');
    }
  }

  // Handle course update notification
  void _handleCourseUpdateNotification(Map<String, dynamic> data) {
    try {
      final courseId = data['courseId'];
      if (courseId != null) {
        // Navigate to course detail or refresh course data
        // print('Navigating to course: $courseId');
        // You can implement navigation logic here
      }
    } catch (e) {
      // print('Error handling course update notification: $e');
    }
  }

  // Handle new course notification
  void _handleNewCourseNotification(Map<String, dynamic> data) {
    try {
      final courseId = data['courseId'];
      if (courseId != null) {
        // Navigate to new course
        // print('Navigating to new course: $courseId');
        // You can implement navigation logic here
      }
    } catch (e) {
      // print('Error handling new course notification: $e');
    }
  }

  // Handle payment success notification
  void _handlePaymentSuccessNotification(Map<String, dynamic> data) {
    try {
      final courseId = data['courseId'];
      if (courseId != null) {
        // Navigate to course or show success message
        // print('Payment successful for course: $courseId');
        // You can implement navigation logic here
      }
    } catch (e) {
      // print('Error handling payment success notification: $e');
    }
  }

  // Handle general notification
  void _handleGeneralNotification(Map<String, dynamic> data) {
    try {
      // Handle general notifications
      // print('Handling general notification: $data');
      // You can implement general notification logic here
    } catch (e) {
      // print('Error handling general notification: $e');
    }
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String type = 'general',
  }) async {
    try {
      // Store in Firestore
      final notificationData = {
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await notificationsCollection.add(notificationData);

      // Get user's FCM token
      final tokenDoc =
          await _firestore.collection('user_tokens').doc(userId).get();
      if (tokenDoc.exists) {
        final token = tokenDoc.data()?['fcmToken'] as String?;
        if (token != null) {
          // Send FCM notification (this would typically be done from server)
          // print('FCM token found for user $userId: $token');
          // In a real app, you'd send this to your server to send FCM
        }
      }
    } catch (e) {
      // print('Error sending notification: $e');
    }
  }

  // Get user notifications
  Stream<QuerySnapshot> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return notificationsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await notificationsCollection.doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await notificationsCollection
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      // print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      // print('Error deleting notification: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return notificationsCollection
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      // print('Subscribed to topic: $topic');
    } catch (e) {
      // print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      // print('Unsubscribed from topic: $topic');
    } catch (e) {
      // print('Error unsubscribing from topic: $e');
    }
  }

  /// Get all notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications_${user.uid}');

      if (notificationsJson != null) {
        final List<dynamic> notificationsList = json.decode(notificationsJson);
        return notificationsList.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notifications = await getNotifications();
      final updatedNotifications = notifications.map((notification) {
        if (notification['id'] == notificationId) {
          notification['isRead'] = true;
        }
        return notification;
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'notifications_${user.uid}', json.encode(updatedNotifications));
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Dispose
  void dispose() {
    // Clean up any resources if needed
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // print('Handling a background message: ${message.messageId}');

  // Store notification in Firestore
  try {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user != null) {
      final notificationData = {
        'userId': user.uid,
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'type': message.data['type'] ?? 'general',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'fcmMessageId': message.messageId,
        'handledInBackground': true,
      };

      await firestore.collection('notifications').add(notificationData);
    }
  } catch (e) {
    // print('Error handling background message: $e');
  }
}
