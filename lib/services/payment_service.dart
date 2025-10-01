import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'coupon_service.dart';
import '../config/razorpay_config.dart';

enum PaymentGateway { razorpay, stripe, paypal }

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final Razorpay _razorpay = Razorpay();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Backend URL - use configured backend from RazorpayConfig
  static const String _backendUrl = RazorpayConfig.backendUrl;
  
  // Enable direct integration for development
  static const bool _useTestMode = true;
  static const bool _useDirectIntegration = true;

  // Payment status
  bool _isInitialized = false;
  Function(PaymentSuccessResponse)? _onPaymentSuccess;
  Function(PaymentFailureResponse)? _onPaymentFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;
  String? _currentPaymentRecordId;
  double? _currentPaymentAmount;

  /// Initialize Razorpay
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Only initialize Razorpay on non-web platforms
      if (!kIsWeb) {
        _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
        _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
        _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      }

      _isInitialized = true;
      // Payment service initialized successfully
    } catch (e) {
      // Error initializing payment service: $e
      rethrow;
    }
  }

  /// Start payment for course purchase using secure backend flow
  Future<void> startCoursePayment({
    required String courseId,
    required String courseTitle,
    required double amount,
    required String currency,
    PaymentGateway gateway = PaymentGateway.razorpay,
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
      _onPaymentSuccess = onSuccess;
      _onPaymentFailure = onFailure;
      _onExternalWallet = onExternalWallet;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create local payment record in Firestore
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

      switch (gateway) {
        case PaymentGateway.razorpay:
          // Create order through secure backend
          final orderResult = await _createRazorpayOrder(
            amount: amount,
            currency: currency,
            courseId: courseId,
            courseTitle: courseTitle,
            couponCode: couponCode,
            discountAmount: discountAmount,
          );

          if (!orderResult['success']) {
            throw Exception(orderResult['error'] ?? 'Failed to create order');
          }

          // Get Razorpay Key ID from settings (public key only)
          final keyId = await _getRazorpayKeyId();
          if (keyId == null || keyId.isEmpty) {
            throw Exception(
                'Razorpay Key ID not configured. Please contact admin.');
          }

          // Use server-created order id only
          String orderId = orderResult['order_id'];

          final options = {
            'key': keyId,
            'amount': (amount * 100).toInt(), // Amount in paise
            'currency': currency,
            'name': 'Hackethos4u',
            'description': 'Course: $courseTitle',
            'order_id': orderId,
            'prefill': {
              'contact': user.phoneNumber ?? '',
              'email': user.email ?? '',
              'name': user.displayName ?? '',
            },
            'notes': {
              'paymentRecordId': paymentRecordId,
              'courseId': courseId,
            },
            'theme': {
              'color': '#2196F3',
              'backdrop_color': '#000000',
            },
            'modal': {
              'ondismiss': () {
                print('Payment modal dismissed');
              }
            },
            'method': {
              'netbanking': true,
              'wallet': true,
              'upi': true,
              'card': true,
              'emi': true,
            },
            'retry': {
              'enabled': true,
              'max_count': 3,
            },
            'timeout': 300, // 5 minutes
          };

          // Only open Razorpay on non-web platforms
          if (!kIsWeb) {
            _razorpay.open(options);
          } else {
            // For web, redirect to Razorpay Checkout
            _openRazorpayWebCheckout(options);
          }
          break;
        case PaymentGateway.stripe:
          // Fallback: mark as pending-stripe and instruct client redirection (to be implemented server-side)
          await _updatePaymentStatus(
            paymentId: paymentRecordId,
            status: 'pending_stripe',
          );
          _onPaymentFailure?.call(PaymentFailureResponse(
              0,
              'Stripe integration not configured on client. Please try Razorpay.',
              {}));
          break;
        case PaymentGateway.paypal:
          // Fallback: mark as pending-paypal and instruct client redirection (to be implemented server-side)
          await _updatePaymentStatus(
            paymentId: paymentRecordId,
            status: 'pending_paypal',
          );
          _onPaymentFailure?.call(PaymentFailureResponse(
              0,
              'PayPal integration not configured on client. Please try Razorpay.',
              {}));
          break;
      }
    } catch (e) {
      // Error starting payment: $e
      // Surface failure to UI callback if set
      _onPaymentFailure?.call(PaymentFailureResponse(0, e.toString(), {}));
    }
  }

  /// Create Razorpay order through secure backend
  Future<Map<String, dynamic>> _createRazorpayOrder({
    required double amount,
    required String currency,
    required String courseId,
    required String courseTitle,
    String? couponCode,
    double? discountAmount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare order data
      final orderData = {
        'amount': (amount * 100).toInt(), // Convert to paise
        'currency': currency,
        'receipt':
            'course_${courseId}_${DateTime.now().millisecondsSinceEpoch}',
        'notes': {
          'courseId': courseId,
          'courseTitle': courseTitle,
          'userId': user.uid,
          'userEmail': user.email,
          'couponCode': couponCode,
          'discountAmount': discountAmount,
        },
      };

      // If using test mode, create a mock order
      if (_useTestMode) {
        final mockOrderId = 'order_test_${DateTime.now().millisecondsSinceEpoch}';
        await _storeOrderDetails(mockOrderId, orderData);
        
        return {
          'success': true,
          'order_id': mockOrderId,
          'amount': amount,
          'currency': currency,
        };
      }

      // Call backend to create order
      final response = await http.post(
        Uri.parse('$_backendUrl/razorpay/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await user.getIdToken()}',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Store order details in Firestore for tracking
        await _storeOrderDetails(responseData['order_id'], orderData);

        return {
          'success': true,
          'order_id': responseData['order_id'],
          'amount': amount,
          'currency': currency,
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      print('Error creating Razorpay order: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get Razorpay Key ID from settings (public key only)
  Future<String?> _getRazorpayKeyId() async {
    try {
      // Always use direct configuration for now
      final keyId = RazorpayConfig.currentKeyId;
      print('Razorpay Config - Test Mode: ${RazorpayConfig.isTestMode}');
      print('Razorpay Config - Key ID: $keyId');
      print('Razorpay Config - Is Configured: ${RazorpayConfig.isConfigured}');
      return keyId;
    } catch (e) {
      print('Error getting Razorpay Key ID: $e');
      return null;
    }
  }

  /// Store order details in Firestore for tracking
  Future<void> _storeOrderDetails(
      String orderId, Map<String, dynamic> orderData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': user.uid,
        'userEmail': user.email,
        'amount': orderData['amount'],
        'currency': orderData['currency'],
        'courseId': orderData['notes']['courseId'],
        'courseTitle': orderData['notes']['courseTitle'],
        'couponCode': orderData['notes']['couponCode'],
        'discountAmount': orderData['notes']['discountAmount'],
        'status': 'created',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error storing order details: $e');
    }
  }

  /// Verify payment signature through backend
  Future<Map<String, dynamic>> _verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // If using test mode, always return verified
      if (_useTestMode) {
        return {
          'success': true,
          'verified': true,
          'payment_details': {
            'order_id': orderId,
            'payment_id': paymentId,
            'signature': signature,
          },
        };
      }

      final verificationData = {
        'order_id': orderId,
        'payment_id': paymentId,
        'signature': signature,
      };

      final response = await http.post(
        Uri.parse('$_backendUrl/razorpay/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await user.getIdToken()}',
        },
        body: jsonEncode(verificationData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'verified': responseData['verified'] ?? false,
          'payment_details': responseData['payment_details'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Payment verification failed');
      }
    } catch (e) {
      print('Error verifying payment: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Create payment record in Firestore
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
        'updatedAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'razorpay',
        'platform': 'mobile',
        if (couponId != null) 'couponId': couponId,
        if (couponCode != null) 'couponCode': couponCode,
        if (discountAmount != null) 'discountAmount': discountAmount,
      };

      final docRef = await _firestore.collection('payments').add(paymentData);
      return docRef.id;
    } catch (e) {
      // Error creating payment record: $e
      rethrow;
    }
  }

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Payment successful: ${response.paymentId}

      final paymentDocId = _currentPaymentRecordId;
      if (paymentDocId == null) {
        // No current payment record id found.
        return;
      }

      // Verify payment through backend
      final verificationResult = await _verifyPayment(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );

      if (!verificationResult['success'] || !verificationResult['verified']) {
        // Payment verification failed
        await _updatePaymentStatus(
          paymentId: paymentDocId,
          status: 'verification_failed',
          errorMessage: 'Payment verification failed',
        );
        _onPaymentFailure?.call(
            PaymentFailureResponse(0, 'Payment verification failed', {}));
        return;
      }

      // Update payment record
      await _updatePaymentStatus(
        paymentId: paymentDocId,
        status: 'completed',
        razorpayPaymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );

      // Read payment record for details
      final payment = await getPaymentDetails(paymentDocId);
      final courseTitleFromRecord =
          payment?['courseTitle']?.toString() ?? 'Course';
      final courseIdFromRecord = payment?['courseId']?.toString() ?? '';
      final amountFromRecord = (payment?['amount'] as num?)?.toDouble() ?? 0.0;
      final couponIdFromRecord = payment?['couponId']?.toString();

      // Increment coupon usage if applied
      if (couponIdFromRecord != null && couponIdFromRecord.isNotEmpty) {
        try {
          await CouponService().incrementUsage(couponIdFromRecord);
        } catch (_) {}
      }

      // Enroll user in course
      await _enrollUserInCourse(
        courseId: courseIdFromRecord,
        userId: _auth.currentUser?.uid ?? '',
      );

      // Send notification
      await _sendPaymentNotification(
        userId: _auth.currentUser?.uid ?? '',
        courseTitle: courseTitleFromRecord,
        amount: amountFromRecord,
      );

      if (_onPaymentSuccess != null) {
        _onPaymentSuccess!(response);
      }
    } catch (e) {
      // Error handling payment success: $e
    }
  }

  /// Handle payment failure
  void _handlePaymentError(PaymentFailureResponse response) async {
    try {
      // Payment failed: ${response.message}
      final paymentDocId = _currentPaymentRecordId;
      if (paymentDocId != null) {
        await _updatePaymentStatus(
          paymentId: paymentDocId,
          status: 'failed',
          errorMessage: response.message ?? '',
        );
      }

      if (_onPaymentFailure != null) {
        _onPaymentFailure!(response);
      }
    } catch (e) {
      // Error handling payment failure: $e
    }
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    try {
      // External wallet selected: ${response.walletName}
      final paymentDocId = _currentPaymentRecordId;
      if (paymentDocId != null) {
        _updatePaymentStatus(
          paymentId: paymentDocId,
          status: 'external_wallet',
        );
      }
      if (_onExternalWallet != null) {
        _onExternalWallet?.call(response);
      }
    } catch (e) {
      // Error handling external wallet: $e
    }
  }

  /// Update payment status in Firestore
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

      if (razorpayPaymentId != null) {
        updateData['razorpayPaymentId'] = razorpayPaymentId;
      }

      if (signature != null) {
        updateData['signature'] = signature;
      }

      if (errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      await _firestore.collection('payments').doc(paymentId).update(updateData);
    } catch (e) {
      // Error updating payment status: $e
      rethrow;
    }
  }

  /// Enroll user in course after successful payment
  Future<void> _enrollUserInCourse({
    required String courseId,
    required String userId,
  }) async {
    try {
      if (courseId.isEmpty) {
        throw Exception('Invalid courseId for enrollment');
      }

      // Check if user is already enrolled
      final existingEnrollment = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: userId)
          .get();

      if (existingEnrollment.docs.isNotEmpty) {
        // User already enrolled in course
        return;
      }

      // Create enrollment record
      final enrollmentData = {
        'courseId': courseId,
        'userId': userId,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0.0,
        'completedLessons': 0,
        'totalLessons': 0,
        'timeSpent': 0,
        'lastAccessed': FieldValue.serverTimestamp(),
        'certificateEarned': false,
        'status': 'active',
        'paymentRecordId': _currentPaymentRecordId,
      };

      final enrollmentRef =
          await _firestore.collection('enrollments').add(enrollmentData);

      // Create invoice for the user
      try {
        final user = _auth.currentUser;
        if (user != null) {
          final courseDoc =
              await _firestore.collection('courses').doc(courseId).get();
          final courseTitle = courseDoc.data()?['title'] ?? 'Course';
          final amount = (_currentPaymentAmount ?? 0.0);

          final userInvoiceRef = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('invoices')
              .add({
            'courseId': courseId,
            'courseTitle': courseTitle,
            'amount': amount,
            'paymentRecordId': _currentPaymentRecordId,
            'enrollmentId': enrollmentRef.id,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'paid',
          });

          // Optional: also store under course for admin reporting
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('invoices')
              .doc(userInvoiceRef.id)
              .set({
            'userId': user.uid,
            'amount': amount,
            'paymentRecordId': _currentPaymentRecordId,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'paid',
          });
        }
      } catch (e) {
        // Ignore invoice failure to not block enrollment
      }

      // Update course enrollment count
      await _updateCourseEnrollmentCount(courseId);
    } catch (e) {
      // Error enrolling user in course: $e
      rethrow;
    }
  }

  /// Update course enrollment count
  Future<void> _updateCourseEnrollmentCount(String courseId) async {
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);

      await _firestore.runTransaction((transaction) async {
        final courseDoc = await transaction.get(courseRef);
        if (courseDoc.exists) {
          final currentCount = courseDoc.data()?['studentsCount'] ?? 0;
          transaction.update(courseRef, {
            'studentsCount': currentCount + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // Error updating course enrollment count: $e
    }
  }

  /// Send payment notification
  Future<void> _sendPaymentNotification({
    required String userId,
    required String courseTitle,
    required double amount,
  }) async {
    try {
      final notificationData = {
        'userId': userId,
        'title': 'Payment Successful!',
        'body': 'You have successfully enrolled in $courseTitle',
        'type': 'payment_success',
        'data': {
          'courseTitle': courseTitle,
          'amount': amount,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      // Error sending payment notification: $e
    }
  }

  /// Get payment history for user
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      // Error getting payment history: $e
      return [];
    }
  }

  /// Get payment details
  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      // Error getting payment details: $e
      return null;
    }
  }

  /// Verify payment signature
  bool verifyPaymentSignature({
    required String paymentId,
    required String orderId,
    required String signature,
  }) {
    try {
      // In production, verify signature on server side
      // For now, return true (implement proper verification)
      return true;
    } catch (e) {
      // Error verifying payment signature: $e
      return false;
    }
  }

  /// Refund payment
  Future<bool> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      // This should be implemented on server side
      // For now, just update the payment record
      await _updatePaymentStatus(
        paymentId: paymentId,
        status: 'refunded',
        errorMessage: reason ?? 'Refund processed',
      );

      return true;
    } catch (e) {
      // Error refunding payment: $e
      return false;
    }
  }

  /// Process payment (for compatibility with existing code)
  Future<Map<String, dynamic>> processPayment(
      Map<String, dynamic> paymentData) async {
    try {
      final amount = paymentData['amount'] as double;
      final currency = paymentData['currency'] ?? 'INR';
      final courseId = paymentData['courseId'] as String;
      final courseTitle = paymentData['courseTitle'] as String;
      final couponCode = paymentData['couponCode'] as String?;
      final discountAmount = paymentData['discountAmount'] as double?;

      // Create a completer to handle the async payment flow
      final completer = Completer<Map<String, dynamic>>();

      await startCoursePayment(
        courseId: courseId,
        courseTitle: courseTitle,
        amount: amount,
        currency: currency,
        couponCode: couponCode,
        discountAmount: discountAmount,
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

      // Wait for payment completion (with timeout)
      return await completer.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () => {
          'success': false,
          'error': 'Payment timeout',
        },
      );
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Direct Razorpay payment for testing
  Future<Map<String, dynamic>> processDirectPayment({
    required double amount,
    required String courseTitle,
    required String courseId,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a completer to handle the async payment flow
      final completer = Completer<Map<String, dynamic>>();

      // Set up payment callbacks
      _onPaymentSuccess = (response) {
        completer.complete({
          'success': true,
          'paymentId': response.paymentId,
          'orderId': response.orderId,
          'signature': response.signature,
        });
      };

      _onPaymentFailure = (response) {
        completer.complete({
          'success': false,
          'error': response.message ?? 'Payment failed',
          'code': response.code,
        });
      };

      _onExternalWallet = (response) {
        completer.complete({
          'success': false,
          'error': 'External wallet selected: ${response.walletName}',
          'walletName': response.walletName,
        });
      };

      // Create payment record
      final paymentRecordId = await _createPaymentRecord(
        courseId: courseId,
        courseTitle: courseTitle,
        amount: amount,
        currency: 'INR',
        userId: user.uid,
        userEmail: user.email ?? '',
      );
      _currentPaymentRecordId = paymentRecordId;
      _currentPaymentAmount = amount;

      // Get Razorpay Key ID
      final keyId = await _getRazorpayKeyId();
      print('Razorpay Key ID: $keyId');
      if (keyId == null || keyId.isEmpty) {
        throw Exception('Razorpay Key ID not configured');
      }

      // Create order ID
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

      final options = {
        'key': keyId,
        'amount': (amount * 100).toInt(), // Amount in paise
        'currency': 'INR',
        'name': 'Hackethos4u',
        'description': 'Course: $courseTitle',
        'order_id': orderId,
        'prefill': {
          'contact': user.phoneNumber ?? '9876543210',
          'email': user.email ?? 'test@example.com',
          'name': user.displayName ?? 'User',
        },
        'notes': {
          'paymentRecordId': paymentRecordId,
          'courseId': courseId,
        },
        'theme': {
          'color': '#2196F3',
          'backdrop_color': '#000000',
        },
        'method': {
          'netbanking': true,
          'wallet': true,
          'upi': true,
          'card': true,
          'emi': true,
        },
        'retry': {
          'enabled': true,
          'max_count': 3,
        },
        'timeout': 300, // 5 minutes
      };

      // Open Razorpay payment
      _razorpay.open(options);

      // Wait for payment completion (with timeout)
      return await completer.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () => {
          'success': false,
          'error': 'Payment timeout',
        },
      );
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Open Razorpay web checkout
  void _openRazorpayWebCheckout(Map<String, dynamic> options) {
    try {
      // For web, we need to create a checkout URL
      final checkoutUrl = _buildRazorpayWebCheckoutUrl(options);
      
      // Open in new tab
      if (kIsWeb) {
        // Use url_launcher for web
        // This will be handled by the web platform
        print('Opening Razorpay checkout: $checkoutUrl');
        
        // For now, show a message to use mobile app
        _onPaymentFailure?.call(PaymentFailureResponse(
          0, 
          'For web payments, please use our mobile app or contact support.', 
          {}
        ));
      }
    } catch (e) {
      _onPaymentFailure?.call(PaymentFailureResponse(
        0, 
        'Error opening web checkout: $e', 
        {}
      ));
    }
  }

  /// Build Razorpay web checkout URL
  String _buildRazorpayWebCheckoutUrl(Map<String, dynamic> options) {
    final keyId = options['key'] as String;
    final amount = options['amount'] as int;
    final currency = options['currency'] as String;
    final name = options['name'] as String;
    final description = options['description'] as String;
    final orderId = options['order_id'] as String;
    
    final params = {
      'key_id': keyId,
      'amount': amount,
      'currency': currency,
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {
        'name': options['prefill']['name'],
        'email': options['prefill']['email'],
        'contact': options['prefill']['contact'],
      },
      'theme': {
        'color': options['theme']['color'],
      },
    };
    
    // This would be the actual Razorpay checkout URL
    return 'https://checkout.razorpay.com/v1/checkout.js';
  }

  /// Dispose resources
  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
    }
    _currentPaymentAmount = null;
  }
}
