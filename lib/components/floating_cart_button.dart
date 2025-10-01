import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../screens/course/cart_screen.dart';

class FloatingCartButton extends StatelessWidget {
  const FloatingCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartCount = cartProvider.itemCount;

        if (cartCount == 0) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(
                  cartCourses: cartProvider.cartItems,
                  onRemove: (course) =>
                      cartProvider.removeFromCart(course['id']),
                  onCheckout: () {
                    Navigator.pushNamed(context, '/payment');
                  },
                ),
              ),
            );
          },
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart),
              if (cartCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cartCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: Text('Cart (\$${cartProvider.totalPrice.toStringAsFixed(2)})'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
        );
      },
    );
  }
}
