import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  static const String _storageKey = 'cart_items_v1';

  // Getters
  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  int get itemCount => _cartItems.length;
  bool get isEmpty => _cartItems.isEmpty;

  // Calculate total price
  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) {
      final price = _extractPrice(item['price']);
      return sum + price;
    });
  }

  // Calculate discounted total price
  double get discountedTotalPrice {
    return _cartItems.fold(0.0, (sum, item) {
      final originalPrice = _extractPrice(item['originalPrice'] ?? item['price']);
      final discountedPrice = _extractPrice(item['price']);
      return sum + discountedPrice;
    });
  }

  // Calculate total savings
  double get totalSavings {
    return _cartItems.fold(0.0, (sum, item) {
      final originalPrice = _extractPrice(item['originalPrice'] ?? item['price']);
      final discountedPrice = _extractPrice(item['price']);
      return sum + (originalPrice - discountedPrice);
    });
  }

  // Add item to cart
  void addToCart(Map<String, dynamic> course) {
    if (!_cartItems.any((item) => item['id'] == course['id'])) {
      _cartItems.add(course);
      notifyListeners();
      saveCartToStorage();
    }
  }

  // Remove item from cart
  void removeFromCart(String courseId) {
    _cartItems.removeWhere((item) => item['id'] == courseId);
    notifyListeners();
    saveCartToStorage();
  }

  // Update item quantity (for future use)
  void updateQuantity(String courseId, int quantity) {
    final index = _cartItems.indexWhere((item) => item['id'] == courseId);
    if (index != -1) {
      _cartItems[index]['quantity'] = quantity;
      notifyListeners();
      saveCartToStorage();
    }
  }

  // Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
    saveCartToStorage();
  }

  // Check if course is in cart
  bool isInCart(String courseId) {
    return _cartItems.any((item) => item['id'] == courseId);
  }

  // Get cart item by ID
  Map<String, dynamic>? getCartItem(String courseId) {
    try {
      return _cartItems.firstWhere((item) => item['id'] == courseId);
    } catch (e) {
      return null;
    }
  }

  // Apply coupon discount
  void applyCoupon(String couponCode, double discountPercentage) {
    for (int i = 0; i < _cartItems.length; i++) {
      final originalPrice = _cartItems[i]['price'] ?? 0.0;
      final discountedPrice = originalPrice * (1 - discountPercentage / 100);
      _cartItems[i]['price'] = discountedPrice;
      _cartItems[i]['appliedCoupon'] = couponCode;
      _cartItems[i]['discountPercentage'] = discountPercentage;
    }
    notifyListeners();
    saveCartToStorage();
  }

  // Remove coupon
  void removeCoupon() {
    for (int i = 0; i < _cartItems.length; i++) {
      final originalPrice =
          _cartItems[i]['originalPrice'] ?? _cartItems[i]['price'] ?? 0.0;
      _cartItems[i]['price'] = originalPrice;
      _cartItems[i].remove('appliedCoupon');
      _cartItems[i].remove('discountPercentage');
    }
    notifyListeners();
    saveCartToStorage();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Load cart from storage (for future persistence)
  Future<void> loadCartFromStorage() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _cartItems.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _cartItems.add(item);
          } else if (item is Map) {
            _cartItems.add(item.map((key, value) => MapEntry('$key', value)));
          }
        }
      }
    } catch (_) {
      // silently ignore corrupt cache
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Extract price safely from dynamic value
  double _extractPrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  // Save cart to storage (for future persistence)
  Future<void> saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_cartItems);
      await prefs.setString(_storageKey, jsonString);
    } catch (_) {
      // ignore write errors
    }
  }
}
