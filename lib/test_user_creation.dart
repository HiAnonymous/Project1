import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'examples/user_creation_example.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('🚀 Starting User Creation Test...\n');
  
  final example = UserCreationExample();
  
  // Test creating a faculty member
  print('📝 Testing Faculty Creation...');
  await example.createFacultyExample();
  print('');
  
  // Test creating a student
  print('📝 Testing Student Creation...');
  await example.createStudentExample();
  print('');
  
  // Test creating multiple users
  print('📝 Testing Multiple Users Creation...');
  await example.createMultipleUsersExample();
  print('');
  
  print('✅ User Creation Tests Completed!');
} 