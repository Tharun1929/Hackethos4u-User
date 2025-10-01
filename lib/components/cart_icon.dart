import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../screens/course/cart_screen.dart';

class CartIcon extends StatelessWidget {
  const CartIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartCount = cartProvider.itemCount;

        return Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(
                      cartCourses: cartProvider.cartItems,
                      onRemove: (course) =>
                          cartProvider.removeFromCart(course['id']),
                      onCheckout: () {
                        // Navigate to checkout/payment screen
                        Navigator.pushNamed(context, '/payment');
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined),
              tooltip: 'Shopping Cart',
            ),
            if (cartCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppThemes.badgeAdvanced,
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
        );
      },
    );
  }
}
