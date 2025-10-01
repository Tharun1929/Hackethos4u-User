// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'materials_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Materials _$MaterialsFromJson(Map<String, dynamic> json) => Materials(
      id: (json['id'] as num).toInt(),
      section: json['section'] == null
          ? null
          : Section.fromJson(json['section'] as Map<String, dynamic>),
      materialType: json['material_type'] as String?,
      materialName: json['material_name'] as String?,
      url: json['material_url'] as String?,
      isCompleted: json['is_completed'] as bool?,
      videoDuration: json['video_duration'] == null
          ? null
          : Duration(microseconds: (json['video_duration'] as num).toInt()),
      videoSize: (json['video_size'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      isLocalVideo: json['is_local_video'] as bool?,
      localVideoPath: json['local_video_path'] as String?,
      uploadDate: json['upload_date'] == null
          ? null
          : DateTime.parse(json['upload_date'] as String),
      watchedDuration: json['watched_duration'] == null
          ? null
          : Duration(microseconds: (json['watched_duration'] as num).toInt()),
      lastWatchedPosition: json['last_watched_position'] == null
          ? null
          : Duration(
              microseconds: (json['last_watched_position'] as num).toInt()),
      isUnlocked: json['is_unlocked'] as bool?,
      unlockRequirement: (json['unlock_requirement'] as num?)?.toDouble(),
      moduleIndex: (json['module_index'] as num?)?.toInt(),
      videoIndex: (json['video_index'] as num?)?.toInt(),
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      difficultyLevel: json['difficulty_level'] as String?,
      isFreePreview: json['is_free_preview'] as bool?,
    );

Map<String, dynamic> _$MaterialsToJson(Materials instance) => <String, dynamic>{
      'id': instance.id,
      'section': instance.section,
      'material_type': instance.materialType,
      'material_name': instance.materialName,
      'material_url': instance.url,
      'is_completed': instance.isCompleted,
      'video_duration': instance.videoDuration?.inMicroseconds,
      'video_size': instance.videoSize,
      'thumbnail_url': instance.thumbnailUrl,
      'is_local_video': instance.isLocalVideo,
      'local_video_path': instance.localVideoPath,
      'upload_date': instance.uploadDate?.toIso8601String(),
      'watched_duration': instance.watchedDuration?.inMicroseconds,
      'last_watched_position': instance.lastWatchedPosition?.inMicroseconds,
      'is_unlocked': instance.isUnlocked,
      'unlock_requirement': instance.unlockRequirement,
      'module_index': instance.moduleIndex,
      'video_index': instance.videoIndex,
      'description': instance.description,
      'tags': instance.tags,
      'difficulty_level': instance.difficultyLevel,
      'is_free_preview': instance.isFreePreview,
    };
