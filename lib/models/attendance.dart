
import 'package:cloud_firestore/cloud_firestore.dart';

class BiometricData {
  final String id;
  final String studentId;
  final String biometricHash;
  final String registeredDevice;
  final DateTime addedOn;

  BiometricData({
    required this.id,
    required this.studentId,
    required this.biometricHash,
    required this.registeredDevice,
    required this.addedOn,
  });

  factory BiometricData.fromJson(Map<String, dynamic> json) {
    return BiometricData(
      id: json['id'],
      studentId: json['student_id'],
      biometricHash: json['biometric_hash'],
      registeredDevice: json['registered_device'],
      addedOn: (json['added_on'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'biometric_hash': biometricHash,
        'registered_device': registeredDevice,
        'added_on': addedOn,
      };
}

class Attendance {
  final String id;
  final String studentId;
  final String timetableId;
  final DateTime attendanceDate;
  final String status;
  final bool biometricVerified;
  final DateTime markedAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.timetableId,
    required this.attendanceDate,
    required this.status,
    required this.biometricVerified,
    required this.markedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentId: json['student_id'],
      timetableId: json['timetable_id'],
      attendanceDate: (json['attendance_date'] as Timestamp).toDate(),
      status: json['status'],
      biometricVerified: json['biometric_verified'],
      markedAt: (json['marked_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'timetable_id': timetableId,
        'attendance_date': attendanceDate,
        'status': status,
        'biometric_verified': biometricVerified,
        'marked_at': markedAt,
      };
}