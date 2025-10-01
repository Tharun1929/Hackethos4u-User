import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Comprehensive community and chat management system
class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<QuerySnapshot>? _forumsSubscription;
  StreamSubscription<QuerySnapshot>? _postsSubscription;

  // Callbacks
  Function(List<Map<String, dynamic>>)? _onMessagesUpdated;
  Function(List<Map<String, dynamic>>)? _onForumsUpdated;
  Function(List<Map<String, dynamic>>)? _onPostsUpdated;

  bool _isInitialized = false;

  /// Initialize community service
  Future<void> initialize({
    Function(List<Map<String, dynamic>>)? onMessagesUpdated,
    Function(List<Map<String, dynamic>>)? onForumsUpdated,
    Function(List<Map<String, dynamic>>)? onPostsUpdated,
  }) async {
    if (_isInitialized) return;

    _onMessagesUpdated = onMessagesUpdated;
    _onForumsUpdated = onForumsUpdated;
    _onPostsUpdated = onPostsUpdated;

    // Start listening to real-time updates
    await _startMessagesListener();
    await _startForumsListener();
    await _startPostsListener();

    _isInitialized = true;
    // print('✅ CommunityService initialized successfully');
  }

  /// Cursor for paginated queries
  DocumentSnapshot? _lastPostCursor;
  DocumentSnapshot? _lastCommentCursor;
  DocumentSnapshot? _lastMessageCursor;

  /// Start listening to messages
  Future<void> _startMessagesListener() async {
    try {
      _messagesSubscription = _firestore
          .collection('community_messages')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .listen((snapshot) {
        final messages = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        // print('💬 Messages updated: ${messages.length} messages');
        _onMessagesUpdated?.call(messages);
      });

      // print('✅ Messages listener started');
    } catch (e) {
      // print('❌ Error starting messages listener: $e');
    }
  }

  /// Start listening to forums
  Future<void> _startForumsListener() async {
    try {
      _forumsSubscription = _firestore
          .collection('community_forums')
          .orderBy('lastActivity', descending: true)
          .snapshots()
          .listen((snapshot) {
        final forums = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        // print('📋 Forums updated: ${forums.length} forums');
        _onForumsUpdated?.call(forums);
      });

      // print('✅ Forums listener started');
    } catch (e) {
      // print('❌ Error starting forums listener: $e');
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
          return {...data, 'id': doc.id};
        }).toList();

        // print('📝 Posts updated: ${posts.length} posts');
        _onPostsUpdated?.call(posts);
      });

      // print('✅ Posts listener started');
    } catch (e) {
      // print('❌ Error starting posts listener: $e');
    }
  }

  /// Send message to community chat
  Future<String?> sendMessage({
    required String message,
    String? replyTo,
    String? forumId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userEmail': user.email ?? '',
        'message': message,
        'replyTo': replyTo,
        'forumId': forumId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
        'isEdited': false,
        'editedAt': null,
      };

      final docRef =
          await _firestore.collection('community_messages').add(messageData);

      // Update forum last activity if specified
      if (forumId != null) {
        await _firestore.collection('community_forums').doc(forumId).update({
          'lastActivity': FieldValue.serverTimestamp(),
          'messageCount': FieldValue.increment(1),
        });
      }

      // print('✅ Message sent: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      // print('❌ Error sending message: $e');
      return null;
    }
  }

  /// Edit message
  Future<bool> editMessage({
    required String messageId,
    required String newMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final ref = _firestore.collection('community_messages').doc(messageId);
      final doc = await ref.get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != user.uid) {
        throw Exception('Not authorized to edit this message');
      }

      await ref.update({
        'message': newMessage,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete message
  Future<bool> deleteMessage(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final ref = _firestore.collection('community_messages').doc(messageId);
      final doc = await ref.get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != user.uid) {
        throw Exception('Not authorized to delete this message');
      }
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create forum
  Future<String?> createForum({
    required String name,
    required String description,
    String? category,
    bool isPrivate = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final forumData = {
        'name': name,
        'description': description,
        'category': category ?? 'General',
        'isPrivate': isPrivate,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'messageCount': 0,
        'members': [user.uid],
        'moderators': [user.uid],
      };

      final docRef =
          await _firestore.collection('community_forums').add(forumData);
      // print('✅ Forum created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      // print('❌ Error creating forum: $e');
      return null;
    }
  }

  /// Join forum
  Future<bool> joinForum(String forumId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('community_forums').doc(forumId).update({
        'members': FieldValue.arrayUnion([user.uid]),
        'memberCount': FieldValue.increment(1),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // print('✅ Joined forum: $forumId');
      return true;
    } catch (e) {
      // print('❌ Error joining forum: $e');
      return false;
    }
  }

  /// Leave forum
  Future<bool> leaveForum(String forumId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('community_forums').doc(forumId).update({
        'members': FieldValue.arrayRemove([user.uid]),
        'memberCount': FieldValue.increment(-1),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // print('✅ Left forum: $forumId');
      return true;
    } catch (e) {
      // print('❌ Error leaving forum: $e');
      return false;
    }
  }

  /// Create post
  Future<String?> createPost({
    required String title,
    required String content,
    String? forumId,
    String? category,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final postData = {
        'title': title,
        'content': content,
        'forumId': forumId,
        'category': category ?? 'General',
        'tags': tags ?? [],
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
        'authorEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
        'comments': 0,
        'views': 0,
        'isPinned': false,
        'isLocked': false,
      };

      final docRef =
          await _firestore.collection('community_posts').add(postData);

      // Update forum post count if specified
      if (forumId != null) {
        await _firestore.collection('community_forums').doc(forumId).update({
          'postCount': FieldValue.increment(1),
          'lastActivity': FieldValue.serverTimestamp(),
        });
      }

      // print('✅ Post created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      // print('❌ Error creating post: $e');
      return null;
    }
  }

  /// Edit post
  Future<bool> editPost({
    required String postId,
    String? title,
    String? content,
    List<String>? tags,
    String? category,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final ref = _firestore.collection('community_posts').doc(postId);
      final doc = await ref.get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      if (data['authorId'] != user.uid) {
        throw Exception('Not authorized to edit this post');
      }

      final update = <String, dynamic>{
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (tags != null) 'tags': tags,
        if (category != null) 'category': category,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (update.isEmpty) return true;
      await ref.update(update);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Like message
  Future<bool> likeMessage(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('community_messages').doc(messageId).update({
        'likedBy': FieldValue.arrayUnion([user.uid]),
        'likes': FieldValue.increment(1),
      });

      // print('✅ Message liked: $messageId');
      return true;
    } catch (e) {
      // print('❌ Error liking message: $e');
      return false;
    }
  }

  /// Unlike message
  Future<bool> unlikeMessage(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('community_messages').doc(messageId).update({
        'likedBy': FieldValue.arrayRemove([user.uid]),
        'likes': FieldValue.increment(-1),
      });

      // print('✅ Message unliked: $messageId');
      return true;
    } catch (e) {
      // print('❌ Error unliking message: $e');
      return false;
    }
  }

  /// Like post
  Future<bool> likePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('community_posts').doc(postId).update({
        'likedBy': FieldValue.arrayUnion([user.uid]),
        'likes': FieldValue.increment(1),
      });

      // print('✅ Post liked: $postId');
      return true;
    } catch (e) {
      // print('❌ Error liking post: $e');
      return false;
    }
  }

  /// Unlike post
  Future<bool> unlikePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('community_posts').doc(postId).update({
        'likedBy': FieldValue.arrayRemove([user.uid]),
        'likes': FieldValue.increment(-1),
      });

      // print('✅ Post unliked: $postId');
      return true;
    } catch (e) {
      // print('❌ Error unliking post: $e');
      return false;
    }
  }

  /// Add comment to post
  Future<String?> addComment({
    required String postId,
    required String content,
    String? replyTo,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final commentData = {
        'postId': postId,
        'content': content,
        'replyTo': replyTo,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
        'authorEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      };

      final docRef =
          await _firestore.collection('community_comments').add(commentData);

      // Update post comment count
      await _firestore.collection('community_posts').doc(postId).update({
        'comments': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // print('✅ Comment added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      // print('❌ Error adding comment: $e');
      return null;
    }
  }

  /// Edit comment
  Future<bool> editComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final ref = _firestore.collection('community_comments').doc(commentId);
      final doc = await ref.get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      if (data['authorId'] != user.uid) {
        throw Exception('Not authorized to edit this comment');
      }
      await ref.update({
        'content': content,
        'editedAt': FieldValue.serverTimestamp(),
        'isEdited': true,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete comment
  Future<bool> deleteComment(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final ref = _firestore.collection('community_comments').doc(commentId);
      final doc = await ref.get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      if (data['authorId'] != user.uid) {
        throw Exception('Not authorized to delete this comment');
      }
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get messages for forum
  Future<List<Map<String, dynamic>>> getForumMessages(String forumId,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('community_messages')
          .where('forumId', isEqualTo: forumId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting forum messages: $e');
      return [];
    }
  }

  /// Paginated forum messages
  Future<List<Map<String, dynamic>>> getForumMessagesPaginated(
    String forumId, {
    int pageSize = 30,
    bool reset = false,
  }) async {
    try {
      if (reset) _lastMessageCursor = null;
      Query query = _firestore
          .collection('community_messages')
          .where('forumId', isEqualTo: forumId)
          .orderBy('timestamp', descending: true)
          .limit(pageSize);
      if (_lastMessageCursor != null) {
        query = (query as Query<Map<String, dynamic>>)
            .startAfterDocument(_lastMessageCursor!);
      }
      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastMessageCursor = snapshot.docs.last;
      }
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get forums
  Future<List<Map<String, dynamic>>> getForums({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('community_forums')
          .orderBy('lastActivity', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting forums: $e');
      return [];
    }
  }

  /// Get posts
  Future<List<Map<String, dynamic>>> getPosts({
    String? forumId,
    String? category,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('community_posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (forumId != null) {
        query = query.where('forumId', isEqualTo: forumId);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting posts: $e');
      return [];
    }
  }

  /// Paginated posts
  Future<List<Map<String, dynamic>>> getPostsPaginated({
    String? forumId,
    String? category,
    int pageSize = 20,
    bool reset = false,
  }) async {
    try {
      if (reset) _lastPostCursor = null;
      Query query = _firestore
          .collection('community_posts')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (forumId != null) {
        query = query.where('forumId', isEqualTo: forumId);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (_lastPostCursor != null) {
        query = (query as Query<Map<String, dynamic>>)
            .startAfterDocument(_lastPostCursor!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastPostCursor = snapshot.docs.last;
      }
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get post comments
  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('community_comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting post comments: $e');
      return [];
    }
  }

  /// Paginated comments
  Future<List<Map<String, dynamic>>> getPostCommentsPaginated(
    String postId, {
    int pageSize = 30,
    bool reset = false,
  }) async {
    try {
      if (reset) _lastCommentCursor = null;
      Query query = _firestore
          .collection('community_comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .limit(pageSize);
      if (_lastCommentCursor != null) {
        query = (query as Query<Map<String, dynamic>>)
            .startAfterDocument(_lastCommentCursor!);
      }
      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastCommentCursor = snapshot.docs.last;
      }
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Report content (post/comment/message)
  Future<bool> reportContent({
    required String contentId,
    required String contentType, // 'post' | 'comment' | 'message'
    required String reason,
    String? details,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      await _firestore.collection('community_reports').add({
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
        'details': details ?? '',
        'reportedBy': user.uid,
        'reportedByEmail': user.email ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle like utility (works for posts/comments/messages)
  Future<bool> toggleLike({
    required String collection,
    required String docId,
    required bool like,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final ref = _firestore.collection(collection).doc(docId);
      await ref.update({
        'likedBy': like
            ? FieldValue.arrayUnion([user.uid])
            : FieldValue.arrayRemove([user.uid]),
        'likes': FieldValue.increment(like ? 1 : -1),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Search posts
  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    try {
      // Note: This is a basic search. For production, consider using Algolia or similar
      final snapshot = await _firestore
          .collection('community_posts')
          .orderBy('title')
          .startAt([query]).endAt(['$query\uf8ff']).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error searching posts: $e');
      return [];
    }
  }

  /// Get user's posts
  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('community_posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting user posts: $e');
      return [];
    }
  }

  /// Delete post
  Future<bool> deletePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is the author or moderator
      final postDoc =
          await _firestore.collection('community_posts').doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['authorId'] != user.uid) {
        // Check if user is moderator (implement moderator check)
        throw Exception('Not authorized to delete this post');
      }

      // Delete post
      await _firestore.collection('community_posts').doc(postId).delete();

      // Delete all comments
      final commentsSnapshot = await _firestore
          .collection('community_comments')
          .where('postId', isEqualTo: postId)
          .get();

      final batch = _firestore.batch();
      for (final doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // print('✅ Post deleted: $postId');
      return true;
    } catch (e) {
      // print('❌ Error deleting post: $e');
      return false;
    }
  }

  /// Get community statistics
  Future<Map<String, dynamic>> getCommunityStats() async {
    try {
      final forumsCount = await _firestore
          .collection('community_forums')
          .get()
          .then((snapshot) => snapshot.docs.length);
      final postsCount = await _firestore
          .collection('community_posts')
          .get()
          .then((snapshot) => snapshot.docs.length);
      final messagesCount = await _firestore
          .collection('community_messages')
          .get()
          .then((snapshot) => snapshot.docs.length);

      return {
        'forums': forumsCount,
        'posts': postsCount,
        'messages': messagesCount,
        'totalActivity': forumsCount + postsCount + messagesCount,
      };
    } catch (e) {
      // print('❌ Error getting community stats: $e');
      return {
        'forums': 0,
        'posts': 0,
        'messages': 0,
        'totalActivity': 0,
      };
    }
  }

  /// Get discussions (alias for getPosts)
  Future<List<Map<String, dynamic>>> getDiscussions({int limit = 20}) async {
    return await getPosts(limit: limit);
  }

  /// Get popular topics
  Future<List<Map<String, dynamic>>> getPopularTopics() async {
    try {
      final snapshot = await _firestore
          .collection('community_posts')
          .orderBy('likes', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      // print('❌ Error getting popular topics: $e');
      return [];
    }
  }

  /// Create discussion (alias for createPost)
  Future<String?> createDiscussion({
    required String title,
    required String content,
    String? forumId,
    String? category,
    List<String>? tags,
  }) async {
    return await createPost(
      title: title,
      content: content,
      forumId: forumId,
      category: category,
      tags: tags,
    );
  }

  /// Dispose resources
  void dispose() {
    _messagesSubscription?.cancel();
    _forumsSubscription?.cancel();
    _postsSubscription?.cancel();
    _isInitialized = false;
    // print('✅ CommunityService disposed');
  }
}
