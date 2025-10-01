import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class CouponService {
  static final CouponService _instance = CouponService._internal();
  factory CouponService() => _instance;
  CouponService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Validate and apply coupon
  Future<Map<String, dynamic>> validateCoupon({
    required String couponCode,
    required String courseId,
    required double originalPrice,
  }) async {
    try {
      // Get coupon from Firestore
      final couponDoc = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: couponCode.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (couponDoc.docs.isEmpty) {
        return {
          'isValid': false,
          'message': 'Invalid coupon code',
          'discount': 0.0,
          'finalPrice': originalPrice,
        };
      }

      final coupon = couponDoc.docs.first.data();
      final couponId = couponDoc.docs.first.id;

      // Check if coupon is expired
      if (coupon['expiryDate'] != null) {
        final expiryDate = coupon['expiryDate'].toDate();
        if (DateTime.now().isAfter(expiryDate)) {
          return {
            'isValid': false,
            'message': 'Coupon has expired',
            'discount': 0.0,
            'finalPrice': originalPrice,
          };
        }
      }

      // Check if coupon has usage limit
      if (coupon['usageLimit'] != null) {
        final usageCount = await _getCouponUsageCount(couponId);
        if (usageCount >= coupon['usageLimit']) {
          return {
            'isValid': false,
            'message': 'Coupon usage limit reached',
            'discount': 0.0,
            'finalPrice': originalPrice,
          };
        }
      }

      // Check if user has already used this coupon
      final user = _auth.currentUser;
      if (user != null) {
        final hasUsedCoupon = await _hasUserUsedCoupon(user.uid, couponId);
        if (hasUsedCoupon && coupon['oneTimeUse'] == true) {
          return {
            'isValid': false,
            'message': 'You have already used this coupon',
            'discount': 0.0,
            'finalPrice': originalPrice,
          };
        }
      }

      // Check if coupon applies to this course
      if (coupon['applicableCourses'] != null) {
        final applicableCourses =
            List<String>.from(coupon['applicableCourses']);
        if (!applicableCourses.contains(courseId) &&
            !applicableCourses.contains('all')) {
          return {
            'isValid': false,
            'message': 'Coupon not applicable to this course',
            'discount': 0.0,
            'finalPrice': originalPrice,
          };
        }
      }

      // Calculate discount
      double discount = 0.0;
      double finalPrice = originalPrice;

      if (coupon['discountType'] == 'percentage') {
        discount = originalPrice * (coupon['discountValue'] / 100);
        finalPrice = originalPrice - discount;
      } else if (coupon['discountType'] == 'fixed') {
        discount = coupon['discountValue'];
        finalPrice = originalPrice - discount;
      }

      // Apply minimum order value
      if (coupon['minimumOrderValue'] != null &&
          originalPrice < coupon['minimumOrderValue']) {
        return {
          'isValid': false,
          'message': 'Minimum order value not met',
          'discount': 0.0,
          'finalPrice': originalPrice,
        };
      }

      // Apply maximum discount
      if (coupon['maximumDiscount'] != null &&
          discount > coupon['maximumDiscount']) {
        discount = coupon['maximumDiscount'];
        finalPrice = originalPrice - discount;
      }

      // Ensure final price is not negative
      if (finalPrice < 0) {
        finalPrice = 0;
        discount = originalPrice;
      }

      return {
        'isValid': true,
        'message': 'Coupon applied successfully',
        'discount': discount,
        'finalPrice': finalPrice,
        'couponId': couponId,
        'couponData': coupon,
      };
    } catch (e) {
      // print('Error validating coupon: $e');
      return {
        'isValid': false,
        'message': 'Error validating coupon',
        'discount': 0.0,
        'finalPrice': originalPrice,
      };
    }
  }

  /// Record coupon usage
  Future<bool> recordCouponUsage({
    required String couponId,
    required String courseId,
    required double originalPrice,
    required double discount,
    required double finalPrice,
    required String paymentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('coupon_usage').add({
        'userId': user.uid,
        'couponId': couponId,
        'courseId': courseId,
        'originalPrice': originalPrice,
        'discount': discount,
        'finalPrice': finalPrice,
        'paymentId': paymentId,
        'usedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update coupon usage count
      await _firestore.collection('coupons').doc(couponId).update({
        'usageCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      // print('Error recording coupon usage: $e');
      return false;
    }
  }

  /// Get coupon usage count
  Future<int> _getCouponUsageCount(String couponId) async {
    try {
      final usageQuery = await _firestore
          .collection('coupon_usage')
          .where('couponId', isEqualTo: couponId)
          .count()
          .get();
      return usageQuery.count ?? 0;
    } catch (e) {
      // print('Error getting coupon usage count: $e');
      return 0;
    }
  }

  /// Increment usage count for coupon (lightweight helper)
  Future<void> incrementUsage(String couponId) async {
    try {
      await _firestore.collection('coupons').doc(couponId).update({
        'usageCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error incrementing coupon usage: $e');
    }
  }

  /// Check if user has used a coupon
  Future<bool> _hasUserUsedCoupon(String userId, String couponId) async {
    try {
      final usageQuery = await _firestore
          .collection('coupon_usage')
          .where('userId', isEqualTo: userId)
          .where('couponId', isEqualTo: couponId)
          .limit(1)
          .get();
      return usageQuery.docs.isNotEmpty;
    } catch (e) {
      // print('Error checking user coupon usage: $e');
      return false;
    }
  }

  /// Get available coupons for a course
  Future<List<Map<String, dynamic>>> getAvailableCoupons(
      String courseId) async {
    try {
      final couponsQuery = await _firestore
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .where('expiryDate', isGreaterThan: DateTime.now())
          .get();

      final availableCoupons = <Map<String, dynamic>>[];

      for (final doc in couponsQuery.docs) {
        final coupon = doc.data();
        final couponId = doc.id;

        // Check if coupon applies to this course
        if (coupon['applicableCourses'] != null) {
          final applicableCourses =
              List<String>.from(coupon['applicableCourses']);
          if (!applicableCourses.contains(courseId) &&
              !applicableCourses.contains('all')) {
            continue;
          }
        }

        // Check usage limit
        if (coupon['usageLimit'] != null) {
          final usageCount = await _getCouponUsageCount(couponId);
          if (usageCount >= coupon['usageLimit']) {
            continue;
          }
        }

        availableCoupons.add({
          'id': couponId,
          ...coupon,
        });
      }

      return availableCoupons;
    } catch (e) {
      // print('Error getting available coupons: $e');
      return [];
    }
  }

  /// Generate random coupon code
  static String generateCouponCode({int length = 8}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Dynamic pricing methods
  Future<Map<String, dynamic>> calculateDynamicPricing(
      String courseId, double basePrice) async {
    try {
      // Get course popularity and demand
      final courseDoc =
          await _firestore.collection('courses').doc(courseId).get();
      final courseData = courseDoc.data();

      if (courseData == null) return {'price': basePrice, 'discount': 0.0};

      final enrollments = courseData['students'] ?? 0;
      final rating = courseData['rating'] ?? 0.0;

      // Calculate dynamic pricing based on demand
      double multiplier = 1.0;
      if (enrollments > 1000) {
        multiplier = 1.2;
      } else if (enrollments > 500)
        multiplier = 1.1;
      else if (enrollments < 100) multiplier = 0.9;

      if (rating > 4.5) {
        multiplier *= 1.1;
      } else if (rating < 3.5) multiplier *= 0.9;

      final dynamicPrice = basePrice * multiplier;
      final discount = basePrice - dynamicPrice;

      return {
        'price': dynamicPrice,
        'discount': discount,
        'multiplier': multiplier,
      };
    } catch (e) {
      // print('Error calculating dynamic pricing: $e');
      return {'price': basePrice, 'discount': 0.0};
    }
  }

  Future<List<Map<String, dynamic>>> getPromotionalOffers() async {
    try {
      final querySnapshot = await _firestore
          .collection('promotional_offers')
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      // print('Error getting promotional offers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> applyPromotionalOffer(
      String offerId, String courseId, double originalPrice) async {
    try {
      final offerDoc =
          await _firestore.collection('promotional_offers').doc(offerId).get();
      final offerData = offerDoc.data();

      if (offerData == null || !offerData['isActive']) {
        return {'success': false, 'message': 'Offer not found or inactive'};
      }

      final discountType = offerData['discountType'] ?? 'percentage';
      final discountValue = offerData['discountValue'] ?? 0.0;

      double discountedPrice = originalPrice;
      if (discountType == 'percentage') {
        discountedPrice = originalPrice * (1 - discountValue / 100);
      } else {
        discountedPrice = originalPrice - discountValue;
      }

      return {
        'success': true,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'discount': originalPrice - discountedPrice,
        'offerName': offerData['name'] ?? 'Promotional Offer',
      };
    } catch (e) {
      // print('Error applying promotional offer: $e');
      return {'success': false, 'message': 'Error applying offer'};
    }
  }
}
