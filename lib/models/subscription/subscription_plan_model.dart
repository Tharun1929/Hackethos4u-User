import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String duration; // 'monthly', 'quarterly', 'yearly', 'lifetime'
  final int durationMonths; // 1, 3, 6, 12, -1 for lifetime
  final bool isActive;
  final List<String> features;
  final double? discountPercentage;
  final double? originalPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'INR',
    required this.duration,
    required this.durationMonths,
    this.isActive = true,
    this.features = const [],
    this.discountPercentage,
    this.originalPrice,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    String asString(dynamic v, [String fallback = '']) =>
        v == null ? fallback : v.toString();
    double asDouble(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }
    int asInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }
    DateTime asDateTime(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      if (v is Map<String, dynamic>) {
        final seconds = v['seconds'] ?? v['_seconds'];
        if (seconds is int) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
      return DateTime.now();
    }

    return SubscriptionPlanModel(
      id: asString(json['id']),
      name: asString(json['name']),
      description: asString(json['description']),
      price: asDouble(json['price']),
      currency: asString(json['currency'], 'INR'),
      duration: asString(json['duration'], 'monthly'),
      durationMonths: asInt(json['durationMonths'], 1),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      features: (json['features'] is List)
          ? List<String>.from((json['features'] as List).map((e) => e.toString()))
          : <String>[],
      discountPercentage: asDouble(json['discountPercentage'], 0.0),
      originalPrice: asDouble(json['originalPrice'], 0.0),
      createdAt: asDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? asDateTime(json['updatedAt']) : null,
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'duration': duration,
      'durationMonths': durationMonths,
      'isActive': isActive,
      'features': features,
      'discountPercentage': discountPercentage,
      'originalPrice': originalPrice,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  SubscriptionPlanModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    String? duration,
    int? durationMonths,
    bool? isActive,
    List<String>? features,
    double? discountPercentage,
    double? originalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      duration: duration ?? this.duration,
      durationMonths: durationMonths ?? this.durationMonths,
      isActive: isActive ?? this.isActive,
      features: features ?? this.features,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      originalPrice: originalPrice ?? this.originalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  double get effectivePrice {
    if (discountPercentage != null && discountPercentage! > 0) {
      return price * (1 - discountPercentage! / 100);
    }
    return price;
  }

  bool get isDiscounted => discountPercentage != null && discountPercentage! > 0;

  String get formattedDuration {
    switch (duration) {
      case 'monthly':
        return '1 Month';
      case 'quarterly':
        return '3 Months';
      case 'yearly':
        return '1 Year';
      case 'lifetime':
        return 'Lifetime';
      default:
        return '$durationMonths Month${durationMonths > 1 ? 's' : ''}';
    }
  }
}
