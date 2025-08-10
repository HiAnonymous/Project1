import 'package:flutter/material.dart';
import 'package:insightquill/models/user.dart';
import 'package:insightquill/models/quiz.dart';
import 'package:insightquill/services/auth_service.dart';
import 'package:insightquill/services/database_service.dart';
import 'package:insightquill/models/feedback.dart' as feedback_model;

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

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
      _setError('Failed to initialize app: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String identifier, UserRole role) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('AppProvider: Starting login process for $identifier');
      final success = await _authService.login(identifier, role);
      print('AppProvider: Auth service returned: $success');
      
      if (success) {
        print('AppProvider: Loading user data...');
        await _loadUserData();
        print('AppProvider: User data loaded, notifying listeners');
        notifyListeners();
        print('AppProvider: Login successful, returning true');
        return true;
      } else {
        print('AppProvider: Login failed, setting error');
        _setError('Invalid credentials');
        return false;
      }
    } catch (e) {
      print('AppProvider: Login exception: $e');
      _setError('Login failed: $e');
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
    if (currentUser == null) {
      print('AppProvider: _loadUserData called but currentUser is null');
      return;
    }

    try {
      print('AppProvider: Loading user data for user: ${currentUser!.registrationNumber} with role: ${currentUser!.role}');
      if (currentUser!.role == UserRole.student) {
        print('AppProvider: Loading student quizzes...');
        _activeQuizzes = await _databaseService.getActiveQuizzesForStudent(currentUser!.id);
        print('AppProvider: Loaded ${_activeQuizzes.length} student quizzes');
      } else {
        print('AppProvider: Loading faculty quizzes...');
        // Fetch the faculty profile to get the faculty document ID
        final faculty = await _databaseService.getFacultyByUserId(currentUser!.id);
        if (faculty == null) {
          print('AppProvider: No faculty profile found for user ${currentUser!.id}');
          _activeQuizzes = [];
        } else {
          _activeQuizzes = await _databaseService.getQuizzesByFaculty(faculty.id);
        }
        print('AppProvider: Loaded ${_activeQuizzes.length} faculty quizzes');
      }
      print('AppProvider: User data loaded successfully');
    } catch (e) {
      print('AppProvider: Error loading user data: $e');
      _setError('Failed to load user data: $e');
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
  void createQuiz(Quiz quiz) async {
    try {
      // TODO: Implement quiz creation in database service
      refreshQuizzes();
    } catch (e) {
      _setError('Failed to create quiz: $e');
    }
  }

  void updateQuiz(Quiz quiz) async {
    try {
      // TODO: Implement quiz update in database service
      refreshQuizzes();
    } catch (e) {
      _setError('Failed to update quiz: $e');
    }
  }

  void submitQuiz(QuizSubmission submission) async {
    try {
      await _databaseService.submitQuiz(submission);
      notifyListeners();
    } catch (e) {
      _setError('Failed to submit quiz: $e');
    }
  }

  void submitFeedback(feedback_model.LectureFeedback feedback) async {
    try {
      await _databaseService.submitFeedback(feedback);
      notifyListeners();
    } catch (e) {
      _setError('Failed to submit feedback: $e');
    }
  }
}