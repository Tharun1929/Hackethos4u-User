import 'package:flutter/material.dart';
import '../model/coupon/coupon_model.dart';

class CouponValidator extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onValidate;
  final bool isLoading;
  final CouponData? appliedCoupon;

  const CouponValidator({
    super.key,
    required this.controller,
    required this.onValidate,
    required this.isLoading,
    this.appliedCoupon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Apply Coupon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (appliedCoupon == null) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: isLoading
                        ? Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isLoading ? null : onValidate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  isLoading ? 'Validating...' : 'Apply',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a valid coupon code to get discounts',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coupon Applied!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${appliedCoupon!.code} - ${appliedCoupon!.discountPercentage.toInt()}% off',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Clear coupon logic would be handled by parent
                    controller.clear();
                  },
                  icon:
                      Icon(Icons.close, color: Colors.green.shade600, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
