import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String userId;
  final String courseId;
  final String courseTitle;
  final double amount;
  final String currency;
  final String status; // pending, completed, failed, refunded
  final String paymentMethod; // stripe, paypal, etc.
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;
  final String? failureReason;
  final double? refundAmount;
  final DateTime? refundedAt;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    required this.paymentMethod,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.transactionId,
    required this.createdAt,
    this.completedAt,
    this.metadata,
    this.failureReason,
    this.refundAmount,
    this.refundedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'stripe',
      razorpayOrderId: json['razorpayOrderId'],
      razorpayPaymentId: json['razorpayPaymentId'],
      transactionId: json['transactionId'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp).toDate()
          : json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
      metadata: json['metadata'],
      failureReason: json['failureReason'],
      refundAmount: json['refundAmount']?.toDouble(),
      refundedAt: json['refundedAt'] is Timestamp
          ? (json['refundedAt'] as Timestamp).toDate()
          : json['refundedAt'] != null
              ? DateTime.parse(json['refundedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
      'failureReason': failureReason,
      'refundAmount': refundAmount,
      'refundedAt': refundedAt?.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? courseTitle,
    double? amount,
    String? currency,
    String? status,
    String? paymentMethod,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? transactionId,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    String? failureReason,
    double? refundAmount,
    DateTime? refundedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      failureReason: failureReason ?? this.failureReason,
      refundAmount: refundAmount ?? this.refundAmount,
      refundedAt: refundedAt ?? this.refundedAt,
    );
  }
}
