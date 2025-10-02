import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/payment/payment_model.dart';
import '../models/subscription/subscription_plan_model.dart';
import '../config/razorpay_config.dart';

class EnhancedPaymentService {
  static final EnhancedPaymentService _instance = EnhancedPaymentService._internal();
  factory EnhancedPaymentService() => _instance;
  EnhancedPaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Razorpay? _razorpay; // Make nullable to reinitialize if needed
  bool _isInitialized = false;
  Function(PaymentSuccessResponse)? _onPaymentSuccess;
  Function(PaymentFailureResponse)? _onPaymentFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;
  String? _currentPaymentRecordId;
  String? _currentCourseId;

  /// Initialize Razorpay
  Future<void> initialize() async {
    if (_isInitialized && _razorpay != null) return;

    try {
      if (!kIsWeb) {
        // Dispose old instance if exists
        _razorpay?.clear();
        
        // Create new instance
        _razorpay = Razorpay();
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      }
      _isInitialized = true;
      print('✅ Payment service initialized');
    } catch (e) {
      print('❌ Error initializing payment service: $e');
      rethrow;
    }
  }

  /// Start payment for course purchase
  Future<void> startCoursePayment({
    required String courseId,
    required String courseTitle,
    required double amount,
    required String currency,
    String? subscriptionPlanId,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) async {
    try {
      // Reinitialize to ensure fresh state
      await initialize();

      _currentCourseId = courseId;
      _onPaymentSuccess = onSuccess;
      _onPaymentFailure = onFailure;
      _onExternalWallet = onExternalWallet;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate amount
      if (amount <= 0) {
        throw Exception('Invalid amount: $amount');
      }

      print('💰 Starting payment: ₹$amount for $courseTitle');

      // Create payment record FIRST
      final paymentRecordId = await _createPaymentRecord(
        courseId: courseId,
        courseTitle: courseTitle,
        amount: amount,
        currency: currency,
        userId: user.uid,
        subscriptionPlanId: subscriptionPlanId,
      );
      _currentPaymentRecordId = paymentRecordId;

      // Create Razorpay order
      final orderId = await _createRazorpayOrderDirect(
        amount: amount,
        currency: currency,
        courseId: courseId,
        courseTitle: courseTitle,
        paymentRecordId: paymentRecordId,
      );

      print('📝 Order created: $orderId');

      // Get and validate Key ID
      final keyId = RazorpayConfig.currentKeyId;
      if (keyId.isEmpty || !keyId.startsWith('rzp_')) {
        throw Exception('Invalid Razorpay Key ID: $keyId');
      }

      // Convert to paise - ensure integer
      final amountInPaise = (amount * 100).round();

      print('══════════════════════════════════════');
      print('🔍 CHECKOUT DEBUG INFO:');
      print('  Key ID: ${keyId.substring(0, 15)}...');
      print('  Order ID: $orderId');
      print('  Amount: $amountInPaise paise (₹${amountInPaise / 100})');
      print('  Currency: $currency');
      print('  User Email: ${user.email ?? 'N/A'}');
      print('  User Phone: ${user.phoneNumber ?? 'N/A'}');
      print('══════════════════════════════════════');

      // CRITICAL: Simplified options to debug loading issue
      final options = <String, dynamic>{
        'key': keyId,
        'amount': amountInPaise,
        'currency': currency,
        'name': 'Hackethos4u',
        'description': courseTitle,
        'order_id': orderId,
        'prefill': <String, dynamic>{
          // CRITICAL: Phone number is required for many payment methods
          'contact': user.phoneNumber?.isNotEmpty == true 
              ? user.phoneNumber! 
              : '9999999999',
          'email': user.email ?? 'customer@hackethos4u.com',
          'name': user.displayName ?? 'Customer',
        },
        'theme': <String, dynamic>{
          'color': '#2196F3',
        },
        'timeout': 300, // 5 minutes timeout
        'readonly': <String, dynamic>{
          'email': false,
          'contact': false,
        },
      };

      if (kIsWeb) {
        throw Exception('Web checkout not supported - use Android/iOS');
      }

      if (_razorpay == null) {
        throw Exception('Razorpay not initialized');
      }

      print('🚀 Opening Razorpay checkout with simplified options...');
      print('Options: ${jsonEncode(options)}');
      
      // Add delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Open checkout with error handling
      try {
        _razorpay!.open(options);
        print('✅ Checkout opened successfully - waiting for user action...');
      } catch (e) {
        print('❌ Error opening Razorpay: $e');
        throw Exception('Failed to open checkout: $e');
      }
    } catch (e, stackTrace) {
      print('❌ Payment start error: $e');
      print('Stack trace: $stackTrace');
      onFailure(PaymentFailureResponse(500, e.toString(), {}));
      
      // Clean up
      if (_currentPaymentRecordId != null) {
        await _updatePaymentStatus(
          paymentId: _currentPaymentRecordId!,
          status: 'failed',
          failureReason: 'Setup error: $e',
        );
      }
    }
  }

  /// Create Razorpay order via API - FIXED: Always create fresh order
  Future<String> _createRazorpayOrderDirect({
    required double amount,
    required String currency,
    required String courseId,
    required String courseTitle,
    required String paymentRecordId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // ✅ FIXED: Removed order reuse logic - always create fresh order
      // This prevents Razorpay from closing immediately with stale order IDs

      // Get and validate credentials
      final keyId = RazorpayConfig.currentKeyId;
      final keySecret = RazorpayConfig.currentKeySecret;

      if (keyId.isEmpty || (!keyId.startsWith('rzp_test_') && !keyId.startsWith('rzp_live_'))) {
        throw Exception('Invalid Key ID format');
      }

      if (keySecret.isEmpty || keySecret.length < 10) {
        throw Exception('Invalid Key Secret');
      }

      print('🔑 Using Key ID: ${keyId.substring(0, 15)}...');

      // Create UNIQUE receipt (max 40 chars) - CRITICAL: Must be unique per order
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = DateTime.now().microsecondsSinceEpoch % 100000;
      final receipt = 'rcpt_${timestamp}_$randomSuffix';
      
      // Prepare order - amount MUST be in paise
      final amountInPaise = (amount * 100).round();
      
      final orderData = {
        'amount': amountInPaise,
        'currency': currency,
        'receipt': receipt,
        'notes': {
          'courseId': courseId,
          'courseTitle': courseTitle,
          'userId': user.uid,
          'paymentRecordId': paymentRecordId,
          'timestamp': timestamp.toString(),
        },
      };

      print('📦 Creating NEW order with amount: $amountInPaise paise');
      print('📝 Receipt: $receipt');

      // Create Basic Auth
      final credentials = base64Encode(utf8.encode('$keyId:$keySecret'));

      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $credentials',
        },
        body: jsonEncode(orderData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('API request timeout'),
      );

      print('📥 API Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final orderId = responseData['id'] as String;
        final orderAmount = responseData['amount'] as int;

        print('✅ NEW Order created: $orderId');
        print('   Amount confirmed: $orderAmount paise');

        // Verify amount matches
        if (orderAmount != amountInPaise) {
          throw Exception('Amount mismatch: expected $amountInPaise, got $orderAmount');
        }

        // Store order details
        await _firestore.collection('orders').doc(orderId).set({
          'orderId': orderId,
          'userId': user.uid,
          'amount': amount,
          'amountInPaise': amountInPaise,
          'currency': currency,
          'courseId': courseId,
          'paymentRecordId': paymentRecordId,
          'status': 'created',
          'receipt': receipt,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': FieldValue.serverTimestamp(), // Will expire after ~15 min
        });

        // Update payment record with order ID
        await _firestore.collection('payments').doc(paymentRecordId).update({
          'razorpayOrderId': orderId,
          'orderCreatedAt': FieldValue.serverTimestamp(),
          'receipt': receipt,
        });

        return orderId;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['description'] ?? 
                        errorData['error']?['reason'] ?? 
                        'Unknown error';
        print('❌ API Error: $errorMsg');
        print('   Full response: ${response.body}');
        throw Exception('Razorpay API Error: $errorMsg');
      }
    } catch (e) {
      print('❌ Order creation failed: $e');
      rethrow;
    }
  }

