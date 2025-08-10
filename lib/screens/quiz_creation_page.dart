import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:insightquill/providers/app_provider.dart';
import 'package:insightquill/services/database_service.dart';
import 'package:insightquill/models/course.dart';
import 'package:insightquill/models/quiz.dart';
import 'package:insightquill/models/question.dart';
// Attendance upload removed from this screen


class QuizCreationPage extends StatefulWidget {
  const QuizCreationPage({super.key});

  @override
  State<QuizCreationPage> createState() => _QuizCreationPageState();
}

class _QuizCreationPageState extends State<QuizCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final DatabaseService _dataService = DatabaseService();
  
  String? _selectedCourseId;
  String? _selectedCourseLabel;
  List<Question> _questions = [];
  int _currentStep = 0;
  // Attendance upload removed from quiz flow; handled at course level

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Quiz',
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
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _createQuiz();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) => _buildStepControls(details, theme),
        steps: [
          Step(
            title: const Text('Quiz Details'),
            content: _buildQuizDetailsStep(theme),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Add Questions'),
            content: _buildQuestionsStep(theme),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Review & Create'),
            content: _buildReviewStep(theme),
            isActive: _currentStep >= 2,
            state: _questions.length == 5 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildStepControls(ControlsDetails details, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (details.stepIndex > 0)
            TextButton(
              onPressed: details.onStepCancel,
              child: const Text('Back'),
            ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: details.onStepContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text(
              details.stepIndex == 2 ? 'Create Quiz' : 'Next',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizDetailsStep(ThemeData theme) {
    final user = Provider.of<AppProvider>(context).currentUser!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Quiz Title',
              hintText: 'Enter quiz title',
              prefixIcon: Icon(
                Icons.quiz,
                color: theme.colorScheme.primary,
              ),
              filled: true,
              fillColor: theme.colorScheme.primaryContainer.withAlpha(25),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a quiz title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Course>>(
            future: () async {
              final faculty = await _dataService.getFacultyByUserId(user.id);
              if (faculty == null) return <Course>[];
              return _dataService.getCoursesByFaculty(faculty.id);
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                return const Center(child: Text('No courses found.'));
              }

              final courses = snapshot.data!;
              final safeSelectedId = courses.any((c) => c.id == _selectedCourseId) ? _selectedCourseId : null;
              return DropdownButtonFormField<String>(
                value: safeSelectedId,
                decoration: InputDecoration(
                  labelText: 'Select Course',
                  prefixIcon: Icon(
                    Icons.book,
                    color: theme.colorScheme.primary,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.primaryContainer.withAlpha(25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: courses
                    .map((course) => DropdownMenuItem<String>(
                          value: course.id,
                          child: Text('${course.name} (${course.code})'),
                        ))
                    .toList(),
                onChanged: (courseId) {
                  setState(() {
                    _selectedCourseId = courseId;
                    final selected = courses.firstWhere((c) => c.id == courseId);
                    _selectedCourseLabel = '${selected.name} (${selected.code})';
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a course';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: theme.colorScheme.secondaryContainer.withAlpha(75),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quiz Settings',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Quiz will have exactly 5 questions\n• Duration: 7 minutes\n• Auto-starts 35 minutes after class begins\n• Only available to present students',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(175),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attendance upload removed; questions UI starts here
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions (${_questions.length}/5)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_questions.length < 5)
              ElevatedButton.icon(
                onPressed: () => _showAddQuestionDialog(theme),
                icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
                label: Text(
                  'Add Question',
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_questions.isEmpty)
          Card(
            elevation: 0,
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withAlpha(75),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No questions added yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildQuestionCard(question, index, theme);
          }),
      ],
    );
  }

  Widget _buildQuestionCard(Question question, int index, ThemeData theme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha(50),
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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: Icon(
                    Icons.delete,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...question.options.asMap().entries.map((optEntry) {
              final optIndex = optEntry.key;
              final option = optEntry.value;
              final isCorrect = optIndex == question.correctAnswer;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCorrect 
                            ? theme.colorScheme.tertiary.withAlpha(50)
                            : theme.colorScheme.surface,
                        border: Border.all(
                          color: isCorrect 
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.outline.withAlpha(75),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isCorrect 
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: theme.colorScheme.tertiary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + optIndex)}. $option',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isCorrect ? FontWeight.bold : null,
                          color: isCorrect ? theme.colorScheme.tertiary : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiz Summary',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withAlpha(75),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('Title', _titleController.text, theme),
                _buildSummaryRow('Course', _selectedCourseLabel ?? 'Not selected', theme),
                _buildSummaryRow('Questions', '${_questions.length}/5', theme),
                _buildSummaryRow('Duration', '7 minutes', theme),
                _buildSummaryRow('Auto-start', '35 minutes after class begins', theme),
              ],
            ),
          ),
        ),
        if (_questions.length == 5) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: theme.colorScheme.tertiaryContainer.withAlpha(75),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ready to Create',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your quiz is complete and ready to be created. Students will be able to take this quiz when they are present in class.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(175),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog(ThemeData theme) {
    final questionController = TextEditingController();
    final optionControllers = List.generate(4, (index) => TextEditingController());
    int correctAnswer = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: const Text('Add Question'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'Enter your question',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ...optionControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: correctAnswer,
                          onChanged: (value) => setDialogState(() => correctAnswer = value!),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Option ${String.fromCharCode(65 + index)}',
                              hintText: 'Enter option ${String.fromCharCode(65 + index)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addQuestion(
              questionController.text,
              optionControllers.map((c) => c.text).toList(),
              correctAnswer,
            ),
            child: const Text('Add'),
          ),
        ],
        ),
      ),
    );
  }

  void _addQuestion(String text, List<String> options, int correctAnswer) {
    if (text.isEmpty || options.any((o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _questions.add(Question(
        id: 'q${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        options: options,
        correctAnswer: correctAnswer,
        type: QuestionType.text,
      ));
    });

    Navigator.pop(context);
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }



  void _createQuiz() async {
    if (_questions.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add exactly 5 questions')),
      );
      return;
    }


    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final faculty = await _dataService.getFacultyByUserId(appProvider.currentUser!.id);
    if (faculty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty profile not found')), 
      );
      return;
    }
    final timetables = await _dataService.getTimetableByFaculty(faculty.id);
    if (timetables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No timetable found for this course')),
      );
      return;
    }

    final quiz = Quiz(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: _selectedCourseId!,
      facultyId: faculty.id,
      title: _titleController.text.trim(),
      questions: _questions,
      createdAt: DateTime.now(),
      scheduledAt: DateTime.now().add(const Duration(minutes: 35)),
      duration: 7,
      isActive: true,
      isCancelled: false,
      isPaused: false,
      attendanceUploaded: false,
      attendance: const [],
    );

    await _dataService.createQuiz(quiz);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz created successfully!')),
    );

    Navigator.pop(context);
  }

  // Attendance Excel parsing handled on course level in dashboard
}