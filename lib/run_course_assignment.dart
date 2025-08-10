import 'assign_course_to_faculty.dart';

void main() async {
  print('🎓 Course Assignment System');
  print('==========================\n');
  
  final courseService = CourseAssignmentService();
  
  // Assign a course to John Doe
  await courseService.assignCourseToJohnDoe();
  
  print('\n📋 Current course assignments:');
  await courseService.listJohnDoesCourses();
  
  print('\n✅ Course assignment process completed!');
} 