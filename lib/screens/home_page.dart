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
        if (appProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!appProvider.isLoggedIn) {
          return const LoginPage();
        }

        if (appProvider.currentUser?.role == UserRole.faculty) {
          return const FacultyDashboard();
        } else {
          return const StudentDashboard();
        }
      },
    );
  }
}