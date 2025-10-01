class CouponData {
  final String id;
  final String code;
  final String description;
  final double discountPercentage;
  final double discountAmount;
  final String discountType; // 'percentage' or 'fixed'
  final double minimumAmount;
  final double maximumDiscount;
  final DateTime validFrom;
  final DateTime validUntil;
  final int usageLimit;
  final int usedCount;
  final bool isActive;
  final List<String> applicableCourses;
  final List<String> applicableCategories;

  CouponData({
    required this.id,
    required this.code,
    required this.description,
    required this.discountPercentage,
    required this.discountAmount,
    required this.discountType,
    required this.minimumAmount,
    required this.maximumDiscount,
    required this.validFrom,
    required this.validUntil,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
    this.applicableCourses = const [],
    this.applicableCategories = const [],
  });

  factory CouponData.fromJson(Map<String, dynamic> json) {
    return CouponData(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0.0).toDouble(),
      discountType: json['discountType'] ?? 'percentage',
      minimumAmount: (json['minimumAmount'] ?? 0.0).toDouble(),
      maximumDiscount: (json['maximumDiscount'] ?? 0.0).toDouble(),
      validFrom: DateTime.tryParse(json['validFrom'] ?? '') ?? DateTime.now(),
      validUntil: DateTime.tryParse(json['validUntil'] ?? '') ?? DateTime.now(),
      usageLimit: json['usageLimit'] ?? 0,
      usedCount: json['usedCount'] ?? 0,
      isActive: json['isActive'] ?? false,
      applicableCourses: List<String>.from(json['applicableCourses'] ?? []),
      applicableCategories:
          List<String>.from(json['applicableCategories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'discountType': discountType,
      'minimumAmount': minimumAmount,
      'maximumDiscount': maximumDiscount,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'isActive': isActive,
      'applicableCourses': applicableCourses,
      'applicableCategories': applicableCategories,
    };
  }

  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(validFrom) &&
        now.isBefore(validUntil) &&
        usedCount < usageLimit;
  }

  double calculateDiscount(double originalAmount) {
    if (!isValid || originalAmount < minimumAmount) {
      return 0.0;
    }

    double discount = 0.0;
    if (discountType == 'percentage') {
      discount = originalAmount * (discountPercentage / 100);
      if (maximumDiscount > 0 && discount > maximumDiscount) {
        discount = maximumDiscount;
      }
    } else {
      discount = discountAmount;
    }

    return discount;
  }

  CouponData copyWith({
    String? id,
    String? code,
    String? description,
    double? discountPercentage,
    double? discountAmount,
    String? discountType,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? validFrom,
    DateTime? validUntil,
    int? usageLimit,
    int? usedCount,
    bool? isActive,
    List<String>? applicableCourses,
    List<String>? applicableCategories,
  }) {
    return CouponData(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maximumDiscount: maximumDiscount ?? this.maximumDiscount,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      applicableCourses: applicableCourses ?? this.applicableCourses,
      applicableCategories: applicableCategories ?? this.applicableCategories,
    );
  }
}
