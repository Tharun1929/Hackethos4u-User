import 'package:flutter/material.dart';
import 'qa_model.dart';
import '../../api/qa_api.dart';

class QAViewModel extends ChangeNotifier {
  List<QuestionModel> _questions = [];
  List<QuestionModel> _filteredQuestions = [];
  QuestionModel? _selectedQuestion;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _error = '';
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Filter and search state
  QAFilterModel? _currentFilter;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Recent';

  // Form controllers
  final TextEditingController questionTitleController = TextEditingController();
  final TextEditingController questionContentController =
      TextEditingController();
  final TextEditingController answerContentController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Getters
  List<QuestionModel> get questions => _questions;
  List<QuestionModel> get filteredQuestions => _filteredQuestions;
  QuestionModel? get selectedQuestion => _selectedQuestion;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get error => _error;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  String get selectedSort => _selectedSort;
  QAFilterModel? get currentFilter => _currentFilter;

  // Filter options
  static const List<String> filterOptions = [
    'All',
    'Unanswered',
    'Answered',
    'My Questions',
    'Resolved',
    'Unresolved',
  ];

  static const List<String> sortOptions = [
    'Recent',
    'Most Votes',
    'Most Answers',
    'Oldest',
    'Most Viewed',
  ];

  @override
  void dispose() {
    questionTitleController.dispose();
    questionContentController.dispose();
    answerContentController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Load questions with optional filter
  Future<void> loadQuestions({
    QAFilterModel? filter,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _questions.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final newQuestions = await QAApi.getQuestions(
        filter: filter ?? _currentFilter,
        page: _currentPage,
        limit: 20,
      );

      if (refresh) {
        _questions = newQuestions;
      } else {
        _questions.addAll(newQuestions);
      }

      _hasMoreData = newQuestions.length == 20;
      _currentPage++;
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more questions (pagination)
  Future<void> loadMoreQuestions() async {
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final newQuestions = await QAApi.getQuestions(
        filter: _currentFilter,
        page: _currentPage,
        limit: 20,
      );

      _questions.addAll(newQuestions);
      _hasMoreData = newQuestions.length == 20;
      _currentPage++;
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Load specific question with answers
  Future<void> loadQuestionById(String questionId) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _selectedQuestion = await QAApi.getQuestionById(questionId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new question
  Future<bool> createQuestion({
    required String title,
    required String content,
    required String courseId,
    List<String> tags = const [],
  }) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final newQuestion = CreateQuestionModel(
        title: title,
        content: content,
        courseId: courseId,
        tags: tags,
      );

      final createdQuestion = await QAApi.createQuestion(newQuestion);

      // Add to the beginning of the list
      _questions.insert(0, createdQuestion);
      _applyFilters();

      // Clear form
      questionTitleController.clear();
      questionContentController.clear();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create answer
  Future<bool> createAnswer({
    required String questionId,
    required String content,
  }) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final newAnswer = CreateAnswerModel(
        questionId: questionId,
        content: content,
      );

      final createdAnswer = await QAApi.createAnswer(newAnswer);

      // Update the question with the new answer
      final questionIndex = _questions.indexWhere((q) => q.id == questionId);
      if (questionIndex != -1) {
        final updatedAnswers =
            List<AnswerModel>.from(_questions[questionIndex].answers)
              ..add(createdAnswer);
        final updatedQuestion = _questions[questionIndex].copyWith(
          answers: updatedAnswers,
          answerCount: _questions[questionIndex].answerCount + 1,
          isAnswered: true,
        );
        _questions[questionIndex] = updatedQuestion;

        // Update selected question if it's the same
        if (_selectedQuestion?.id == questionId) {
          _selectedQuestion = updatedQuestion;
        }
      }

      _applyFilters();
      answerContentController.clear();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vote on question
  Future<void> voteQuestion(String questionId, bool isUpvote) async {
    try {
      final success = await QAApi.voteQuestion(questionId, isUpvote);
      if (success) {
        final questionIndex = _questions.indexWhere((q) => q.id == questionId);
        if (questionIndex != -1) {
          final currentVotes = _questions[questionIndex].votes;
          _questions[questionIndex] = _questions[questionIndex].copyWith(
            votes: currentVotes + (isUpvote ? 1 : -1),
          );

          // Update selected question if it's the same
          if (_selectedQuestion?.id == questionId) {
            _selectedQuestion = _selectedQuestion!.copyWith(
              votes: currentVotes + (isUpvote ? 1 : -1),
            );
          }
        }
        _applyFilters();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Vote on answer
  Future<void> voteAnswer(String answerId, bool isUpvote) async {
    try {
      final success = await QAApi.voteAnswer(answerId, isUpvote);
      if (success) {
        // Update answer votes in all questions
        for (int i = 0; i < _questions.length; i++) {
          final answerIndex =
              _questions[i].answers.indexWhere((a) => a.id == answerId);
          if (answerIndex != -1) {
            final currentVotes = _questions[i].answers[answerIndex].votes;
            final updatedAnswer = _questions[i].answers[answerIndex].copyWith(
                  votes: currentVotes + (isUpvote ? 1 : -1),
                );

            final updatedAnswers =
                List<AnswerModel>.from(_questions[i].answers);
            updatedAnswers[answerIndex] = updatedAnswer;

            _questions[i] = _questions[i].copyWith(answers: updatedAnswers);

            // Update selected question if it's the same
            if (_selectedQuestion?.id == _questions[i].id) {
              _selectedQuestion =
                  _selectedQuestion!.copyWith(answers: updatedAnswers);
            }
            break;
          }
        }
        _applyFilters();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Accept answer
  Future<void> acceptAnswer(String answerId) async {
    try {
      final success = await QAApi.acceptAnswer(answerId);
      if (success) {
        // Update answer in all questions
        for (int i = 0; i < _questions.length; i++) {
          final answerIndex =
              _questions[i].answers.indexWhere((a) => a.id == answerId);
          if (answerIndex != -1) {
            final updatedAnswers =
                _questions[i].answers.map<AnswerModel>((answer) {
              if (answer.id == answerId) {
                return answer.copyWith(isAccepted: true, isBestAnswer: true);
              } else {
                return answer.copyWith(isBestAnswer: false);
              }
            }).toList();

            _questions[i] = _questions[i].copyWith(
              answers: updatedAnswers,
              isResolved: true,
            );

            // Update selected question if it's the same
            if (_selectedQuestion?.id == _questions[i].id) {
              _selectedQuestion = _selectedQuestion!.copyWith(
                answers: updatedAnswers,
                isResolved: true,
              );
            }
            break;
          }
        }
        _applyFilters();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Set filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
  }

  // Set sort
  void setSort(String sort) {
    _selectedSort = sort;
    _applyFilters();
  }

  // Apply filters and search
  void _applyFilters() {
    List<QuestionModel> filtered = List.from(_questions);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((q) =>
              q.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              q.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              q.authorName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply category filter
    switch (_selectedFilter) {
      case 'Unanswered':
        filtered = filtered.where((q) => !q.isAnswered).toList();
        break;
      case 'Answered':
        filtered = filtered.where((q) => q.isAnswered).toList();
        break;
      case 'Resolved':
        filtered = filtered.where((q) => q.isResolved).toList();
        break;
      case 'Unresolved':
        filtered = filtered.where((q) => !q.isResolved).toList();
        break;
      case 'My Questions':
        // This would need user ID from auth service
        // filtered = filtered.where((q) => q.authorId == currentUserId).toList();
        break;
    }

    // Apply sort
    switch (_selectedSort) {
      case 'Most Votes':
        filtered.sort((a, b) => b.votes.compareTo(a.votes));
        break;
      case 'Most Answers':
        filtered.sort((a, b) => b.answerCount.compareTo(a.answerCount));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Most Viewed':
        // This would need view count field
        break;
      case 'Recent':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    _filteredQuestions = filtered;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Clear selected question
  void clearSelectedQuestion() {
    _selectedQuestion = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadQuestions(refresh: true);
  }
}
