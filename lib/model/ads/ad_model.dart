import 'package:json_annotation/json_annotation.dart';

part 'ad_model.g.dart';

@JsonSerializable()
class AdModel {
  int? id;
  @JsonKey(name: 'title')
  String? title;
  @JsonKey(name: 'description')
  String? description;
  @JsonKey(name: 'thumbnail_url')
  String? thumbnailUrl;
  @JsonKey(name: 'youtube_link')
  String? youtubeLink;
  @JsonKey(name: 'is_active')
  bool? isActive;
  @JsonKey(name: 'display_duration')
  int? displayDuration; // in seconds
  @JsonKey(name: 'created_at')
  DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;
  @JsonKey(name: 'priority')
  int? priority; // Higher number = higher priority
  @JsonKey(name: 'target_audience')
  List<String>? targetAudience;
  @JsonKey(name: 'category')
  String? category;
  @JsonKey(name: 'course_id')
  int? courseId;
  @JsonKey(name: 'video_url')
  String? videoUrl;
  @JsonKey(name: 'is_auto')
  bool? isAuto;
  @JsonKey(name: 'subtitle')
  String? subtitle;
  @JsonKey(name: 'duration')
  String? duration;
  @JsonKey(name: 'thumbnail')
  String? thumbnail;
  @JsonKey(name: 'redirect_url')
  String? redirectUrl;

  AdModel({
    this.id,
    this.title,
    this.description,
    this.thumbnailUrl,
    this.youtubeLink,
    this.isActive,
    this.displayDuration,
    this.createdAt,
    this.updatedAt,
    this.priority,
    this.targetAudience,
    this.category,
    this.courseId,
    this.videoUrl,
    this.isAuto,
    this.subtitle,
    this.duration,
    this.thumbnail,
    this.redirectUrl,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) =>
      _$AdModelFromJson(json);
  Map<String, dynamic> toJson() => _$AdModelToJson(this);

  // Helper methods
  bool get isValid =>
      isActive == true && youtubeLink != null && youtubeLink!.isNotEmpty;

  String get formattedDuration {
    if (displayDuration == null) return '5s';
    return '${displayDuration}s';
  }

  String get youtubeVideoId {
    if (youtubeLink == null) return '';

    // Extract video ID from various YouTube URL formats
    final uri = Uri.tryParse(youtubeLink!);
    if (uri == null) return '';

    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'] ?? '';
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    }

    return '';
  }

  String get youtubeEmbedUrl {
    final videoId = youtubeVideoId;
    if (videoId.isEmpty) return '';
    return 'https://www.youtube.com/embed/$videoId';
  }

  String get youtubeThumbnailUrl {
    final videoId = youtubeVideoId;
    if (videoId.isEmpty) return '';
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }
}
