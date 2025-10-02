import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/enhanced_payment_service.dart';
import '../../models/subscription/subscription_plan_model.dart';

class EnhancedPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> courseData;

  const EnhancedPaymentScreen({
    super.key,
    required this.courseData,
  });

  @override
  State<EnhancedPaymentScreen> createState() => _EnhancedPaymentScreenState();
}

class _EnhancedPaymentScreenState extends State<EnhancedPaymentScreen>
    with TickerProviderStateMixin {
  final EnhancedPaymentService _paymentService = EnhancedPaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Make animation controllers nullable to avoid late initialization error
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // State
  bool _isLoading = true;
  bool _isProcessing = false;
  List<SubscriptionPlanModel> _subscriptionPlans = [];
  SubscriptionPlanModel? _selectedPlan;
  String _selectedPaymentMethod = 'razorpay';
  final TextEditingController _couponController = TextEditingController();
  String? _couponError;
  double? _discountAmount;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSubscriptionPlans();
  }

  Future<void> _applyCoupon() async {
    if (!mounted) return;
    
    setState(() {
      _couponError = null;
      _discountAmount = null;
    });

    final code = _couponController.text.trim();
    if (code.isEmpty) {
      if (mounted) {
        setState(() => _couponError = 'Enter a code');
      }
      return;
    }

    try {
      // Basic validation against Firestore 'coupons' (status=active)
      final snap = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: code.toUpperCase())
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (!mounted) return;

      if (snap.docs.isEmpty) {
        setState(() => _couponError = 'Invalid or inactive coupon');
        return;
      }
      
      final data = snap.docs.first.data();
      final double base = (_selectedPlan?.effectivePrice ??
          ((widget.courseData['price'] is num)
              ? (widget.courseData['price'] as num).toDouble()
              : 0.0));

      double discount = 0;
      if ((data['type'] ?? 'percent') == 'percent') {
        discount = base * ((data['value'] as num).toDouble() / 100);
      } else {
        discount = (data['value'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _discountAmount = discount.clamp(0, base);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon applied: -₹${_discountAmount!.toInt()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _couponError = 'Error applying coupon');
      }
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController!, curve: Curves.easeOutCubic));

    _animationController!.forward();
  }

  Future<void> _loadSubscriptionPlans() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final plans = await _paymentService.getSubscriptionPlans();

      if (!mounted) return;

      // Fallback: if no plans defined in Firestore, create a one-time purchase option
      List<SubscriptionPlanModel> effectivePlans = plans;
      if (effectivePlans.isEmpty) {
        final double coursePrice = (widget.courseData['price'] is num)
            ? (widget.courseData['price'] as num).toDouble()
            : 0.0;
        effectivePlans = [
          SubscriptionPlanModel(
            id: 'one_time',
            name: 'One-time Purchase',
            description: 'Lifetime access to this course',
            price: coursePrice,
            currency: 'INR',
            duration: 'lifetime',
            durationMonths: -1,
            createdAt: DateTime.now(),
          ),
        ];
      }

      setState(() {
        _subscriptionPlans = effectivePlans;
        _selectedPlan = effectivePlans.isNotEmpty ? effectivePlans.first : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading subscription plans: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fadeAnimation != null && _slideAnimation != null
              ? FadeTransition(
                  opacity: _fadeAnimation!,
                  child: SlideTransition(
                    position: _slideAnimation!,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCourseInfo(),
                          const SizedBox(height: 24),
                          _buildSubscriptionPlans(),
                          const SizedBox(height: 24),
                          _buildPaymentMethods(),
                          const SizedBox(height: 24),
                          _buildPaymentButton(),
                          const SizedBox(height: 16),
                          _buildSecurityInfo(),
                        ],
                      ),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCourseInfo() {
    final theme = Theme.of(context);
    return Container(
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: widget.courseData['image'] != null && 
                       widget.courseData['image'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.courseData['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.school, size: 30, color: Colors.grey);
                          },
                        ),
                      )
                    : const Icon(Icons.school, size: 30, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.courseData['title'] ?? 'Course Title',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (_) {
                        final dynamic instructorRaw = widget.courseData['instructor'];
                        final String instructorName = instructorRaw is Map
                            ? (instructorRaw['name']?.toString() ?? '')
                            : (instructorRaw?.toString() ?? '');
                        return Text(
                          instructorName.isNotEmpty ? instructorName : 'Instructor',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.courseData['rating'] ?? 4.5}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.people, color: Colors.grey[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.courseData['enrollmentCount'] ?? 0} students',
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
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._subscriptionPlans.map((plan) => _buildPlanCard(plan)),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlanModel plan) {
    final theme = Theme.of(context);
    final isSelected = _selectedPlan?.id == plan.id;
    final isPopular = plan.duration == 'yearly';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPlan = plan;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isPopular)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (plan.isDiscounted && plan.originalPrice != null) ...[
                            Text(
                              '₹${plan.originalPrice!.toInt()}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '₹${plan.effectivePrice.toInt()}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.formattedDuration,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (plan.features.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coupon input
        TextField(
          controller: _couponController,
          decoration: InputDecoration(
            labelText: 'Coupon code',
            hintText: 'Enter coupon',
            errorText: _couponError,
            suffixIcon: TextButton(
              onPressed: _isProcessing ? null : _applyCoupon,
              child: const Text('Apply'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Payment Method',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Razorpay',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Pay with UPI, Cards, Net Banking',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: 'razorpay',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    final theme = Theme.of(context);
    // Fallback to course price if no plan selected/available
    final double coursePrice = (widget.courseData['price'] is num)
        ? (widget.courseData['price'] as num).toDouble()
        : 0.0;
    final baseAmount = _selectedPlan?.effectivePrice ?? coursePrice;
    final totalAmount = (baseAmount - (_discountAmount ?? 0)).clamp(0, double.infinity);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Pay ₹${totalAmount.toInt()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.security,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your payment is secure and encrypted. We use industry-standard security measures.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!mounted) return;
    
    // Validate amount before processing
    final double coursePrice = (widget.courseData['price'] is num)
        ? (widget.courseData['price'] as num).toDouble()
        : 0.0;
    final baseAmount = _selectedPlan?.effectivePrice ?? coursePrice;
    final totalAmount = (baseAmount - (_discountAmount ?? 0)).clamp(0, double.infinity);

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid payment amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.courseData['id'] == null || widget.courseData['id'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid course data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });

    try {
      print('Starting payment with amount: $totalAmount');
      print('Course ID: ${widget.courseData['id']}');
      print('Plan ID: ${_selectedPlan?.id}');

      await _paymentService.startCoursePayment(
        courseId: widget.courseData['id'] ?? '',
        courseTitle: widget.courseData['title'] ?? '',
        amount: totalAmount.toDouble(),
        currency: 'INR',
        subscriptionPlanId: _selectedPlan?.id,
        onSuccess: (response) {
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Course unlocked.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        },
        onFailure: (response) {
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onExternalWallet: (response) {
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('External wallet selected: ${response.walletName}'),
              backgroundColor: Colors.blue,
            ),
          );
        },
      );
    } catch (e) {
      print('Payment error details: $e');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}