import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:insightquill/providers/app_provider.dart';
import 'package:insightquill/services/database_service.dart';

import 'package:insightquill/models/quiz.dart';
import 'package:insightquill/screens/feedback_page.dart';

class QuizTakingPage extends StatefulWidget {
  final Quiz quiz;

  const QuizTakingPage({super.key, required this.quiz});

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> with WidgetsBindingObserver {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;
  int _currentQuestionIndex = 0;
  Map<String, int> _answers = {};
  bool _isSubmitting = false;
  bool _hasLeftApp = false;
  final DatabaseService _dataService = DatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTimer();
    _enableKioskMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _disableKioskMode();
    super.dispose();
  }

  Future<void> _initializeTimer() async {
    // Prefer active session end time. Fallback to scheduledAt + duration.
    DateTime now = DateTime.now();
    DateTime? end;
    try {
      final latest = await _dataService.getLatestSessionForQuiz(widget.quiz.id);
      if (latest != null) {
        end = latest.endTime;
      } else if (widget.quiz.scheduledAt != null) {
        end = widget.quiz.scheduledAt!.add(Duration(minutes: widget.quiz.duration));
      }
    } catch (_) {}

    if (end == null) {
      // Default to quiz duration from now if no timing info is available
      _timeRemaining = Duration(minutes: widget.quiz.duration);
    } else {
      final diff = end.difference(now);
      _timeRemaining = diff.isNegative ? Duration.zero : diff;
    }
    if (mounted) {
      setState(() {});
      _startTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      setState(() => _hasLeftApp = true);
      _showAntiCheatWarning();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining -= const Duration(seconds: 1);
        });
      } else {
        _autoSubmitQuiz();
      }
    });
  }

  void _enableKioskMode() {
    // Simulate enabling kiosk mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _disableKioskMode() {
    // Restore normal system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitWarning();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.quiz.quizTitle,
            style: TextStyle(color: theme.colorScheme.onError),
          ),
          backgroundColor: theme.colorScheme.error,
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
            TextButton.icon(
              onPressed: _onStopPressed,
              icon: Icon(Icons.stop, color: theme.colorScheme.onError),
              label: Text(
                'Stop',
                style: TextStyle(color: theme.colorScheme.onError, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    color: theme.colorScheme.onError,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeRemaining),
                    style: TextStyle(
                      color: theme.colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.error.withValues(alpha: 0.1),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              _buildQuizHeader(theme),
              _buildAntiCheatWarning(theme),
              Expanded(child: _buildQuestionCard(theme)),
              _buildNavigationControls(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizHeader(ThemeData theme) {
    final totalQuestions = widget.quiz.questions.length;
    final progress = totalQuestions == 0
        ? 0.0
        : (_currentQuestionIndex + 1) / totalQuestions;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalQuestions == 0
                    ? 'No questions'
                    : 'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                totalQuestions == 0
                    ? '0 answered'
                    : '${_answers.length}/$totalQuestions Answered',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildAntiCheatWarning(ThemeData theme) {
    if (!_hasLeftApp) return const SizedBox();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: theme.colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Warning: App switching detected. This may be considered cheating.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(ThemeData theme) {
    final totalQuestions = widget.quiz.questions.length;
    if (totalQuestions == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'This quiz has no questions.',
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    final question = widget.quiz.questions[_currentQuestionIndex];
    final selectedAnswer = _answers[question.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_currentQuestionIndex + 1}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.text,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ...question.options.asMap().entries.map((entry) {
                final optionIndex = entry.key;
                final optionText = entry.value;
                final isSelected = selectedAnswer == optionIndex;

                return GestureDetector(
                  onTap: () => _selectAnswer(question.id, optionIndex),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            border: Border.all(
                              color: isSelected 
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: isSelected 
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          String.fromCharCode(65 + optionIndex),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            optionText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isSelected ? theme.colorScheme.primary : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationControls(ThemeData theme) {
    final totalQuestions = widget.quiz.questions.length; 
    final isLastQuestion = _currentQuestionIndex == totalQuestions - 1;
    final canSubmit = _answers.length == totalQuestions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentQuestionIndex--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: totalQuestions == 0
                ? null
                : isLastQuestion 
                  ? (canSubmit && !_isSubmitting ? _submitQuiz : null)
                  : () => setState(() => _currentQuestionIndex++),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastQuestion 
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
                foregroundColor: isLastQuestion 
                    ? theme.colorScheme.onTertiary
                    : theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting 
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onTertiary,
                    ),
                  )
                : Text(
                    isLastQuestion ? 'Submit Quiz' : 'Next',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLastQuestion 
                          ? theme.colorScheme.onTertiary
                          : theme.colorScheme.onPrimary,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(String questionId, int answerIndex) {
    setState(() {
      _answers[questionId] = answerIndex;
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  void _submitQuiz() async {
    if (_answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer at least one question')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Calculate score
      int correctAnswers = 0;
      for (final entry in _answers.entries) {
        final question = widget.quiz.questions.firstWhere((q) => q.id == entry.key);
        if (entry.value == question.correctAnswer) {
          correctAnswers++;
        }
      }

      final score = correctAnswers;
      final totalQuestions = widget.quiz.questions.length;

      final submission = QuizSubmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        quizId: widget.quiz.id,
        studentId: Provider.of<AppProvider>(context, listen: false).currentUser!.id,
        answers: _answers,
        submittedAt: DateTime.now(),
        score: score,
        totalQuestions: totalQuestions,
      );

      Provider.of<AppProvider>(context, listen: false).submitQuiz(submission);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FeedbackPage(quiz: widget.quiz),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting quiz: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _finalizeQuizEarlyWithPopup() async {
    if (_isSubmitting) return;
    _timer.cancel();
    setState(() => _isSubmitting = true);

    try {
      // Compute score with whatever answers are present
      int correctAnswers = 0;
      for (final entry in _answers.entries) {
        final question = widget.quiz.questions.firstWhere((q) => q.id == entry.key);
        if (entry.value == question.correctAnswer) {
          correctAnswers++;
        }
      }

      final totalQuestions = widget.quiz.questions.length;
      final submission = QuizSubmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        quizId: widget.quiz.id,
        studentId: Provider.of<AppProvider>(context, listen: false).currentUser!.id,
        answers: _answers,
        submittedAt: DateTime.now(),
        score: correctAnswers,
        totalQuestions: totalQuestions,
      );

      Provider.of<AppProvider>(context, listen: false).submitQuiz(submission);

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Quiz Ended'),
          content: const Text('Your responses have been submitted.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => FeedbackPage(quiz: widget.quiz)),
                );
              },
              child: const Text('View Feedback'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end quiz: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _onStopPressed() {
    if (_isSubmitting) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Quiz?'),
        content: const Text('Are you sure you want to end the quiz now? You won\'t be able to change your answers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _finalizeQuizEarlyWithPopup();
            },
            child: const Text('End Now'),
          ),
        ],
      ),
    );
  }

  void _autoSubmitQuiz() {
    _timer.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time\'s up! Quiz submitted automatically.')),
    );
    _submitQuiz();
  }



  void _showExitWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Are you sure you want to exit? Your progress will be lost and this may be considered as cheating.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Quiz'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Exit quiz
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showAntiCheatWarning() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Warning: Leaving the app during quiz is not allowed!'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}