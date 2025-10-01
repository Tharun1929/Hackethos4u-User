import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/payment/payment_model.dart';
import '../models/payment/order_model.dart';
import '../models/subscription/subscription_plan_model.dart';
import '../config/razorpay_config.dart';

class EnhancedPaymentService {
  static final EnhancedPaymentService _instance = EnhancedPaymentService._internal();
  factory EnhancedPaymentService() => _instance;
  EnhancedPaymentService._internal();

  final Razorpay _razorpay = Razorpay();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Razorpay Configuration
  static String get _razorpayKeyId => RazorpayConfig.currentKeyId;
  static const String _backendUrl = 'https://your-backend-url.com'; // Replace with your backend URL

  // Payment status
  bool _isInitialized = false;
  Function(PaymentSuccessResponse)? _onPaymentSuccess;
  Function(PaymentFailureResponse)? _onPaymentFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;
  String? _currentPaymentRecordId;
  String? _currentOrderId;

  /// Initialize Razorpay
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb) {
        _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
        _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
        _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      }

      _isInitialized = true;
    } catch (e) {
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
      if (!_isInitialized) {
        await initialize();
      }

      _onPaymentSuccess = onSuccess;
      _onPaymentFailure = onFailure;
      _onExternalWallet = onExternalWallet;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create payment record
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
      final orderResult = await _createRazorpayOrder(
        amount: amount,
        currency: currency,
        courseId: courseId,
        courseTitle: courseTitle,
      );

      if (!orderResult['success']) {
        throw Exception(orderResult['error'] ?? 'Failed to create order');
      }

      final orderId = orderResult['orderId'];
      _currentOrderId = orderId;

      // Open Razorpay checkout
      final options = {
        'key': _razorpayKeyId,
        'amount': (amount * 100).toInt(), // Amount in paise
        'currency': currency,
        'name': 'Hackethos4u Learning', // Fixed: Use consistent app name
        'description': courseTitle,
        'order_id': orderId,
        'prefill': {
          'contact': user.phoneNumber ?? '',
          'email': user.email ?? '',
          'name': user.displayName ?? '',
        },
        'theme': {
          'color': '#2196F3',
        },
        'notes': {
          'course_id': courseId,
          'user_id': user.uid,
          'payment_record_id': paymentRecordId,
        },
      };

      if (kIsWeb) {
        // Web flow is not supported via plugin; fail fast with clear message
        onFailure(PaymentFailureResponse(
          0,
          'Web checkout is not enabled in this build. Please test payment on Android/iOS device or emulator.',
          {},
        ));
        return;
      }

      _razorpay.open(options);
    } catch (e) {
      onFailure(PaymentFailureResponse(
        500,
        e.toString(),
        {},
      ));
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
      };

      final docRef = await _firestore.collection('payments').add(paymentData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create payment record: $e');
    }
  }

  /// Create Razorpay order
  Future<Map<String, dynamic>> _createRazorpayOrder({
    required double amount,
    required String currency,
    required String courseId,
    required String courseTitle,
  }) async {
    try {
      // In production, this should be done on your backend
      // For now, we'll create a mock order ID
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      
      return {
        'success': true,
        'orderId': orderId,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    try {
      _updatePaymentStatus(
        paymentId: _currentPaymentRecordId!,
        status: 'completed',
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
        razorpaySignature: response.signature,
      );

      _onPaymentSuccess?.call(response);
    } catch (e) {
      _onPaymentFailure?.call(PaymentFailureResponse(
        500,
        e.toString(),
        {},
      ));
    }
  }

  /// Handle payment failure
  void _handlePaymentError(PaymentFailureResponse response) {
    try {
      _updatePaymentStatus(
        paymentId: _currentPaymentRecordId!,
        status: 'failed',
        failureReason: response.message,
      );

      _onPaymentFailure?.call(response);
    } catch (e) {
      // Error updating payment status
    }
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    _onExternalWallet?.call(response);
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

      if (razorpayPaymentId != null) {
        updateData['razorpayPaymentId'] = razorpayPaymentId;
      }
      if (razorpayOrderId != null) {
        updateData['razorpayOrderId'] = razorpayOrderId;
      }
      if (razorpaySignature != null) {
        updateData['razorpaySignature'] = razorpaySignature;
      }
      if (failureReason != null) {
        updateData['failureReason'] = failureReason;
      }
      if (status == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('payments').doc(paymentId).update(updateData);

      // If payment is successful, enroll user in course
      if (status == 'completed') {
        await _enrollUserInCourse(paymentId);
      }
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Enroll user in course after successful payment
  Future<void> _enrollUserInCourse(String paymentId) async {
    try {
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      if (!paymentDoc.exists) return;

      final paymentData = paymentDoc.data()!;
      final userId = paymentData['userId'];
      final courseId = paymentData['courseId'];

      // Check if user is already enrolled
      final existingEnrollment = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (existingEnrollment.docs.isNotEmpty) return;

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
      });

      // Update course enrollment count
      await _firestore.collection('courses').doc(courseId).update({
        'enrollmentCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to enroll user in course: $e');
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
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _razorpay.clear();
    _isInitialized = false;
  }
}
