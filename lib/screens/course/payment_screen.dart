import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/coupon_service.dart';
import '../../services/payment_service.dart';
import '../../utils/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> courseData;

  const PaymentScreen({
    super.key,
    required this.courseData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Services
  final CouponService _couponService = CouponService();
  final PaymentService _paymentService = PaymentService();

  // Controllers
  final TextEditingController _couponController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isCouponValidating = false;
  Map<String, dynamic>? _appliedCoupon;
  List<Map<String, dynamic>> _availableCoupons = [];
  List<Map<String, dynamic>> _promotionalOffers = [];

  // Pricing
  double _lifetimePrice = 0.0; // effective price to buy lifetime
  double _originalMrp = 0.0; // strikethrough MRP for lifetime
  double _monthlyPrice = 0.0; // per-month price if available
  double _discountedPrice =
      0.0; // currently selected payable amount after offers
  double _discount = 0.0;
  String _pricingStrategy = 'default';
  String _selectedPlan = 'lifetime'; // 'lifetime' | 'monthly'

  @override
  void initState() {
    super.initState();
    _initializePricing();
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(RegExp(r'[^0-9\.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _initializePricing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _lifetimePrice = _asDouble(widget.courseData['price']);
      _originalMrp = _asDouble(widget.courseData['originalPrice']);
      _monthlyPrice = _asDouble(widget.courseData['monthlyPrice']);

      // Set initial selection and payable amount
      _selectedPlan = (_monthlyPrice > 0) ? 'lifetime' : 'lifetime';
      _discountedPrice =
          _selectedPlan == 'monthly' ? _monthlyPrice : _lifetimePrice;

      // Get dynamic pricing for the selected plan
      final dynamicPricing = await _couponService.calculateDynamicPricing(
        widget.courseData['id'],
        _discountedPrice,
      );

      if ((dynamicPricing['discountPercentage'] ?? 0) > 0) {
        _discountedPrice =
            (dynamicPricing['discountedPrice'] as num).toDouble();
        _discount = (dynamicPricing['savings'] as num).toDouble();
        _pricingStrategy = dynamicPricing['pricingStrategy'] ?? 'default';
      }

      // Get available coupons
      _availableCoupons =
          await _couponService.getAvailableCoupons(widget.courseData['id']);

      // Get promotional offers
      _promotionalOffers = await _couponService.getPromotionalOffers();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPlanChanged(String plan) {
    if (plan == _selectedPlan) return;
    setState(() {
      _selectedPlan = plan;
      // Reset discounts when plan changes; user can re-apply coupons
      _appliedCoupon = null;
      _discount = 0.0;
      _discountedPrice = plan == 'monthly' ? _monthlyPrice : _lifetimePrice;
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseInfo(),
                  const SizedBox(height: 24),
                  if (_monthlyPrice > 0) _buildPlanSelector(),
                  const SizedBox(height: 16),
                  _buildPricingSection(),
                  const SizedBox(height: 24),
                  _buildPromotionalOffers(),
                  const SizedBox(height: 24),
                  _buildCouponSection(),
                  const SizedBox(height: 24),
                  _buildAvailableCoupons(),
                  const SizedBox(height: 24),
                  _buildPaymentMethods(),
                  const SizedBox(height: 24),
                  _buildPaymentButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildCourseInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.courseData['thumbnail'] ?? '',
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.courseData['title'] ?? 'Course Title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.courseData['instructor'] ?? 'Instructor',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.courseData['duration'] ?? 'Duration',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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

  Widget _buildPlanSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose your plan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'lifetime',
              groupValue: _selectedPlan,
              onChanged: (v) => _onPlanChanged(v ?? 'lifetime'),
              title: Text(
                  'Lifetime access - ₹${_lifetimePrice.toStringAsFixed(0)}'),
              subtitle: _originalMrp > _lifetimePrice
                  ? Text('₹${_originalMrp.toStringAsFixed(0)}',
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough))
                  : null,
            ),
            RadioListTile<String>(
              value: 'monthly',
              groupValue: _selectedPlan,
              onChanged: (v) => _onPlanChanged(v ?? 'monthly'),
              title: Text(
                  'Monthly subscription - ₹${_monthlyPrice.toStringAsFixed(0)}/month'),
              subtitle: const Text('Cancel anytime'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_pricingStrategy != 'default') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getPricingStrategyText(),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedPlan == 'monthly'
                    ? 'Monthly Price:'
                    : 'Lifetime Price:'),
                Text(
                  '₹${_discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount:',
                    style: TextStyle(color: Colors.green[600]),
                  ),
                  Text(
                    '-₹${_discount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${_discountedPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionalOffers() {
    if (_promotionalOffers.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Special Offers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._promotionalOffers.map((offer) => _buildOfferCard(offer)),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer['name'] ?? 'Special Offer',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer['description'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _applyPromotionalOffer(offer),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coupon Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _isCouponValidating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isCouponValidating ? null : _validateCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
            if (_appliedCoupon != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coupon "${_appliedCoupon!['couponData']['name']}" applied successfully!',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _removeCoupon,
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCoupons() {
    if (_availableCoupons.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Coupons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._availableCoupons.map((coupon) => _buildCouponCard(coupon)),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer, color: Colors.orange[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon['name'] ?? 'Coupon',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  coupon['description'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: ${coupon['code']}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _applyCoupon(coupon),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodCard(
              'Razorpay',
              'Pay with UPI, Cards, Net Banking, Wallets',
              Icons.payment,
              Colors.blue,
              isSelected: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secure payment powered by Razorpay',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildPaymentMethodCard(
      String title, String subtitle, IconData icon, Color color, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? color.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? color : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Radio<String>(
            value: title,
            groupValue: isSelected ? title : null,
            onChanged: (_) {},
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ₹${_discountedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }


  String _getPricingStrategyText() {
    switch (_pricingStrategy) {
      case 'new_user':
        return '🎉 Welcome! 20% off for new users';
      case 'loyal_user':
        return '⭐ Thank you! 15% off for loyal users';
      case 'early_bird':
        return '🚀 Early Bird Special! 25% off';
      case 'bulk_purchase':
        return '📦 Bulk Purchase! 30% off';
      default:
        return '';
    }
  }

  Future<void> _validateCoupon() async {
    if (_couponController.text.trim().isEmpty) return;

    setState(() {
      _isCouponValidating = true;
    });

    try {
      final result = await _couponService.validateCoupon(
        couponCode: _couponController.text.trim(),
        courseId: widget.courseData['id'],
        originalPrice: _discountedPrice,
      );

      if (result['isValid']) {
        setState(() {
          _appliedCoupon = result;
          _discount += (result['discount'] as num).toDouble();
          _discountedPrice = (result['finalPrice'] as num).toDouble();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error validating coupon'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCouponValidating = false;
      });
    }
  }

  void _applyCoupon(Map<String, dynamic> coupon) {
    _couponController.text = coupon['code'];
    _validateCoupon();
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discount = 0.0;
      _discountedPrice =
          _selectedPlan == 'monthly' ? _monthlyPrice : _lifetimePrice;
    });
  }

  Future<void> _applyPromotionalOffer(Map<String, dynamic> offer) async {
    try {
      final result = await _couponService.applyPromotionalOffer(
        offer['id'],
        widget.courseData['id'],
        _discountedPrice,
      );

      if (result['isValid']) {
        setState(() {
          _discount += (result['discount'] as num).toDouble();
          _discountedPrice = (result['finalPrice'] as num).toDouble();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error applying offer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createInvoice({required String paymentId}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final invoices = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices');
      final docRef = await invoices.add({
        'userId': user.uid,
        'courseId': widget.courseData['id'],
        'courseTitle': widget.courseData['title'],
        'plan': _selectedPlan,
        'amount': _discountedPrice,
        'currency': 'INR',
        'paymentId': paymentId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Optional: course-level summary
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseData['id'])
          .collection('invoices')
          .doc(docRef.id)
          .set({
        'userId': user.uid,
        'amount': _discountedPrice,
        'paymentId': paymentId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use direct Razorpay payment
      final result = await _paymentService.processDirectPayment(
        amount: _discountedPrice,
        courseTitle: widget.courseData['title'] ?? 'Course',
        courseId: widget.courseData['id']?.toString() ?? 'course_123',
      );

      if (result['success'] == true) {
        final paymentId = result['paymentId']?.toString() ?? '';
        await _createInvoice(paymentId: paymentId);
        await _enrollUserInCourse();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to learning screen
        Navigator.of(context).pushReplacementNamed('/learningCourse', 
            arguments: widget.courseData['id']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (result['error'] ?? result['message'] ?? 'Payment failed').toString()
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment processing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _enrollUserInCourse() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final courseId = widget.courseData['id']?.toString() ?? '';
      if (courseId.isEmpty) return;

      final enrollments = FirebaseFirestore.instance.collection('enrollments');
      // Check existing
      final existing = await enrollments
          .where('userId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return;

      await enrollments.add({
        'userId': user.uid,
        'userEmail': user.email,
        'courseId': courseId,
        'courseTitle': widget.courseData['title'],
        'plan': _selectedPlan,
        'amountPaid': _discountedPrice,
        'enrolledAt': FieldValue.serverTimestamp(),
        'enrollmentStatus': 'Active',
      });
    } catch (_) {}
  }
}
