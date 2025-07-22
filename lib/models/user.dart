enum UserRole { faculty, student }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? registrationNumber;
  final String? department;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.registrationNumber,
    this.department,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.toString(),
    'registrationNumber': registrationNumber,
    'department': department,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    role: UserRole.values.firstWhere((e) => e.toString() == json['role']),
    registrationNumber: json['registrationNumber'],
    department: json['department'],
  );
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
}