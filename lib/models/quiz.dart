
import 'package:cloud_firestore/cloud_firestore.dart';
import 'question.dart';

// Legacy Quiz class for compatibility with existing code
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
  final bool isPaused;
  final bool attendanceUploaded;
  final List<Map<String, dynamic>> attendance; // parsed attendance rows

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
    this.isPaused = false,
    this.attendanceUploaded = false,
    this.attendance = const [],
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

  // Compatibility getters for UI code
  String get quizTitle => title;
  String get status {
    if (isCancelled) return 'cancelled';
    if (isPaused) return 'paused';
    if (!attendanceUploaded) return 'pending';
    return isActive ? 'active' : 'inactive';
  }
  String get createdBy => facultyId;
  String get timetableId => courseId; // Using courseId as timetableId for compatibility

  Map<String, dynamic> toJson() => {
    'id': id,
    'course_id': courseId,
    'faculty_id': facultyId,
    'created_by': facultyId, // for compatibility with existing queries
    'title': title,
    'questions': questions.map((q) => q.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'scheduled_at': scheduledAt?.toIso8601String(),
    'duration': duration,
    'is_active': isActive,
    'is_cancelled': isCancelled,
    'is_paused': isPaused,
    'attendance_uploaded': attendanceUploaded,
    'attendance': attendance,
  };

  factory Quiz.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (value is DateTime) return value;
      // Support Firestore Timestamp without direct import here
      final typeName = value.runtimeType.toString();
      if (typeName == 'Timestamp') {
        // Cloud Firestore Timestamp has toDate()
        try {
          // ignore: avoid_dynamic_calls
          return (value as dynamic).toDate() as DateTime;
        } catch (_) {}
      }
      if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return Quiz(
      id: json['id'],
      courseId: json['course_id'],
      facultyId: json['faculty_id'] ?? json['created_by'],
      title: json['title'],
      questions: (json['questions'] as List?)?.map((q) => Question.fromJson(q)).toList() ?? const [],
      createdAt: parseDate(json['created_at']),
      scheduledAt: json['scheduled_at'] != null ? parseDate(json['scheduled_at']) : null,
      duration: json['duration'] ?? 7,
      isActive: json['is_active'] ?? false,
      isCancelled: json['is_cancelled'] ?? false,
      isPaused: json['is_paused'] ?? false,
      attendanceUploaded: json['attendance_uploaded'] ?? false,
      attendance: (json['attendance'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? const [],
    );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'quiz_id': quizId,
    'student_id': studentId,
    'answers': answers,
    'submitted_at': submittedAt.toIso8601String(),
    'score': score,
    'total_questions': totalQuestions,
  };

  factory QuizSubmission.fromJson(Map<String, dynamic> json) => QuizSubmission(
    id: json['id'],
    quizId: json['quiz_id'],
    studentId: json['student_id'],
    answers: Map<String, int>.from(json['answers']),
    submittedAt: DateTime.parse(json['submitted_at']),
    score: json['score'],
    totalQuestions: json['total_questions'],
  );
}

// New schema classes for the proposed database structure
class QuizNew {
  final String id;
  final String timetableId;
  final DateTime scheduledDate;
  final String quizTitle;
  final String createdBy; // FK to faculty_id
  final String status;

  QuizNew({
    required this.id,
    required this.timetableId,
    required this.scheduledDate,
    required this.quizTitle,
    required this.createdBy,
    required this.status,
  });

  factory QuizNew.fromJson(Map<String, dynamic> json) {
    return QuizNew(
      id: json['id'],
      timetableId: json['timetable_id'],
      scheduledDate: json['scheduled_date'] is Timestamp 
        ? (json['scheduled_date'] as Timestamp).toDate()
        : DateTime.parse(json['scheduled_date']),
      quizTitle: json['quiz_title'],
      createdBy: json['created_by'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timetable_id': timetableId,
        'scheduled_date': scheduledDate,
        'quiz_title': quizTitle,
        'created_by': createdBy,
        'status': status,
      };
}

class QuizQuestion {
  final String id;
  final String quizId;
  final String questionText;
  final String? imageUrl;
  final List<String> options; // JSON array
  final String correctAnswer;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    this.imageUrl,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      quizId: json['quiz_id'],
      questionText: json['question_text'],
      imageUrl: json['image_url'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correct_answer'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quiz_id': quizId,
        'question_text': questionText,
        'image_url': imageUrl,
        'options': options,
        'correct_answer': correctAnswer,
      };
}

class QuizSession {
  final String id;
  final String quizId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final int? remainingMs; // remaining duration when paused
  final DateTime? pausedAt;

  QuizSession({
    required this.id,
    required this.quizId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.remainingMs,
    this.pausedAt,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      id: json['id'],
      quizId: json['quiz_id'],
      startTime: json['start_time'] is Timestamp 
        ? (json['start_time'] as Timestamp).toDate()
        : DateTime.parse(json['start_time']),
      endTime: json['end_time'] is Timestamp 
        ? (json['end_time'] as Timestamp).toDate()
        : DateTime.parse(json['end_time']),
      status: json['status'],
      remainingMs: json['remaining_ms'],
      pausedAt: json['paused_at'] is Timestamp
          ? (json['paused_at'] as Timestamp).toDate()
          : (json['paused_at'] != null ? DateTime.parse(json['paused_at']) : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quiz_id': quizId,
        'start_time': startTime,
        'end_time': endTime,
        'status': status,
        if (remainingMs != null) 'remaining_ms': remainingMs,
        if (pausedAt != null) 'paused_at': pausedAt,
      };
}

class StudentQuizResponse {
  final String id;
  final String sessionId;
  final String studentId;
  final String questionId;
  final String selectedOption;
  final bool isCorrect;
  final DateTime answeredAt;

  StudentQuizResponse({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory StudentQuizResponse.fromJson(Map<String, dynamic> json) {
    return StudentQuizResponse(
      id: json['id'],
      sessionId: json['session_id'],
      studentId: json['student_id'],
      questionId: json['question_id'],
      selectedOption: json['selected_option'],
      isCorrect: json['is_correct'],
      answeredAt: json['answered_at'] is Timestamp 
        ? (json['answered_at'] as Timestamp).toDate()
        : DateTime.parse(json['answered_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'student_id': studentId,
        'question_id': questionId,
        'selected_option': selectedOption,
        'is_correct': isCorrect,
        'answered_at': answeredAt,
      };
}

class StudentQuizResult {
  final String id;
  final String sessionId;
  final String studentId;
  final double score;
  final double percentageScore;
  final DateTime submittedAt;

  StudentQuizResult({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.score,
    required this.percentageScore,
    required this.submittedAt,
  });

  factory StudentQuizResult.fromJson(Map<String, dynamic> json) {
    return StudentQuizResult(
      id: json['id'],
      sessionId: json['session_id'],
      studentId: json['student_id'],
      score: json['score'],
      percentageScore: json['percentage_score'],
      submittedAt: json['submitted_at'] is Timestamp 
        ? (json['submitted_at'] as Timestamp).toDate()
        : DateTime.parse(json['submitted_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'student_id': studentId,
        'score': score,
        'percentage_score': percentageScore,
        'submitted_at': submittedAt,
      };
}