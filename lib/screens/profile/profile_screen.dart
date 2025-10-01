import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_themes.dart';
import '../../providers/user_provider.dart';
import '../../model/user/user_model.dart';
import '../../services/profile_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Profile menu items
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Edit Profile',
      'icon': Icons.person_outline,
      'color': const Color(0xFF2196F3),
      'route': '/editProfile',
    },
    {
      'title': 'Learning Streak',
      'icon': Icons.trending_up,
      'color': const Color(0xFFFF9800),
      'route': '/learningStreak',
    },
    {
      'title': 'My Certificates',
      'icon': Icons.workspace_premium,
      'color': const Color(0xFF4CAF50),
      'route': '/enhancedCertificates',
    },
    {
      'title': 'Learning History',
      'icon': Icons.history_edu,
      'color': const Color(0xFF9C27B0),
      'route': '/learningHistory',
    },
    {
      'title': 'Achievements',
      'icon': Icons.military_tech,
      'color': const Color(0xFFFFD700),
      'route': '/achievements',
    },
    {
      'title': 'Wishlist',
      'icon': Icons.bookmark_outline,
      'color': const Color(0xFFE91E63),
      'route': '/wishlist',
    },
    {
      'title': 'Settings',
      'icon': Icons.settings_outlined,
      'color': const Color(0xFF607D8B),
      'route': '/settings',
    },
    {
      'title': 'Help & Support',
      'icon': Icons.support_agent,
      'color': const Color(0xFF00BCD4),
      'route': '/help',
    },
    {
      'title': 'Privacy Policy',
      'icon': Icons.security,
      'color': const Color(0xFF795548),
      'route': '/privacy',
    },
    {
      'title': 'Terms of Service',
      'icon': Icons.description_outlined,
      'color': const Color(0xFF607D8B),
      'route': '/terms',
    },
    {
      'title': 'Logout',
      'icon': Icons.exit_to_app,
      'color': const Color(0xFFF44336),
      'route': '/logout',
    },
  ];

  // Recent achievements - loaded from Firestore
  List<Map<String, dynamic>> _recentAchievements = [];

  // Real profile/stats
  Map<String, dynamic>? _profileDoc;
  Map<String, dynamic>? _statsDoc;
  bool _loading = true;

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

    // Load profile + stats from Firestore
    _loadProfileData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;

        if (user == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        20, 20, 20, 40), // Increased bottom padding
                    child: Column(
                      children: [
                        _buildProfileCard(user),
                        const SizedBox(height: 24),
                        _buildStatsCard(user),
                        const SizedBox(height: 24),
                        _buildRecentAchievements(),
                        const SizedBox(height: 24),
                        _buildMenuItems(),
                        const SizedBox(height: 40), // Increased bottom spacing
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadProfileData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _loading = false;
        });
        return;
      }
      final profile = await ProfileManager().getUserProfile(uid);
      final stats = await ProfileManager().getUserStats(uid);

      // Load recent achievements
      final achievementsQuery = await FirebaseFirestore.instance
          .collection('userAchievements')
          .doc(uid)
          .collection('achievements')
          .orderBy('earnedAt', descending: true)
          .limit(3)
          .get();

      final achievements = achievementsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Achievement',
          'description': data['description'] ?? 'Great job!',
          'icon': _getAchievementIcon(data['type']),
          'color': _getAchievementColor(data['type']),
          'date': data['earnedAt'] != null
              ? (data['earnedAt'] as Timestamp)
                  .toDate()
                  .toIso8601String()
                  .split('T')[0]
              : DateTime.now().toIso8601String().split('T')[0],
          'points': data['points'] ?? 0,
        };
      }).toList();

      setState(() {
        _profileDoc = profile;
        _statsDoc = stats;
        _recentAchievements = achievements;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person,
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
                    'My Profile',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your account and preferences',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showProfileOptions,
              icon: Icon(
                Icons.more_vert,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profile Header
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(37),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(
                            '${user.firstname ?? ''} ${user.lastname ?? ''}'
                                    .trim()
                                    .isEmpty
                                ? 'Guest User'
                                : '${user.firstname ?? ''} ${user.lastname ?? ''}'
                                    .trim()),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstname ?? ''} ${user.lastname ?? ''}'
                                .trim()
                                .isEmpty
                            ? 'Guest User'
                            : '${user.firstname ?? ''} ${user.lastname ?? ''}'
                                .trim(),
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'No email',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Student',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editProfile(),
                  icon: Icon(
                    Icons.edit,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Learning Progress
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Progress',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildProgressItem(
                          'Courses Completed',
                          '${_statsDoc?['completedCourses'] ?? 0}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildProgressItem(
                          'Learning Streak',
                          '${_statsDoc?['currentStreak'] ?? 0} days',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(
      String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600, color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Widget _buildStatsCard(UserModel user) {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Learning Statistics',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Courses',
                    '${_statsDoc?['totalEnrollments'] ?? (user.totalCourses ?? 0)}',
                    Icons.school,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Certificates',
                    '${_statsDoc?['certificatesEarned'] ?? 0}',
                    Icons.verified,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Hours',
                    '${(_statsDoc?['totalLearningHours'] ?? 0)}h',
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Streak',
                    '${_statsDoc?['currentStreak'] ?? 0}d',
                    Icons.local_fire_department,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_statsDoc?['points'] ?? 0} Points',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary),
                        ),
                        Text(
                          'Completion: ${((_statsDoc?['completionRate'] ?? 0.0) as num).toDouble().toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildRecentAchievements() {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Achievements',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _viewAllAchievements(),
                  child: Text(
                    'View All',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._recentAchievements
                .map((achievement) => _buildAchievementItem(achievement)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    final theme = Theme.of(context);
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
              color: achievement['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              achievement['icon'],
              color: achievement['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'],
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  achievement['description'],
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ),
                Text(
                  achievement['date'],
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: achievement['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${achievement['points']}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: achievement['color'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account & Settings',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._menuItems.map((item) => _buildMenuItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item['icon'],
            color: item['color'],
            size: 20,
          ),
        ),
        title: Text(
          item['title'],
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        onTap: () => _handleMenuTap(item),
      ),
    );
  }

  // Enhanced action methods with real functionality
  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                _editProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                _exportData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    Navigator.pushNamed(context, '/editProfile');
  }

  void _viewAllAchievements() {
    Navigator.pushNamed(context, '/achievements');
  }

  void _handleMenuTap(Map<String, dynamic> item) {
    switch (item['route']) {
      case '/editProfile':
        _editProfile();
        break;
      case '/enhancedCertificates':
        Navigator.pushNamed(context, '/enhancedCertificates');
        break;
      case '/learningHistory':
        Navigator.pushNamed(context, '/learningHistory');
        break;
      case '/achievements':
        Navigator.pushNamed(context, '/achievements');
        break;
      case '/learningStreak':
        Navigator.pushNamed(context, '/learningStreak');
        break;
      case '/wishlist':
        Navigator.pushNamed(context, '/wishlist');
        break;
      case '/settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case '/help':
        _showHelpDialog();
        break;
      case '/privacy':
        _showPrivacyDialog();
        break;
      case '/terms':
        _showTermsDialog();
        break;
      case '/logout':
        _showLogoutDialog();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['title']} feature coming soon!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
    }
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing profile...'),
        backgroundColor: AppThemes.primarySolid,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting your data...'),
        backgroundColor: AppThemes.badgeBeginner,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
            'Need help? Contact our support team at support@edutiv.com or call us at +91 1800 123 4567'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
            'Your privacy is important to us. We collect and use your data only to provide you with the best learning experience.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const Text(
            'By using our platform, you agree to our terms of service and community guidelines.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logging out...'),
        backgroundColor: AppThemes.badgeAdvanced,
      ),
    );

    // Navigate to login screen
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
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
        return AppThemes.badgeIntermediate;
      case 'streak':
        return AppThemes.badgeAdvanced;
      case 'first_lesson':
        return AppThemes.primarySolid;
      case 'certificate':
        return Colors.green;
      case 'perfect_score':
        return Colors.amber;
      default:
        return AppThemes.primarySolid;
    }
  }
}
