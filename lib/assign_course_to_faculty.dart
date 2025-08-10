import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'services/database_service.dart';
import 'models/user.dart';
import 'models/course.dart';
import 'database/collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseAssignmentService {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hash password for security
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Create a course and assign it to a faculty
  Future<Course?> createCourse({
    required String programId,
    required String name,
    required String code,
    required String facultyId,
    required String department,
    List<String> enrolledStudents = const [],
  }) async {
    try {
      // Check if faculty exists
      final faculty = await _dbService.getFacultyById(facultyId);
      if (faculty == null) {
        print('❌ Faculty with ID $facultyId not found');
        return null;
      }

      // Create course document
      final courseData = {
        'program_id': programId,
        'course_name': name,
        'course_code': code,
        'faculty_id': facultyId,
        'department': department,
        'enrolled_students': enrolledStudents,
      };

      final courseDocRef = await _db.collection(Collections.courses).add(courseData);
      
      // Get the created course
      final courseDoc = await courseDocRef.get();
      final createdCourseData = courseDoc.data()!;
      createdCourseData['id'] = courseDoc.id;
      
      print('✅ Successfully created course: ${courseDoc.id}');
      return Course.fromJson(createdCourseData);
    } catch (e) {
      print('❌ Create course error: $e');
      return null;
    }
  }

  // Find or create John Doe faculty
  Future<Faculty?> findOrCreateJohnDoe() async {
    try {
      // First, try to find John Doe by email
      final facultyQuery = _db.collection(Collections.faculty)
          .where('email', isEqualTo: 'john.doe@university.edu')
          .limit(1);
      
      final facultySnapshot = await facultyQuery.get();
      
      if (facultySnapshot.docs.isNotEmpty) {
        final facultyData = facultySnapshot.docs.first.data();
        facultyData['id'] = facultySnapshot.docs.first.id;
        final faculty = Faculty.fromJson(facultyData);
        print('✅ Found existing John Doe faculty: ${faculty.id}');
        return faculty;
      }

      // If not found, create John Doe faculty
      print('📝 Creating new John Doe faculty...');
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

      if (result != null && result['faculty'] != null) {
        print('✅ Created new John Doe faculty: ${result['faculty'].id}');
        return result['faculty'];
      } else {
        print('❌ Failed to create John Doe faculty');
        return null;
      }
    } catch (e) {
      print('❌ Error finding/creating John Doe: $e');
      return null;
    }
  }

  // Main method to assign course to John Doe
  Future<void> assignCourseToJohnDoe() async {
    try {
      print('🚀 Starting course assignment to John Doe...\n');

      // Step 1: Find or create John Doe faculty
      final johnDoe = await findOrCreateJohnDoe();
      if (johnDoe == null) {
        print('❌ Could not find or create John Doe faculty');
        return;
      }

      print('👨‍🏫 Faculty: ${johnDoe.firstName} ${johnDoe.lastName}');
      print('📧 Email: ${johnDoe.email}');
      print('🏢 Department: ${johnDoe.departmentId}\n');

      // Step 2: Create a course and assign it to John Doe
      final course = await createCourse(
        programId: 'prog_bsc_cs',
        name: 'Introduction to Computer Science',
        code: 'CS101',
        facultyId: johnDoe.id,
        department: 'Computer Science',
        enrolledStudents: [], // Empty for now, can be populated later
      );

      if (course != null) {
        print('✅ Course successfully assigned to John Doe!');
        print('📚 Course Details:');
        print('   - Name: ${course.name}');
        print('   - Code: ${course.code}');
        print('   - Department: ${course.department}');
        print('   - Faculty ID: ${course.facultyId}');
        print('   - Enrolled Students: ${course.enrolledStudents.length}');
      } else {
        print('❌ Failed to create course');
      }
    } catch (e) {
      print('❌ Error in course assignment: $e');
    }
  }

  // Method to create multiple courses for John Doe
  Future<void> assignMultipleCoursesToJohnDoe() async {
    try {
      print('🚀 Starting multiple course assignments to John Doe...\n');

      // Step 1: Find or create John Doe faculty
      final johnDoe = await findOrCreateJohnDoe();
      if (johnDoe == null) {
        print('❌ Could not find or create John Doe faculty');
        return;
      }

      // Step 2: Define courses to assign
      final coursesToCreate = [
        {
          'programId': 'prog_bsc_cs',
          'name': 'Introduction to Computer Science',
          'code': 'CS101',
          'department': 'Computer Science',
        },
        {
          'programId': 'prog_bsc_cs',
          'name': 'Data Structures and Algorithms',
          'code': 'CS201',
          'department': 'Computer Science',
        },
        {
          'programId': 'prog_bsc_cs',
          'name': 'Database Management Systems',
          'code': 'CS301',
          'department': 'Computer Science',
        },
      ];

      // Step 3: Create each course
      for (final courseData in coursesToCreate) {
        final course = await createCourse(
          programId: courseData['programId']!,
          name: courseData['name']!,
          code: courseData['code']!,
          facultyId: johnDoe.id,
          department: courseData['department']!,
        );

        if (course != null) {
          print('✅ Created course: ${course.code} - ${course.name}');
        } else {
          print('❌ Failed to create course: ${courseData['code']}');
        }
      }

      print('\n🎉 Course assignment process completed!');
    } catch (e) {
      print('❌ Error in multiple course assignment: $e');
    }
  }

  // Method to list all courses assigned to John Doe
  Future<void> listJohnDoesCourses() async {
    try {
      print('📋 Listing John Doe\'s courses...\n');

      // Find John Doe
      final johnDoe = await findOrCreateJohnDoe();
      if (johnDoe == null) {
        print('❌ Could not find John Doe faculty');
        return;
      }

      // Get courses assigned to John Doe
      final courses = await _dbService.getCoursesByFaculty(johnDoe.id);

      if (courses.isEmpty) {
        print('📝 No courses found for John Doe');
      } else {
        print('📚 Courses assigned to John Doe (${courses.length} total):');
        for (int i = 0; i < courses.length; i++) {
          final course = courses[i];
          print('${i + 1}. ${course.code} - ${course.name}');
          print('   Department: ${course.department}');
          print('   Enrolled Students: ${course.enrolledStudents.length}');
          print('');
        }
      }
    } catch (e) {
      print('❌ Error listing courses: $e');
    }
  }
}

// Usage example
void main() async {
  final courseService = CourseAssignmentService();
  
  // Assign a single course to John Doe
  await courseService.assignCourseToJohnDoe();
  
  // Or assign multiple courses
  // await courseService.assignMultipleCoursesToJohnDoe();
  
  // List John Doe's courses
  await courseService.listJohnDoesCourses();
} 