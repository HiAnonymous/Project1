import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:insightquill/services/database_service.dart';
import 'package:insightquill/models/quiz.dart';
import 'package:insightquill/models/user.dart';
import 'package:insightquill/models/course.dart';

class QuizAnalyticsPage extends StatefulWidget {
  final Quiz quiz;

  const QuizAnalyticsPage({super.key, required this.quiz});

  @override
  State<QuizAnalyticsPage> createState() => _QuizAnalyticsPageState();
}

class _QuizAnalyticsPageState extends State<QuizAnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dataService = DatabaseService();

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
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchOverviewData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildNoDataWidget('No submissions yet', theme);
        }

        final submissions = snapshot.data!['submissions'] as List<StudentQuizResult>;
        final course = snapshot.data!['course'] as Course?;
        
        if (submissions.isEmpty) {
          return _buildNoDataWidget('No submissions yet', theme);
        }

        final averageScore = submissions.fold<double>(0, (sum, s) => sum + s.score) / submissions.length;
        final averagePercentage = submissions.fold<double>(0, (sum, s) => sum + s.percentageScore) / submissions.length;
        
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
      },
    );
  }

  Future<Map<String, dynamic>> _fetchOverviewData() async {
    final submissions = await _dataService.getSubmissionsByQuiz(widget.quiz.id);
    final timetables = await _dataService.getTimetableByFaculty(widget.quiz.createdBy);
    final timetable = timetables.firstWhere((t) => t.id == widget.quiz.timetableId);
    final course = await _dataService.getCourseById(timetable.courseId);
    return {
      'submissions': submissions,
      'course': course,
    };
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
              widget.quiz.quizTitle,
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
                _buildInfoChip('10 Questions', Icons.quiz, theme),
                const SizedBox(width: 12),
                _buildInfoChip('7 mins', Icons.timer, theme),
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

  Widget _buildStatsOverview(List<StudentQuizResult> submissions, double averageScore, double averagePercentage, ThemeData theme) {
    final highScorers = submissions.where((s) => s.percentageScore >= 80).length;
    final mediumScorers = submissions.where((s) => s.percentageScore >= 60 && s.percentageScore < 80).length;
    final lowScorers = submissions.where((s) => s.percentageScore < 60).length;

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

  Widget _buildSubmissionsList(List<StudentQuizResult> submissions, ThemeData theme) {
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
              return FutureBuilder<Student?>(
                future: _dataService.getStudentById(submission.studentId),
                builder: (context, studentSnapshot) {
                  if (studentSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                        height: 78,
                        child: Center(child: CircularProgressIndicator.adaptive()));
                  }
                  final student = studentSnapshot.data;
                  return _buildSubmissionItem(submission, student, theme);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionItem(StudentQuizResult submission, Student? student, ThemeData theme) {
    final isGoodScore = submission.percentageScore >= 60;
    final studentName = student != null ? "${student.firstName} ${student.lastName}" : "Unknown";
    
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
              '${submission.percentageScore.toStringAsFixed(1)}%',
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
    return FutureBuilder<List<StudentQuizResult>>(
      future: _dataService.getSubmissionsByQuiz(widget.quiz.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoDataWidget('No performance data available', theme);
        }

        final submissions = snapshot.data!;

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
      },
    );
  }

  Widget _buildPerformanceChart(List<StudentQuizResult> submissions, ThemeData theme) {
    final sortedSubmissions = List<StudentQuizResult>.from(submissions)
      ..sort((a, b) => b.percentageScore.compareTo(a.percentageScore));

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
              return FutureBuilder<Student?>(
                future: _dataService.getStudentById(submission.studentId),
                builder: (context, studentSnapshot) {
                  if (studentSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                        height: 54,
                        child: Center(child: CircularProgressIndicator.adaptive()));
                  }
                  final student = studentSnapshot.data;
                  return _buildRankingItem(index + 1, student, submission, theme);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(int rank, Student? student, StudentQuizResult submission, ThemeData theme) {
    final isTopThree = rank <= 3;
    final studentName = student != null ? "${student.firstName} ${student.lastName}" : "Unknown";
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
            '${submission.score.toInt()}/10', // Placeholder
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: submission.percentageScore >= 80 
                  ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
                  : submission.percentageScore >= 60
                      ? Colors.orange.withValues(alpha: 0.2)
                      : theme.colorScheme.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${submission.percentageScore.toStringAsFixed(1)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: submission.percentageScore >= 80 
                    ? theme.colorScheme.tertiary
                    : submission.percentageScore >= 60
                        ? Colors.orange
                        : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(List<StudentQuizResult> submissions, ThemeData theme) {
    final topPerformers = submissions.where((s) => s.percentageScore >= 80).toList()
      ..sort((a, b) => b.percentageScore.compareTo(a.percentageScore));

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
                return FutureBuilder<Student?>(
                    future: _dataService.getStudentById(submission.studentId),
                    builder: (context, studentSnapshot) {
                      if (studentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox(
                            height: 44,
                            child: Center(
                                child: CircularProgressIndicator.adaptive()));
                      }
                      final student = studentSnapshot.data;
                      return _buildTopPerformerItem(student, submission, theme);
                    });
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformerItem(Student? student, StudentQuizResult submission, ThemeData theme) {
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
              student != null ? "${student.firstName} ${student.lastName}" : "Unknown",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${submission.percentageScore.toStringAsFixed(1)}%',
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
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _dataService.getSubmissionsByQuiz(widget.quiz.id),
        _dataService.getQuestionsForQuiz(widget.quiz.id),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return _buildNoDataWidget('No question analysis available', theme);
        }

        final submissions = snapshot.data![0] as List<StudentQuizResult>;
        final questions = snapshot.data![1] as List<QuizQuestion>;

        if (submissions.isEmpty) {
          return _buildNoDataWidget('No question analysis available', theme);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return _buildQuestionAnalysis(question, index, submissions, theme);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildQuestionAnalysis(QuizQuestion question, int index, List<StudentQuizResult> submissions, ThemeData theme) {
    // This logic needs to be re-implemented as we don't have individual answers.
    // For now, returning a placeholder.
    final double accuracy = 0;

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
                    question.questionText,
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
              'Accuracy: 0/0 students answered correctly',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Correct Answer: A. ${question.options[0]}', // Placeholder
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