import 'package:json_annotation/json_annotation.dart';

import '../category/category_model.dart';
import '../review/review_model.dart';
import '../section/section_model.dart';

part 'course_model.g.dart';

@JsonSerializable()
class CourseModel {
  int? id;
  @JsonKey(name: 'course_name')
  String? courseName;
  @JsonKey(name: 'course_image')
  String? courseImage;
  CategoryModel? category;
  String? description;
  @JsonKey(name: 'total_video')
  int? totalVideo;
  @JsonKey(name: 'total_times')
  String? totalTime;
  @JsonKey(name: 'total_rating')
  double? totalRating;
  @JsonKey(name: 'rating')
  double? rating;
  @JsonKey(name: 'price')
  double? price;
  @JsonKey(name: 'instructor')
  String? instructor;
  @JsonKey(name: 'duration')
  String? duration;
  @JsonKey(name: 'students_count')
  int? studentsCount;
  List<Section>? sections;
  List<Review>? reviews;
  List<dynamic>? tools;

  CourseModel({
    this.id,
    this.courseName,
    this.courseImage,
    this.category,
    this.description,
    this.totalVideo,
    this.totalTime,
    this.totalRating,
    this.rating,
    this.price,
    this.instructor,
    this.duration,
    this.studentsCount,
    this.sections,
    this.reviews,
    this.tools,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModelFromJson(json);
  Map<String, dynamic> toJson() => _$CourseModelToJson(this);
}
