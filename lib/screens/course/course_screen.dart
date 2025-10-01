import 'package:flutter/material.dart';
import '../../model/course/course_data.dart';
import 'detail_course_screen.dart';
import 'dart:async';
import '../../utils/app_themes.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoading = true;
  Timer? _debounceTimer;

  // Add state for courses
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Filter options
  final List<String> _filterOptions = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced'
  ];
  final List<String> _priceFilters = [
    'All',
    'Free',
    'Paid',
    'Under ₹1000',
    'Under ₹2000'
  ];

  // Dynamic filter tabs based on real data
  List<Map<String, dynamic>> _topTabs = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
  ];

  // Sort options
  final List<String> _sortOptions = ['Newest', 'Popular', 'Free', 'Paid'];

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
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();

    _loadCourses();
    
    // Check for search arguments from home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['searchQuery'] != null) {
        _searchController.text = args['searchQuery'];
        _onSearchChanged();
      }
    });
  }

  Future<void> _loadCourses() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load courses from Firestore
      final courses = await CourseData.getAllCourses();

      if (mounted) {
        // Generate dynamic categories from real course data
        final categories = _generateCategoriesFromCourses(courses);
        
        setState(() {
          _allCourses = courses;
          _filteredCourses = courses;
          _topTabs = [
            {'name': 'All', 'icon': Icons.grid_view_rounded},
            ...categories,
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      // print('Error loading courses: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  List<Map<String, dynamic>> _generateCategoriesFromCourses(List<Map<String, dynamic>> courses) {
    final Set<String> uniqueCategories = {};
    
    for (final course in courses) {
      final category = course['category']?.toString() ?? '';
      if (category.isNotEmpty) {
        uniqueCategories.add(category);
      }
    }
    
    // Map categories to icons
    final Map<String, IconData> categoryIcons = {
      'Programming': Icons.code_rounded,
      'Web Development': Icons.web_rounded,
      'Mobile Development': Icons.phone_android_rounded,
      'Data Science': Icons.analytics_rounded,
      'Machine Learning': Icons.psychology_rounded,
      'Cybersecurity': Icons.security_rounded,
      'Design': Icons.design_services_rounded,
      'Marketing': Icons.campaign_rounded,
      'Business': Icons.business_rounded,
      'Finance': Icons.account_balance_rounded,
      'Health & Fitness': Icons.fitness_center_rounded,
      'Music': Icons.music_note_rounded,
      'Photography': Icons.camera_alt_rounded,
      'Language Learning': Icons.language_rounded,
    };
    
    return uniqueCategories.map((category) => {
      'name': category,
      'icon': categoryIcons[category] ?? Icons.category_rounded,
    }).toList();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final query = _searchController.text;
      setState(() {
        _searchQuery = query;
        _isSearching = query.isNotEmpty;
      });

      if (query.isNotEmpty) {
        await _performSearch(query);
      } else {
        _applyFilters();
      }
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final searchResults = await CourseData.searchCourses(query);
      setState(() {
        _filteredCourses = searchResults;
      });
    } catch (e) {
      // print('Error searching courses: $e');
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _allCourses;

    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((course) => course['category'] == _selectedCategory)
          .toList();
    }

    setState(() {
      _filteredCourses = filtered;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  void _viewCourse(dynamic courseId) {
    // Handle null courseId safely
    if (courseId == null) {
      // print('Error: courseId is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Course ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Handle both string and integer course IDs
    dynamic finalCourseId;
    if (courseId is String) {
      // For string IDs, try to parse as int first, otherwise use as string
      final intId = int.tryParse(courseId);
      finalCourseId = intId ?? courseId;
    } else if (courseId is int) {
      finalCourseId = courseId;
    } else {
      // For other types, convert to string and try to parse as int
      final intId = int.tryParse(courseId.toString());
      finalCourseId = intId ?? courseId.toString();
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailCourseScreen(courseId: finalCourseId),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushNamed(context, '/home');
  }

  void _navigateToCommunity() {
    Navigator.pushNamed(context, '/community');
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection('Level', _filterOptions),
                  const SizedBox(height: 20),
                  _buildFilterSection('Price', _priceFilters),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return FilterChip(
              label: Text(option),
              selected: false, // You can implement selection logic here
              onSelected: (selected) {
                // Handle filter selection
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Filter Applied — $title: $option'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context);
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.blue.withOpacity(0.1),
              checkmarkColor: Colors.blue,
              labelStyle: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Remove the getter since we now use _filteredCourses state variable

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading ? _buildShimmerLoading(theme) : _buildMainContent(theme),
    );
  }

  Widget _buildShimmerLoading(ThemeData theme) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Shimmer AppBar
          SliverAppBar(
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            floating: true,
            pinned: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _buildShimmerContainer(24, 24),
                      Expanded(
                        child: _buildShimmerContainer(120, 20),
                      ),
                      _buildShimmerContainer(24, 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Shimmer Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildShimmerContainer(double.infinity, 56),
                  const SizedBox(height: 24),
                  _buildShimmerContainer(100, 20),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) => Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        child: _buildShimmerContainer(80, 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildShimmerContainer(150, 20),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) => _buildShimmerCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
          // Clean AppBar
          SliverAppBar(
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            floating: true,
            pinned: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                      ),
                      // Title
                      Expanded(
                        child: Text(
                          'Explore Courses',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Removed filter button to avoid duplicate filter options
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content - Reduced density
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Search Bar
                  _buildSearchBar(theme),
                  const SizedBox(height: 24),

                  // Top Filter Tabs
                  _buildTopFilterTabs(theme),
                  const SizedBox(height: 24),

                  // Sectioned Courses
                  _buildSectionedCourses(theme),
                  const SizedBox(
                      height:
                          100), // Added bottom padding for bottom navigation
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
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
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for courses, topics...',
            hintStyle: theme.inputDecorationTheme.hintStyle,
            prefixIcon: Icon(Icons.search_rounded,
                color: theme.textTheme.bodySmall?.color, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _isSearching = false;
                      });
                    },
                    icon: Icon(Icons.clear_rounded,
                        color: theme.textTheme.bodySmall?.color, size: 20),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.cardColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTopFilterTabs(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              // Sort Button
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.sort_rounded,
                  color: theme.textTheme.bodyMedium?.color,
                  size: 20,
                ),
                onSelected: (value) {
                  // Handle sort selection
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sort Applied — $value'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                itemBuilder: (context) => _sortOptions.map((option) {
                  return PopupMenuItem<String>(
                    value: option,
                    child: Row(
                      children: [
                        Icon(
                          option == 'Newest'
                              ? Icons.new_releases_rounded
                              : option == 'Popular'
                                  ? Icons.trending_up_rounded
                                  : option == 'Free'
                                      ? Icons.free_breakfast_rounded
                                      : Icons.payment_rounded,
                          size: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 8),
                        Text(option),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _topTabs.length,
              itemBuilder: (context, index) {
                final tab = _topTabs[index];
                final isSelected = tab['name'] == _selectedCategory;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _onCategorySelected(tab['name']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (tab['name'] == 'AI'
                                ? AppThemes.chipTintAI
                                : tab['name'] == 'Python'
                                    ? AppThemes.chipTintPython
                                    : AppThemes.chipTintDefault),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab['icon'],
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : theme.textTheme.bodyMedium?.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tab['name'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionedCourses(ThemeData theme) {
    final filteredCourses = _filteredCourses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isSearching) ...[
          Text(
            'Search Results (${filteredCourses.length})',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 24),
        if (filteredCourses.isEmpty)
          _buildNoResultsFound(theme)
        else
          _buildSectionedListView(filteredCourses, theme),
      ],
    );
  }

  Widget _buildNoResultsFound(ThemeData theme) {
    // Check if this is a search result or no courses at all
    final isSearching = _isSearching;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.school_outlined,
            size: 80,
            color: isSearching
                ? Colors.grey[400]
                : theme.colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching ? 'No courses found' : 'No courses uploaded yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isSearching ? Colors.grey[600] : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'Try adjusting your search terms'
                : 'We are working hard to bring you amazing courses!\nStay tuned for updates.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isSearching) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionedListView(
      List<Map<String, dynamic>> courses, ThemeData theme) {
    // Simplified sections - reduced content density
    final topPicks = courses.take(4).toList();
    final recentlyAdded = courses.skip(4).take(4).toList();

    return Column(
      children: [
        // Top Picks Section
        if (topPicks.isNotEmpty) ...[
          _buildSectionHeader('⭐ Top Picks', theme),
          const SizedBox(height: 16),
          _buildCourseGrid(topPicks, theme),
          const SizedBox(height: 32),
        ],
        // Recently Added Section
        if (recentlyAdded.isNotEmpty) ...[
          _buildSectionHeader('🆕 Recently Added', theme),
          const SizedBox(height: 16),
          _buildCourseGrid(recentlyAdded, theme),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        GestureDetector(
          onTap: () {
            // Navigate to see all courses in this section
            Navigator.pushNamed(context, '/explore');
          },
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
    );
  }

  Widget _buildCourseGrid(List<Map<String, dynamic>> courses, ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85, // Adjusted aspect ratio to prevent overflow
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildModernCourseCard(course, theme);
      },
    );
  }

  Widget _buildModernCourseCard(Map<String, dynamic> course, ThemeData theme) {
    return GestureDetector(
      onTap: () => _viewCourse(course['id']),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Course Thumbnail - Fixed height
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 100, // Fixed height to prevent overflow
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.school_rounded,
                        size: 32,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    // Rating Badge
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              course['rating'].toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 9, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Level Badge
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getLevelColor(course['level']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course['level'],
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Course Info - Flexible container to prevent overflow
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      course['title'],
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (() {
                        final instructor = course['instructor'];
                        if (instructor is Map) {
                          return (instructor['name'] ?? '').toString();
                        }
                        return (instructor ?? '').toString();
                      })(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontSize: 10, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 8,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (() {
                            final d = course['duration']?.toString() ?? '';
                            // Avoid adding an extra 'h' when value already contains units
                            if (d.contains('hour') || d.contains('hr')) {
                              return d;
                            }
                            return '${d}h';
                          })(),
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 8, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.people_rounded,
                          size: 8,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${course['students']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 8, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Spacer(), // Push price and button to bottom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${course['price']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _viewCourse(course['id']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Learn More',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
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
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
