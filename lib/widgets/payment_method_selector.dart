import 'package:flutter/material.dart';

enum PaymentMethodType { upi, card, netbanking, wallet, other }

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final PaymentMethodType type;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class PaymentMethodSelector extends StatefulWidget {
  final PaymentMethod? selectedMethod;
  final Function(PaymentMethod) onMethodSelected;

  const PaymentMethodSelector({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  PaymentMethod? _selectedMethod;

  final List<PaymentMethod> _paymentMethods = [
    const PaymentMethod(
      id: 'upi',
      name: 'UPI',
      description: 'Pay using UPI apps like Google Pay, PhonePe',
      icon: Icons.account_balance_wallet,
      color: Colors.purple,
      type: PaymentMethodType.upi,
    ),
    const PaymentMethod(
      id: 'card',
      name: 'Credit/Debit Card',
      description: 'Pay using Visa, MasterCard, RuPay',
      icon: Icons.credit_card,
      color: Colors.blue,
      type: PaymentMethodType.card,
    ),
    const PaymentMethod(
      id: 'netbanking',
      name: 'Net Banking',
      description: 'Pay using your bank account',
      icon: Icons.account_balance,
      color: Colors.green,
      type: PaymentMethodType.netbanking,
    ),
    const PaymentMethod(
      id: 'wallet',
      name: 'Digital Wallet',
      description: 'Pay using Paytm, Amazon Pay',
      icon: Icons.account_balance_wallet,
      color: Colors.orange,
      type: PaymentMethodType.wallet,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod ?? _paymentMethods.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ..._paymentMethods.map((method) => _buildPaymentMethodTile(method)),
      ],
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = _selectedMethod?.id == method.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: _selectedMethod,
        onChanged: (value) {
          setState(() {
            _selectedMethod = value;
          });
          widget.onMethodSelected(value!);
        },
        title: Row(
          children: [
            Icon(method.icon, color: method.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    method.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: Colors.blue,
      ),
    );
  }
}
