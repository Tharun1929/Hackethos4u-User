import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/course/course_data.dart';
import '../course/detail_course_screen.dart';
import '../../widgets/sliding_ads_widget.dart';
import '../homescreen/main_page.dart';
import '../../services/expert_service.dart';
import '../../utils/app_themes.dart';
import '../../providers/user_provider.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoading = true;
  Timer? _debounceTimer;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Enhanced data with online images
  List<Map<String, dynamic>> _popularCourses = [];
  List<Map<String, dynamic>> _experts = [];
  Map<String, dynamic> _communityStats = {};

  final ExpertService _expertService = ExpertService();

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Live Mentorship',
      'description': 'Get personalized guidance from industry experts',
      'icon': Icons.people_alt_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'Career Support',
      'description': 'Resume building, interview prep, job placement',
      'icon': Icons.work_rounded,
      'color': Colors.green,
    },
    {
      'title': 'Real-World Projects',
      'description': 'Build portfolio with hands-on projects',
      'icon': Icons.code_rounded,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
    
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load real data only; do not auto-populate sample content in production
      
      final all = await CourseData.getPopularCourses();
      final experts = await _expertService.getExperts(limit: 10);
      final communityStats = await _loadCommunityStats();
      if (!mounted) return;
      setState(() {
        _popularCourses = all;
        _experts = experts;
        _communityStats = communityStats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _loadCommunityStats() async {
    try {
      // Try to get real community stats from Firestore
      final communityDoc = await FirebaseFirestore.instance
          .collection('community')
          .doc('stats')
          .get();

      if (communityDoc.exists) {
        return communityDoc.data() ?? {};
      }

      // Fallback: return sample stats
      return {
        'totalMembers': 12500,
        'activeMembers': 8500,
        'postsToday': 45,
        'discussions': 1200,
        'experts': 25,
      };
    } catch (e) {
      // Return sample stats on error
      return {
        'totalMembers': 12500,
        'activeMembers': 8500,
        'postsToday': 45,
        'discussions': 1200,
        'experts': 25,
      };
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text;
        _isSearching = _searchQuery.isNotEmpty;
      });
      
      // If search query is not empty, navigate to explore with search
      if (_searchQuery.isNotEmpty) {
        _navigateToExploreWithSearch();
      }
    });
  }

  void _navigateToExploreWithSearch() {
    // Navigate to explore screen with search query
    Navigator.pushNamed(context, '/explore', arguments: {'searchQuery': _searchQuery});
  }

  void _navigateToExplore() {
    Navigator.pushNamed(context, '/explore');
  }

  void _navigateToCommunity() {
    Navigator.pushNamed(context, '/community');
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _navigateToCart() {
    Navigator.pushNamed(context, '/cart');
  }

  void _askExpert(String expertName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting you with $expertName...')),
    );
  }

  void _joinCommunity() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MainPage(index: 3),
      )
    );
  }


  void _viewAllCourses() {
    _navigateToExplore();
  }

  String _getUserName() {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;
      if (user != null && !user.isGuest) {
        final firstName = user.firstname ?? '';
        final lastName = user.lastname ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) {
          return fullName;
        }
        if (firstName.isNotEmpty) {
          return firstName;
        }
        if (lastName.isNotEmpty) {
          return lastName;
        }
        // If no name is set, try to get from Firebase Auth
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser?.displayName != null) {
          return firebaseUser!.displayName!;
        }
        if (firebaseUser?.email != null) {
          return firebaseUser!.email!.split('@').first;
        }
      }
      return 'Guest User';
    } catch (e) {
      return 'Guest User';
    }
  }

  void _viewAllExperts() {
    // Navigate to community screen with experts tab
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MainPage(index: 3), // Community tab
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading ? _buildShimmerLoading() : _buildMainContent(theme),
    );
  }

  Widget _buildShimmerLoading() {
    return SafeArea(
        child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
          slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            pinned: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _buildShimmerContainer(120, 24),
                      const Spacer(),
                      _buildShimmerContainer(40, 40, isCircle: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const SizedBox(height: 16),
                  _buildShimmerContainer(200, 24),
                  const SizedBox(height: 8),
                  _buildShimmerContainer(150, 16),
                    const SizedBox(height: 20),
                  _buildShimmerContainer(double.infinity, 56),
                  const SizedBox(height: 24),
                  _buildShimmerContainer(120, 20),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildShimmerCard(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
    );
  }

  Widget _buildShimmerContainer(double width, double height, {bool isCircle = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: isCircle ? null : BorderRadius.circular(8),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      )
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 220, // Fixed height to prevent overflow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(200, 14),
                const SizedBox(height: 4),
                _buildShimmerContainer(150, 12),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildShimmerContainer(60, 10),
                    const SizedBox(width: 12),
                    _buildShimmerContainer(40, 10),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerContainer(80, 16),
                    _buildShimmerContainer(60, 22),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Clean AppBar (prevent overflow by using title/actions and fixed height)
          SliverAppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0,
            floating: true,
            pinned: true,
            toolbarHeight: 64,
            titleSpacing: 20,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/hackethos4u_logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Hackethos4u',
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _navigateToCart,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _navigateToProfile,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Greeting Section
                  _buildGreetingSection(),
                  
                  const SizedBox(height: 20),
                  
                  // Real Ads Carousel (auto sliding, dots, network images)
                  SlidingAdsWidget(
                    height: 180,
                    autoSlideDuration: const Duration(seconds: 5),
                    showDots: true,
                    autoSlide: true,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Search Bar
                  _buildSearchBar(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Popular Courses Section
                  _buildPopularCoursesSection(theme),
                  
                  const SizedBox(height: 24), // Reduced spacing
                  
                  
                  // Join Community Section
                  _buildJoinCommunitySection(theme),
                  
                  const SizedBox(height: 24), // Reduced spacing
                  
                  // Why Choose Us Section
                  _buildWhyChooseUsSection(theme),
                  
                  const SizedBox(height: 100), // Added bottom padding for bottom navigation
                ],
                  ),
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildGreetingSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${_getUserName()} 👋',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to learn something new today?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for courses, instructors...',
              hintStyle: theme.inputDecorationTheme.hintStyle,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: theme.textTheme.bodySmall?.color,
                size: 24,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularCoursesSection(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: AppThemes.badgeIntermediate,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
        Text(
                    'Popular Today',
          style: theme.textTheme.headlineMedium,
        ),
                ],
              ),
              GestureDetector(
                onTap: _viewAllCourses,
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_popularCourses.isEmpty)
            _buildComingSoonMessage(theme)
          else
            SizedBox(
              height: 220, // Increased height to prevent overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _popularCourses.length,
                itemBuilder: (context, index) {
                  final course = _popularCourses[index];
                  return Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 16),
                    child: _buildModernCourseCard(course, theme),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernCourseCard(Map<String, dynamic> course, ThemeData theme) {
    final String title = (course['title'] ?? course['courseName'] ?? 'Course').toString();
    final dynamic instructorRaw = course['instructor'];
    final String instructorName = instructorRaw is Map
        ? (instructorRaw['name']?.toString() ?? '')
        : (instructorRaw?.toString() ?? '');
    final num ratingNum = (course['rating'] ?? course['totalRating'] ?? 0) as num;
    final String durationText = (course['duration'] ?? course['totalTime'] ?? '').toString();
    final dynamic priceRaw = course['price'];
    final String priceText = priceRaw is num ? priceRaw.toStringAsFixed(0) : (priceRaw?.toString() ?? '0');
    final String? imageAny = (course['image'] ?? course['thumbnail'] ?? course['courseImage'])?.toString();
    return Container(
      constraints: const BoxConstraints(maxHeight: 230),
      child: GestureDetector(
        onTap: () {
          final id = course['id'];
        if (id != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailCourseScreen(courseId: id),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail with online image - Fixed height
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 105, // Fixed height to prevent overflow
                width: double.infinity,
                child: Image.network(
                  (imageAny is String && imageAny.isNotEmpty) ? imageAny : 'assets/default_pp.png',
                  height: 105,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 105,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.school_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Course Info - Flexible height container to prevent overflow
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      instructorName,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ratingNum.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            durationText,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: theme.textTheme.bodySmall?.color),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(), // Push price and button to bottom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '₹$priceText',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Enroll',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildComingSoonMessage(ThemeData theme) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amazing courses are being prepared\nfor you!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildExpertLoadingShimmer(ThemeData theme) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 220,
          margin: const EdgeInsets.only(right: 16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              width: 100,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 10,
                              width: 80,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 24,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpertCard(Map<String, dynamic> expert, ThemeData theme) {
    return GestureDetector(
      onTap: () => _askExpert((expert['name'] ?? '').toString()),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: expert['image'] != null && expert['image'].toString().isNotEmpty
                        ? NetworkImage(expert['image'])
                        : null,
                    onBackgroundImageError: (exception, stackTrace) {
                      // Fallback handled by child widget
                    },
                    child: expert['image'] == null || expert['image'].toString().isEmpty
                        ? Icon(
                            Icons.person,
                            color: theme.colorScheme.primary,
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (expert['name'] ?? 'Expert').toString(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expert['role'] ?? 'Expert',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              expert['rating']?.toString() ?? '4.5',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${expert['students'] ?? 1000} students)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ask Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinCommunitySection(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: _joinCommunity,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join Our Learning Community',
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connect with ${_communityStats['totalMembers'] ?? 12500}+ learners worldwide',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCommunityStat(
                          Icons.people,
                          '${_communityStats['activeMembers'] ?? 8500}',
                          'Active',
                          theme,
                        ),
                        const SizedBox(width: 12),
                        _buildCommunityStat(
                          Icons.chat_bubble,
                          '${_communityStats['postsToday'] ?? 45}',
                          'Posts Today',
                          theme,
                        ),
                        const SizedBox(width: 12),
                        _buildCommunityStat(
                          Icons.forum,
                          '${_communityStats['discussions'] ?? 1200}',
                          'Discussions',
                          theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Join Now',
                        style: TextStyle(
                          color: Colors.white,
              fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Community avatars
              Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 16,
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

  Widget _buildCommunityStat(IconData icon, String value, String label, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyChooseUsSection(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose Us',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 12), // Reduced spacing
          ...List.generate(_features.length, (index) {
            final feature = _features[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8), // Reduced margin
              child: _buildFeatureCard(feature, theme),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10), // Reduced padding
            decoration: BoxDecoration(
              color: feature['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature['icon'],
              color: feature['color'],
              size: 20, // Reduced icon size
            ),
          ),
          const SizedBox(width: 12), // Reduced spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'],
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2), // Reduced spacing
                Text(
                  feature['description'],
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
