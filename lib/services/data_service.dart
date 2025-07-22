import 'package:insightquill/models/user.dart';
import 'package:insightquill/models/course.dart';
import 'package:insightquill/models/quiz.dart';
import 'package:insightquill/models/feedback.dart';
import 'package:insightquill/models/attendance.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Dummy Users
  final List<User> _users = [
    // Faculty
    User(
      id: 'faculty_001',
      name: 'Dr. Sarah Johnson',
      email: 'sarah.johnson@college.edu',
      role: UserRole.faculty,
      department: 'Computer Science',
    ),
    User(
      id: 'faculty_002',
      name: 'Prof. Michael Chen',
      email: 'michael.chen@college.edu',
      role: UserRole.faculty,
      department: 'Mathematics',
    ),
    User(
      id: 'faculty_003',
      name: 'Dr. Emily Davis',
      email: 'emily.davis@college.edu',
      role: UserRole.faculty,
      department: 'Physics',
    ),
    // Students
    User(
      id: 'student_001',
      name: 'Alex Rodriguez',
      email: 'alex.rodriguez@student.college.edu',
      role: UserRole.student,
      registrationNumber: 'CS2021001',
      department: 'Computer Science',
    ),
    User(
      id: 'student_002',
      name: 'Emma Thompson',
      email: 'emma.thompson@student.college.edu',
      role: UserRole.student,
      registrationNumber: 'CS2021002',
      department: 'Computer Science',
    ),
    User(
      id: 'student_003',
      name: 'James Wilson',
      email: 'james.wilson@student.college.edu',
      role: UserRole.student,
      registrationNumber: 'CS2021003',
      department: 'Computer Science',
    ),
    User(
      id: 'student_004',
      name: 'Sophia Martinez',
      email: 'sophia.martinez@student.college.edu',
      role: UserRole.student,
      registrationNumber: 'MATH2021001',
      department: 'Mathematics',
    ),
    User(
      id: 'student_005',
      name: 'Liam Brown',
      email: 'liam.brown@student.college.edu',
      role: UserRole.student,
      registrationNumber: 'PHY2021001',
      department: 'Physics',
    ),
  ];

  // Dummy Courses
  final List<Course> _courses = [
    Course(
      id: 'course_001',
      name: 'Data Structures and Algorithms',
      code: 'CS301',
      facultyId: 'faculty_001',
      department: 'Computer Science',
      enrolledStudents: ['student_001', 'student_002', 'student_003'],
    ),
    Course(
      id: 'course_002',
      name: 'Linear Algebra',
      code: 'MATH201',
      facultyId: 'faculty_002',
      department: 'Mathematics',
      enrolledStudents: ['student_004', 'student_001', 'student_002'],
    ),
    Course(
      id: 'course_003',
      name: 'Quantum Physics',
      code: 'PHY401',
      facultyId: 'faculty_003',
      department: 'Physics',
      enrolledStudents: ['student_005', 'student_003'],
    ),
  ];

  // Dummy Timetable
  final List<Timetable> _timetables = [
    Timetable(
      id: 'tt_001',
      courseId: 'course_001',
      courseName: 'Data Structures and Algorithms',
      facultyName: 'Dr. Sarah Johnson',
      startTime: DateTime.now().copyWith(hour: 9, minute: 0),
      endTime: DateTime.now().copyWith(hour: 9, minute: 50),
      classroom: 'CS Lab 1',
      dayOfWeek: 'Monday',
    ),
    Timetable(
      id: 'tt_002',
      courseId: 'course_002',
      courseName: 'Linear Algebra',
      facultyName: 'Prof. Michael Chen',
      startTime: DateTime.now().copyWith(hour: 11, minute: 0),
      endTime: DateTime.now().copyWith(hour: 11, minute: 50),
      classroom: 'Math Room 202',
      dayOfWeek: 'Tuesday',
    ),
    Timetable(
      id: 'tt_003',
      courseId: 'course_003',
      courseName: 'Quantum Physics',
      facultyName: 'Dr. Emily Davis',
      startTime: DateTime.now().copyWith(hour: 14, minute: 0),
      endTime: DateTime.now().copyWith(hour: 14, minute: 50),
      classroom: 'Physics Lab',
      dayOfWeek: 'Wednesday',
    ),
  ];

  // Dummy Quizzes
  List<Quiz> _quizzes = [];
  List<QuizSubmission> _submissions = [];
  List<Feedback> _feedbacks = [];
  List<BiometricData> _biometricData = [];
  List<AttendanceRecord> _attendanceRecords = [];

  // Initialize dummy quizzes
  void _initializeQuizzes() {
    if (_quizzes.isNotEmpty) return;
    
    _quizzes.addAll([
      Quiz(
        id: 'quiz_001',
        courseId: 'course_001',
        facultyId: 'faculty_001',
        title: 'Arrays and Linked Lists',
        questions: [
          Question(
            id: 'q1',
            text: 'What is the time complexity of inserting at the beginning of a linked list?',
            options: ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'],
            correctAnswer: 0,
            type: QuestionType.text,
          ),
          Question(
            id: 'q2',
            text: 'Which data structure follows LIFO principle?',
            options: ['Queue', 'Stack', 'Array', 'Tree'],
            correctAnswer: 1,
            type: QuestionType.text,
          ),
          Question(
            id: 'q3',
            text: 'In array indexing, what is the index of the first element?',
            options: ['1', '0', '-1', 'undefined'],
            correctAnswer: 1,
            type: QuestionType.text,
          ),
          Question(
            id: 'q4',
            text: 'Which operation is not efficient in arrays?',
            options: ['Access', 'Insertion at end', 'Insertion at beginning', 'Searching'],
            correctAnswer: 2,
            type: QuestionType.text,
          ),
          Question(
            id: 'q5',
            text: 'What is the space complexity of a singly linked list with n nodes?',
            options: ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'],
            correctAnswer: 1,
            type: QuestionType.text,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        scheduledAt: DateTime.now().add(const Duration(minutes: 35)),
        isActive: true,
      ),
    ]);

    // Generate biometric data (simulating student presence)
    _biometricData.addAll([
      BiometricData(
        userId: 'student_001',
        courseId: 'course_001',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isPresent: true,
      ),
      BiometricData(
        userId: 'student_002',
        courseId: 'course_001',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        isPresent: true,
      ),
      BiometricData(
        userId: 'student_003',
        courseId: 'course_001',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isPresent: false,
      ),
    ]);

    // Generate attendance records with your specifications
    final classStartTime = DateTime.now().subtract(const Duration(minutes: 40)); // Class started 40 mins ago
    
    _attendanceRecords.addAll([
      // Student 1: Present, spent 35 minutes, eligible for quiz
      AttendanceRecord(
        id: 'att_001',
        studentId: 'student_001',
        courseId: 'course_001',
        classStartTime: classStartTime,
        checkInTime: classStartTime.add(const Duration(minutes: 5)), // Checked in 5 mins after class started
        isPresent: true,
        minutesAttended: 35,
        isEligibleForQuiz: true,
      ),
      // Student 2: Present, spent 35 minutes, eligible for quiz
      AttendanceRecord(
        id: 'att_002',
        studentId: 'student_002',
        courseId: 'course_001',
        classStartTime: classStartTime,
        checkInTime: classStartTime.add(const Duration(minutes: 2)),
        isPresent: true,
        minutesAttended: 35,
        isEligibleForQuiz: true,
      ),
      // Student 3: Logged in but absent from class, not eligible for quiz
      AttendanceRecord(
        id: 'att_003',
        studentId: 'student_003',
        courseId: 'course_001',
        classStartTime: classStartTime,
        checkInTime: classStartTime.add(const Duration(minutes: 1)),
        checkOutTime: classStartTime.add(const Duration(minutes: 5)), // Left early
        isPresent: false, // Marked absent by biometric/faculty
        minutesAttended: 4,
        isEligibleForQuiz: false,
      ),
    ]);

    // Generate some dummy quiz submissions to show analytics
    _submissions.addAll([
      QuizSubmission(
        id: 'sub_001',
        quizId: 'quiz_001',
        studentId: 'student_001',
        answers: {'q1': 0, 'q2': 1, 'q3': 1, 'q4': 2, 'q5': 1},
        submittedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        score: 5,
        totalQuestions: 5,
      ),
      QuizSubmission(
        id: 'sub_002',
        quizId: 'quiz_001',
        studentId: 'student_002',
        answers: {'q1': 0, 'q2': 1, 'q3': 1, 'q4': 1, 'q5': 1},
        submittedAt: DateTime.now().subtract(const Duration(minutes: 12)),
        score: 4,
        totalQuestions: 5,
      ),
    ]);

    // Generate some dummy feedback
    _feedbacks.addAll([
      Feedback(
        id: 'fb_001',
        studentId: 'student_001',
        facultyId: 'faculty_001',
        courseId: 'course_001',
        rating: 5,
        comment: 'Excellent lecture! Very clear explanations of data structures.',
        submittedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Feedback(
        id: 'fb_002',
        studentId: 'student_002',
        facultyId: 'faculty_001',
        courseId: 'course_001',
        rating: 4,
        comment: 'Good content, would like more practical examples.',
        submittedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    ]);
  }

  // Authentication
  User? authenticate(String identifier, UserRole role) {
    if (role == UserRole.faculty) {
      return _users.where((u) => u.role == UserRole.faculty && u.email == identifier).firstOrNull;
    } else {
      return _users.where((u) => u.role == UserRole.student && u.registrationNumber == identifier).firstOrNull;
    }
  }

  // User methods
  List<User> getFacultyMembers() => _users.where((u) => u.role == UserRole.faculty).toList();
  List<User> getStudents() => _users.where((u) => u.role == UserRole.student).toList();
  User? getUserById(String id) => _users.where((u) => u.id == id).firstOrNull;

  // Course methods
  List<Course> getCoursesByFaculty(String facultyId) => _courses.where((c) => c.facultyId == facultyId).toList();
  List<Course> getCoursesByStudent(String studentId) => _courses.where((c) => c.enrolledStudents.contains(studentId)).toList();
  Course? getCourseById(String id) => _courses.where((c) => c.id == id).firstOrNull;

  // Timetable methods
  List<Timetable> getTimetableByStudent(String studentId) {
    final studentCourses = getCoursesByStudent(studentId);
    return _timetables.where((t) => studentCourses.any((c) => c.id == t.courseId)).toList();
  }

  List<Timetable> getTimetableByFaculty(String facultyId) {
    final facultyCourses = getCoursesByFaculty(facultyId);
    return _timetables.where((t) => facultyCourses.any((c) => c.id == t.courseId)).toList();
  }

  // Quiz methods
  void createQuiz(Quiz quiz) => _quizzes.add(quiz);
  
  List<Quiz> getQuizzesByFaculty(String facultyId) {
    _initializeQuizzes();
    return _quizzes.where((q) => q.facultyId == facultyId).toList();
  }

  List<Quiz> getActiveQuizzesForStudent(String studentId) {
    _initializeQuizzes();
    final studentCourses = getCoursesByStudent(studentId);
    return _quizzes.where((q) => 
      studentCourses.any((c) => c.id == q.courseId) && 
      q.canStart() &&
      _isStudentEligibleForQuiz(studentId, q.courseId)
    ).toList();
  }

  Quiz? getQuizById(String id) {
    _initializeQuizzes();
    return _quizzes.where((q) => q.id == id).firstOrNull;
  }

  void updateQuiz(Quiz quiz) {
    final index = _quizzes.indexWhere((q) => q.id == quiz.id);
    if (index != -1) _quizzes[index] = quiz;
  }

  // Quiz submission methods
  void submitQuiz(QuizSubmission submission) => _submissions.add(submission);
  
  List<QuizSubmission> getSubmissionsByQuiz(String quizId) => 
    _submissions.where((s) => s.quizId == quizId).toList();
  
  QuizSubmission? getSubmissionByStudentAndQuiz(String studentId, String quizId) =>
    _submissions.where((s) => s.studentId == studentId && s.quizId == quizId).firstOrNull;

  // Feedback methods
  void submitFeedback(Feedback feedback) => _feedbacks.add(feedback);
  
  List<Feedback> getFeedbacksByFaculty(String facultyId) =>
    _feedbacks.where((f) => f.facultyId == facultyId).toList();

  FeedbackSummary getFeedbackSummary(String facultyId, String courseId) {
    final courseFeedbacks = _feedbacks.where((f) => f.facultyId == facultyId && f.courseId == courseId).toList();
    
    if (courseFeedbacks.isEmpty) {
      return FeedbackSummary(
        facultyId: facultyId,
        courseId: courseId,
        averageRating: 0.0,
        totalFeedbacks: 0,
        ratingDistribution: {},
        recentComments: [],
      );
    }

    final totalRating = courseFeedbacks.fold<double>(0, (sum, f) => sum + f.rating);
    final avgRating = totalRating / courseFeedbacks.length;
    
    final distribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      distribution[i] = courseFeedbacks.where((f) => f.rating == i).length;
    }

    final recentComments = courseFeedbacks
        .where((f) => f.comment.isNotEmpty)
        .map((f) => f.comment)
        .take(5)
        .toList();

    return FeedbackSummary(
      facultyId: facultyId,
      courseId: courseId,
      averageRating: avgRating,
      totalFeedbacks: courseFeedbacks.length,
      ratingDistribution: distribution,
      recentComments: recentComments,
    );
  }

  // Biometric methods
  bool _isStudentPresent(String studentId, String courseId) {
    final recentData = _biometricData.where((b) => 
      b.userId == studentId && 
      b.courseId == courseId &&
      DateTime.now().difference(b.timestamp).inMinutes < 60
    ).toList();
    
    return recentData.isNotEmpty && recentData.last.isPresent;
  }

  List<String> getPresentStudents(String courseId) {
    return _biometricData
        .where((b) => 
          b.courseId == courseId && 
          b.isPresent &&
          DateTime.now().difference(b.timestamp).inMinutes < 60
        )
        .map((b) => b.userId)
        .toSet()
        .toList();
  }

  // Attendance methods
  bool _isStudentEligibleForQuiz(String studentId, String courseId) {
    _initializeQuizzes(); // Ensure attendance data is initialized
    final record = _attendanceRecords.where((a) => 
      a.studentId == studentId && 
      a.courseId == courseId
    ).firstOrNull;
    
    return record != null && record.isEligibleForQuiz;
  }

  AttendanceRecord? getAttendanceRecord(String studentId, String courseId) {
    _initializeQuizzes(); // Ensure attendance data is initialized
    return _attendanceRecords.where((a) => 
      a.studentId == studentId && 
      a.courseId == courseId
    ).firstOrNull;
  }

  AttendanceSummary getAttendanceSummary(String courseId) {
    _initializeQuizzes(); // Ensure attendance data is initialized
    final courseAttendance = _attendanceRecords.where((a) => a.courseId == courseId).toList();
    final course = getCourseById(courseId);
    final totalStudents = course?.enrolledStudents.length ?? 0;
    final presentStudents = courseAttendance.where((a) => a.isPresent).length;
    final eligibleForQuiz = courseAttendance.where((a) => a.isEligibleForQuiz).length;
    
    return AttendanceSummary(
      courseId: courseId,
      totalStudents: totalStudents,
      presentStudents: presentStudents,
      eligibleForQuiz: eligibleForQuiz,
      records: courseAttendance,
    );
  }

  void updateAttendanceRecord(AttendanceRecord record) {
    final index = _attendanceRecords.indexWhere((a) => a.id == record.id);
    if (index != -1) {
      _attendanceRecords[index] = record;
    } else {
      _attendanceRecords.add(record);
    }
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}