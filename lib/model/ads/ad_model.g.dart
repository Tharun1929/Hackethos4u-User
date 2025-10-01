// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdModel _$AdModelFromJson(Map<String, dynamic> json) => AdModel(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      youtubeLink: json['youtube_link'] as String?,
      isActive: json['is_active'] as bool?,
      displayDuration: (json['display_duration'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      priority: (json['priority'] as num?)?.toInt(),
      targetAudience: (json['target_audience'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      category: json['category'] as String?,
      courseId: (json['course_id'] as num?)?.toInt(),
      videoUrl: json['video_url'] as String?,
    );

Map<String, dynamic> _$AdModelToJson(AdModel instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'thumbnail_url': instance.thumbnailUrl,
      'youtube_link': instance.youtubeLink,
      'is_active': instance.isActive,
      'display_duration': instance.displayDuration,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'priority': instance.priority,
      'target_audience': instance.targetAudience,
      'category': instance.category,
      'course_id': instance.courseId,
      'video_url': instance.videoUrl,
    };
