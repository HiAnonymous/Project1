import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = DatabaseService();
  final result = await db.rebuildStudentsFromCourses();
  // This is a script-like entry; printing to console for visibility
  // ignore: avoid_print
  print('Rebuild complete: ensured ${result['ensured']} students, enrolled ${result['enrolled']} entries.');
} 