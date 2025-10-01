// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qa_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionModel _$QuestionModelFromJson(Map<String, dynamic> json) =>
    QuestionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      courseId: json['courseId'] as String,
      courseName: json['courseName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      answerCount: (json['answerCount'] as num?)?.toInt() ?? 0,
      isAnswered: json['isAnswered'] as bool? ?? false,
      isResolved: json['isResolved'] as bool? ?? false,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => AnswerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$QuestionModelToJson(QuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'authorAvatar': instance.authorAvatar,
      'courseId': instance.courseId,
      'courseName': instance.courseName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'votes': instance.votes,
      'answerCount': instance.answerCount,
      'isAnswered': instance.isAnswered,
      'isResolved': instance.isResolved,
      'tags': instance.tags,
      'answers': instance.answers,
      'metadata': instance.metadata,
    };

AnswerModel _$AnswerModelFromJson(Map<String, dynamic> json) => AnswerModel(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      isInstructor: json['isInstructor'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      isAccepted: json['isAccepted'] as bool? ?? false,
      isBestAnswer: json['isBestAnswer'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AnswerModelToJson(AnswerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionId': instance.questionId,
      'content': instance.content,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'authorAvatar': instance.authorAvatar,
      'isInstructor': instance.isInstructor,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'votes': instance.votes,
      'isAccepted': instance.isAccepted,
      'isBestAnswer': instance.isBestAnswer,
      'metadata': instance.metadata,
    };

QAFilterModel _$QAFilterModelFromJson(Map<String, dynamic> json) =>
    QAFilterModel(
      searchQuery: json['searchQuery'] as String?,
      filterBy: json['filterBy'] as String?,
      sortBy: json['sortBy'] as String?,
      courseId: json['courseId'] as String?,
      authorId: json['authorId'] as String?,
      isAnswered: json['isAnswered'] as bool?,
      isResolved: json['isResolved'] as bool?,
      dateFrom: json['dateFrom'] == null
          ? null
          : DateTime.parse(json['dateFrom'] as String),
      dateTo: json['dateTo'] == null
          ? null
          : DateTime.parse(json['dateTo'] as String),
    );

Map<String, dynamic> _$QAFilterModelToJson(QAFilterModel instance) =>
    <String, dynamic>{
      'searchQuery': instance.searchQuery,
      'filterBy': instance.filterBy,
      'sortBy': instance.sortBy,
      'courseId': instance.courseId,
      'authorId': instance.authorId,
      'isAnswered': instance.isAnswered,
      'isResolved': instance.isResolved,
      'dateFrom': instance.dateFrom?.toIso8601String(),
      'dateTo': instance.dateTo?.toIso8601String(),
    };

CreateQuestionModel _$CreateQuestionModelFromJson(Map<String, dynamic> json) =>
    CreateQuestionModel(
      title: json['title'] as String,
      content: json['content'] as String,
      courseId: json['courseId'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$CreateQuestionModelToJson(
  CreateQuestionModel instance,
) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
      'courseId': instance.courseId,
      'tags': instance.tags,
    };

CreateAnswerModel _$CreateAnswerModelFromJson(Map<String, dynamic> json) =>
    CreateAnswerModel(
      questionId: json['questionId'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$CreateAnswerModelToJson(CreateAnswerModel instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'content': instance.content,
    };
