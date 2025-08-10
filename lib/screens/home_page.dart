import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:insightquill/providers/app_provider.dart';
import 'package:insightquill/screens/login_page.dart';
import 'package:insightquill/screens/faculty_dashboard.dart';
import 'package:insightquill/screens/student_dashboard.dart';
import 'package:insightquill/models/user.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        print('HomePage: Building with isLoading: ${appProvider.isLoading}, isLoggedIn: ${appProvider.isLoggedIn}');
        print('HomePage: Current user: ${appProvider.currentUser?.registrationNumber}, role: ${appProvider.currentUser?.role}');
        
        if (appProvider.isLoading) {
          print('HomePage: Showing loading screen');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!appProvider.isLoggedIn) {
          print('HomePage: User not logged in, showing login page');
          return const LoginPage();
        }

        if (appProvider.currentUser?.role == UserRole.faculty) {
          print('HomePage: User is faculty, showing faculty dashboard');
          return const FacultyDashboard();
        } else {
          print('HomePage: User is student, showing student dashboard');
          return const StudentDashboard();
        }
      },
    );
  }
}