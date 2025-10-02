import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/razorpay_config.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final Razorpay _razorpay = Razorpay();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  Function(PaymentSuccessResponse)? _onPaymentSuccess;
  Function(PaymentFailureResponse)? _onPaymentFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;
  String? _currentPaymentRecordId;
  double? _currentPaymentAmount;
  String? _currentCourseId;

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
      print('✅ Payment service initialized (PROTOTYPE MODE)');
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
    String? couponId,
    String? couponCode,
    double? discountAmount,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      _currentPaymentAmount = amount;
      _currentCourseId = courseId;
      _onPaymentSuccess = onSuccess;
      _onPaymentFailure = onFailure;
      _onExternalWallet = onExternalWallet;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('💰 Starting payment: ₹$amount for $courseTitle');

      // Create local payment record
      final paymentRecordId = await _createPaymentRecord(
        courseId: courseId,
        courseTitle: courseTitle,
        amount: amount,
        currency: currency,
        userId: user.uid,
        userEmail: user.email ?? '',
        couponId: couponId,
        couponCode: couponCode,
        discountAmount: discountAmount,
      );
      _currentPaymentRecordId = paymentRecordId;

      // Create order directly (PROTOTYPE - uses Razorpay API)
      final orderId = await _createRazorpayOrderDirect(
        amount: amount,
        currency: currency,
        courseId: courseId,
        courseTitle: courseTitle,
      );

      print('📝 Order created: $orderId');

      // Get Key ID
      final keyId = RazorpayConfig.currentKeyId;
      if (keyId.isEmpty || !keyId.startsWith('rzp_')) {
        throw Exception('Invalid Razorpay Key ID in config');
      }

      // IMPORTANT: Amount must match exactly with order creation
      final amountInPaise = (amount * 100).toInt();
      
      print('Opening checkout with:');
      print('  Order ID: $orderId');
      print('  Amount: $amountInPaise paise (₹$amount)');
      print('  Currency: $currency');
      
      final options = {
        'key': keyId,
        'amount': amountInPaise,
        'currency': currency,
        'name': 'Hackethos4u',
        'description': 'Course: $courseTitle',
        'order_id': orderId,
        'prefill': {
          'contact': user.phoneNumber ?? '9999999999',
          'email': user.email ?? 'test@example.com',
          'name': user.displayName ?? 'Test User',
        },
        'notes': {
          'paymentRecordId': paymentRecordId,
          'courseId': courseId,
        },
        'theme': {
          'color': '#2196F3',
          'backdrop_color': '#000000',
        },
      };

      if (!kIsWeb) {
        print('🚀 Opening Razorpay checkout...');
        _razorpay.open(options);
      } else {
        throw Exception('Web payments not supported - use Android/iOS');
      }
    } catch (e) {
      print('❌ Payment start error: $e');
      _onPaymentFailure?.call(PaymentFailureResponse(0, e.toString(), {}));
    }
  }

  /// Create Razorpay order directly (PROTOTYPE ONLY)
  Future<String> _createRazorpayOrderDirect({
    required double amount,
    required String currency,
    required String courseId,
    required String courseTitle,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Validate credentials
      final keyId = RazorpayConfig.currentKeyId;
      final keySecret = RazorpayConfig.currentKeySecret;
      
      print('🔑 Key ID: ${keyId.substring(0, 12)}...');
      print('🔑 Key Secret length: ${keySecret.length}');
      
      if (keyId.isEmpty || !keyId.startsWith('rzp_test_')) {
        throw Exception('Invalid Key ID. Must start with rzp_test_');
      }
      
      if (keySecret.isEmpty) {
        throw Exception('Key Secret is empty. Update razorpay_config.dart');
      }

      // Prepare order payload
      final orderData = {
        'amount': (amount * 100).toInt(),
        'currency': currency,
        'receipt': 'course_${courseId}_${DateTime.now().millisecondsSinceEpoch}',
        'notes': {
          'courseId': courseId,
          'courseTitle': courseTitle,
          'userId': user.uid,
        },
      };

      print('📦 Order data: ${jsonEncode(orderData)}');

      // Create Basic Auth header
      final credentials = '$keyId:$keySecret';
      final encodedCredentials = base64Encode(utf8.encode(credentials));

      print('📡 Calling Razorpay API...');
      
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $encodedCredentials',
        },
        body: jsonEncode(orderData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('API timeout after 30 seconds'),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final orderId = responseData['id'];
        
        print('✅ Order created: $orderId');
        
        // Store order details
        await _firestore.collection('orders').doc(orderId).set({
          'orderId': orderId,
          'userId': user.uid,
          'amount': amount,
          'currency': currency,
          'courseId': courseId,
          'status': 'created',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return orderId;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['description'] ?? errorData.toString();
        print('❌ API Error: $errorMsg');
        throw Exception('Razorpay API Error: $errorMsg');
      }
    } catch (e) {
      print('❌ Order creation failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to create order: $e');
    }
  }

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      print('✅ Payment successful: ${response.paymentId}');

      final paymentDocId = _currentPaymentRecordId;
      if (paymentDocId == null) {
        print('❌ No payment record ID');
        return;
      }

      // For prototype: Skip signature verification, just mark as completed
      print('⚠️ PROTOTYPE MODE: Skipping signature verification');

      // Update payment record
      await _updatePaymentStatus(
        paymentId: paymentDocId,
        status: 'completed',
        razorpayPaymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );

      // Enroll user
      if (_currentCourseId != null) {
        await _enrollUserInCourse(
          courseId: _currentCourseId!,
          userId: _auth.currentUser?.uid ?? '',
        );
      }

      print('🎉 Payment processed successfully');
      _onPaymentSuccess?.call(response);
    } catch (e) {
      print('❌ Error handling success: $e');
      _onPaymentFailure?.call(PaymentFailureResponse(0, e.toString(), {}));
    }
  }

  /// Handle payment failure
  void _handlePaymentError(PaymentFailureResponse response) async {
    try {
      print('❌ Payment failed: ${response.message}');
      final paymentDocId = _currentPaymentRecordId;
      if (paymentDocId != null) {
        await _updatePaymentStatus(
          paymentId: paymentDocId,
          status: 'failed',
          errorMessage: response.message ?? '',
        );
      }
      _onPaymentFailure?.call(response);
    } catch (e) {
      print('❌ Error handling failure: $e');
    }
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('💳 External wallet: ${response.walletName}');
    _onExternalWallet?.call(response);
  }

  /// Create payment record
  Future<String> _createPaymentRecord({
    required String courseId,
    required String courseTitle,
    required double amount,
    required String currency,
    required String userId,
    required String userEmail,
    String? couponId,
    String? couponCode,
    double? discountAmount,
  }) async {
    try {
      final paymentData = {
        'courseId': courseId,
        'courseTitle': courseTitle,
        'amount': amount,
        'currency': currency,
        'userId': userId,
        'userEmail': userEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'razorpay',
        if (couponId != null) 'couponId': couponId,
        if (couponCode != null) 'couponCode': couponCode,
        if (discountAmount != null) 'discountAmount': discountAmount,
      };

      final docRef = await _firestore.collection('payments').add(paymentData);
      return docRef.id;
    } catch (e) {
      print('❌ Error creating payment record: $e');
      rethrow;
    }
  }

  /// Update payment status
  Future<void> _updatePaymentStatus({
    required String paymentId,
    required String status,
    String? razorpayPaymentId,
    String? signature,
    String? errorMessage,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (razorpayPaymentId != null) updateData['razorpayPaymentId'] = razorpayPaymentId;
      if (signature != null) updateData['signature'] = signature;
      if (errorMessage != null) updateData['errorMessage'] = errorMessage;

      await _firestore.collection('payments').doc(paymentId).update(updateData);
    } catch (e) {
      print('❌ Error updating payment: $e');
    }
  }

  /// Enroll user in course
  Future<void> _enrollUserInCourse({
    required String courseId,
    required String userId,
  }) async {
    try {
      final existingEnrollment = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: userId)
          .get();

      if (existingEnrollment.docs.isNotEmpty) {
        print('ℹ️ Already enrolled');
        return;
      }

      await _firestore.collection('enrollments').add({
        'courseId': courseId,
        'userId': userId,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0.0,
        'status': 'active',
        'paymentRecordId': _currentPaymentRecordId,
      });

      await _firestore.collection('courses').doc(courseId).update({
        'studentsCount': FieldValue.increment(1),
      });

      print('✅ User enrolled successfully');
    } catch (e) {
      print('❌ Error enrolling user: $e');
    }
  }

  /// Get payment details
  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Process payment (compatibility method)
  Future<Map<String, dynamic>> processPayment(Map<String, dynamic> paymentData) async {
    try {
      final completer = Completer<Map<String, dynamic>>();

      await startCoursePayment(
        courseId: paymentData['courseId'] as String,
        courseTitle: paymentData['courseTitle'] as String,
        amount: (paymentData['amount'] as num).toDouble(),
        currency: paymentData['currency'] as String? ?? 'INR',
        couponCode: paymentData['couponCode'] as String?,
        discountAmount: paymentData['discountAmount'] as double?,
        onSuccess: (response) {
          completer.complete({
            'success': true,
            'transactionId': response.paymentId,
            'paymentId': response.paymentId,
            'orderId': response.orderId,
            'signature': response.signature,
          });
        },
        onFailure: (response) {
          completer.complete({
            'success': false,
            'error': response.message ?? 'Payment failed',
            'code': response.code,
          });
        },
        onExternalWallet: (response) {
          completer.complete({
            'success': false,
            'error': 'External wallet not supported',
            'walletName': response.walletName,
          });
        },
      );

      return await completer.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () => {'success': false, 'error': 'Payment timeout'},
      );
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Direct payment method (compatibility)
  Future<Map<String, dynamic>> processDirectPayment({
    required double amount,
    required String courseTitle,
    required String courseId,
  }) async {
    try {
      final completer = Completer<Map<String, dynamic>>();

      await startCoursePayment(
        courseId: courseId,
        courseTitle: courseTitle,
        amount: amount,
        currency: 'INR',
        onSuccess: (response) {
          completer.complete({
            'success': true,
            'paymentId': response.paymentId,
            'orderId': response.orderId,
            'signature': response.signature,
          });
        },
        onFailure: (response) {
          completer.complete({
            'success': false,
            'error': response.message ?? 'Payment failed',
            'code': response.code,
          });
        },
        onExternalWallet: (response) {
          completer.complete({
            'success': false,
            'error': 'External wallet selected: ${response.walletName}',
            'walletName': response.walletName,
          });
        },
      );

      return await completer.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () => {'success': false, 'error': 'Payment timeout'},
      );
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Dispose
  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
    }
  }
}