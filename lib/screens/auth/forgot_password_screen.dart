import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      // print('Sending password reset email to: $email');

      await AuthService().sendPasswordResetEmail(email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success dialog with more detailed information
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('Email Sent!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('We\'ve sent a password reset link to:'),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0056D2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Please check:'),
                const SizedBox(height: 8),
                const Text('• Your inbox'),
                const Text('• Spam/Junk folder'),
                const Text('• Promotions tab (Gmail)'),
                const SizedBox(height: 16),
                const Text(
                  'The link will expire in 1 hour.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to login
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // print('Password reset error: $e');

      if (mounted) {
        setState(() => _isLoading = false);

        String errorMessage = 'Failed to send reset email';
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'No account found with this email address';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address format';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Too many requests. Please try again later';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Header Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0056D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF0056D2).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 40,
                        color: Color(0xFF0056D2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A), // Dark text for visibility
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your email to reset your password',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            Color(0xFF757575), // Medium gray for good contrast
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Reset Form
              SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter your email',
                            labelStyle:
                                const TextStyle(color: Color(0xFF1A1A1A)),
                            hintStyle:
                                const TextStyle(color: Color(0xFF9E9E9E)),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF0056D2),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF0056D2), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                          ),
                          style: const TextStyle(
                              color: Color(0xFF1A1A1A)), // Dark text
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Reset Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleResetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Send Reset Link',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Back to Login Link
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              color: Color(0xFF0056D2),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
