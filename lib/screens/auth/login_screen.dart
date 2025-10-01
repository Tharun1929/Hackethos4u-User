import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../homescreen/main_page.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _formController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final bool _useDemoAuth = true; // Use demo auth for testing

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      CurvedAnimation(parent: _formController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _formController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // Check if email format is valid
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      // Use real Firebase authentication
      final authService = AuthService();
      final userCredential =
          await authService.signInWithEmailAndPassword(email, password);

      if (userCredential != null) {
        // Login successful
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Save login state
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString(
              'userName', userCredential.user?.displayName ?? 'User');
          await prefs.setString('userEmail', userCredential.user?.email ?? '');

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Login successful! Welcome back.'),
              backgroundColor: const Color(0xFF3B82F6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Navigate to main page
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeInOut)),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      } else {
        // Invalid credentials
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Invalid email or password. Please try again.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Login failed. Please try again.';

        switch (e.code) {
          case 'user-not-found':
            errorMessage =
                'No user found with this email. Please register first.';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many failed attempts. Please try again later.';
            break;
          case 'network-request-failed':
            errorMessage =
                'Network error. Please check your internet connection.';
            break;
          case 'invalid-credential':
            errorMessage =
                'Invalid credentials. Please check your email and password.';
            break;
          case 'admin-account':
            errorMessage =
                'Please use the Admin app to sign in with this account.';
            break;
          default:
            errorMessage =
                'Authentication failed: ${e.message ?? 'Unknown error'}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Login failed. Please try again.';
        if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timeout. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      // Use real Google Sign-In
      final authService = AuthService();
      final userCredential = await authService.signInWithGoogle();

      if (userCredential != null) {
        // Update user provider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loginWithGoogle(userCredential);

        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Google Sign-In successful!'),
              backgroundColor: const Color(0xFF3B82F6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Navigate to main page
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeInOut)),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Google Sign-In failed. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // Header
                        Center(
                          child: Column(
                            children: [
                              // Logo
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5)
                                          .withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/hackethos4u_logo.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF3B82F6),
                                              Color(0xFF1D4ED8),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.school,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),

                              const Text(
                                'Sign in to continue your learning journey',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Login Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _emailController,
                                  validator: _validateEmail,
                                  enabled: true,
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF64748B),
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Password Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _passwordController,
                                  validator: _validatePassword,
                                  enabled: true,
                                  obscureText: !_isPasswordVisible,
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF64748B),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: const Color(0xFF64748B),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Color(0xFF4F46E5),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Login Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF1D4ED8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5)
                                          .withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _isLoading ? null : _handleLogin,
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              'Sign In',
                                              style: TextStyle(
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

                              const SizedBox(height: 20),

                              // Or divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Google Sign In Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _isGoogleLoading
                                        ? null
                                        : _handleGoogleSignIn,
                                    child: Center(
                                      child: _isGoogleLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Color(0xFF4F46E5),
                                                ),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'assets/google-logo--removebg-preview.png',
                                                  width: 24,
                                                  height: 24,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return const Icon(
                                                      Icons.g_mobiledata,
                                                      color: Color(0xFF4F46E5),
                                                      size: 24,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Continue with Google',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              const SizedBox(height: 40),

                              const SizedBox(height: 30),

                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Color(0xFF4F46E5),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
