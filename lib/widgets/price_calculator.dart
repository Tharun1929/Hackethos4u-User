import 'package:flutter/material.dart';
import '../model/coupon/coupon_model.dart';

class PriceCalculator extends StatelessWidget {
  final double originalPrice;
  final double discountAmount;
  final double finalPrice;
  final CouponData? appliedCoupon;

  const PriceCalculator({
    super.key,
    required this.originalPrice,
    required this.discountAmount,
    required this.finalPrice,
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
            Icon(Icons.receipt_long,
                color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Price Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Price breakdown
        Column(
          children: [
            _buildPriceRow(
              'Original Price',
              '₹${originalPrice.toStringAsFixed(0)}',
              Colors.grey.shade600,
            ),
            if (appliedCoupon != null) ...[
              const SizedBox(height: 8),
              _buildPriceRow(
                'Discount (${appliedCoupon!.discountPercentage.toInt()}%)',
                '-₹${discountAmount.toStringAsFixed(0)}',
                Colors.green.shade700,
                isDiscount: true,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildPriceRow(
              'Total Amount',
              '₹${finalPrice.toStringAsFixed(0)}',
              theme.colorScheme.primary,
              isTotal: true,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Savings info
        if (appliedCoupon != null && discountAmount > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.savings, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You save ₹${discountAmount.toStringAsFixed(0)} with coupon ${appliedCoupon!.code}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String amount,
    Color color, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
