import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:insightquill/providers/app_provider.dart';
import 'package:insightquill/services/database_service.dart';
import 'package:insightquill/models/quiz.dart';
import 'package:insightquill/models/feedback.dart' as feedback_model;
import 'package:insightquill/models/course.dart';
import 'package:insightquill/models/user.dart';

class FeedbackPage extends StatefulWidget {
  final Quiz quiz;
  final StudentQuizResult? submission;

  const FeedbackPage({
    super.key,
    required this.quiz,
    this.submission,
  });

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with TickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _cardAnimation;
  
  int _rating = 0;
  final _commentController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _isSubmitting = false;
  bool _feedbackSubmitted = false;

  @override
  void initState() {
    super.initState();
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.submission?.percentageScore ?? 0.0) / 100,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scoreAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        _cardAnimationController.forward();
      });
    });
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    _cardAnimationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchFeedbackData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text('No data found.')));
        }

        final course = snapshot.data!['course'] as Course?;
        final faculty = snapshot.data!['faculty'] as Faculty?;
        final title = widget.quiz.quizTitle;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildResultsCard(theme, title),
                    const SizedBox(height: 32),
                    AnimatedBuilder(
                      animation: _cardAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _cardAnimation.value,
                        child: child,
                      ),
                      child: _buildFeedbackCard(course, faculty, theme),
                    ),
                    const SizedBox(height: 24),
                    _buildSubmitButton(theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchFeedbackData() async {
    final timetables = await _databaseService.getTimetableByFaculty(widget.quiz.createdBy);
    final timetable = timetables.firstWhere((t) => t.id == widget.quiz.timetableId);
    final course = await _databaseService.getCourseById(timetable.courseId);
    final faculty = course != null ? await _databaseService.getFacultyById(course.facultyId) : null;
    return {
      'course': course,
      'faculty': faculty,
    };
  }

  Widget _buildResultsCard(ThemeData theme, String title) {
    final percentage = widget.submission?.percentageScore ?? 0.0;
    final isGoodScore = percentage >= 60;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isGoodScore
                ? [
                    theme.colorScheme.tertiary.withAlpha(25),
                    theme.colorScheme.tertiary.withAlpha(12),
                  ]
                : [
                    theme.colorScheme.error.withAlpha(25),
                    theme.colorScheme.error.withAlpha(12),
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                isGoodScore ? Icons.celebration : Icons.sentiment_neutral,
                size: 48,
                color: isGoodScore ? theme.colorScheme.tertiary : theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Quiz Completed!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isGoodScore ? theme.colorScheme.tertiary : theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<QuizQuestion>>(
                future: _databaseService.getQuestionsForQuiz(widget.quiz.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text('No questions found.'));
                  }

                  final questions = snapshot.data!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreInfo('Score', '${widget.submission?.score.toInt() ?? 0}/${questions.length}', theme),
                      Container(
                        width: 1,
                        height: 40,
                        color: theme.colorScheme.outline.withAlpha(75),
                      ),
                      _buildScoreInfo('Percentage', '${percentage.toStringAsFixed(1)}%', theme),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) => Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _scoreAnimation.value,
                          strokeWidth: 8,
                          backgroundColor: theme.colorScheme.outline.withAlpha(50),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isGoodScore ? theme.colorScheme.tertiary : theme.colorScheme.error,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_scoreAnimation.value * 100).toInt()}%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isGoodScore ? theme.colorScheme.tertiary : theme.colorScheme.error,
                            ),
                          ),
                          Text(
                            isGoodScore ? 'Well Done!' : 'Keep Trying!',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(175),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreInfo(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(175),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(course, faculty, ThemeData theme) {
    if (_feedbackSubmitted) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you for your feedback!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your feedback helps improve the learning experience.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(175),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.feedback,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate this lecture',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${course?.name ?? 'Unknown Course'} by ${faculty?.firstName ?? ''} ${faculty?.lastName ?? ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(175),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'How would you rate this lecture?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: index < _rating 
                          ? Colors.amber
                          : theme.colorScheme.outline,
                    ),
                  ),
                );
              }),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getRatingText(_rating),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Additional Comments (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your thoughts about the lecture, teaching style, or suggestions for improvement...',
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withAlpha(75),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    if (_feedbackSubmitted) return const SizedBox();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _rating > 0 && !_isSubmitting ? _submitFeedback : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.tertiary,
          foregroundColor: theme.colorScheme.onTertiary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send,
                    color: theme.colorScheme.onTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Submit Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onTertiary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  void _submitFeedback() async {
    if (_rating == 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final feedback = feedback_model.LectureFeedback(
      id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
      studentId: Provider.of<AppProvider>(context, listen: false).currentUser!.id,
      sessionId: widget.submission?.sessionId ?? widget.quiz.id,
      rating: _rating,
      comments: _commentController.text.trim(),
      submittedAt: DateTime.now(),
    );

    await _databaseService.submitFeedback(feedback);

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    setState(() {
      _isSubmitting = false;
      _feedbackSubmitted = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Feedback submitted successfully!'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    }
  }
}