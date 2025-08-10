import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { faculty, student, admin }
enum UserStatus { active, inactive, pending } // Assuming possible statuses

class User {
  final String id;
  final String registrationNumber;
  final String passwordHash;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;

  User({
    required this.id,
    required this.registrationNumber,
    required this.passwordHash,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      registrationNumber: json['registration_number'],
      passwordHash: json['password_hash'],
      role: UserRole.values.byName(json['role']),
      status: UserStatus.values.byName(json['status']),
      createdAt: json['created_at'] is Timestamp 
        ? (json['created_at'] as Timestamp).toDate()
        : DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'registration_number': registrationNumber,
        'password_hash': passwordHash,
        'role': role.name,
        'status': status.name,
        'created_at': createdAt,
      };
}

class Faculty {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String departmentId;
  final String geminiApiKey;
  final String email;

  Faculty({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.departmentId,
    required this.geminiApiKey,
    required this.email,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      departmentId: json['department_id'],
      geminiApiKey: json['gemini_api_key'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'department_id': departmentId,
        'gemini_api_key': geminiApiKey,
        'email': email,
      };
}

class Student {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String departmentId;
  final String programId;
  final int yearOfStudy;
  final String email;

  Student({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.departmentId,
    required this.programId,
    required this.yearOfStudy,
    required this.email,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      departmentId: json['department_id'],
      programId: json['program_id'],
      yearOfStudy: json['year_of_study'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'department_id': departmentId,
        'program_id': programId,
        'year_of_study': yearOfStudy,
        'email': email,
      };
}

class BiometricData {
  final String userId;
  final String courseId;
  final DateTime timestamp;
  final bool isPresent;

  BiometricData({
    required this.userId,
    required this.courseId,
    required this.timestamp,
    required this.isPresent,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'course_id': courseId,
    'timestamp': timestamp.toIso8601String(),
    'is_present': isPresent,
  };

  factory BiometricData.fromJson(Map<String, dynamic> json) => BiometricData(
    userId: json['user_id'],
    courseId: json['course_id'],
    timestamp: DateTime.parse(json['timestamp']),
    isPresent: json['is_present'],
  );
}