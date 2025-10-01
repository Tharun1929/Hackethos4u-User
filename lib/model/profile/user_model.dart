import 'package:hackethos4u/model/course/course_model.dart';
import 'package:json_annotation/json_annotation.dart';

import '../category/category_model.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  int? id;
  @JsonKey(name: 'profile_image')
  String? avatar;
  String? firstname;
  String? lastname;
  @JsonKey(name: 'username')
  String? email;
  String? password;
  String? role;
  @JsonKey(name: 'category')
  CategoryModel? specialization;
  @JsonKey(name: 'enrolled_course')
  List<CourseModel>? enrolledCourse;
  // List<WishlistModel>? wishlist;
  // List<Review>? reviews;

  // Additional properties for profile screen
  String? name;
  String? profilePicture;
  String? location;
  int? enrolledCourses;
  int? certificates;
  int? hoursLearned;
  double? averageRating;

  UserModel({
    this.id,
    this.avatar,
    this.firstname,
    this.lastname,
    this.email,
    this.password,
    this.role,
    this.specialization,
    this.name,
    this.profilePicture,
    this.location,
    this.enrolledCourses,
    this.certificates,
    this.hoursLearned,
    this.averageRating,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
