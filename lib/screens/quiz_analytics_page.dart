import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:insightquill/services/data_service.dart';
import 'package:insightquill/models/quiz.dart';

class QuizAnalyticsPage extends StatefulWidget {
  final Quiz quiz;

  const QuizAnalyticsPage({super.key, required this.quiz});

  @override
  State<QuizAnalyticsPage> createState() => _QuizAnalyticsPageState();
}

class _QuizAnalyticsPageState extends State<QuizAnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz Analytics',
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Performance'),
            Tab(text: 'Questions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme),
          _buildPerformanceTab(theme),
          _buildQuestionsTab(theme),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    final submissions = _dataService.getSubmissionsByQuiz(widget.quiz.id);
    final course = _dataService.getCourseById(widget.quiz.courseId);
    
    if (submissions.isEmpty) {
      return _buildNoDataWidget('No submissions yet', theme);
    }

    final averageScore = submissions.fold<double>(0, (sum, s) => sum + s.score) / submissions.length;
    final averagePercentage = submissions.fold<double>(0, (sum, s) => sum + s.percentage) / submissions.length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuizInfoCard(course, theme),
          const SizedBox(height: 20),
          _buildStatsOverview(submissions, averageScore, averagePercentage, theme),
          const SizedBox(height: 20),
          _buildSubmissionsList(submissions, theme),
        ],
      ),
    );
  }

  Widget _buildQuizInfoCard(course, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.quiz.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course?.name ?? 'Unknown Course',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip('${widget.quiz.questions.length} Questions', Icons.quiz, theme),
                const SizedBox(width: 12),
                _buildInfoChip('${widget.quiz.duration} mins', Icons.timer, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(List<QuizSubmission> submissions, double averageScore, double averagePercentage, ThemeData theme) {
    final highScorers = submissions.where((s) => s.percentage >= 80).length;
    final mediumScorers = submissions.where((s) => s.percentage >= 60 && s.percentage < 80).length;
    final lowScorers = submissions.where((s) => s.percentage < 60).length;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Submissions',
                    submissions.length.toString(),
                    Icons.assignment_turned_in,
                    theme.colorScheme.primary,
                    theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Average Score',
                    '${averagePercentage.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    theme.colorScheme.secondary,
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Score Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildScoreDistribution(highScorers, mediumScorers, lowScorers, submissions.length, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistribution(int high, int medium, int low, int total, ThemeData theme) {
    if (total == 0) return const SizedBox();

    return Column(
      children: [
        _buildDistributionBar('Excellent (80-100%)', high, total, theme.colorScheme.tertiary, theme),
        const SizedBox(height: 8),
        _buildDistributionBar('Good (60-79%)', medium, total, Colors.orange, theme),
        const SizedBox(height: 8),
        _buildDistributionBar('Needs Improvement (<60%)', low, total, theme.colorScheme.error, theme),
      ],
    );
  }

  Widget _buildDistributionBar(String label, int count, int total, Color color, ThemeData theme) {
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildSubmissionsList(List<QuizSubmission> submissions, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Submissions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...submissions.take(5).map((submission) {
              final student = _dataService.getUserById(submission.studentId);
              return _buildSubmissionItem(submission, student?.name ?? 'Unknown', theme);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionItem(QuizSubmission submission, String studentName, ThemeData theme) {
    final isGoodScore = submission.percentage >= 60;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isGoodScore 
                ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
                : theme.colorScheme.error.withValues(alpha: 0.2),
            child: Text(
              studentName.split(' ').map((n) => n[0]).take(2).join(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isGoodScore ? theme.colorScheme.tertiary : theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(submission.submittedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isGoodScore 
                  ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
                  : theme.colorScheme.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${submission.percentage.toStringAsFixed(1)}%',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isGoodScore ? theme.colorScheme.tertiary : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(ThemeData theme) {
    final submissions = _dataService.getSubmissionsByQuiz(widget.quiz.id);
    
    if (submissions.isEmpty) {
      return _buildNoDataWidget('No performance data available', theme);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceChart(submissions, theme),
          const SizedBox(height: 20),
          _buildTopPerformers(submissions, theme),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(List<QuizSubmission> submissions, ThemeData theme) {
    final sortedSubmissions = List<QuizSubmission>.from(submissions)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Ranking',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...sortedSubmissions.asMap().entries.take(10).map((entry) {
              final index = entry.key;
              final submission = entry.value;
              final student = _dataService.getUserById(submission.studentId);
              return _buildRankingItem(index + 1, student?.name ?? 'Unknown', submission, theme);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(int rank, String studentName, QuizSubmission submission, ThemeData theme) {
    final isTopThree = rank <= 3;
    final rankColor = rank == 1 
        ? Colors.amber 
        : rank == 2 
            ? Colors.grey[400]! 
            : rank == 3 
                ? Colors.brown[400]! 
                : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTopThree 
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isTopThree 
            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isTopThree ? rankColor : Colors.transparent,
              shape: BoxShape.circle,
              border: isTopThree ? null : Border.all(color: rankColor),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isTopThree ? Colors.white : rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              studentName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${submission.score}/${submission.totalQuestions}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: submission.percentage >= 80 
                  ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
                  : submission.percentage >= 60
                      ? Colors.orange.withValues(alpha: 0.2)
                      : theme.colorScheme.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${submission.percentage.toStringAsFixed(1)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: submission.percentage >= 80 
                    ? theme.colorScheme.tertiary
                    : submission.percentage >= 60
                        ? Colors.orange
                        : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(List<QuizSubmission> submissions, ThemeData theme) {
    final topPerformers = submissions.where((s) => s.percentage >= 80).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    return Card(
      elevation: 0,
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Top Performers (80%+)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topPerformers.isEmpty)
              Text(
                'No students scored above 80%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            else
              ...topPerformers.take(5).map((submission) {
                final student = _dataService.getUserById(submission.studentId);
                return _buildTopPerformerItem(student?.name ?? 'Unknown', submission, theme);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformerItem(String studentName, QuizSubmission submission, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              studentName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${submission.percentage.toStringAsFixed(1)}%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab(ThemeData theme) {
    final submissions = _dataService.getSubmissionsByQuiz(widget.quiz.id);
    
    if (submissions.isEmpty) {
      return _buildNoDataWidget('No question analysis available', theme);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.quiz.questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return _buildQuestionAnalysis(question, index, submissions, theme);
        }).toList(),
      ),
    );
  }

  Widget _buildQuestionAnalysis(Question question, int index, List<QuizSubmission> submissions, ThemeData theme) {
    final correctAnswers = submissions.where((s) => s.answers[question.id] == question.correctAnswer).length;
    final accuracy = submissions.isNotEmpty ? (correctAnswers / submissions.length) * 100 : 0.0;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accuracy >= 70 
                        ? theme.colorScheme.tertiary
                        : accuracy >= 50
                            ? Colors.orange
                            : theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accuracy >= 70 
                        ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
                        : accuracy >= 50
                            ? Colors.orange.withValues(alpha: 0.2)
                            : theme.colorScheme.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${accuracy.toStringAsFixed(1)}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accuracy >= 70 
                          ? theme.colorScheme.tertiary
                          : accuracy >= 50
                              ? Colors.orange
                              : theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Accuracy: $correctAnswers/${submissions.length} students answered correctly',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Correct Answer: ${String.fromCharCode(65 + question.correctAnswer)}. ${question.options[question.correctAnswer]}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget(String message, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}