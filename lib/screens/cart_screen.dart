import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return IconButton(
                onPressed: cartProvider.isEmpty
                    ? null
                    : () {
                        _clearCart(cartProvider);
                      },
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear Cart',
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty) {
            return _buildEmptyCart(theme);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.itemCount,
                  itemBuilder: (context, index) {
                    final item = cartProvider.cartItems[index];
                    return _buildCartItem(theme, item, cartProvider);
                  },
                ),
              ),
              _buildCheckoutSection(theme, cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some courses to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Browse Courses'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
      ThemeData theme, Map<String, dynamic> item, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Course thumbnail
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(item['thumbnail'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
              child: item['thumbnail'] == null
                  ? const Icon(Icons.image, color: Colors.grey)
                  : null,
            ),

            const SizedBox(width: 16),

            // Course details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Course Title',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['instructor'] ?? 'Instructor',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${item['price']?.toStringAsFixed(0) ?? '0'}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (item['originalPrice'] != null &&
                          item['originalPrice'] > item['price'])
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '₹${item['originalPrice']?.toStringAsFixed(0) ?? '0'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              onPressed: () => _removeFromCart(cartProvider, item),
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red,
              tooltip: 'Remove from cart',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(ThemeData theme, CartProvider cartProvider) {
    final total = cartProvider.totalPrice;
    final originalTotal = _computeOriginalTotal(cartProvider);
    final discount = originalTotal - total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  '₹${originalTotal.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
            if (discount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '-₹${discount.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Checkout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _proceedToCheckout(cartProvider),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Proceed to Checkout (${cartProvider.itemCount} items)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeFromCart(CartProvider cartProvider, Map<String, dynamic> item) {
    cartProvider.removeFromCart(item['id']);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Course removed from cart'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _clearCart(CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(CartProvider cartProvider) {
    if (cartProvider.isEmpty) return;

    // Navigate to payment screen with cart items
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'cartItems': cartProvider.cartItems,
        'total': cartProvider.totalPrice,
        'originalTotal': _computeOriginalTotal(cartProvider),
      },
    );
  }

  double _computeOriginalTotal(CartProvider cartProvider) {
    double sum = 0.0;
    for (final item in cartProvider.cartItems) {
      final original = (item['originalPrice'] ?? item['price'] ?? 0.0) as num;
      sum += original.toDouble();
    }
    return sum;
  }
}
