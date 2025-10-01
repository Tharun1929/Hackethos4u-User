import 'package:json_annotation/json_annotation.dart';

part 'qa_model.g.dart';

@JsonSerializable()
class QuestionModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String courseId;
  final String courseName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int votes;
  final int answerCount;
  final bool isAnswered;
  final bool isResolved;
  final List<String> tags;
  final List<AnswerModel> answers;
  final Map<String, dynamic>? metadata;

  QuestionModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.courseId,
    required this.courseName,
    required this.createdAt,
    required this.updatedAt,
    this.votes = 0,
    this.answerCount = 0,
    this.isAnswered = false,
    this.isResolved = false,
    this.tags = const [],
    this.answers = const [],
    this.metadata,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionModelToJson(this);

  QuestionModel copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? courseId,
    String? courseName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? votes,
    int? answerCount,
    bool? isAnswered,
    bool? isResolved,
    List<String>? tags,
    List<AnswerModel>? answers,
    Map<String, dynamic>? metadata,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      votes: votes ?? this.votes,
      answerCount: answerCount ?? this.answerCount,
      isAnswered: isAnswered ?? this.isAnswered,
      isResolved: isResolved ?? this.isResolved,
      tags: tags ?? this.tags,
      answers: answers ?? this.answers,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class AnswerModel {
  final String id;
  final String questionId;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final bool isInstructor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int votes;
  final bool isAccepted;
  final bool isBestAnswer;
  final Map<String, dynamic>? metadata;

  AnswerModel({
    required this.id,
    required this.questionId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.isInstructor = false,
    required this.createdAt,
    required this.updatedAt,
    this.votes = 0,
    this.isAccepted = false,
    this.isBestAnswer = false,
    this.metadata,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) =>
      _$AnswerModelFromJson(json);
  Map<String, dynamic> toJson() => _$AnswerModelToJson(this);

  AnswerModel copyWith({
    String? id,
    String? questionId,
    String? content,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    bool? isInstructor,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? votes,
    bool? isAccepted,
    bool? isBestAnswer,
    Map<String, dynamic>? metadata,
  }) {
    return AnswerModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      isInstructor: isInstructor ?? this.isInstructor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      votes: votes ?? this.votes,
      isAccepted: isAccepted ?? this.isAccepted,
      isBestAnswer: isBestAnswer ?? this.isBestAnswer,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class QAFilterModel {
  final String? searchQuery;
  final String? filterBy;
  final String? sortBy;
  final String? courseId;
  final String? authorId;
  final bool? isAnswered;
  final bool? isResolved;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  QAFilterModel({
    this.searchQuery,
    this.filterBy,
    this.sortBy,
    this.courseId,
    this.authorId,
    this.isAnswered,
    this.isResolved,
    this.dateFrom,
    this.dateTo,
  });

  factory QAFilterModel.fromJson(Map<String, dynamic> json) =>
      _$QAFilterModelFromJson(json);
  Map<String, dynamic> toJson() => _$QAFilterModelToJson(this);
}

@JsonSerializable()
class CreateQuestionModel {
  final String title;
  final String content;
  final String courseId;
  final List<String> tags;

  CreateQuestionModel({
    required this.title,
    required this.content,
    required this.courseId,
    this.tags = const [],
  });

  factory CreateQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$CreateQuestionModelFromJson(json);
  Map<String, dynamic> toJson() => _$CreateQuestionModelToJson(this);
}

@JsonSerializable()
class CreateAnswerModel {
  final String questionId;
  final String content;

  CreateAnswerModel({
    required this.questionId,
    required this.content,
  });

  factory CreateAnswerModel.fromJson(Map<String, dynamic> json) =>
      _$CreateAnswerModelFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAnswerModelToJson(this);
}
