
import 'package:cloud_firestore/cloud_firestore.dart';

class Feedback {
  final String id;
  final String studentId;
  final String facultyId;
  final String courseId;
  final int rating; // 1-5 stars
  final String comment;
  final DateTime submittedAt;

  Feedback({
    required this.id,
    required this.studentId,
    required this.facultyId,
    required this.courseId,
    required this.rating,
    required this.comment,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'faculty_id': facultyId,
    'course_id': courseId,
    'rating': rating,
    'comment': comment,
    'submitted_at': submittedAt.toIso8601String(),
  };

  factory Feedback.fromJson(Map<String, dynamic> json) => Feedback(
    id: json['id'],
    studentId: json['student_id'],
    facultyId: json['faculty_id'],
    courseId: json['course_id'],
    rating: json['rating'],
    comment: json['comment'],
    submittedAt: json['submitted_at'] is Timestamp 
      ? (json['submitted_at'] as Timestamp).toDate()
      : DateTime.parse(json['submitted_at']),
  );
}

class LectureFeedback {
  final String id;
  final String studentId;
  final String sessionId;
  final int rating;
  final String comments;
  final DateTime submittedAt;

  LectureFeedback({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.rating,
    required this.comments,
    required this.submittedAt,
  });

  factory LectureFeedback.fromJson(Map<String, dynamic> json) {
    return LectureFeedback(
      id: json['id'],
      studentId: json['student_id'],
      sessionId: json['session_id'],
      rating: json['rating'],
      comments: json['comments'],
      submittedAt: json['submitted_at'] is Timestamp 
        ? (json['submitted_at'] as Timestamp).toDate()
        : DateTime.parse(json['submitted_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'session_id': sessionId,
        'rating': rating,
        'comments': comments,
        'submitted_at': submittedAt,
      };
}

class FeedbackSummary {
  final String facultyId;
  final String courseId;
  final double averageRating;
  final int totalFeedbacks;
  final Map<int, int> ratingDistribution;
  final List<String> recentComments;

  FeedbackSummary({
    required this.facultyId,
    required this.courseId,
    required this.averageRating,
    required this.totalFeedbacks,
    required this.ratingDistribution,
    required this.recentComments,
  });
}