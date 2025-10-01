class AdModel {
  final String id;
  final String title;
  final String thumbnail;
  final String link;
  final String type; // 'youtube', 'website', 'course', etc.
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int clickCount;
  final int viewCount;

  AdModel({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.link,
    required this.type,
    this.isActive = true,
    required this.createdAt,
    this.expiresAt,
    this.clickCount = 0,
    this.viewCount = 0,
  });

  factory AdModel.fromMap(Map<String, dynamic> map) {
    return AdModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      link: map['link'] ?? '',
      type: map['type'] ?? 'website',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      expiresAt: map['expiresAt']?.toDate(),
      clickCount: map['clickCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'thumbnail': thumbnail,
      'link': link,
      'type': type,
      'isActive': isActive,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'clickCount': clickCount,
      'viewCount': viewCount,
    };
  }

  AdModel copyWith({
    String? id,
    String? title,
    String? thumbnail,
    String? link,
    String? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? clickCount,
    int? viewCount,
  }) {
    return AdModel(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      link: link ?? this.link,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      clickCount: clickCount ?? this.clickCount,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}
