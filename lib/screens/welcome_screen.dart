import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _currentPage = 0;
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.auto_stories_rounded,
      title: 'Welcome to Hackethos4u',
      subtitle: 'Your Gateway to Professional Learning',
      content:
          'Access world-class courses from industry experts and transform your career with hands-on projects and real-world applications.',
      gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      illustration: '🎓',
    ),
    OnboardingPage(
      icon: Icons.trending_up_rounded,
      title: 'Track Your Progress',
      subtitle: 'Monitor Your Learning Journey',
      content:
          'Get detailed insights into your learning progress. Earn certificates and build a professional portfolio that showcases your achievements.',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      illustration: '📊',
    ),
    OnboardingPage(
      icon: Icons.forum_rounded,
      title: 'Join Our Community',
      subtitle: 'Connect with Fellow Learners',
      content:
          'Connect with learners worldwide. Participate in discussions, join study groups, and network with professionals in your field.',
      gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      illustration: '🌐',
    ),
    OnboardingPage(
      icon: Icons.verified_rounded,
      title: 'Get Certified',
      subtitle: 'Earn Industry-Recognized Certificates',
      content:
          'Earn professional certificates upon completion. Boost your career prospects and credibility with industry-recognized certifications.',
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      illustration: '🏆',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    // Save onboarding completion status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingCompleted', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFF), // Very light blue-white
              Color(0xFFE8F2FF), // Light blue tint
              Color(0xFFD1E7FF), // Slightly more blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Illustration Container
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF4F46E5),
                                        Color(0xFF6366F1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4F46E5)
                                            .withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      page.illustration,
                                      style: const TextStyle(fontSize: 80),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 50),

                                // Title
                                Text(
                                  page.title,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 10),

                                // Subtitle
                                Text(
                                  page.subtitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF4F46E5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 20),

                                // Content
                                Text(
                                  page.content,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF64748B),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Page indicators and buttons
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 30 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Next/Get Started button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4F46E5),
                            Color(0xFF6366F1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _completeOnboarding();
                            }
                          },
                          child: Center(
                            child: Text(
                              _currentPage < _pages.length - 1
                                  ? 'Next'
                                  : 'Get Started',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String content;
  final List<Color> gradient;
  final String illustration;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.gradient,
    required this.illustration,
  });
}
