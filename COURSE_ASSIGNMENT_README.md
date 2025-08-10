# Course Assignment System

This system allows you to assign courses to faculty members, specifically John Doe in this example.

## Overview

The course assignment system consists of:

1. **CourseAssignmentService** (`lib/assign_course_to_faculty.dart`) - Main service for course operations
2. **DatabaseService** (`lib/services/database_service.dart`) - Enhanced with course CRUD operations
3. **Run Script** (`lib/run_course_assignment.dart`) - Simple script to execute course assignment

## Features

### ✅ Faculty Management
- Find existing faculty by email
- Create new faculty if not found
- Automatic user account creation with proper role assignment

### ✅ Course Management
- Create courses with full details
- Assign courses to specific faculty members
- Validate faculty existence before assignment
- Support for multiple course assignments

### ✅ Course Details
- Course name and code
- Program association
- Department assignment
- Faculty assignment
- Enrolled students tracking

## Usage

### Quick Start

1. **Run the course assignment script:**
   ```bash
   cd Project1
   dart lib/run_course_assignment.dart
   ```

2. **Or run the main assignment file:**
   ```bash
   dart lib/assign_course_to_faculty.dart
   ```

### What the script does:

1. **Finds or Creates John Doe Faculty:**
   - Searches for existing faculty with email: `john.doe@university.edu`
   - If not found, creates a new faculty account with:
     - Registration Number: `FAC001`
     - Name: John Doe
     - Department: Computer Science
     - Email: john.doe@university.edu

2. **Assigns Course:**
   - Creates "Introduction to Computer Science" (CS101)
   - Assigns it to John Doe
   - Sets department as "Computer Science"

3. **Lists Current Assignments:**
   - Shows all courses currently assigned to John Doe

## Course Assignment Details

### Default Course Created:
- **Name:** Introduction to Computer Science
- **Code:** CS101
- **Program:** BSc Computer Science
- **Department:** Computer Science
- **Faculty:** John Doe

### Multiple Course Assignment

You can also assign multiple courses by uncommenting this line in the main function:

```dart
await courseService.assignMultipleCoursesToJohnDoe();
```

This will create:
1. CS101 - Introduction to Computer Science
2. CS201 - Data Structures and Algorithms  
3. CS301 - Database Management Systems

## Database Structure

### Faculty Document:
```json
{
  "user_id": "user_document_id",
  "first_name": "John",
  "last_name": "Doe",
  "department_id": "dept_cs",
  "email": "john.doe@university.edu",
  "gemini_api_key": "your_gemini_api_key_here"
}
```

### Course Document:
```json
{
  "program_id": "prog_bsc_cs",
  "course_name": "Introduction to Computer Science",
  "course_code": "CS101",
  "faculty_id": "faculty_document_id",
  "department": "Computer Science",
  "enrolled_students": []
}
```

## API Methods

### CourseAssignmentService Methods:

- `findOrCreateJohnDoe()` - Finds or creates John Doe faculty
- `createCourse()` - Creates a new course and assigns it to faculty
- `assignCourseToJohnDoe()` - Main method to assign course to John Doe
- `assignMultipleCoursesToJohnDoe()` - Assigns multiple courses
- `listJohnDoesCourses()` - Lists all courses assigned to John Doe

### DatabaseService Methods (Enhanced):

- `createCourse()` - Creates a new course
- `updateCourse()` - Updates existing course
- `deleteCourse()` - Deletes a course
- `getCoursesByFaculty()` - Gets all courses for a faculty

## Error Handling

The system includes comprehensive error handling:
- Faculty validation before course creation
- Duplicate email checking
- Database operation error catching
- Detailed logging for debugging

## Customization

To assign courses to different faculty or create different courses:

1. **Change faculty details** in `findOrCreateJohnDoe()` method
2. **Modify course details** in `assignCourseToJohnDoe()` method
3. **Add more courses** in `assignMultipleCoursesToJohnDoe()` method

## Requirements

- Firebase Firestore database
- Proper Firebase configuration
- Required dependencies in `pubspec.yaml`:
  - `cloud_firestore`
  - `crypto`

## Output Example

```
🎓 Course Assignment System
==========================

🚀 Starting course assignment to John Doe...

✅ Found existing John Doe faculty: faculty_document_id
👨‍🏫 Faculty: John Doe
📧 Email: john.doe@university.edu
🏢 Department: dept_cs

✅ Successfully created course: course_document_id
✅ Course successfully assigned to John Doe!
📚 Course Details:
   - Name: Introduction to Computer Science
   - Code: CS101
   - Department: Computer Science
   - Faculty ID: faculty_document_id
   - Enrolled Students: 0

📋 Current course assignments:

📚 Courses assigned to John Doe (1 total):
1. CS101 - Introduction to Computer Science
   Department: Computer Science
   Enrolled Students: 0

✅ Course assignment process completed!
``` 