import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_service.dart';
import 'invoice_service.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PaymentService _paymentService = PaymentService();

  // Get available subscription plans
  Future<List<Map<String, dynamic>>> getAvailablePlans() async {
    try {
      final plansQuery = await _firestore
          .collection('plans')
          .where('status', isEqualTo: 'active')
          .orderBy('priceMonthly', descending: false)
          .get();

      return plansQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      // print('Error fetching subscription plans: $e');
      return [];
    }
  }

  // Get user's current subscription
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('startedAt', descending: true)
          .limit(1)
          .get();

      if (subscriptionQuery.docs.isNotEmpty) {
        final subscriptionData = subscriptionQuery.docs.first.data();
        subscriptionData['id'] = subscriptionQuery.docs.first.id;
        return subscriptionData;
      }
      return null;
    } catch (e) {
      // print('Error fetching current subscription: $e');
      return null;
    }
  }

  // Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) return false;

      final expiresAt = subscription['expiresAt']?.toDate();
      if (expiresAt == null) return false;

      return DateTime.now().isBefore(expiresAt);
    } catch (e) {
      // print('Error checking subscription status: $e');
      return false;
    }
  }

  // Purchase subscription plan
  Future<bool> purchasePlan({
    required String planId,
    required Map<String, dynamic> planData,
    required String billingCycle, // 'monthly' | 'yearly'
    required String paymentMethod, // 'razorpay' | 'stripe' | 'paypal'
    bool testMode = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Calculate pricing based on billing cycle
      final price = billingCycle == 'yearly'
          ? (planData['priceYearly'] as num?)?.toDouble() ?? 0.0
          : (planData['priceMonthly'] as num?)?.toDouble() ?? 0.0;

      if (price <= 0) {
        throw Exception('Invalid plan price');
      }

      // Process payment
      final paymentResult = await _paymentService.processPayment({
        'amount': price,
        'currency': 'INR',
        'description':
            '${planData['name']} Subscription - ${billingCycle == 'yearly' ? 'Yearly' : 'Monthly'}',
        'paymentMethod': paymentMethod,
        'testMode': testMode,
        'metadata': {
          'type': 'subscription',
          'planId': planId,
          'billingCycle': billingCycle,
          'planName': planData['name'] ?? '',
        },
      });

      if (paymentResult['success'] == true) {
        // Create subscription record
        await _createSubscriptionRecord(
          planId: planId,
          planData: planData,
          billingCycle: billingCycle,
          paymentMethod: paymentMethod,
          transactionId: paymentResult['transactionId'],
          amount: price,
          testMode: testMode,
        );

        // Generate invoice
        await InvoiceService().generateInvoice(
          courseId: planId,
          courseTitle: planData['name'] ?? 'Subscription',
          paymentMethod: paymentMethod,
          transactionId: paymentResult['transactionId'] ?? '',
          amount: price,
          // description: '${planData['name']} Subscription - ${billingCycle == 'yearly' ? 'Yearly' : 'Monthly'}',
          // customerName: user.displayName ?? user.email ?? 'User',
          // customerEmail: user.email ?? '',
          // items: [
          //   {
          //     'name': '${planData['name']} Subscription',
          //     'description': '${billingCycle == 'yearly' ? 'Yearly' : 'Monthly'} subscription plan',
          //     'quantity': 1,
          //     'price': price,
          //   }
          // ],
        );

        return true;
      } else {
        throw Exception(paymentResult['error'] ?? 'Payment failed');
      }
    } catch (e) {
      // print('Error purchasing subscription: $e');
      rethrow;
    }
  }

  // Create subscription record in Firestore
  Future<void> _createSubscriptionRecord({
    required String planId,
    required Map<String, dynamic> planData,
    required String billingCycle,
    required String paymentMethod,
    required String transactionId,
    required double amount,
    bool testMode = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final trialDays = (planData['trialDays'] as num?)?.toInt() ?? 0;

      // Calculate expiry date based on billing cycle
      DateTime expiresAt;
      if (trialDays > 0) {
        expiresAt = now.add(Duration(days: trialDays));
      } else {
        expiresAt = billingCycle == 'yearly'
            ? now.add(const Duration(days: 365))
            : now.add(const Duration(days: 30));
      }

      // Cancel any existing active subscription
      await _cancelExistingSubscriptions(user.uid);

      // Create new subscription record
      final subDoc = await _firestore.collection('subscriptions').add({
        'userId': user.uid,
        'planId': planId,
        'planName': planData['name'] ?? '',
        'billingCycle': billingCycle,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'amount': amount,
        'status': 'active',
        'trialDays': trialDays,
        'isTrialActive': trialDays > 0,
        'startedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'nextBillingDate': trialDays > 0
            ? Timestamp.fromDate(now.add(Duration(days: trialDays)))
            : Timestamp.fromDate(expiresAt),
        'testMode': testMode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user profile with subscription info
      await _firestore.collection('users').doc(user.uid).set({
        'subscription': planData['name']?.toString().toLowerCase() == 'pro'
            ? 'pro'
            : 'basic',
        'subscriptionId': subDoc.id,
        'subscriptionPlanId': planId,
        'subscriptionBillingCycle': billingCycle,
        'subscriptionExpiresAt': Timestamp.fromDate(expiresAt),
        'subscriptionStatus': 'active',
        'lastSubscriptionUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log subscription event
      await _firestore.collection('subscriptionLogs').add({
        'userId': user.uid,
        'action': 'subscription_created',
        'planId': planId,
        'planName': planData['name'],
        'billingCycle': billingCycle,
        'amount': amount,
        'transactionId': transactionId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error creating subscription record: $e');
      rethrow;
    }
  }

  // Cancel existing active subscriptions
  Future<void> _cancelExistingSubscriptions(String userId) async {
    try {
      final activeSubscriptions = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in activeSubscriptions.docs) {
        await doc.reference.update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // print('Error cancelling existing subscriptions: $e');
    }
  }

  // Cancel current subscription
  Future<bool> cancelSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final subscription = await getCurrentSubscription();
      if (subscription == null) return false;

      // Update subscription status
      await _firestore
          .collection('subscriptions')
          .doc(subscription['id'])
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Update user profile
      await _firestore.collection('users').doc(user.uid).set({
        'subscriptionStatus': 'cancelled',
        'lastSubscriptionUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log cancellation
      await _firestore.collection('subscriptionLogs').add({
        'userId': user.uid,
        'action': 'subscription_cancelled',
        'subscriptionId': subscription['id'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      // print('Error cancelling subscription: $e');
      return false;
    }
  }

  // Get subscription features
  List<String> getSubscriptionFeatures(Map<String, dynamic> planData) {
    return (planData['features'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
  }

  // Check if user has specific feature access
  Future<bool> hasFeatureAccess(String feature) async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) return false;

      final planId = subscription['planId'];
      final planDoc = await _firestore.collection('plans').doc(planId).get();

      if (!planDoc.exists) return false;

      final planData = planDoc.data()!;
      final features = getSubscriptionFeatures(planData);

      return features.contains(feature);
    } catch (e) {
      // print('Error checking feature access: $e');
      return false;
    }
  }
}
