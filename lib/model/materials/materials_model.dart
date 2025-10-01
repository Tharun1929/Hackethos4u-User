import 'package:json_annotation/json_annotation.dart';

import '../section/section_model.dart';
part 'materials_model.g.dart';

@JsonSerializable()
class Materials {
  int id;
  Section? section;
  @JsonKey(name: 'material_type')
  String? materialType;
  @JsonKey(name: 'material_name')
  String? materialName;
  @JsonKey(name: 'material_url')
  String? url;
  @JsonKey(name: 'is_completed')
  bool? isCompleted;

  // Enhanced video curriculum fields
  @JsonKey(name: 'video_duration')
  Duration? videoDuration;
  @JsonKey(name: 'video_size')
  int? videoSize; // in bytes
  @JsonKey(name: 'thumbnail_url')
  String? thumbnailUrl;
  @JsonKey(name: 'is_local_video')
  bool? isLocalVideo;
  @JsonKey(name: 'local_video_path')
  String? localVideoPath;
  @JsonKey(name: 'upload_date')
  DateTime? uploadDate;
  @JsonKey(name: 'watched_duration')
  Duration? watchedDuration;
  @JsonKey(name: 'last_watched_position')
  Duration? lastWatchedPosition;
  @JsonKey(name: 'is_unlocked')
  bool? isUnlocked;
  @JsonKey(name: 'unlock_requirement')
  double? unlockRequirement; // percentage of previous video to watch
  @JsonKey(name: 'module_index')
  int? moduleIndex;
  @JsonKey(name: 'video_index')
  int? videoIndex;
  @JsonKey(name: 'description')
  String? description;
  @JsonKey(name: 'tags')
  List<String>? tags;
  @JsonKey(name: 'difficulty_level')
  String? difficultyLevel; // beginner, intermediate, advanced
  @JsonKey(name: 'is_free_preview')
  bool? isFreePreview;

  Materials({
    required this.id,
    this.section,
    this.materialType,
    this.materialName,
    this.url,
    this.isCompleted,
    this.videoDuration,
    this.videoSize,
    this.thumbnailUrl,
    this.isLocalVideo,
    this.localVideoPath,
    this.uploadDate,
    this.watchedDuration,
    this.lastWatchedPosition,
    this.isUnlocked,
    this.unlockRequirement,
    this.moduleIndex,
    this.videoIndex,
    this.description,
    this.tags,
    this.difficultyLevel,
    this.isFreePreview,
  });

  factory Materials.fromJson(Map<String, dynamic> json) =>
      _$MaterialsFromJson(json);
  Map<String, dynamic> toJson() => _$MaterialsToJson(this);

  // Helper methods for video curriculum
  bool get isVideo => materialType == 'video';
  bool get isLocalVideoFile => isLocalVideo == true && localVideoPath != null;
  bool get isRemoteVideo => url != null && url!.isNotEmpty && !isLocalVideoFile;

  double get watchProgress {
    if (videoDuration == null || videoDuration!.inMilliseconds == 0) return 0.0;
    if (watchedDuration == null) return 0.0;
    return watchedDuration!.inMilliseconds / videoDuration!.inMilliseconds;
  }

  bool get canUnlockNext {
    return watchProgress >= (unlockRequirement ?? 0.7);
  }

  String get formattedDuration {
    if (videoDuration == null) return '00:00';
    final hours = videoDuration!.inHours;
    final minutes = videoDuration!.inMinutes.remainder(60);
    final seconds = videoDuration!.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get formattedSize {
    if (videoSize == null) return '0 MB';
    final mb = videoSize! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
