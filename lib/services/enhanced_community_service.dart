import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class EnhancedCommunityService {
  static final EnhancedCommunityService _instance =
      EnhancedCommunityService._internal();
  factory EnhancedCommunityService() => _instance;
  EnhancedCommunityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<QuerySnapshot>? _forumsSubscription;
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  StreamSubscription<QuerySnapshot>? _qaSubscription;

  // Callbacks
  Function(List<Map<String, dynamic>>)? _onMessagesUpdated;
  Function(List<Map<String, dynamic>>)? _onForumsUpdated;
  Function(List<Map<String, dynamic>>)? _onPostsUpdated;
  Function(List<Map<String, dynamic>>)? _onQAUpdated;

  bool _isInitialized = false;

  /// Initialize enhanced community service
  Future<void> initialize({
    Function(List<Map<String, dynamic>>)? onMessagesUpdated,
    Function(List<Map<String, dynamic>>)? onForumsUpdated,
    Function(List<Map<String, dynamic>>)? onPostsUpdated,
    Function(List<Map<String, dynamic>>)? onQAUpdated,
  }) async {
    if (_isInitialized) return;

    _onMessagesUpdated = onMessagesUpdated;
    _onForumsUpdated = onForumsUpdated;
    _onPostsUpdated = onPostsUpdated;
    _onQAUpdated = onQAUpdated;

    // Start listening to real-time updates
    await _startMessagesListener();
    await _startForumsListener();
    await _startPostsListener();
    await _startQAListener();

    _isInitialized = true;
    // print('✅ EnhancedCommunityService initialized successfully');
  }

  /// Start listening to messages
  Future<void> _startMessagesListener() async {
    try {
      _messagesSubscription = _firestore
          .collection('community_messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        final messages = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        _onMessagesUpdated?.call(messages);
      });
    } catch (e) {
      // print('Error starting messages listener: $e');
    }
  }

  /// Start listening to forums
  Future<void> _startForumsListener() async {
    try {
      _forumsSubscription = _firestore
          .collection('community_forums')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        final forums = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        _onForumsUpdated?.call(forums);
      });
    } catch (e) {
      // print('Error starting forums listener: $e');
    }
  }

  /// Start listening to posts
  Future<void> _startPostsListener() async {
    try {
      _postsSubscription = _firestore
          .collection('community_posts')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        final posts = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        _onPostsUpdated?.call(posts);
      });
    } catch (e) {
      // print('Error starting posts listener: $e');
    }
  }

  /// Start listening to Q&A
  Future<void> _startQAListener() async {
    try {
      _qaSubscription = _firestore
          .collection('community_qa')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        final qa = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        _onQAUpdated?.call(qa);
      });
    } catch (e) {
      // print('Error starting Q&A listener: $e');
    }
  }

  /// Send a message to community chat
  Future<bool> sendMessage({
    required String content,
    String? courseId,
    String? lessonId,
    MessageType type = MessageType.general,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user is muted or banned
      final userStatus = await _getUserStatus(user.uid);
      if (userStatus['isMuted'] == true || userStatus['isBanned'] == true) {
        return false;
      }

      // Check message content for moderation
      final moderationResult = await _moderateMessage(content);
      if (!moderationResult['isApproved']) {
        // Log inappropriate content
        await _logModerationEvent(
            user.uid, content, moderationResult['reason']);
        return false;
      }

      await _firestore.collection('community_messages').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userAvatar': user.photoURL ?? '',
        'content': content,
        'courseId': courseId,
        'lessonId': lessonId,
        'type': type.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'isApproved': true,
        'isPinned': false,
        'reactions': {},
        'reports': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      // print('Error sending message: $e');
      return false;
    }
  }

  /// Create a forum post
  Future<bool> createForumPost({
    required String title,
    required String content,
    required String category,
    List<String> tags = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user is muted or banned
      final userStatus = await _getUserStatus(user.uid);
      if (userStatus['isMuted'] == true || userStatus['isBanned'] == true) {
        return false;
      }

      // Check content for moderation
      final moderationResult = await _moderateMessage('$title $content');
      if (!moderationResult['isApproved']) {
        await _logModerationEvent(
            user.uid, '$title $content', moderationResult['reason']);
        return false;
      }

      await _firestore.collection('community_forums').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userAvatar': user.photoURL ?? '',
        'title': title,
        'content': content,
        'category': category,
        'tags': tags,
        'isApproved': true,
        'isPinned': false,
        'isLocked': false,
        'views': 0,
        'replies': 0,
        'likes': 0,
        'reports': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      // print('Error creating forum post: $e');
      return false;
    }
  }

  /// Ask a question in Q&A section
  Future<bool> askQuestion({
    required String question,
    required String courseId,
    String? lessonId,
    List<String> tags = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user is muted or banned
      final userStatus = await _getUserStatus(user.uid);
      if (userStatus['isMuted'] == true || userStatus['isBanned'] == true) {
        return false;
      }

      // Check question for moderation
      final moderationResult = await _moderateMessage(question);
      if (!moderationResult['isApproved']) {
        await _logModerationEvent(
            user.uid, question, moderationResult['reason']);
        return false;
      }

      await _firestore.collection('community_qa').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userAvatar': user.photoURL ?? '',
        'question': question,
        'courseId': courseId,
        'lessonId': lessonId,
        'tags': tags,
        'isAnswered': false,
        'isApproved': true,
        'isPinned': false,
        'answers': [],
        'views': 0,
        'upvotes': 0,
        'reports': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      // print('Error asking question: $e');
      return false;
    }
  }

  /// Answer a question
  Future<bool> answerQuestion({
    required String questionId,
    required String answer,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user is muted or banned
      final userStatus = await _getUserStatus(user.uid);
      if (userStatus['isMuted'] == true || userStatus['isBanned'] == true) {
        return false;
      }

      // Check answer for moderation
      final moderationResult = await _moderateMessage(answer);
      if (!moderationResult['isApproved']) {
        await _logModerationEvent(user.uid, answer, moderationResult['reason']);
        return false;
      }

      final answerData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userAvatar': user.photoURL ?? '',
        'answer': answer,
        'isApproved': true,
        'upvotes': 0,
        'downvotes': 0,
        'isAccepted': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('community_qa').doc(questionId).update({
        'answers': FieldValue.arrayUnion([answerData]),
        'isAnswered': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      // print('Error answering question: $e');
      return false;
    }
  }

  /// Moderate message content
  Future<Map<String, dynamic>> _moderateMessage(String content) async {
    // Simple content moderation - in production, use AI/ML services
    final inappropriateWords = [
      'spam',
      'scam',
      'fake',
      'hack',
      'crack',
      'pirate',
      'illegal',
      'inappropriate',
      'offensive',
      'abusive',
      'harassment'
    ];

    final lowerContent = content.toLowerCase();
    for (final word in inappropriateWords) {
      if (lowerContent.contains(word)) {
        return {
          'isApproved': false,
          'reason': 'Content contains inappropriate language',
          'flaggedWord': word,
        };
      }
    }

    // Check for spam patterns
    if (content.length < 3) {
      return {
        'isApproved': false,
        'reason': 'Message too short',
      };
    }

    if (content.length > 1000) {
      return {
        'isApproved': false,
        'reason': 'Message too long',
      };
    }

    return {
      'isApproved': true,
      'reason': 'Content approved',
    };
  }

  /// Get user status (muted, banned, etc.)
  Future<Map<String, dynamic>> _getUserStatus(String userId) async {
    try {
      final doc = await _firestore.collection('user_status').doc(userId).get();
      if (doc.exists) {
        return doc.data()!;
      }
      return {
        'isMuted': false,
        'isBanned': false,
        'muteExpiry': null,
        'banExpiry': null,
      };
    } catch (e) {
      // print('Error getting user status: $e');
      return {
        'isMuted': false,
        'isBanned': false,
        'muteExpiry': null,
        'banExpiry': null,
      };
    }
  }

  /// Log moderation event
  Future<void> _logModerationEvent(
      String userId, String content, String reason) async {
    try {
      await _firestore.collection('moderation_logs').add({
        'userId': userId,
        'content': content,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'content_flagged',
      });
    } catch (e) {
      // print('Error logging moderation event: $e');
    }
  }

  /// Report content
  Future<bool> reportContent({
    required String contentId,
    required String contentType,
    required String reason,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('reports').add({
        'reporterId': user.uid,
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
        'description': description,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment report count on the content
      await _firestore
          .collection('community_$contentType')
          .doc(contentId)
          .update({
        'reports': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      // print('Error reporting content: $e');
      return false;
    }
  }

  /// Get community statistics
  Future<Map<String, dynamic>> getCommunityStats() async {
    try {
      final messagesCount =
          await _firestore.collection('community_messages').count().get();
      final forumsCount =
          await _firestore.collection('community_forums').count().get();
      final qaCount = await _firestore.collection('community_qa').count().get();
      final usersCount = await _firestore.collection('users').count().get();

      return {
        'totalMessages': messagesCount.count,
        'totalForums': forumsCount.count,
        'totalQA': qaCount.count,
        'totalUsers': usersCount.count,
        'activeUsers': await _getActiveUsersCount(),
      };
    } catch (e) {
      // print('Error getting community stats: $e');
      return {
        'totalMessages': 0,
        'totalForums': 0,
        'totalQA': 0,
        'totalUsers': 0,
        'activeUsers': 0,
      };
    }
  }

  /// Get active users count (users active in last 24 hours)
  Future<int> _getActiveUsersCount() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final query = await _firestore
          .collection('users')
          .where('lastActive', isGreaterThan: yesterday)
          .count()
          .get();
      return query.count ?? 0;
    } catch (e) {
      // print('Error getting active users count: $e');
      return 0;
    }
  }

  /// Dispose resources
  void dispose() {
    _messagesSubscription?.cancel();
    _forumsSubscription?.cancel();
    _postsSubscription?.cancel();
    _qaSubscription?.cancel();
    _isInitialized = false;
  }
}

enum MessageType {
  general,
  course,
  lesson,
  question,
  answer,
  announcement,
}
