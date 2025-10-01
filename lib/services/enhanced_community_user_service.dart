import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class EnhancedCommunityUserService {
  static final EnhancedCommunityUserService _instance =
      EnhancedCommunityUserService._internal();
  factory EnhancedCommunityUserService() => _instance;
  EnhancedCommunityUserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  StreamSubscription<QuerySnapshot>? _commentsSubscription;
  StreamSubscription<QuerySnapshot>? _qaSubscription;

  // Callbacks
  Function(List<Map<String, dynamic>>)? _onPostsUpdated;
  Function(List<Map<String, dynamic>>)? _onCommentsUpdated;
  Function(List<Map<String, dynamic>>)? _onQAUpdated;

  bool _isInitialized = false;

  /// Initialize community service
  Future<void> initialize({
    Function(List<Map<String, dynamic>>)? onPostsUpdated,
    Function(List<Map<String, dynamic>>)? onCommentsUpdated,
    Function(List<Map<String, dynamic>>)? onQAUpdated,
  }) async {
    if (_isInitialized) return;

    _onPostsUpdated = onPostsUpdated;
    _onCommentsUpdated = onCommentsUpdated;
    _onQAUpdated = onQAUpdated;

    // Start listening to real-time updates
    await _startPostsListener();
    await _startCommentsListener();
    await _startQAListener();

    _isInitialized = true;
  }

  /// Start listening to posts
  Future<void> _startPostsListener() async {
    try {
      _postsSubscription = _firestore
          .collection('community_posts')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        final posts = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        _onPostsUpdated?.call(posts);
      });
    } catch (e) {
      print('Error starting posts listener: $e');
    }
  }

  /// Start listening to comments
  Future<void> _startCommentsListener() async {
    try {
      _commentsSubscription = _firestore
          .collection('community_comments')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .listen((snapshot) {
        final comments = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        _onCommentsUpdated?.call(comments);
      });
    } catch (e) {
      print('Error starting comments listener: $e');
    }
  }

  /// Start listening to Q&A
  Future<void> _startQAListener() async {
    try {
      _qaSubscription = _firestore
          .collection('community_qa')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        final qa = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        _onQAUpdated?.call(qa);
      });
    } catch (e) {
      print('Error starting Q&A listener: $e');
    }
  }

  /// Create a new post
  Future<String?> createPost({
    required String title,
    required String content,
    String category = 'General',
    List<String> tags = const [],
    String? courseId,
    String? courseTitle,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final postData = {
        'title': title,
        'content': content,
        'category': category,
        'tags': tags,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
        'authorEmail': user.email ?? '',
        'authorAvatar': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
        'comments': 0,
        'views': 0,
        'isPinned': false,
        'isLocked': false,
        'isApproved': true,
        'reports': [],
      };

      final docRef = await _firestore.collection('community_posts').add(postData);
      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  /// Create a comment
  Future<String?> createComment({
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
        'authorAvatar': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
        'isEdited': false,
        'isApproved': true,
        'reports': [],
      };

      final docRef = await _firestore.collection('community_comments').add(commentData);

      // Update post comment count
      await _firestore.collection('community_posts').doc(postId).update({
        'comments': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating comment: $e');
      return null;
    }
  }

  /// Ask a question
  Future<String?> askQuestion({
    required String question,
    List<String> tags = const [],
    String? courseId,
    String? courseTitle,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final qaData = {
        'question': question,
        'tags': tags,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
        'authorEmail': user.email ?? '',
        'authorAvatar': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'answers': [],
        'views': 0,
        'upvotes': 0,
        'upvotedBy': [],
        'isAnswered': false,
        'isPinned': false,
        'isApproved': true,
        'reports': [],
      };

      final docRef = await _firestore.collection('community_qa').add(qaData);
      return docRef.id;
    } catch (e) {
      print('Error asking question: $e');
      return null;
    }
  }

  /// Answer a question
  Future<String?> answerQuestion({
    required String questionId,
    required String answer,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final answerData = {
        'content': answer,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
        'authorEmail': user.email ?? '',
        'authorAvatar': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'upvotedBy': [],
        'isAccepted': false,
        'isEdited': false,
        'isApproved': true,
        'reports': [],
      };

      final docRef = await _firestore.collection('community_qa_answers').add(answerData);

      // Update question with answer
      await _firestore.collection('community_qa').doc(questionId).update({
        'answers': FieldValue.arrayUnion([docRef.id]),
        'isAnswered': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error answering question: $e');
      return null;
    }
  }

  /// Like/Unlike content
  Future<bool> toggleLike({
    required String contentId,
    required String contentType,
    required bool like,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final collection = _getCollectionName(contentType);
      if (collection == null) return false;

      await _firestore.collection(collection).doc(contentId).update({
        'likedBy': like
            ? FieldValue.arrayUnion([user.uid])
            : FieldValue.arrayRemove([user.uid]),
        'likes': FieldValue.increment(like ? 1 : -1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  /// Upvote/Downvote Q&A
  Future<bool> toggleUpvote({
    required String qaId,
    required bool upvote,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('community_qa').doc(qaId).update({
        'upvotedBy': upvote
            ? FieldValue.arrayUnion([user.uid])
            : FieldValue.arrayRemove([user.uid]),
        'upvotes': FieldValue.increment(upvote ? 1 : -1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error toggling upvote: $e');
      return false;
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
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('community_reports').add({
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
        'description': description,
        'reporterId': user.uid,
        'reporterName': user.displayName ?? 'Anonymous',
        'reporterEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Mark content as reported
      final collection = _getCollectionName(contentType);
      if (collection != null) {
        await _firestore.collection(collection).doc(contentId).update({
          'reports': FieldValue.arrayUnion([user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error reporting content: $e');
      return false;
    }
  }

  /// Get posts with filtering
  Future<List<Map<String, dynamic>>> getPosts({
    String? category,
    String? courseId,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection('community_posts')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (courseId != null) {
        query = query.where('courseId', isEqualTo: courseId);
      }

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('community_posts')
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }

  /// Get comments for a post
  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('community_comments')
          .where('postId', isEqualTo: postId)
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      print('Error getting post comments: $e');
      return [];
    }
  }

  /// Get Q&A with filtering
  Future<List<Map<String, dynamic>>> getQA({
    String? courseId,
    bool? isAnswered,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection('community_qa')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (courseId != null) {
        query = query.where('courseId', isEqualTo: courseId);
      }
      if (isAnswered != null) {
        query = query.where('isAnswered', isEqualTo: isAnswered);
      }

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('community_qa')
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      print('Error getting Q&A: $e');
      return [];
    }
  }

  /// Get answers for a question
  Future<List<Map<String, dynamic>>> getQuestionAnswers(String questionId) async {
    try {
      final snapshot = await _firestore
          .collection('community_qa_answers')
          .where('questionId', isEqualTo: questionId)
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      print('Error getting question answers: $e');
      return [];
    }
  }

  /// Search content
  Future<List<Map<String, dynamic>>> searchContent({
    required String query,
    String? contentType,
    int limit = 20,
  }) async {
    try {
      List<Map<String, dynamic>> results = [];

      if (contentType == null || contentType == 'posts') {
        final postsSnapshot = await _firestore
            .collection('community_posts')
            .where('isApproved', isEqualTo: true)
            .get();

        for (final doc in postsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
              data['content'].toString().toLowerCase().contains(query.toLowerCase())) {
            results.add({...data, 'id': doc.id, 'type': 'post'});
          }
        }
      }

      if (contentType == null || contentType == 'qa') {
        final qaSnapshot = await _firestore
            .collection('community_qa')
            .where('isApproved', isEqualTo: true)
            .get();

        for (final doc in qaSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['question'].toString().toLowerCase().contains(query.toLowerCase())) {
            results.add({...data, 'id': doc.id, 'type': 'qa'});
          }
        }
      }

      // Sort by relevance (simple implementation)
      results.sort((a, b) {
        final aTitle = a['title']?.toString().toLowerCase() ?? '';
        final bTitle = b['title']?.toString().toLowerCase() ?? '';
        final aContent = a['content']?.toString().toLowerCase() ?? '';
        final bContent = b['content']?.toString().toLowerCase() ?? '';
        final aQuestion = a['question']?.toString().toLowerCase() ?? '';
        final bQuestion = b['question']?.toString().toLowerCase() ?? '';

        final aScore = (aTitle.contains(query.toLowerCase()) ? 2 : 0) +
            (aContent.contains(query.toLowerCase()) ? 1 : 0) +
            (aQuestion.contains(query.toLowerCase()) ? 2 : 0);
        final bScore = (bTitle.contains(query.toLowerCase()) ? 2 : 0) +
            (bContent.contains(query.toLowerCase()) ? 1 : 0) +
            (bQuestion.contains(query.toLowerCase()) ? 2 : 0);

        return bScore.compareTo(aScore);
      });

      return results.take(limit).toList();
    } catch (e) {
      print('Error searching content: $e');
      return [];
    }
  }

  /// Get user's content
  Future<Map<String, List<Map<String, dynamic>>>> getUserContent(String userId) async {
    try {
      final futures = await Future.wait([
        _firestore
            .collection('community_posts')
            .where('authorId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get(),
        _firestore
            .collection('community_comments')
            .where('authorId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get(),
        _firestore
            .collection('community_qa')
            .where('authorId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get(),
      ]);

      return {
        'posts': futures[0].docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {...data, 'id': doc.id};
        }).toList(),
        'comments': futures[1].docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {...data, 'id': doc.id};
        }).toList(),
        'qa': futures[2].docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {...data, 'id': doc.id};
        }).toList(),
      };
    } catch (e) {
      print('Error getting user content: $e');
      return {'posts': [], 'comments': [], 'qa': []};
    }
  }

  /// Get collection name from content type
  String? _getCollectionName(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'post':
        return 'community_posts';
      case 'comment':
        return 'community_comments';
      case 'qa':
      case 'question':
        return 'community_qa';
      case 'answer':
        return 'community_qa_answers';
      default:
        return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _postsSubscription?.cancel();
    _commentsSubscription?.cancel();
    _qaSubscription?.cancel();
    _isInitialized = false;
  }
}
