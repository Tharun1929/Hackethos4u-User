import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String id;
  final String title;
  final String instructor;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final String duration;
  final int lessonsCount;
  final double rating;
  final int studentsCount;
  final bool hasFreeDemo;

  CartItem({
    required this.id,
    required this.title,
    required this.instructor,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    required this.duration,
    required this.lessonsCount,
    required this.rating,
    required this.studentsCount,
    required this.hasFreeDemo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'instructor': instructor,
      'imageUrl': imageUrl,
      'price': price,
      'originalPrice': originalPrice,
      'duration': duration,
      'lessonsCount': lessonsCount,
      'rating': rating,
      'studentsCount': studentsCount,
      'hasFreeDemo': hasFreeDemo,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      title: json['title'],
      instructor: json['instructor'],
      imageUrl: json['imageUrl'],
      price: json['price'].toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      duration: json['duration'],
      lessonsCount: json['lessonsCount'],
      rating: json['rating'].toDouble(),
      studentsCount: json['studentsCount'],
      hasFreeDemo: json['hasFreeDemo'],
    );
  }
}

class CartService extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.price);

  // Static methods for CartViewModel
  static Future<List<Map<String, dynamic>>> loadCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_items');
      if (cartData != null) {
        final List<dynamic> cartList = json.decode(cartData);
        return List<Map<String, dynamic>>.from(cartList);
      }
    } catch (e) {
      // Error loading cart items: $e
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> loadSavedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('saved_items');
      if (savedData != null) {
        final List<dynamic> savedList = json.decode(savedData);
        return List<Map<String, dynamic>>.from(savedList);
      }
    } catch (e) {
      // Error loading saved items: $e
    }
    return [];
  }

  static Future<Map<String, dynamic>> loadCouponInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final couponData = prefs.getString('coupon_info');
      if (couponData != null) {
        return Map<String, dynamic>.from(json.decode(couponData));
      }
    } catch (e) {
      // Error loading coupon info: $e
    }
    return {};
  }

  static Future<void> saveCartItems(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = json.encode(items);
      await prefs.setString('cart_items', cartData);
    } catch (e) {
      // Error saving cart items: $e
    }
  }

  static Future<void> saveSavedItems(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = json.encode(items);
      await prefs.setString('saved_items', savedData);
    } catch (e) {
      // Error saving saved items: $e
    }
  }

  static Future<void> clearCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_items');
    } catch (e) {
      // Error clearing cart items: $e
    }
  }

  static Future<void> clearSavedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_items');
    } catch (e) {
      // Error clearing saved items: $e
    }
  }

  static Future<void> saveCouponInfo(
      String coupon, double discountPercentage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final couponData = json.encode({
        'coupon': coupon,
        'discountPercentage': discountPercentage,
      });
      await prefs.setString('coupon_info', couponData);
    } catch (e) {
      // Error saving coupon info: $e
    }
  }

  static Future<void> clearCartData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_items');
      await prefs.remove('saved_items');
      await prefs.remove('coupon_info');
    } catch (e) {
      // Error clearing cart data: $e
    }
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_items');

      if (cartData != null) {
        final List<dynamic> cartList = json.decode(cartData);
        _items = cartList.map((item) => CartItem.fromJson(item)).toList();
      }
    } catch (e) {
      // Error loading cart: $e
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData =
          json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString('cart_items', cartData);
    } catch (e) {
      // Error saving cart: $e
    }
  }

  Future<void> addToCart(CartItem item) async {
    if (!_items.any((cartItem) => cartItem.id == item.id)) {
      _items.add(item);
      await saveCart();
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    await saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    await saveCart();
    notifyListeners();
  }

  bool isInCart(String itemId) {
    return _items.any((item) => item.id == itemId);
  }

  CartItem? getItem(String itemId) {
    try {
      return _items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }
}
