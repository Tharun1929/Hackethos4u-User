import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecureCardInput extends StatefulWidget {
  final TextEditingController cardNumberController;
  final TextEditingController cardExpiryController;
  final TextEditingController cardCvvController;
  final TextEditingController cardNameController;

  const SecureCardInput({
    super.key,
    required this.cardNumberController,
    required this.cardExpiryController,
    required this.cardCvvController,
    required this.cardNameController,
  });

  @override
  State<SecureCardInput> createState() => _SecureCardInputState();
}

class _SecureCardInputState extends State<SecureCardInput> {
  bool _isCvvVisible = false;
  String _cardType = 'Unknown';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Card Number
        TextField(
          controller: widget.cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon: Icon(Icons.credit_card, color: _getCardTypeColor()),
            suffixIcon: Icon(_getCardTypeIcon(), color: _getCardTypeColor()),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          onChanged: (value) {
            _detectCardType(value);
          },
          maxLength: 19, // 16 digits + 3 spaces
        ),
        const SizedBox(height: 16),

        // Cardholder Name
        TextField(
          controller: widget.cardNameController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'JOHN DOE',
            prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
          ],
        ),
        const SizedBox(height: 16),

        // Expiry and CVV Row
        Row(
          children: [
            // Expiry Date
            Expanded(
              child: TextField(
                controller: widget.cardExpiryController,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  prefixIcon:
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateFormatter(),
                ],
                maxLength: 5,
              ),
            ),
            const SizedBox(width: 16),

            // CVV
            Expanded(
              child: TextField(
                controller: widget.cardCvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: Icon(Icons.security, color: Colors.grey[600]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCvvVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isCvvVisible = !_isCvvVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                obscureText: !_isCvvVisible,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                maxLength: 4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Security notice
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your card details are encrypted and secure',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _detectCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s'), '');

    if (cleanNumber.startsWith('4')) {
      setState(() {
        _cardType = 'Visa';
      });
    } else if (cleanNumber.startsWith('5')) {
      setState(() {
        _cardType = 'Mastercard';
      });
    } else if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
      setState(() {
        _cardType = 'American Express';
      });
    } else if (cleanNumber.startsWith('6')) {
      setState(() {
        _cardType = 'Discover';
      });
    } else if (cleanNumber.startsWith('35')) {
      setState(() {
        _cardType = 'JCB';
      });
    } else if (cleanNumber.startsWith('62')) {
      setState(() {
        _cardType = 'UnionPay';
      });
    } else {
      setState(() {
        _cardType = 'Unknown';
      });
    }
  }

  Color _getCardTypeColor() {
    switch (_cardType) {
      case 'Visa':
        return Colors.blue;
      case 'Mastercard':
        return Colors.orange;
      case 'American Express':
        return Colors.green;
      case 'Discover':
        return Colors.red;
      case 'JCB':
        return Colors.purple;
      case 'UnionPay':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCardTypeIcon() {
    switch (_cardType) {
      case 'Visa':
        return Icons.credit_card;
      case 'Mastercard':
        return Icons.credit_card;
      case 'American Express':
        return Icons.credit_card;
      case 'Discover':
        return Icons.credit_card;
      case 'JCB':
        return Icons.credit_card;
      case 'UnionPay':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
}

// Custom formatters
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll(RegExp(r'\s'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.length <= 2) {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    final formatted = '${text.substring(0, 2)}/${text.substring(2, 4)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
