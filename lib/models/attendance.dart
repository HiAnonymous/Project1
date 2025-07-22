class AttendanceRecord {
  final String id;
  final String studentId;
  final String courseId;
  final DateTime classStartTime;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool isPresent;
  final int minutesAttended;
  final bool isEligibleForQuiz;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.classStartTime,
    this.checkInTime,
    this.checkOutTime,
    required this.isPresent,
    required this.minutesAttended,
    required this.isEligibleForQuiz,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'courseId': courseId,
        'classStartTime': classStartTime.toIso8601String(),
        'checkInTime': checkInTime?.toIso8601String(),
        'checkOutTime': checkOutTime?.toIso8601String(),
        'isPresent': isPresent,
        'minutesAttended': minutesAttended,
        'isEligibleForQuiz': isEligibleForQuiz,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        id: json['id'],
        studentId: json['studentId'],
        courseId: json['courseId'],
        classStartTime: DateTime.parse(json['classStartTime']),
        checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
        checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
        isPresent: json['isPresent'],
        minutesAttended: json['minutesAttended'],
        isEligibleForQuiz: json['isEligibleForQuiz'],
      );

  // Copy method for updating records
  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? courseId,
    DateTime? classStartTime,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool? isPresent,
    int? minutesAttended,
    bool? isEligibleForQuiz,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      classStartTime: classStartTime ?? this.classStartTime,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      isPresent: isPresent ?? this.isPresent,
      minutesAttended: minutesAttended ?? this.minutesAttended,
      isEligibleForQuiz: isEligibleForQuiz ?? this.isEligibleForQuiz,
    );
  }
}

class AttendanceSummary {
  final String courseId;
  final int totalStudents;
  final int presentStudents;
  final int eligibleForQuiz;
  final List<AttendanceRecord> records;

  AttendanceSummary({
    required this.courseId,
    required this.totalStudents,
    required this.presentStudents,
    required this.eligibleForQuiz,
    required this.records,
  });
}