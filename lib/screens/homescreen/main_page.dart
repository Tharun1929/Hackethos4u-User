import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../course/course_screen.dart';
import '../progress_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';

class MainPage extends StatefulWidget {
  final int? id;
  final int? index;
  const MainPage({super.key, this.id, this.index});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int currentIndex = 2; // Default to Home (center)
  late AnimationController _animationController;
  late Animation<double> _animation;

  final screens = [
    const CourseScreen(), // Explore
    const ProgressScreen(), // Progress
    const HomeScreen(), // Home (center)
    const CommunityScreen(), // Community
    const ProfileScreen(), // Profile
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    currentIndex = widget.index ?? 2; // Default to Home (index 2)
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (mounted) {
      setState(() {
        currentIndex = index;
      });
      _animationController.forward().then((_) {
        if (mounted) {
          _animationController.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ??
              theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.explore_rounded, 'Explore', theme),
                _buildNavItem(1, Icons.trending_up_rounded, 'Progress', theme),
                _buildHomeButton(theme),
                _buildNavItem(3, Icons.forum_rounded, 'Community', theme),
                _buildNavItem(4, Icons.person_rounded, 'Profile', theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(ThemeData theme) {
    final isSelected = currentIndex == 2;
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.home_rounded,
          size: 28,
          color: isSelected
              ? Colors.white
              : theme.bottomNavigationBarTheme.unselectedItemColor,
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, String label, ThemeData theme) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.bottomNavigationBarTheme.unselectedItemColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.bottomNavigationBarTheme.unselectedItemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
