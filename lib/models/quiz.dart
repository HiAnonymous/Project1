enum QuestionType { text, image }

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswer;
  final QuestionType type;
  final String? imageUrl;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswer,
    required this.type,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'options': options,
    'correctAnswer': correctAnswer,
    'type': type.toString(),
    'imageUrl': imageUrl,
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'],
    text: json['text'],
    options: List<String>.from(json['options']),
    correctAnswer: json['correctAnswer'],
    type: QuestionType.values.firstWhere((e) => e.toString() == json['type']),
    imageUrl: json['imageUrl'],
  );
}

class Quiz {
  final String id;
  final String courseId;
  final String facultyId;
  final String title;
  final List<Question> questions;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final int duration; // in minutes
  final bool isActive;
  final bool isCancelled;

  Quiz({
    required this.id,
    required this.courseId,
    required this.facultyId,
    required this.title,
    required this.questions,
    required this.createdAt,
    this.scheduledAt,
    this.duration = 7,
    this.isActive = false,
    this.isCancelled = false,
  });

  bool canStart() {
    if (isCancelled || !isActive) return false;
    if (scheduledAt == null) return false;
    final now = DateTime.now();
    return now.isAfter(scheduledAt!) && now.isBefore(scheduledAt!.add(Duration(minutes: duration)));
  }

  bool canCancel() {
    if (scheduledAt == null) return false;
    final now = DateTime.now();
    final lectureStart = scheduledAt!.subtract(const Duration(minutes: 35));
    return now.isBefore(scheduledAt!) && now.isAfter(lectureStart);
  }
}

class QuizSubmission {
  final String id;
  final String quizId;
  final String studentId;
  final Map<String, int> answers;
  final DateTime submittedAt;
  final int score;
  final int totalQuestions;

  QuizSubmission({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.answers,
    required this.submittedAt,
    required this.score,
    required this.totalQuestions,
  });

  double get percentage => (score / totalQuestions) * 100;
}