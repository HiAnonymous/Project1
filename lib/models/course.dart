


class Course {
  final String id;
  final String programId;
  final String name;
  final String code;
  // Additional fields from current: facultyId, department, enrolledStudents (store as array in Firestore)
  final String facultyId;
  final String department;
  final List<String> enrolledStudents;
  final List<Map<String, dynamic>> roster; // optional richer student list with attendance

  Course({
    required this.id,
    required this.programId,
    required this.name,
    required this.code,
    required this.facultyId,
    required this.department,
    required this.enrolledStudents,
    this.roster = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      programId: json['program_id'],
      name: json['course_name'],
      code: json['course_code'],
      facultyId: json['faculty_id'],
      department: json['department'],
      enrolledStudents: List<String>.from(json['enrolled_students'] ?? []),
      roster: (json['roster'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'program_id': programId,
        'course_name': name,
        'course_code': code,
        'faculty_id': facultyId,
        'department': department,
        'enrolled_students': enrolledStudents,
        'roster': roster,
      };
}

