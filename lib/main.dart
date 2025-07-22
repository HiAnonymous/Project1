import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:insightquill/theme.dart';
import 'package:insightquill/providers/app_provider.dart';
import 'package:insightquill/screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: 'InsightQuill - College Feedback System',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
