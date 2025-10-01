import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _currentSubscription;
  bool _isLoading = true;
  String _selectedBillingCycle = 'monthly';
  String _selectedPaymentMethod = 'razorpay';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final plans = await _subscriptionService.getAvailablePlans();
      final currentSubscription =
          await _subscriptionService.getCurrentSubscription();

      setState(() {
        _plans = plans;
        _currentSubscription = currentSubscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscriptions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Current Subscription Status
                if (_currentSubscription != null)
                  _buildCurrentSubscriptionCard(),

                // Billing Cycle Selector
                _buildBillingCycleSelector(),

                // Payment Method Selector
                _buildPaymentMethodSelector(),

                // Plans List
                Expanded(
                  child: _plans.isEmpty
                      ? const Center(
                          child: Text('No subscription plans available'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _plans.length,
                          itemBuilder: (context, index) {
                            final plan = _plans[index];
                            return _buildPlanCard(plan);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    final expiresAt = _currentSubscription!['expiresAt']?.toDate();
    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.warning : Icons.check_circle,
            color: isExpired ? Colors.red[600] : Colors.green[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan: ${_currentSubscription!['planName']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpired ? Colors.red[700] : Colors.green[700],
                  ),
                ),
                Text(
                  isExpired
                      ? 'Expired on ${_formatDate(expiresAt!)}'
                      : 'Expires on ${_formatDate(expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired ? Colors.red[600] : Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
          if (!isExpired)
            TextButton(
              onPressed: _cancelSubscription,
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }

  Widget _buildBillingCycleSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Billing Cycle:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'monthly',
                  label: Text('Monthly'),
                ),
                ButtonSegment(
                  value: 'yearly',
                  label: Text('Yearly'),
                ),
              ],
              selected: {_selectedBillingCycle},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedBillingCycle = selection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Payment Method:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'razorpay',
                  label: Text('Razorpay'),
                ),
                ButtonSegment(
                  value: 'stripe',
                  label: Text('Stripe'),
                ),
                ButtonSegment(
                  value: 'paypal',
                  label: Text('PayPal'),
                ),
              ],
              selected: {_selectedPaymentMethod},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedPaymentMethod = selection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final price = _selectedBillingCycle == 'yearly'
        ? (plan['priceYearly'] as num?)?.toDouble() ?? 0.0
        : (plan['priceMonthly'] as num?)?.toDouble() ?? 0.0;

    final features = (plan['features'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final isPopular =
        plan['name']?.toString().toLowerCase().contains('pro') ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Plan Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isPopular ? AppTheme.primaryColor : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan['name'] ?? 'Plan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isPopular ? Colors.white : Colors.black,
                            ),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
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
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan['description'] ?? '',
                        style: TextStyle(
                          color: isPopular ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isPopular ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      _selectedBillingCycle == 'yearly' ? '/year' : '/month',
                      style: TextStyle(
                        color: isPopular ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Features List
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Features:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          // Subscribe Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _subscribeToPlan(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPopular ? AppTheme.primaryColor : Colors.grey[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Subscribe to ${plan['name']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribeToPlan(Map<String, dynamic> plan) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing subscription...'),
            ],
          ),
        ),
      );

      final success = await _subscriptionService.purchasePlan(
        planId: plan['id'],
        planData: plan,
        billingCycle: _selectedBillingCycle,
        paymentMethod: _selectedPaymentMethod,
        testMode: true,
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Successfully subscribed to ${plan['name']}!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Refresh data
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelSubscription() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Subscription'),
          content: const Text(
              'Are you sure you want to cancel your subscription? You will lose access to premium features.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Subscription'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel Subscription'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await _subscriptionService.cancelSubscription();
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription cancelled successfully'),
                backgroundColor: Colors.orange,
              ),
            );
            _loadData(); // Refresh data
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
