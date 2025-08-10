import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      id: json['id'],
      courseId: json['course_id'],
      courseName: json['course_name'],
      facultyName: json['faculty_name'],
      startTime: json['start_time'] is Timestamp 
        ? (json['start_time'] as Timestamp).toDate()
        : DateTime.parse(json['start_time']),
      endTime: json['end_time'] is Timestamp 
        ? (json['end_time'] as Timestamp).toDate()
        : DateTime.parse(json['end_time']),
      classroom: json['classroom'],
      dayOfWeek: json['day_of_week'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_id': courseId,
        'course_name': courseName,
        'faculty_name': facultyName,
        'start_time': startTime,
        'end_time': endTime,
        'classroom': classroom,
        'day_of_week': dayOfWeek,
      };

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