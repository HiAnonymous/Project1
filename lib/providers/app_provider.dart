import 'package:flutter/material.dart';
import 'package:insightquill/models/user.dart';
import 'package:insightquill/models/quiz.dart';
import 'package:insightquill/services/auth_service.dart';
import 'package:insightquill/services/data_service.dart';
import 'package:insightquill/models/feedback.dart' as feedback_model;

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DataService _dataService = DataService();

  User? get currentUser => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;

  List<Quiz> _activeQuizzes = [];
  List<Quiz> get activeQuizzes => _activeQuizzes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _authService.loadUserSession();
      if (isLoggedIn) {
        await _loadUserData();
      }
    } catch (e) {
      _setError('Failed to initialize app: \$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String identifier, UserRole role) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _authService.login(identifier, role);
      if (success) {
        await _loadUserData();
        notifyListeners();
        return true;
      } else {
        _setError('Invalid credentials');
        return false;
      }
    } catch (e) {
      _setError('Login failed: \$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _activeQuizzes.clear();
    _clearError();
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;

    if (currentUser!.role == UserRole.student) {
      _activeQuizzes = _dataService.getActiveQuizzesForStudent(currentUser!.id);
    } else {
      _activeQuizzes = _dataService.getQuizzesByFaculty(currentUser!.id);
    }
  }

  void refreshQuizzes() async {
    await _loadUserData();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Quiz-specific methods
  void createQuiz(Quiz quiz) {
    _dataService.createQuiz(quiz);
    refreshQuizzes();
  }

  void updateQuiz(Quiz quiz) {
    _dataService.updateQuiz(quiz);
    refreshQuizzes();
  }

  void submitQuiz(QuizSubmission submission) {
    _dataService.submitQuiz(submission);
    notifyListeners();
  }

  void submitFeedback(feedback_model.Feedback feedback) {
    _dataService.submitFeedback(feedback);
    notifyListeners();
  }
}