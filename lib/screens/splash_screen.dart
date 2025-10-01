import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loaderController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _loaderOpacity;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Loader animation controller
    _loaderController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Logo animations
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Text animations
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    _textSlide = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // Loader animation
    _loaderOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loaderController,
      curve: Curves.easeOut,
    ));

    // Start animations in sequence
    _startAnimations();

    // Navigate after animation
    _navigateToNextScreen();
  }

  void _startAnimations() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _loaderController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    // Wait for all animations to complete
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isOnboardingCompleted =
        prefs.getBool('isOnboardingCompleted') ?? false;

    // Check Firebase Auth state
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final isLoggedIn = firebaseUser != null;

    if (!isOnboardingCompleted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    } else if (isLoggedIn) {
      // User is logged in - go to main page
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // User has completed onboarding but not logged in - go to login
      Navigator.pushReplacementNamed(context, '/login');
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
              Color(0xFF1E3A8A), // Deep blue
              Color(0xFF3B82F6), // Primary blue
              Color(0xFF1D4ED8), // Darker blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo with animation
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.asset(
                              'assets/hackethos4u_logo.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.security,
                                  size: 60,
                                  color: Color(0xFF3B82F6),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // App Name with animation
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            const Text(
                              'HACKETHOS4U',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 3.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Learn Cybersecurity & Ethical Hacking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Professional loading indicator
                AnimatedBuilder(
                  animation: _loaderController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loaderOpacity.value,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.9),
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}