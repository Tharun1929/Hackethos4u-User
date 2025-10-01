// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: (json['id'] as num?)?.toInt(),
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      password: json['password'] as String?,
      profileImage: json['profileImage'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      pincode: json['pincode'] as String?,
      occupation: json['occupation'] as String?,
      education: json['education'] as String?,
      interests: json['interests'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool?,
      isPhoneVerified: json['isPhoneVerified'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      authToken: json['authToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      tokenExpiry: json['tokenExpiry'] == null
          ? null
          : DateTime.parse(json['tokenExpiry'] as String),
      enrolledCourses: (json['enrolledCourses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      wishlistCourses: (json['wishlistCourses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      preferences: json['preferences'] as Map<String, dynamic>?,
      subscriptionType: json['subscriptionType'] as String?,
      subscriptionExpiry: json['subscriptionExpiry'] == null
          ? null
          : DateTime.parse(json['subscriptionExpiry'] as String),
      totalSpent: (json['totalSpent'] as num?)?.toDouble(),
      totalCourses: (json['totalCourses'] as num?)?.toInt(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: (json['totalReviews'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'firstname': instance.firstname,
      'lastname': instance.lastname,
      'email': instance.email,
      'phone': instance.phone,
      'password': instance.password,
      'profileImage': instance.profileImage,
      'dateOfBirth': instance.dateOfBirth,
      'gender': instance.gender,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'pincode': instance.pincode,
      'occupation': instance.occupation,
      'education': instance.education,
      'interests': instance.interests,
      'isEmailVerified': instance.isEmailVerified,
      'isPhoneVerified': instance.isPhoneVerified,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'authToken': instance.authToken,
      'refreshToken': instance.refreshToken,
      'tokenExpiry': instance.tokenExpiry?.toIso8601String(),
      'enrolledCourses': instance.enrolledCourses,
      'wishlistCourses': instance.wishlistCourses,
      'preferences': instance.preferences,
      'subscriptionType': instance.subscriptionType,
      'subscriptionExpiry': instance.subscriptionExpiry?.toIso8601String(),
      'totalSpent': instance.totalSpent,
      'totalCourses': instance.totalCourses,
      'averageRating': instance.averageRating,
      'totalReviews': instance.totalReviews,
    };