  /// Create payment record in Firestore
  Future<String> _createPaymentRecord({
    required String courseId,
    required String courseTitle,
    required double amount,
    required String currency,
    required String userId,
    String? subscriptionPlanId,
  }) async {
    try {
      final attemptId = 'pay_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 10000}';
      
      final paymentData = {
        'userId': userId,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'amount': amount,
        'currency': currency,
        'status': 'pending',
        'paymentMethod': 'razorpay',
        'createdAt': FieldValue.serverTimestamp(),
        'subscriptionPlanId': subscriptionPlanId,
        'attemptId': attemptId,
      };

      final docRef = await _firestore.collection('payments').add(paymentData);
      print('📝 Payment record created: ${docRef.id} (Attempt: $attemptId)');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating payment record: $e');
      rethrow;
    }
  }

  /// Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      print('✅ Payment successful!');
      print('   Payment ID: ${response.paymentId}');
      print('   Order ID: ${response.orderId}');
      print('   Signature: ${response.signature}');

      final paymentDocId = _currentPaymentRecordId;
      if (paymentDocId == null) {
        print('❌ No payment record ID found');
        return;
      }

      // Update payment status
      await _updatePaymentStatus(
        paymentId: paymentDocId,
        status: 'completed',
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
        razorpaySignature: response.signature,
      );

