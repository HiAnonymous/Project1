// lib/services/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../models/course.dart';
import '../models/quiz.dart';
import '../models/feedback.dart' as feedback_models;
import '../database/collections.dart';
import '../models/timetable.dart';


class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Authentication
  Future<User?> authenticate(String identifier, UserRole role) async {
    try {
      print('Authenticating: $identifier with role: $role');
      
      if (role == UserRole.faculty) {
        // For faculty, first find the faculty by email
        print('Looking for faculty with email: $identifier');
        final facultyQuery = _db.collection(Collections.faculty)
            .where('email', isEqualTo: identifier)
            .limit(1);
        
        final facultySnapshot = await facultyQuery.get();
        print('Faculty query result: ${facultySnapshot.docs.length} documents found');
        
        if (facultySnapshot.docs.isNotEmpty) {
          final facultyData = facultySnapshot.docs.first.data();
          final userId = facultyData['user_id'];
          print('Found faculty with user_id: $userId');
          
          // Now get the user by user_id
          final userDoc = await _db.collection(Collections.users).doc(userId).get();
          print('User document exists: ${userDoc.exists}');
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            userData['id'] = userDoc.id;
            final user = User.fromJson(userData);
            print('Successfully authenticated faculty: ${user.registrationNumber}');
            return user;
          } else {
            print('User document not found for user_id: $userId');
          }
        } else {
          print('No faculty found with email: $identifier');
        }
      } else {
        // For students, find by registration number
        print('Looking for student with registration number: $identifier');
        final query = _db.collection(Collections.users)
            .where('registration_number', isEqualTo: identifier)
            .where('role', isEqualTo: role.name)
            .limit(1);
        
        final snapshot = await query.get();
        print('Student query result: ${snapshot.docs.length} documents found');
        
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          data['id'] = snapshot.docs.first.id;
          final user = User.fromJson(data);
          print('Successfully authenticated student: ${user.registrationNumber}');
          return user;
        } else {
          print('No student found with registration number: $identifier');
        }
      }
      print('Authentication failed for: $identifier');
      return null;
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  // User methods
  Future<User?> getUserById(String id) async {
    try {
      final doc = await _db.collection(Collections.users).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  Future<User?> getUserByRegistrationNumber(String registrationNumber, {UserRole? role}) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection(Collections.users)
          .where('registration_number', isEqualTo: registrationNumber);
      if (role != null) {
        query = query.where('role', isEqualTo: role.name);
      }
      final snapshot = await query.limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return User.fromJson(data);
    } catch (e) {
      print('Get user by registration number error: $e');
      return null;
    }
  }

  Future<Faculty?> getFacultyByUserId(String userId) async {
    try {
      final query = _db.collection(Collections.faculty)
          .where('user_id', isEqualTo: userId)
          .limit(1);
      
      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Faculty.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get faculty error: $e');
      return null;
    }
  }

  Future<Student?> getStudentByUserId(String userId) async {
    try {
      final query = _db.collection(Collections.students)
          .where('user_id', isEqualTo: userId)
          .limit(1);
      
      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Student.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get student error: $e');
      return null;
    }
  }

  // Add missing method for getting student by ID
  Future<Student?> getStudentById(String id) async {
    try {
      final doc = await _db.collection(Collections.students).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Student.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get student by ID error: $e');
      return null;
    }
  }

  // Course methods
  Future<List<Course>> getCoursesByFaculty(String facultyId) async {
    try {
      final query = _db.collection(Collections.courses)
          .where('faculty_id', isEqualTo: facultyId);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Course.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get courses error: $e');
      return [];
    }
  }

  Future<List<Course>> getAllCourses() async {
    try {
      final snapshot = await _db.collection(Collections.courses).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Course.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get all courses error: $e');
      return [];
    }
  }

  Future<List<Course>> getCoursesByStudent(String studentId) async {
    try {
      // Get enrollments for student
      final enrollmentsQuery = _db.collection(Collections.enrollments)
          .where('student_id', isEqualTo: studentId)
          .where('is_active', isEqualTo: true);
      
      final enrollmentsSnapshot = await enrollmentsQuery.get();
      final courseIds = enrollmentsSnapshot.docs
          .map((doc) => doc.data()['course_id'] as String)
          .toList();
      
      if (courseIds.isEmpty) return [];
      
      // Get courses
      final coursesQuery = _db.collection(Collections.courses)
          .where(FieldPath.documentId, whereIn: courseIds);
      
      final coursesSnapshot = await coursesQuery.get();
      return coursesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Course.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get student courses error: $e');
      return [];
    }
  }

  // Quiz methods
  Future<List<Quiz>> getQuizzesByFaculty(String facultyId) async {
    try {
      // Fetch quizzes created by this faculty
      final query = _db.collection(Collections.quizzes)
          .where('created_by', isEqualTo: facultyId);

      final snapshot = await query.get();
      final quizzes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Quiz.fromJson(data);
      }).toList();

      // Filter out quizzes whose courses have been removed
      final courses = await getCoursesByFaculty(facultyId);
      if (courses.isEmpty) return <Quiz>[];
      final courseIds = courses.map((c) => c.id).toSet();
      final filtered = quizzes.where((q) => courseIds.contains(q.courseId)).toList();

      filtered.sort((a,b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    } catch (e) {
      print('Get faculty quizzes error: $e');
      return [];
    }
  }

  Future<List<Quiz>> getActiveQuizzesForStudent(String studentId) async {
    try {
      // Get student's courses
      final courses = await getCoursesByStudent(studentId);
      if (courses.isEmpty) return [];
      final courseIds = courses.map((c) => c.id).toList();

      // Firestore often requires a composite index when mixing whereIn + orderBy.
      // To avoid runtime index errors, fetch without orderBy and sort in-memory.
      final query = _db.collection(Collections.quizzes)
          .where('course_id', whereIn: courseIds)
          .where('is_active', isEqualTo: true)
          .where('is_cancelled', isEqualTo: false);

      final snapshot = await query.get();
      final quizzes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Quiz.fromJson(data);
      }).toList();

      quizzes.sort((a, b) => (b.scheduledAt ?? b.createdAt).compareTo(a.scheduledAt ?? a.createdAt));
      return quizzes;
    } catch (e) {
      print('Get active quizzes error: $e');
      return [];
    }
  }

  // Attendance methods
  Future<bool> isStudentEligibleForQuiz(String studentId, String courseId) async {
    try {
      final query = _db.collection(Collections.attendance)
          .where('student_id', isEqualTo: studentId)
          .where('course_id', isEqualTo: courseId)
          .where('is_eligible_for_quiz', isEqualTo: true)
          .limit(1);
      
      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Check quiz eligibility error: $e');
      return false;
    }
  }

  // Feedback methods
  Future<void> submitFeedback(feedback_models.LectureFeedback feedback) async {
    try {
      await _db.collection(Collections.lectureFeedback).add(feedback.toJson());
    } catch (e) {
      print('Submit feedback error: $e');
      rethrow;
    }
  }

  Future<List<feedback_models.Feedback>> getFeedbacksByFaculty(String facultyId) async {
    try {
      final query = _db.collection(Collections.lectureFeedback)
          .where('faculty_id', isEqualTo: facultyId)
          .orderBy('submitted_at', descending: true);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return feedback_models.Feedback.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get feedbacks error: $e');
      return [];
    }
  }

  // Quiz submission methods
  Future<void> submitQuiz(QuizSubmission submission) async {
    try {
      await _db.collection(Collections.studentQuizResults).add(submission.toJson());
    } catch (e) {
      print('Submit quiz error: $e');
      rethrow;
    }
  }

  Future<List<StudentQuizResult>> getSubmissionsByQuiz(String quizId) async {
    try {
      final query = _db.collection(Collections.studentQuizResults)
          .where('quiz_id', isEqualTo: quizId);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return StudentQuizResult.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get submissions error: $e');
      return [];
    }
  }

  Stream<List<StudentQuizResult>> streamSubmissionsByQuiz(String quizId) {
    return _db
        .collection(Collections.studentQuizResults)
        .where('quiz_id', isEqualTo: quizId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return StudentQuizResult.fromJson(data);
            }).toList());
  }

  // Additional methods needed by UI code
  Future<List<Timetable>> getTimetableByFaculty(String facultyId) async {
    try {
      // Get courses for faculty
      final courses = await getCoursesByFaculty(facultyId);
      if (courses.isEmpty) return [];
      
      final courseIds = courses.map((c) => c.id).toList();
      
      // Get timetables for these courses
      final query = _db.collection(Collections.timetables)
          .where('course_id', whereIn: courseIds);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Timetable.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get faculty timetables error: $e');
      return [];
    }
  }

  Future<List<Timetable>> getTimetablesByCourse(String courseId) async {
    try {
      final query = _db.collection(Collections.timetables)
          .where('course_id', isEqualTo: courseId);
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Timetable.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get timetables by course error: $e');
      return [];
    }
  }

  Future<Course?> getCourseById(String id) async {
    try {
      final doc = await _db.collection(Collections.courses).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Course.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get course error: $e');
      return null;
    }
  }

  Future<Faculty?> getFacultyById(String id) async {
    try {
      final doc = await _db.collection(Collections.faculty).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Faculty.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get faculty error: $e');
      return null;
    }
  }

  Future<List<QuizQuestion>> getQuestionsForQuiz(String quizId) async {
    try {
      final query = _db.collection(Collections.quizQuestions)
          .where('quiz_id', isEqualTo: quizId);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return QuizQuestion.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get quiz questions error: $e');
      return [];
    }
  }

  Future<void> createQuiz(Quiz quiz) async {
    try {
      await _db.collection(Collections.quizzes).add(quiz.toJson());
    } catch (e) {
      print('Create quiz error: $e');
      rethrow;
    }
  }

  Future<void> updateQuiz(Quiz quiz) async {
    try {
      await _db.collection(Collections.quizzes).doc(quiz.id).update(quiz.toJson());
    } catch (e) {
      print('Update quiz error: $e');
      rethrow;
    }
  }

  Future<void> updateQuizFields(String quizId, Map<String, dynamic> updates) async {
    try {
      await _db.collection(Collections.quizzes).doc(quizId).update(updates);
    } catch (e) {
      print('Update quiz fields error: $e');
      rethrow;
    }
  }

  // Quiz session methods
  Future<void> createQuizSession(QuizSession session) async {
    try {
      await _db.collection(Collections.quizSessions).add(session.toJson());
    } catch (e) {
      print('Create quiz session error: $e');
      rethrow;
    }
  }

  Future<void> updateQuizSessionFields(String sessionId, Map<String, dynamic> updates) async {
    try {
      await _db.collection(Collections.quizSessions).doc(sessionId).update(updates);
    } catch (e) {
      print('Update quiz session error: $e');
      rethrow;
    }
  }

  Future<QuizSession?> getLatestSessionForQuiz(String quizId) async {
    try {
      final query = _db.collection(Collections.quizSessions)
          .where('quiz_id', isEqualTo: quizId)
          .orderBy('start_time', descending: true)
          .limit(1);
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return QuizSession.fromJson(data);
    } catch (e) {
      print('Get latest quiz session error: $e');
      return null;
    }
  }

  // Timetable creation
  Future<Timetable?> createTimetable({
    required String courseId,
    required String courseName,
    required String facultyName,
    required DateTime startTime,
    required DateTime endTime,
    String classroom = '',
    required String dayOfWeek,
  }) async {
    try {
      final data = {
        'course_id': courseId,
        'course_name': courseName,
        'faculty_name': facultyName,
        'start_time': startTime,
        'end_time': endTime,
        'classroom': classroom,
        'day_of_week': dayOfWeek,
      };
      final ref = await _db.collection(Collections.timetables).add(data);
      final doc = await ref.get();
      final createdData = doc.data()!;
      createdData['id'] = doc.id;
      return Timetable.fromJson(createdData);
    } catch (e) {
      print('Create timetable error: $e');
      return null;
    }
  }

  Future<List<Timetable>> getTimetableByStudent(String studentId) async {
    try {
      // Get student's courses first
      final courses = await getCoursesByStudent(studentId);
      if (courses.isEmpty) return [];
      
      final courseIds = courses.map((c) => c.id).toList();
      
      // Get timetables for these courses
      final query = _db.collection(Collections.timetables)
          .where('course_id', whereIn: courseIds);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Timetable.fromJson(data);
      }).toList();
    } catch (e) {
      print('Get student timetables error: $e');
      return [];
    }
  }

  Future<StudentQuizResult?> getSubmissionByStudentAndQuiz(String studentId, String quizId) async {
    try {
      final query = _db.collection(Collections.studentQuizResults)
          .where('student_id', isEqualTo: studentId)
          .where('quiz_id', isEqualTo: quizId)
          .limit(1);
      
      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return StudentQuizResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get student quiz submission error: $e');
      return null;
    }
  }

  // User Creation Methods
  Future<User?> createUser({
    required String registrationNumber,
    required String passwordHash,
    required UserRole role,
    UserStatus status = UserStatus.active,
  }) async {
    try {
      // Check if user already exists
      final existingQuery = _db.collection(Collections.users)
          .where('registration_number', isEqualTo: registrationNumber)
          .limit(1);
      
      final existingSnapshot = await existingQuery.get();
      if (existingSnapshot.docs.isNotEmpty) {
        print('User with registration number $registrationNumber already exists');
        return null;
      }

      // Create new user document
      final userData = {
        'registration_number': registrationNumber,
        'password_hash': passwordHash,
        'role': role.name,
        'status': status.name,
        'created_at': FieldValue.serverTimestamp(),
      };

      final userDocRef = await _db.collection(Collections.users).add(userData);
      
      // Get the created user
      final userDoc = await userDocRef.get();
      final createdUserData = userDoc.data()!;
      createdUserData['id'] = userDoc.id;
      
      print('Successfully created user: ${userDoc.id}');
      return User.fromJson(createdUserData);
    } catch (e) {
      print('Create user error: $e');
      return null;
    }
  }

  Future<Faculty?> createFaculty({
    required String userId,
    required String firstName,
    required String lastName,
    required String departmentId,
    required String email,
    String geminiApiKey = '',
  }) async {
    try {
      // Check if faculty already exists for this user
      final existingQuery = _db.collection(Collections.faculty)
          .where('user_id', isEqualTo: userId)
          .limit(1);
      
      final existingSnapshot = await existingQuery.get();
      if (existingSnapshot.docs.isNotEmpty) {
        print('Faculty already exists for user: $userId');
        return null;
      }

      // Check if email is already in use
      final emailQuery = _db.collection(Collections.faculty)
          .where('email', isEqualTo: email)
          .limit(1);
      
      final emailSnapshot = await emailQuery.get();
      if (emailSnapshot.docs.isNotEmpty) {
        print('Faculty with email $email already exists');
        return null;
      }

      // Create faculty document
      final facultyData = {
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'department_id': departmentId,
        'email': email,
        'gemini_api_key': geminiApiKey,
      };

      final facultyDocRef = await _db.collection(Collections.faculty).add(facultyData);
      
      // Get the created faculty
      final facultyDoc = await facultyDocRef.get();
      final createdFacultyData = facultyDoc.data()!;
      createdFacultyData['id'] = facultyDoc.id;
      
      print('Successfully created faculty: ${facultyDoc.id}');
      return Faculty.fromJson(createdFacultyData);
    } catch (e) {
      print('Create faculty error: $e');
      return null;
    }
  }

  Future<Student?> createStudent({
    required String userId,
    required String firstName,
    required String lastName,
    required String departmentId,
    required String programId,
    required int yearOfStudy,
    required String email,
  }) async {
    try {
      // Check if student already exists for this user
      final existingQuery = _db.collection(Collections.students)
          .where('user_id', isEqualTo: userId)
          .limit(1);
      
      final existingSnapshot = await existingQuery.get();
      if (existingSnapshot.docs.isNotEmpty) {
        print('Student already exists for user: $userId');
        return null;
      }

      // Check if email is already in use
      final emailQuery = _db.collection(Collections.students)
          .where('email', isEqualTo: email)
          .limit(1);
      
      final emailSnapshot = await emailQuery.get();
      if (emailSnapshot.docs.isNotEmpty) {
        print('Student with email $email already exists');
        return null;
      }

      // Create student document
      final studentData = {
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'department_id': departmentId,
        'program_id': programId,
        'year_of_study': yearOfStudy,
        'email': email,
      };

      final studentDocRef = await _db.collection(Collections.students).add(studentData);
      
      // Get the created student
      final studentDoc = await studentDocRef.get();
      final createdStudentData = studentDoc.data()!;
      createdStudentData['id'] = studentDoc.id;
      
      print('Successfully created student: ${studentDoc.id}');
      return Student.fromJson(createdStudentData);
    } catch (e) {
      print('Create student error: $e');
      return null;
    }
  }

  // Complete user creation workflow
  Future<Map<String, dynamic>?> createCompleteUser({
    required String registrationNumber,
    required String passwordHash,
    required UserRole role,
    required String firstName,
    required String lastName,
    required String departmentId,
    required String email,
    String? programId,
    int? yearOfStudy,
    String geminiApiKey = '',
    UserStatus status = UserStatus.active,
  }) async {
    try {
      // Step 1: Create the user
      final user = await createUser(
        registrationNumber: registrationNumber,
        passwordHash: passwordHash,
        role: role,
        status: status,
      );

      if (user == null) {
        print('Failed to create user');
        return null;
      }

      // Step 2: Create role-specific profile
      if (role == UserRole.faculty) {
        final faculty = await createFaculty(
          userId: user.id,
          firstName: firstName,
          lastName: lastName,
          departmentId: departmentId,
          email: email,
          geminiApiKey: geminiApiKey,
        );

        if (faculty == null) {
          // Clean up the created user if faculty creation fails
          await _db.collection(Collections.users).doc(user.id).delete();
          print('Failed to create faculty profile');
          return null;
        }

        return {
          'user': user,
          'faculty': faculty,
        };
      } else if (role == UserRole.student) {
        if (programId == null || yearOfStudy == null) {
          // Clean up the created user
          await _db.collection(Collections.users).doc(user.id).delete();
          print('Program ID and year of study are required for students');
          return null;
        }

        final student = await createStudent(
          userId: user.id,
          firstName: firstName,
          lastName: lastName,
          departmentId: departmentId,
          programId: programId,
          yearOfStudy: yearOfStudy,
          email: email,
        );

        if (student == null) {
          // Clean up the created user if student creation fails
          await _db.collection(Collections.users).doc(user.id).delete();
          print('Failed to create student profile');
          return null;
        }

        return {
          'user': user,
          'student': student,
        };
      }

      return {'user': user};
    } catch (e) {
      print('Create complete user error: $e');
      return null;
    }
  }

  // Update user methods
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _db.collection(Collections.users).doc(userId).update(updates);
      print('Successfully updated user: $userId');
      return true;
    } catch (e) {
      print('Update user error: $e');
      return false;
    }
  }

  Future<bool> updateFaculty(String facultyId, Map<String, dynamic> updates) async {
    try {
      await _db.collection(Collections.faculty).doc(facultyId).update(updates);
      print('Successfully updated faculty: $facultyId');
      return true;
    } catch (e) {
      print('Update faculty error: $e');
      return false;
    }
  }

  Future<bool> updateStudent(String studentId, Map<String, dynamic> updates) async {
    try {
      await _db.collection(Collections.students).doc(studentId).update(updates);
      print('Successfully updated student: $studentId');
      return true;
    } catch (e) {
      print('Update student error: $e');
      return false;
    }
  }

  // Delete user methods
  Future<bool> deleteUser(String userId) async {
    try {
      // Delete role-specific profile first
      final user = await getUserById(userId);
      if (user != null) {
        if (user.role == UserRole.faculty) {
          final faculty = await getFacultyByUserId(userId);
          if (faculty != null) {
            await _db.collection(Collections.faculty).doc(faculty.id).delete();
          }
        } else if (user.role == UserRole.student) {
          final student = await getStudentByUserId(userId);
          if (student != null) {
            await _db.collection(Collections.students).doc(student.id).delete();
          }
        }
      }

      // Delete the user
      await _db.collection(Collections.users).doc(userId).delete();
      print('Successfully deleted user: $userId');
      return true;
    } catch (e) {
      print('Delete user error: $e');
      return false;
    }
  }

  // Course creation method
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
      final faculty = await getFacultyById(facultyId);
      if (faculty == null) {
        print('Faculty with ID $facultyId not found');
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
      
      print('Successfully created course: ${courseDoc.id}');
      return Course.fromJson(createdCourseData);
    } catch (e) {
      print('Create course error: $e');
      return null;
    }
  }

  // Update course method
  Future<bool> updateCourse(String courseId, Map<String, dynamic> updates) async {
    try {
      await _db.collection(Collections.courses).doc(courseId).update(updates);
      print('Successfully updated course: $courseId');
      return true;
    } catch (e) {
      print('Update course error: $e');
      return false;
    }
  }

  // Delete course method
  Future<bool> deleteCourse(String courseId) async {
    try {
      // 1) Find and delete quizzes for this course
      final quizzesQuery = _db.collection(Collections.quizzes)
          .where('course_id', isEqualTo: courseId);
      final quizzesSnapshot = await quizzesQuery.get();
      final quizIds = <String>[];
      for (final doc in quizzesSnapshot.docs) {
        quizIds.add(doc.id);
        await _db.collection(Collections.quizzes).doc(doc.id).delete();
      }

      // 2) Delete quiz questions and results and sessions for each quiz
      for (final quizId in quizIds) {
        final questionsSnapshot = await _db
            .collection(Collections.quizQuestions)
            .where('quiz_id', isEqualTo: quizId)
            .get();
        for (final q in questionsSnapshot.docs) {
          await _db.collection(Collections.quizQuestions).doc(q.id).delete();
        }

        final resultsSnapshot = await _db
            .collection(Collections.studentQuizResults)
            .where('quiz_id', isEqualTo: quizId)
            .get();
        for (final r in resultsSnapshot.docs) {
          await _db.collection(Collections.studentQuizResults).doc(r.id).delete();
        }

        final sessionsSnapshot = await _db
            .collection(Collections.quizSessions)
            .where('quiz_id', isEqualTo: quizId)
            .get();
        for (final s in sessionsSnapshot.docs) {
          await _db.collection(Collections.quizSessions).doc(s.id).delete();
        }
      }

      // 3) Delete timetables for this course
      final timetablesSnapshot = await _db
          .collection(Collections.timetables)
          .where('course_id', isEqualTo: courseId)
          .get();
      for (final t in timetablesSnapshot.docs) {
        await _db.collection(Collections.timetables).doc(t.id).delete();
      }

      // 4) Delete enrollments for this course (if any)
      final enrollmentsSnapshot = await _db
          .collection(Collections.enrollments)
          .where('course_id', isEqualTo: courseId)
          .get();
      for (final e in enrollmentsSnapshot.docs) {
        await _db.collection(Collections.enrollments).doc(e.id).delete();
      }

      // 5) Finally delete the course document
      await _db.collection(Collections.courses).doc(courseId).delete();
      print('Successfully deleted course and cascading data: $courseId');
      return true;
    } catch (e) {
      print('Delete course error: $e');
      return false;
    }
  }

  // Enrollment methods
  Future<bool> createEnrollment({required String studentUserId, required String courseId}) async {
    try {
      // Avoid duplicates
      final existing = await _db
          .collection(Collections.enrollments)
          .where('student_id', isEqualTo: studentUserId)
          .where('course_id', isEqualTo: courseId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return true; // already enrolled
      }

      await _db.collection(Collections.enrollments).add({
        'student_id': studentUserId,
        'course_id': courseId,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Create enrollment error: $e');
      return false;
    }
  }

  Future<int> bulkEnrollStudentsByRegistrationNumbers({
    required String courseId,
    required List<String> registrationNumbers,
  }) async {
    int enrolledCount = 0;
    for (final reg in registrationNumbers) {
      final normalized = reg.trim();
      if (normalized.isEmpty) continue;
      final user = await getUserByRegistrationNumber(normalized, role: UserRole.student);
      if (user == null) continue;
      final ok = await createEnrollment(studentUserId: user.id, courseId: courseId);
      if (ok) enrolledCount++;
    }
    return enrolledCount;
  }

  // TESTING ONLY: Mark all students as present/eligible for all their enrollments.
  // Creates or updates an attendance document per (student_id, course_id) pair.
  Future<int> markAllStudentsPresentForTesting() async {
    int updated = 0;
    try {
      final enrollments = await _db.collection(Collections.enrollments).get();
      final now = DateTime.now();
      for (final e in enrollments.docs) {
        final data = e.data();
        final String studentId = data['student_id'];
        final String courseId = data['course_id'];

        // Try to find an existing attendance record for this student+course
        final existing = await _db
            .collection(Collections.attendance)
            .where('student_id', isEqualTo: studentId)
            .where('course_id', isEqualTo: courseId)
            .limit(1)
            .get();

        final payload = {
          'student_id': studentId,
          'course_id': courseId,
          'status': 'present',
          'biometric_verified': true,
          'is_eligible_for_quiz': true,
          'attendance_date': now,
          'marked_at': now,
        };

        if (existing.docs.isNotEmpty) {
          await _db.collection(Collections.attendance).doc(existing.docs.first.id).set(payload, SetOptions(merge: true));
        } else {
          await _db.collection(Collections.attendance).add(payload);
        }
        updated++;
      }
    } catch (e) {
      print('markAllStudentsPresentForTesting error: $e');
    }
    return updated;
  }

  // Ensure a student user/profile exists for the given registration number.
  // Returns the userId if successful.
  Future<String?> ensureStudentForRegistrationNumber({
    required String registrationNumber,
    required String programId,
    required String departmentId,
    String? name,
    String? email,
    int? yearOfStudy,
  }) async {
    try {
      // 1) Ensure user exists
      User? user = await getUserByRegistrationNumber(registrationNumber, role: UserRole.student);
      if (user == null) {
        final passwordHash = _hashPassword(registrationNumber);
        final createdUser = await createUser(
          registrationNumber: registrationNumber,
          passwordHash: passwordHash,
          role: UserRole.student,
          status: UserStatus.active,
        );
        if (createdUser == null) return null;
        user = createdUser;
      }

      // 2) Ensure student profile exists
      final existingStudent = await getStudentByUserId(user.id);
      if (existingStudent == null) {
        String firstName = 'Student';
        String lastName = registrationNumber;
        if (name != null && name.trim().isNotEmpty) {
          final parts = name.trim().split(RegExp(r"\s+"));
          firstName = parts.first;
          lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        }
        final studentEmail = (email != null && email.trim().isNotEmpty)
            ? email.trim()
            : '${registrationNumber.toLowerCase()}@student.example.edu';
        final createdStudent = await createStudent(
          userId: user.id,
          firstName: firstName,
          lastName: lastName,
          departmentId: departmentId,
          programId: programId,
          yearOfStudy: yearOfStudy ?? 1,
          email: studentEmail,
        );
        if (createdStudent == null) return null;
      }

      return user.id;
    } catch (e) {
      print('ensureStudentForRegistrationNumber error: $e');
      return null;
    }
  }

  // Rebuild students collection by scanning each course roster.
  // For each row, ensure user+student profile and create the enrollment.
  Future<Map<String, int>> rebuildStudentsFromCourses() async {
    int ensured = 0;
    int enrolled = 0;
    try {
      final courses = await getAllCourses();
      for (final course in courses) {
        // Prefer the structured roster; fallback to enrolled_students reg numbers
        final List<Map<String, dynamic>> roster = course.roster;
        final regNumbers = <String>{};
        if (roster.isNotEmpty) {
          for (final row in roster) {
            final reg = (row['REGISTER NO'] ?? row['REG NO'] ?? row['REG'] ?? '').toString().trim();
            if (reg.isEmpty) continue;
            final name = (row['NAME'] ?? '').toString();
            final email = (row['EMAIL'] ?? '').toString();
            final userId = await ensureStudentForRegistrationNumber(
              registrationNumber: reg,
              programId: course.programId,
              departmentId: course.department,
              name: name,
              email: email,
            );
            if (userId != null) {
              ensured++;
              final ok = await createEnrollment(studentUserId: userId, courseId: course.id);
              if (ok) enrolled++;
            }
            regNumbers.add(reg);
          }
        }
        // Also handle/enforce enrollment for any raw registration numbers
        if (course.enrolledStudents.isNotEmpty) {
          for (final reg in course.enrolledStudents) {
            final normalized = reg.trim();
            if (normalized.isEmpty || regNumbers.contains(normalized)) continue;
            final userId = await ensureStudentForRegistrationNumber(
              registrationNumber: normalized,
              programId: course.programId,
              departmentId: course.department,
            );
            if (userId != null) {
              ensured++;
              final ok = await createEnrollment(studentUserId: userId, courseId: course.id);
              if (ok) enrolled++;
            }
          }
        }
      }
    } catch (e) {
      print('rebuildStudentsFromCourses error: $e');
    }
    return {'ensured': ensured, 'enrolled': enrolled};
  }
} 