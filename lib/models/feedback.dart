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
    'studentId': studentId,
    'facultyId': facultyId,
    'courseId': courseId,
    'rating': rating,
    'comment': comment,
    'submittedAt': submittedAt.toIso8601String(),
  };

  factory Feedback.fromJson(Map<String, dynamic> json) => Feedback(
    id: json['id'],
    studentId: json['studentId'],
    facultyId: json['facultyId'],
    courseId: json['courseId'],
    rating: json['rating'],
    comment: json['comment'],
    submittedAt: DateTime.parse(json['submittedAt']),
  );
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