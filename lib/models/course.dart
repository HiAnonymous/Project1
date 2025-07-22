class Course {
  final String id;
  final String name;
  final String code;
  final String facultyId;
  final String department;
  final List<String> enrolledStudents;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.facultyId,
    required this.department,
    required this.enrolledStudents,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'facultyId': facultyId,
    'department': department,
    'enrolledStudents': enrolledStudents,
  };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'],
    name: json['name'],
    code: json['code'],
    facultyId: json['facultyId'],
    department: json['department'],
    enrolledStudents: List<String>.from(json['enrolledStudents']),
  );
}

class Timetable {
  final String id;
  final String courseId;
  final String courseName;
  final String facultyName;
  final DateTime startTime;
  final DateTime endTime;
  final String classroom;
  final String dayOfWeek;

  Timetable({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.facultyName,
    required this.startTime,
    required this.endTime,
    required this.classroom,
    required this.dayOfWeek,
  });

  bool isCurrentlyActive() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    final todayEnd = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
    return now.isAfter(todayStart) && now.isBefore(todayEnd) && 
           dayOfWeek.toLowerCase() == _getDayName(now.weekday).toLowerCase();
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
}