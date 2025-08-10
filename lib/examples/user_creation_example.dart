import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../models/user.dart';

class UserCreationExample {
  final DatabaseService _dbService = DatabaseService();

  // Hash password for security
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Example: Create a new faculty member
  Future<void> createFacultyExample() async {
    try {
      final result = await _dbService.createCompleteUser(
        registrationNumber: 'FAC001',
        passwordHash: _hashPassword('faculty123'),
        role: UserRole.faculty,
        firstName: 'John',
        lastName: 'Doe',
        departmentId: 'dept_cs',
        email: 'john.doe@university.edu',
        geminiApiKey: 'your_gemini_api_key_here',
      );

      if (result != null) {
        print('✅ Faculty created successfully!');
        print('User ID: ${result['user'].id}');
        print('Faculty ID: ${result['faculty'].id}');
      } else {
        print('❌ Failed to create faculty');
      }
    } catch (e) {
      print('Error creating faculty: $e');
    }
  }

  // Example: Create a new student
  Future<void> createStudentExample() async {
    try {
      final result = await _dbService.createCompleteUser(
        registrationNumber: 'STU2024001',
        passwordHash: _hashPassword('student123'),
        role: UserRole.student,
        firstName: 'Jane',
        lastName: 'Smith',
        departmentId: 'dept_cs',
        email: 'jane.smith@student.university.edu',
        programId: 'prog_bsc_cs',
        yearOfStudy: 2,
      );

      if (result != null) {
        print('✅ Student created successfully!');
        print('User ID: ${result['user'].id}');
        print('Student ID: ${result['student'].id}');
      } else {
        print('❌ Failed to create student');
      }
    } catch (e) {
      print('Error creating student: $e');
    }
  }

  // Example: Create multiple users in batch
  Future<void> createMultipleUsersExample() async {
    final facultyData = [
      {
        'registrationNumber': 'FAC002',
        'password': 'faculty456',
        'firstName': 'Alice',
        'lastName': 'Johnson',
        'departmentId': 'dept_math',
        'email': 'alice.johnson@university.edu',
      },
      {
        'registrationNumber': 'FAC003',
        'password': 'faculty789',
        'firstName': 'Bob',
        'lastName': 'Wilson',
        'departmentId': 'dept_physics',
        'email': 'bob.wilson@university.edu',
      },
    ];

    final studentData = [
      {
        'registrationNumber': 'STU2024002',
        'password': 'student456',
        'firstName': 'Mike',
        'lastName': 'Brown',
        'departmentId': 'dept_cs',
        'email': 'mike.brown@student.university.edu',
        'programId': 'prog_bsc_cs',
        'yearOfStudy': 1,
      },
      {
        'registrationNumber': 'STU2024003',
        'password': 'student789',
        'firstName': 'Sarah',
        'lastName': 'Davis',
        'departmentId': 'dept_math',
        'email': 'sarah.davis@student.university.edu',
        'programId': 'prog_bsc_math',
        'yearOfStudy': 3,
      },
    ];

    // Create faculty members
    for (final faculty in facultyData) {
      final result = await _dbService.createCompleteUser(
        registrationNumber: faculty['registrationNumber'] as String,
        passwordHash: _hashPassword(faculty['password'] as String),
        role: UserRole.faculty,
        firstName: faculty['firstName'] as String,
        lastName: faculty['lastName'] as String,
        departmentId: faculty['departmentId'] as String,
        email: faculty['email'] as String,
      );

      if (result != null) {
        print('✅ Created faculty: ${faculty['firstName']} ${faculty['lastName']}');
      } else {
        print('❌ Failed to create faculty: ${faculty['firstName']} ${faculty['lastName']}');
      }
    }

    // Create students
    for (final student in studentData) {
      final result = await _dbService.createCompleteUser(
        registrationNumber: student['registrationNumber'] as String,
        passwordHash: _hashPassword(student['password'] as String),
        role: UserRole.student,
        firstName: student['firstName'] as String,
        lastName: student['lastName'] as String,
        departmentId: student['departmentId'] as String,
        email: student['email'] as String,
        programId: student['programId'] as String,
        yearOfStudy: student['yearOfStudy'] as int,
      );

      if (result != null) {
        print('✅ Created student: ${student['firstName']} ${student['lastName']}');
      } else {
        print('❌ Failed to create student: ${student['firstName']} ${student['lastName']}');
      }
    }
  }

  // Example: Update user information
  Future<void> updateUserExample() async {
    try {
      // First, find a user (you would typically get this from authentication)
      final user = await _dbService.authenticate('FAC001', UserRole.faculty);
      
      if (user != null) {
        // Update user status
        final success = await _dbService.updateUser(user.id, {
          'status': UserStatus.inactive.name,
        });

        if (success) {
          print('✅ User updated successfully');
        } else {
          print('❌ Failed to update user');
        }
      } else {
        print('❌ User not found');
      }
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  // Example: Delete a user
  Future<void> deleteUserExample() async {
    try {
      // First, find a user
      final user = await _dbService.authenticate('STU2024001', UserRole.student);
      
      if (user != null) {
        final success = await _dbService.deleteUser(user.id);
        
        if (success) {
          print('✅ User deleted successfully');
        } else {
          print('❌ Failed to delete user');
        }
      } else {
        print('❌ User not found');
      }
    } catch (e) {
      print('Error deleting user: $e');
    }
  }
}

// Usage example in your app:
/*
void main() async {
  final example = UserCreationExample();
  
  // Create a faculty member
  await example.createFacultyExample();
  
  // Create a student
  await example.createStudentExample();
  
  // Create multiple users
  await example.createMultipleUsersExample();
  
  // Update a user
  await example.updateUserExample();
  
  // Delete a user
  await example.deleteUserExample();
}
*/ 