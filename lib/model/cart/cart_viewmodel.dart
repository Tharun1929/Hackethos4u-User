import 'package:flutter/foundation.dart';
import '../../services/cart_service.dart';

class CartViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _savedForLater = [];
  String _appliedCoupon = '';
  double _discountPercentage = 0.0;

  // Mock coupon codes for demonstration
  final Map<String, double> _validCoupons = {
    'WELCOME10': 10.0,
    'STUDENT20': 20.0,
    'FLASH25': 25.0,
  };

  // Getters
  List<Map<String, dynamic>> get cartItems => _cartItems;
  List<Map<String, dynamic>> get savedForLater => _savedForLater;
  String get appliedCoupon => _appliedCoupon;
  double get discountPercentage => _discountPercentage;
  bool get isCouponApplied => _appliedCoupon.isNotEmpty;
  int get cartItemCount => _cartItems.length;
  int get savedItemCount => _savedForLater.length;

  // Load cart data from storage
  Future<void> loadCartData() async {
    _cartItems = await CartService.loadCartItems();
    _savedForLater = await CartService.loadSavedItems();

    final couponInfo = await CartService.loadCouponInfo();
    _appliedCoupon = couponInfo['coupon'] ?? '';
    _discountPercentage = couponInfo['discountPercentage'] ?? 0.0;

    notifyListeners();
  }

  // Price calculations
  double get subtotal {
    return _cartItems.fold(0.0, (sum, item) {
      final price = _extractPrice(item['price']);
      final quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });
  }

  double get discount {
    return subtotal * (_discountPercentage / 100);
  }

  double get total {
    return subtotal - discount;
  }

  double _extractPrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  // Cart operations
  Future<void> addToCart(Map<String, dynamic> course) async {
    final existingIndex =
        _cartItems.indexWhere((item) => item['id'] == course['id']);

    if (existingIndex != -1) {
      // Update quantity if already in cart
      final currentQuantity = _cartItems[existingIndex]['quantity'] ?? 1;
      _cartItems[existingIndex]['quantity'] = currentQuantity + 1;
    } else {
      // Add new item with quantity 1
      _cartItems.add({
        ...course,
        'quantity': 1,
      });
    }

    // Save to local storage
    await CartService.saveCartItems(_cartItems);
    notifyListeners();
  }

  Future<void> removeFromCart(Map<String, dynamic> course) async {
    _cartItems.removeWhere((item) => item['id'] == course['id']);
    await CartService.saveCartItems(_cartItems);
    notifyListeners();
  }

  void removeFromCartByIndex(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> updateQuantity(int index, int newQuantity) async {
    if (index >= 0 && index < _cartItems.length) {
      if (newQuantity > 0) {
        _cartItems[index]['quantity'] = newQuantity;
      } else {
        _cartItems.removeAt(index);
      }
      await CartService.saveCartItems(_cartItems);
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    await CartService.clearCartItems();
    notifyListeners();
  }

  // Saved for later operations
  Future<void> saveForLater(Map<String, dynamic> course) async {
    final existingIndex =
        _savedForLater.indexWhere((item) => item['id'] == course['id']);

    if (existingIndex == -1) {
      _savedForLater.add(course);
      await CartService.saveSavedItems(_savedForLater);
      notifyListeners();
    }
  }

  Future<void> saveForLaterByIndex(int index) async {
    if (index >= 0 && index < _cartItems.length) {
      final course = _cartItems[index];
      _cartItems.removeAt(index);
      await CartService.saveCartItems(_cartItems);
      await saveForLater(course);
    }
  }

  Future<void> moveToCart(int index) async {
    if (index >= 0 && index < _savedForLater.length) {
      final course = _savedForLater[index];
      _savedForLater.removeAt(index);
      await CartService.saveSavedItems(_savedForLater);
      await addToCart(course);
    }
  }

  Future<void> removeFromSaved(int index) async {
    if (index >= 0 && index < _savedForLater.length) {
      _savedForLater.removeAt(index);
      await CartService.saveSavedItems(_savedForLater);
      notifyListeners();
    }
  }

  Future<void> clearSaved() async {
    _savedForLater.clear();
    await CartService.clearSavedItems();
    notifyListeners();
  }

  // Coupon operations
  Future<bool> applyCoupon(String couponCode) async {
    final code = couponCode.trim().toUpperCase();

    if (_validCoupons.containsKey(code)) {
      _appliedCoupon = code;
      _discountPercentage = _validCoupons[code]!;
      await CartService.saveCouponInfo(_appliedCoupon, _discountPercentage);
      notifyListeners();
      return true;
    }
    return false;
    return _validCoupons.containsKey(couponCode.trim().toUpperCase());
  }

  List<String> get availableCoupons => _validCoupons.keys.toList();

  // Utility methods
  bool isInCart(Map<String, dynamic> course) {
    return _cartItems.any((item) => item['id'] == course['id']);
  }

  bool isSaved(Map<String, dynamic> course) {
    return _savedForLater.any((item) => item['id'] == course['id']);
  }

  int getQuantity(Map<String, dynamic> course) {
    final item = _cartItems.firstWhere(
      (item) => item['id'] == course['id'],
      orElse: () => {},
    );
    return item['quantity'] ?? 0;
  }

  // Checkout
  Map<String, dynamic> getCheckoutData() {
    return {
      'items': _cartItems,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'coupon': _appliedCoupon,
      'discountPercentage': _discountPercentage,
    };
  }

  Future<void> processCheckout() async {
    // Clear cart after successful checkout
    _cartItems.clear();
    _appliedCoupon = '';
    _discountPercentage = 0.0;
    await CartService.clearCartData();
    notifyListeners();
  }
}
