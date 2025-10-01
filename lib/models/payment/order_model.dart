import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String currency;
  final String status; // pending, paid, completed, cancelled, refunded
  final String paymentMethod;
  final String? paymentIntentId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? billingAddress;
  final Map<String, dynamic>? metadata;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.currency = 'USD',
    required this.status,
    required this.paymentMethod,
    this.paymentIntentId,
    required this.createdAt,
    this.paidAt,
    this.completedAt,
    this.billingAddress,
    this.metadata,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userName: json['userName'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      tax: (json['tax'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'stripe',
      paymentIntentId: json['paymentIntentId'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      paidAt: json['paidAt'] is Timestamp
          ? (json['paidAt'] as Timestamp).toDate()
          : json['paidAt'] != null
              ? DateTime.parse(json['paidAt'])
              : null,
      completedAt: json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp).toDate()
          : json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
      billingAddress: json['billingAddress'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentIntentId': paymentIntentId,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'billingAddress': billingAddress,
      'metadata': metadata,
    };
  }
}

class OrderItem {
  final String courseId;
  final String courseTitle;
  final String courseImage;
  final double price;
  final int quantity;

  OrderItem({
    required this.courseId,
    required this.courseTitle,
    required this.courseImage,
    required this.price,
    this.quantity = 1,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      courseImage: json['courseImage'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseTitle': courseTitle,
      'courseImage': courseImage,
      'price': price,
      'quantity': quantity,
    };
  }
}