      // Enroll user in course
      if (_currentCourseId != null) {
        await _enrollUserInCourse(paymentDocId);
      }

      print('🎉 Payment processed successfully');
      _onPaymentSuccess?.call(response);
      
      // Clean up
      _cleanup();
    } catch (e, stackTrace) {
      print('❌ Error handling success: $e');
      print('Stack trace: $stackTrace');
      _onPaymentFailure?.call(PaymentFailureResponse(500, e.toString(), {}));
    }
  }

  /// Handle payment failure
  void _handlePaymentError(PaymentFailureResponse response) async {
    try {
      print('❌ Payment failed!');
      print('   Code: ${response.code}');
      print('   Message: ${response.message}');
      print('   Error: ${response.error}');
      
      final paymentDocId = _currentPaymentRecordId;
      if (paymentDocId != null) {
        await _updatePaymentStatus(
          paymentId: paymentDocId,
          status: 'failed',
          failureReason: '[${response.code}] ${response.message}',
        );
      }
      
      _onPaymentFailure?.call(response);
      _cleanup();
    } catch (e) {
      print('❌ Error handling failure: $e');
    }
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('💳 External wallet selected: ${response.walletName}');
    _onExternalWallet?.call(response);
  }

  /// Clean up current transaction state
  void _cleanup() {
    _currentPaymentRecordId = null;
    _currentCourseId = null;
    _onPaymentSuccess = null;
    _onPaymentFailure = null;
    _onExternalWallet = null;
  }

  /// Update payment status
  Future<void> _updatePaymentStatus({
    required String paymentId,
    required String status,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
    String? failureReason,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (razorpayPaymentId != null) updateData['razorpayPaymentId'] = razorpayPaymentId;
      if (razorpayOrderId != null) updateData['razorpayOrderId'] = razorpayOrderId;
      if (razorpaySignature != null) updateData['razorpaySignature'] = razorpaySignature;
      if (failureReason != null) updateData['failureReason'] = failureReason;
      if (status == 'completed') updateData['completedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('payments').doc(paymentId).update(updateData);
      print('✅ Payment status updated: $status');
    } catch (e) {
      print('❌ Error updating payment: $e');
    }
  }

  /// Enroll user in course after successful payment
  Future<void> _enrollUserInCourse(String paymentId) async {
    try {
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      if (!paymentDoc.exists) {
        print('❌ Payment document not found');
        return;
      }

      final paymentData = paymentDoc.data()!;
      final userId = paymentData['userId'] as String;
      final courseId = paymentData['courseId'] as String;

      // Check if already enrolled
      final existingEnrollment = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (existingEnrollment.docs.isNotEmpty) {
        print('ℹ️ User already enrolled in course');
        return;
      }

      // Create enrollment
      await _firestore.collection('enrollments').add({
        'userId': userId,
        'courseId': courseId,
        'enrollmentDate': FieldValue.serverTimestamp(),
        'status': 'active',
        'paymentId': paymentId,
        'progress': 0.0,
        'completedModules': [],
        'certificateEligible': false,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });

      // Update course enrollment count
      await _firestore.collection('courses').doc(courseId).update({
        'enrollmentCount': FieldValue.increment(1),
        'lastEnrolledAt': FieldValue.serverTimestamp(),
      });

      print('✅ User enrolled in course successfully');
    } catch (e, stackTrace) {
      print('❌ Error enrolling user: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Get user payments
  Future<List<PaymentModel>> getUserPayments({int limit = 20}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final payments = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return payments.docs
          .map((doc) => PaymentModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('❌ Error fetching payments: $e');
      return [];
    }
  }

  /// Get subscription plans
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    try {
      final plans = await _firestore
          .collection('subscription_plans')
          .where('isActive', isEqualTo: true)
          .orderBy('price', descending: false)
          .get();

      return plans.docs
          .map((doc) => SubscriptionPlanModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('❌ Error fetching plans: $e');
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _isInitialized = false;
    _cleanup();
    print('🗑️ Payment service disposed');
  }
}