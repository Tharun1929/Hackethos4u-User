import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _postController = TextEditingController();

  // Services
  final CommunityService _communityService = CommunityService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Live data containers
  bool _isLoading = true;
  Map<String, dynamic> _communityData = {
    'user': {
      'name': 'Loading...',
      'avatar': 'assets/default_pp.png',
      'level': 'Beginner',
      'points': 0,
      'badges': [],
    },
    'stats': {
      'totalMembers': 0,
      'activeMembers': 0,
      'totalDiscussions': 0,
      'totalEvents': 0,
    },
    'discussions': [],
    'events': [],
    'topics': [],
    'recentActivity': [],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
    _loadCommunityFromApi();
  }

  Future<void> _loadCommunityFromApi() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load real community data with error handling
      final stats = await _communityService.getCommunityStats().catchError((e) {
        print('Error loading stats: $e');
        return <String, dynamic>{
          'totalMembers': 0,
          'activeMembers': 0,
          'totalDiscussions': 0,
          'totalEvents': 0,
        };
      });

      final discussions =
          await _communityService.getDiscussions(limit: 20).catchError((e) {
        print('Error loading discussions: $e');
        return <Map<String, dynamic>>[];
      });

      final topics = await _communityService.getPopularTopics().catchError((e) {
        print('Error loading topics: $e');
        return <Map<String, dynamic>>[];
      });

      // Get current user data
      final user = _auth.currentUser;
      final userData = user != null
          ? {
              'name': user.displayName ?? 'Anonymous User',
              'avatar': user.photoURL ?? 'assets/default_pp.png',
              'level': 'Beginner', // This should come from user profile
              'points': 0,
              'badges': [],
            }
          : null;

      setState(() {
        _communityData = {
          'user': userData ??
              {
                'name': 'Anonymous User',
                'avatar': 'assets/default_pp.png',
                'level': 'Beginner',
                'points': 0,
                'badges': [],
              },
          'stats': stats ?? {},
          'discussions': (discussions)
              .map((d) => {
                    'id': d['id'] ?? '',
                    'title': d['title'] ?? 'Discussion',
                    'content': d['content'] ?? '',
                    'author': {
                      'name': d['authorName'] ?? 'Anonymous',
                      'avatar': d['authorAvatar'] ?? '',
                      'level': d['authorLevel'] ?? 'Beginner',
                      'verified': false,
                    },
                    'time': _formatTime(d['createdAt']),
                    'replies': d['replies'] ?? 0,
                    'likes': d['likes'] ?? 0,
                    'views': d['views'] ?? 0,
                    'tags': List<String>.from(
                        (d['tags'] is List ? d['tags'] : <dynamic>[])),
                    'isLiked': false,
                    'isBookmarked': false,
                    'category': d['category'] ?? 'General',
                  })
              .toList(),
          'topics': (topics)
              .map((t) => {
                    'name': t['name'] ?? 'Topic',
                    'discussionCount': t['discussionCount'] ?? 0,
                    'color': _getTopicColor(t['name'] ?? ''),
                  })
              .toList(),
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading community data: $e');
      // Set fallback data on error
      setState(() {
        _communityData = {
          'user': {
            'name': 'Guest User',
            'avatar': 'assets/default_pp.png',
            'level': 'Guest',
            'points': 0,
            'badges': [],
          },
          'stats': <String, dynamic>{
            'totalMembers': 0,
            'activeMembers': 0,
            'totalDiscussions': 0,
            'totalEvents': 0,
          },
          'discussions': [],
          'topics': [],
        };
        _isLoading = false;
      });
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else {
        return 'Just now';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  Color _getTopicColor(String topicName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[topicName.hashCode % colors.length];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadCommunityFromApi,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCommunityFromApi,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTabIndex,
                      children: [
                        _buildDiscussionsTab(),
                        _buildEventsTab(),
                        _buildTopicsTab(),
                        _buildActivityTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.people,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect with fellow learners',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showCommunityInfo,
                  icon: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCommunityStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityStats() {
    final theme = Theme.of(context);
    final stats = _communityData['stats'] as Map<String, dynamic>? ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '${stats['totalMembers'] ?? 0}',
            'Members',
            Icons.people,
            theme.colorScheme.onPrimary,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            '${stats['activeMembers'] ?? 0}',
            'Active',
            Icons.online_prediction,
            theme.colorScheme.onPrimary,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            '${stats['totalDiscussions'] ?? 0}',
            'Discussions',
            Icons.forum,
            theme.colorScheme.onPrimary,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            '${stats['totalEvents'] ?? 0}',
            'Events',
            Icons.event,
            theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final tabs = ['Discussions', 'Events', 'Topics', 'Activity'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedTabIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDiscussionsTab() {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            ...((_communityData['discussions'] as List<dynamic>?) ??
                    <dynamic>[])
                .map((discussion) =>
                    _buildDiscussionCard(discussion as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search discussions...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
              ),
              onChanged: _handleSearch,
            ),
          ),
          IconButton(
            onPressed: _showFilterOptions,
            icon: Icon(
              Icons.tune,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionCard(Map<String, dynamic> discussion) {
    final theme = Theme.of(context);
    final author = discussion['author'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              CircleAvatar(
                radius: 20,
                backgroundImage: author['avatar'] != null &&
                        author['avatar'].toString().isNotEmpty
                    ? (author['avatar'].toString().startsWith('http')
                        ? NetworkImage(author['avatar'].toString())
                            as ImageProvider<Object>
                        : AssetImage(author['avatar'].toString())
                            as ImageProvider<Object>)
                    : null,
                child: author['avatar'] == null ||
                        author['avatar'].toString().isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          author['name']?.toString() ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (author['verified'] == true)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              color: theme.colorScheme.primary,
                              size: 16,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getLevelColor(
                                    author['level']?.toString() ?? 'Beginner')
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            author['level']?.toString() ?? 'Beginner',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getLevelColor(
                                  author['level']?.toString() ?? 'Beginner'),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      discussion['time']?.toString() ?? 'Just now',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_border, size: 16),
                        const SizedBox(width: 8),
                        Text('Bookmark'),
                      ],
                    ),
                    onTap: () => _toggleBookmark(discussion),
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 16),
                        const SizedBox(width: 8),
                        Text('Share'),
                      ],
                    ),
                    onTap: () => _shareDiscussion(discussion),
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.flag, size: 16),
                        const SizedBox(width: 8),
                        Text('Report'),
                      ],
                    ),
                    onTap: () => _reportDiscussion(discussion),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            discussion['title']?.toString() ?? 'Discussion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            discussion['content']?.toString() ?? 'No content',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ((discussion['tags'] as List<dynamic>?) ?? <dynamic>[])
                .map<Widget>((tag) => _buildTag(tag.toString()))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(
                icon: (discussion['isLiked'] == true)
                    ? Icons.favorite
                    : Icons.favorite_border,
                label: '${discussion['likes'] ?? 0}',
                color: (discussion['isLiked'] == true) ? Colors.red : null,
                onTap: () => _toggleLike(discussion),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${discussion['replies'] ?? 0}',
                onTap: () => _openDiscussion(discussion),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.visibility_outlined,
                label: '${discussion['views'] ?? 0}',
                onTap: () {},
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                          discussion['category']?.toString() ?? 'General')
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  discussion['category']?.toString() ?? 'General',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getCategoryColor(
                        discussion['category']?.toString() ?? 'General'),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: _viewAllEvents,
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...((_communityData['events'] as List<dynamic>?) ?? <dynamic>[])
                .map((event) => _buildEventCard(event as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final theme = Theme.of(context);
    final isRegistered = event['isRegistered'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: event['image'] != null &&
                          event['image'].toString().isNotEmpty
                      ? Image.asset(
                          event['image'].toString(),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.event,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.event,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title']?.toString() ?? 'Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event['description']?.toString() ?? 'No description',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${event['date']?.toString() ?? 'TBD'} • ${event['time']?.toString() ?? 'TBD'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getEventTypeColor(event['type']?.toString() ?? 'Event')
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event['type']?.toString() ?? 'Event',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getEventTypeColor(
                        event['type']?.toString() ?? 'Event'),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${event['attendees'] ?? 0}/${event['maxAttendees'] ?? 0} attendees',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _toggleEventRegistration(event),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isRegistered ? Colors.grey : theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isRegistered ? 'Registered' : 'Register',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsTab() {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Popular Topics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount:
                  ((_communityData['topics'] as List<dynamic>?) ?? <dynamic>[])
                      .length,
              itemBuilder: (context, index) {
                final topics =
                    (_communityData['topics'] as List<dynamic>?) ?? <dynamic>[];
                final topic = topics[index] as Map<String, dynamic>;
                return _buildTopicCard(topic);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _openTopic(topic),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (topic['color'] as Color? ?? Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (topic['color'] as Color? ?? Colors.grey).withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getTopicIcon(topic['name']?.toString() ?? 'Topic'),
              color: topic['color'] as Color? ?? Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              topic['name']?.toString() ?? 'Topic',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${topic['count'] ?? topic['discussionCount'] ?? 0} discussions',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...((_communityData['recentActivity'] as List<dynamic>?) ??
                    <dynamic>[])
                .map((activity) =>
                    _buildActivityItem(activity as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final theme = Theme.of(context);
    IconData icon;
    Color iconColor;

    switch (activity['type']?.toString()) {
      case 'discussion_created':
        icon = Icons.forum;
        iconColor = AppTheme.primaryColor;
        break;
      case 'event_registered':
        icon = Icons.event;
        iconColor = AppTheme.successColor;
        break;
      case 'reply_posted':
        icon = Icons.reply;
        iconColor = AppTheme.warningColor;
        break;
      default:
        icon = Icons.info;
        iconColor = AppTheme.textHintColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: activity['user']?.toString() ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                          text:
                              ' ${activity['action']?.toString() ?? 'performed'} '),
                      TextSpan(
                        text: activity['title']?.toString() ?? 'activity',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Text(
                  activity['time']?.toString() ?? 'Just now',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getLevelColor(String level) {
    switch (level) {
      case 'Expert':
        return AppTheme.errorColor;
      case 'Advanced':
        return AppTheme.warningColor;
      case 'Intermediate':
        return AppTheme.primaryColor;
      case 'Beginner':
        return AppTheme.successColor;
      default:
        return AppTheme.textHintColor;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Cybersecurity':
        return AppTheme.errorColor;
      case 'Career':
        return AppTheme.primaryColor;
      case 'Networking':
        return AppTheme.successColor;
      case 'Cloud Security':
        return AppTheme.primaryColor.withOpacity(0.8);
      default:
        return AppTheme.textHintColor;
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'Workshop':
        return AppTheme.primaryColor;
      case 'Q&A':
        return AppTheme.successColor;
      case 'Panel':
        return AppTheme.warningColor;
      default:
        return AppTheme.textHintColor;
    }
  }

  IconData _getTopicIcon(String topic) {
    switch (topic) {
      case 'Cybersecurity':
        return Icons.security;
      case 'Ethical Hacking':
        return Icons.bug_report;
      case 'Network Security':
        return Icons.network_check;
      case 'Cloud Security':
        return Icons.cloud;
      case 'Career Advice':
        return Icons.work;
      case 'Tools & Techniques':
        return Icons.build;
      default:
        return Icons.topic;
    }
  }

  // Action methods
  void _showCommunityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Community Guidelines'),
        content: const Text(
            'Be respectful, helpful, and constructive in your interactions. Share knowledge and support fellow learners.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleSearch(String query) {
    // Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for: $query'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: const Text('Filter by category, date, popularity, etc.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleLike(Map<String, dynamic> discussion) {
    final like = discussion['isLiked'] != true;
    setState(() {
      discussion['isLiked'] = like;
      discussion['likes'] = (discussion['likes'] ?? 0) + (like ? 1 : -1);
    });
    final String postId = (discussion['id'] ?? '').toString();
    if (postId.isEmpty) return;
    _communityService.toggleLike(
      collection: 'community_posts',
      docId: postId,
      like: like,
    );
  }

  void _toggleBookmark(Map<String, dynamic> discussion) {
    setState(() {
      discussion['isBookmarked'] = !discussion['isBookmarked'];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(discussion['isBookmarked']
            ? 'Bookmarked'
            : 'Removed from bookmarks'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _shareDiscussion(Map<String, dynamic> discussion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Sharing: ${discussion['title']?.toString() ?? 'Discussion'}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _reportDiscussion(Map<String, dynamic> discussion) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Discussion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tell us why you are reporting this discussion.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (spam, abuse, off-topic, etc.)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim().isEmpty
                  ? 'unspecified'
                  : reasonController.text.trim();
              Navigator.pop(context);
              final ok = await _communityService.reportContent(
                contentId: (discussion['id'] ?? '').toString(),
                contentType: 'post',
                reason: reason,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Report submitted. Our team will review it.'
                      : 'Failed to submit report'),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _openDiscussion(Map<String, dynamic> discussion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Opening: ${discussion['title']?.toString() ?? 'Discussion'}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _viewAllEvents() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Viewing all events'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _toggleEventRegistration(Map<String, dynamic> event) {
    setState(() {
      event['isRegistered'] = !event['isRegistered'];
      if (event['isRegistered']) {
        event['attendees']++;
      } else {
        event['attendees']--;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(event['isRegistered']
            ? 'Registered for event'
            : 'Unregistered from event'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _openTopic(Map<String, dynamic> topic) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening topic: ${topic['name']?.toString() ?? 'Topic'}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedCategory = 'General';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Create New Discussion'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter discussion title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.trim().length < 5) {
                        return 'Title must be at least 5 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      hintText: 'What would you like to discuss?',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter content';
                      }
                      if (value.trim().length < 10) {
                        return 'Content must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma separated)',
                      hintText: 'e.g., Security, Hacking, Network',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'General',
                      'Security',
                      'Programming',
                      'Networking',
                      'Tools',
                      'Career'
                    ]
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value ?? 'General';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please fill in title and content'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                final discussionId = await _communityService.createDiscussion(
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  tags: tagsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  category: selectedCategory,
                );

                Navigator.pop(context); // Close loading dialog

                if (discussionId != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Discussion created successfully!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                  // Refresh the data
                  _loadCommunityFromApi();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Failed to create discussion. Please try again.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
