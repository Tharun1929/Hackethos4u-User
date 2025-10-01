// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: (json['id'] as num?)?.toInt(),
      avatar: json['profile_image'] as String?,
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      email: json['username'] as String?,
      password: json['password'] as String?,
      role: json['role'] as String?,
      specialization: json['category'] == null
          ? null
          : CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
      name: json['name'] as String?,
      profilePicture: json['profilePicture'] as String?,
      location: json['location'] as String?,
      enrolledCourses: (json['enrolledCourses'] as num?)?.toInt(),
      certificates: (json['certificates'] as num?)?.toInt(),
      hoursLearned: (json['hoursLearned'] as num?)?.toInt(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
    )..enrolledCourse = (json['enrolled_course'] as List<dynamic>?)
        ?.map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'profile_image': instance.avatar,
      'firstname': instance.firstname,
      'lastname': instance.lastname,
      'username': instance.email,
      'password': instance.password,
      'role': instance.role,
      'category': instance.specialization,
      'enrolled_course': instance.enrolledCourse,
      'name': instance.name,
      'profilePicture': instance.profilePicture,
      'location': instance.location,
      'enrolledCourses': instance.enrolledCourses,
      'certificates': instance.certificates,
      'hoursLearned': instance.hoursLearned,
      'averageRating': instance.averageRating,
    };
