class CourseProgress {
  final String courseId;
  final String courseTitle;
  final String instructor;
  final String courseImage;
  final double overallProgress;
  final int completedLessons;
  final int totalLessons;
  final int completedModules;
  final int totalModules;
  final DateTime lastAccessed;
  final DateTime enrolledDate;
  final String currentModule;
  final String currentLesson;
  final int timeSpent; // in minutes
  final List<ModuleProgress> modules;
  final List<LessonProgress> lessons;
  final Map<String, dynamic> certificates;
  final Map<String, dynamic> achievements;

  CourseProgress({
    required this.courseId,
    required this.courseTitle,
    required this.instructor,
    required this.courseImage,
    required this.overallProgress,
    required this.completedLessons,
    required this.totalLessons,
    required this.completedModules,
    required this.totalModules,
    required this.lastAccessed,
    required this.enrolledDate,
    required this.currentModule,
    required this.currentLesson,
    required this.timeSpent,
    required this.modules,
    required this.lessons,
    required this.certificates,
    required this.achievements,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      instructor: json['instructor'] ?? '',
      courseImage: json['courseImage'] ?? '',
      overallProgress: (json['overallProgress'] ?? 0.0).toDouble(),
      completedLessons: json['completedLessons'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      completedModules: json['completedModules'] ?? 0,
      totalModules: json['totalModules'] ?? 0,
      lastAccessed: DateTime.parse(
          json['lastAccessed'] ?? DateTime.now().toIso8601String()),
      enrolledDate: DateTime.parse(
          json['enrolledDate'] ?? DateTime.now().toIso8601String()),
      currentModule: json['currentModule'] ?? '',
      currentLesson: json['currentLesson'] ?? '',
      timeSpent: json['timeSpent'] ?? 0,
      modules: (json['modules'] as List<dynamic>?)
              ?.map((module) => ModuleProgress.fromJson(module))
              .toList() ??
          [],
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((lesson) => LessonProgress.fromJson(lesson))
              .toList() ??
          [],
      certificates: json['certificates'] ?? {},
      achievements: json['achievements'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseTitle': courseTitle,
      'instructor': instructor,
      'courseImage': courseImage,
      'overallProgress': overallProgress,
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'completedModules': completedModules,
      'totalModules': totalModules,
      'lastAccessed': lastAccessed.toIso8601String(),
      'enrolledDate': enrolledDate.toIso8601String(),
      'currentModule': currentModule,
      'currentLesson': currentLesson,
      'timeSpent': timeSpent,
      'modules': modules.map((module) => module.toJson()).toList(),
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
      'certificates': certificates,
      'achievements': achievements,
    };
  }

  CourseProgress copyWith({
    String? courseId,
    String? courseTitle,
    String? instructor,
    String? courseImage,
    double? overallProgress,
    int? completedLessons,
    int? totalLessons,
    int? completedModules,
    int? totalModules,
    DateTime? lastAccessed,
    DateTime? enrolledDate,
    String? currentModule,
    String? currentLesson,
    int? timeSpent,
    List<ModuleProgress>? modules,
    List<LessonProgress>? lessons,
    Map<String, dynamic>? certificates,
    Map<String, dynamic>? achievements,
  }) {
    return CourseProgress(
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      instructor: instructor ?? this.instructor,
      courseImage: courseImage ?? this.courseImage,
      overallProgress: overallProgress ?? this.overallProgress,
      completedLessons: completedLessons ?? this.completedLessons,
      totalLessons: totalLessons ?? this.totalLessons,
      completedModules: completedModules ?? this.completedModules,
      totalModules: totalModules ?? this.totalModules,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      enrolledDate: enrolledDate ?? this.enrolledDate,
      currentModule: currentModule ?? this.currentModule,
      currentLesson: currentLesson ?? this.currentLesson,
      timeSpent: timeSpent ?? this.timeSpent,
      modules: modules ?? this.modules,
      lessons: lessons ?? this.lessons,
      certificates: certificates ?? this.certificates,
      achievements: achievements ?? this.achievements,
    );
  }
}

class ModuleProgress {
  final String moduleId;
  final String moduleTitle;
  final String moduleDescription;
  final double progress;
  final int completedLessons;
  final int totalLessons;
  final bool isCompleted;
  final bool isLocked;
  final DateTime? unlockedAt;
  final DateTime? completedAt;
  final int estimatedDuration; // in minutes
  final List<String> lessonIds;

  ModuleProgress({
    required this.moduleId,
    required this.moduleTitle,
    required this.moduleDescription,
    required this.progress,
    required this.completedLessons,
    required this.totalLessons,
    required this.isCompleted,
    required this.isLocked,
    this.unlockedAt,
    this.completedAt,
    required this.estimatedDuration,
    required this.lessonIds,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['moduleId'] ?? '',
      moduleTitle: json['moduleTitle'] ?? '',
      moduleDescription: json['moduleDescription'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      completedLessons: json['completedLessons'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      isLocked: json['isLocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      estimatedDuration: json['estimatedDuration'] ?? 0,
      lessonIds: List<String>.from(json['lessonIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'moduleTitle': moduleTitle,
      'moduleDescription': moduleDescription,
      'progress': progress,
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'isCompleted': isCompleted,
      'isLocked': isLocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'estimatedDuration': estimatedDuration,
      'lessonIds': lessonIds,
    };
  }
}

class LessonProgress {
  final String lessonId;
  final String lessonTitle;
  final String lessonType; // video, quiz, assignment, etc.
  final double progress;
  final bool isCompleted;
  final bool isLocked;
  final DateTime? completedAt;
  final int duration; // in minutes
  final int timeSpent; // in minutes
  final Map<String, dynamic> quizResults;
  final Map<String, dynamic> assignmentResults;

  LessonProgress({
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonType,
    required this.progress,
    required this.isCompleted,
    required this.isLocked,
    this.completedAt,
    required this.duration,
    required this.timeSpent,
    required this.quizResults,
    required this.assignmentResults,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: json['lessonId'] ?? '',
      lessonTitle: json['lessonTitle'] ?? '',
      lessonType: json['lessonType'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      isCompleted: json['isCompleted'] ?? false,
      isLocked: json['isLocked'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      duration: json['duration'] ?? 0,
      timeSpent: json['timeSpent'] ?? 0,
      quizResults: json['quizResults'] ?? {},
      assignmentResults: json['assignmentResults'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'lessonType': lessonType,
      'progress': progress,
      'isCompleted': isCompleted,
      'isLocked': isLocked,
      'completedAt': completedAt?.toIso8601String(),
      'duration': duration,
      'timeSpent': timeSpent,
      'quizResults': quizResults,
      'assignmentResults': assignmentResults,
    };
  }

  LessonProgress copyWith({
    String? lessonId,
    String? lessonTitle,
    String? lessonType,
    double? progress,
    bool? isCompleted,
    bool? isLocked,
    DateTime? completedAt,
    int? duration,
    int? timeSpent,
    Map<String, dynamic>? quizResults,
    Map<String, dynamic>? assignmentResults,
  }) {
    return LessonProgress(
      lessonId: lessonId ?? this.lessonId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      lessonType: lessonType ?? this.lessonType,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
      timeSpent: timeSpent ?? this.timeSpent,
      quizResults: quizResults ?? this.quizResults,
      assignmentResults: assignmentResults ?? this.assignmentResults,
    );
  }
}

class LearningAnalytics {
  final int totalCoursesEnrolled;
  final int totalCoursesCompleted;
  final int totalLessonsCompleted;
  final int totalTimeSpent; // in minutes
  final int currentStreak; // days
  final int longestStreak; // days
  final DateTime lastLearningDate;
  final List<String> completedCourseIds;
  final Map<String, int> categoryProgress;
  final List<Achievement> achievements;
  final List<Certificate> certificates;

  LearningAnalytics({
    required this.totalCoursesEnrolled,
    required this.totalCoursesCompleted,
    required this.totalLessonsCompleted,
    required this.totalTimeSpent,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastLearningDate,
    required this.completedCourseIds,
    required this.categoryProgress,
    required this.achievements,
    required this.certificates,
  });

  factory LearningAnalytics.fromJson(Map<String, dynamic> json) {
    return LearningAnalytics(
      totalCoursesEnrolled: json['totalCoursesEnrolled'] ?? 0,
      totalCoursesCompleted: json['totalCoursesCompleted'] ?? 0,
      totalLessonsCompleted: json['totalLessonsCompleted'] ?? 0,
      totalTimeSpent: json['totalTimeSpent'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastLearningDate: DateTime.parse(
          json['lastLearningDate'] ?? DateTime.now().toIso8601String()),
      completedCourseIds: List<String>.from(json['completedCourseIds'] ?? []),
      categoryProgress: Map<String, int>.from(json['categoryProgress'] ?? {}),
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((achievement) => Achievement.fromJson(achievement))
              .toList() ??
          [],
      certificates: (json['certificates'] as List<dynamic>?)
              ?.map((certificate) => Certificate.fromJson(certificate))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCoursesEnrolled': totalCoursesEnrolled,
      'totalCoursesCompleted': totalCoursesCompleted,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalTimeSpent': totalTimeSpent,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastLearningDate': lastLearningDate.toIso8601String(),
      'completedCourseIds': completedCourseIds,
      'categoryProgress': categoryProgress,
      'achievements':
          achievements.map((achievement) => achievement.toJson()).toList(),
      'certificates':
          certificates.map((certificate) => certificate.toJson()).toList(),
    };
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final String category;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.earnedAt,
    required this.category,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      earnedAt:
          DateTime.parse(json['earnedAt'] ?? DateTime.now().toIso8601String()),
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'earnedAt': earnedAt.toIso8601String(),
      'category': category,
    };
  }
}

class Certificate {
  final String id;
  final String courseId;
  final String courseTitle;
  final String certificateUrl;
  final DateTime issuedAt;
  final String certificateNumber;

  Certificate({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.certificateUrl,
    required this.issuedAt,
    required this.certificateNumber,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      certificateUrl: json['certificateUrl'] ?? '',
      issuedAt:
          DateTime.parse(json['issuedAt'] ?? DateTime.now().toIso8601String()),
      certificateNumber: json['certificateNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'certificateUrl': certificateUrl,
      'issuedAt': issuedAt.toIso8601String(),
      'certificateNumber': certificateNumber,
    };
  }
}
