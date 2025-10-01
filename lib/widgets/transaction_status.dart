import 'package:flutter/material.dart';
import '../model/payment/payment_status.dart';

class TransactionStatus extends StatelessWidget {
  final PaymentStatus status;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const TransactionStatus({
    super.key,
    required this.status,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (status) {
      case PaymentStatus.loading:
        return _buildLoadingStatus(theme);
      case PaymentStatus.completed:
        return _buildSuccessStatus(theme);
      case PaymentStatus.failed:
        return _buildFailedStatus(theme);
      case PaymentStatus.cancelled:
        return _buildCancelledStatus(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Processing Payment...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we process your payment securely',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment has been processed successfully. You can now access your course.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFailedStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error,
              color: Colors.red,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ??
                'Your payment could not be processed. Please try again.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelledStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cancel,
              color: Colors.orange,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Cancelled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You cancelled the payment. You can try again anytime.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}
