import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int? id;
  final String? firstname;
  final String? lastname;
  final String? email;
  final String? phone;
  final String? password;
  final String? profileImage;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final String? occupation;
  final String? education;
  final String? interests;
  final bool? isEmailVerified;
  final bool? isPhoneVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? authToken;
  final String? refreshToken;
  final DateTime? tokenExpiry;
  final List<String>? enrolledCourses;
  final List<String>? wishlistCourses;
  final Map<String, dynamic>? preferences;
  final String? subscriptionType;
  final DateTime? subscriptionExpiry;
  final double? totalSpent;
  final int? totalCourses;
  final double? averageRating;
  final int? totalReviews;

  UserModel({
    this.id,
    this.firstname,
    this.lastname,
    this.email,
    this.phone,
    this.password,
    this.profileImage,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.occupation,
    this.education,
    this.interests,
    this.isEmailVerified,
    this.isPhoneVerified,
    this.createdAt,
    this.updatedAt,
    this.authToken,
    this.refreshToken,
    this.tokenExpiry,
    this.enrolledCourses,
    this.wishlistCourses,
    this.preferences,
    this.subscriptionType,
    this.subscriptionExpiry,
    this.totalSpent,
    this.totalCourses,
    this.averageRating,
    this.totalReviews,
  });

  // Getters for payment integration
  String get fullName => '${firstname ?? ''} ${lastname ?? ''}'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : email ?? 'User';
  String get paymentName => fullName.isNotEmpty ? fullName : 'EduTiv User';
  String get paymentEmail => email ?? '';
  String get paymentPhone => phone ?? '';

  // Check if user has required payment info
  bool get hasPaymentInfo =>
      email != null && email!.isNotEmpty && phone != null && phone!.isNotEmpty;

  // Check if user is premium
  bool get isPremium =>
      subscriptionType == 'premium' &&
      subscriptionExpiry != null &&
      subscriptionExpiry!.isAfter(DateTime.now());

  // Check if user can access course
  bool canAccessCourse(String courseId) {
    if (enrolledCourses == null) return false;
    return enrolledCourses!.contains(courseId);
  }

  // Add course to enrolled list
  UserModel addEnrolledCourse(String courseId) {
    final updatedCourses = List<String>.from(enrolledCourses ?? []);
    if (!updatedCourses.contains(courseId)) {
      updatedCourses.add(courseId);
    }
    return copyWith(enrolledCourses: updatedCourses);
  }

  // Add course to wishlist
  UserModel addToWishlist(String courseId) {
    final updatedWishlist = List<String>.from(wishlistCourses ?? []);
    if (!updatedWishlist.contains(courseId)) {
      updatedWishlist.add(courseId);
    }
    return copyWith(wishlistCourses: updatedWishlist);
  }

  // Remove from wishlist
  UserModel removeFromWishlist(String courseId) {
    final updatedWishlist = List<String>.from(wishlistCourses ?? []);
    updatedWishlist.remove(courseId);
    return copyWith(wishlistCourses: updatedWishlist);
  }

  // Update total spent
  UserModel updateTotalSpent(double amount) {
    final newTotal = (totalSpent ?? 0.0) + amount;
    return copyWith(totalSpent: newTotal);
  }

  // Update preferences
  UserModel updatePreferences(Map<String, dynamic> newPreferences) {
    final updatedPrefs = Map<String, dynamic>.from(preferences ?? {});
    updatedPrefs.addAll(newPreferences);
    return copyWith(preferences: updatedPrefs);
  }

  // Copy with method
  UserModel copyWith({
    int? id,
    String? firstname,
    String? lastname,
    String? email,
    String? phone,
    String? password,
    String? profileImage,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? country,
    String? pincode,
    String? occupation,
    String? education,
    String? interests,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authToken,
    String? refreshToken,
    DateTime? tokenExpiry,
    List<String>? enrolledCourses,
    List<String>? wishlistCourses,
    Map<String, dynamic>? preferences,
    String? subscriptionType,
    DateTime? subscriptionExpiry,
    double? totalSpent,
    int? totalCourses,
    double? averageRating,
    int? totalReviews,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      profileImage: profileImage ?? this.profileImage,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      interests: interests ?? this.interests,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authToken: authToken ?? this.authToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      wishlistCourses: wishlistCourses ?? this.wishlistCourses,
      preferences: preferences ?? this.preferences,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      totalSpent: totalSpent ?? this.totalSpent,
      totalCourses: totalCourses ?? this.totalCourses,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }

  // Factory constructors
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // Create from auth response
  factory UserModel.fromAuthResponse(Map<String, dynamic> json) {
    return UserModel(
      id: json['user']['id'],
      firstname: json['user']['firstname'],
      lastname: json['user']['lastname'],
      email: json['user']['email'],
      phone: json['user']['phone'],
      profileImage: json['user']['profile_image'],
      authToken: json['auth_token'],
      refreshToken: json['refresh_token'],
      tokenExpiry: json['token_expiry'] != null
          ? DateTime.parse(json['token_expiry'])
          : null,
    );
  }

  // Create guest user
  factory UserModel.guest() {
    return UserModel(
      id: 0,
      firstname: 'Guest',
      lastname: 'User',
      email: 'guest@edutiv.com',
      phone: '',
      isEmailVerified: false,
      isPhoneVerified: false,
      createdAt: DateTime.now(),
      enrolledCourses: [],
      wishlistCourses: [],
      preferences: {},
      totalSpent: 0.0,
      totalCourses: 0,
      averageRating: 0.0,
      totalReviews: 0,
    );
  }

  // Check if user is guest
  bool get isGuest => id == 0 || email == 'guest@edutiv.com';

  // Check if user is authenticated
  bool get isAuthenticated =>
      !isGuest &&
      authToken != null &&
      authToken!.isNotEmpty &&
      (tokenExpiry == null || tokenExpiry!.isAfter(DateTime.now()));

  @override
  String toString() {
    return 'UserModel(id: $id, name: $fullName, email: $email, isAuthenticated: $isAuthenticated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
