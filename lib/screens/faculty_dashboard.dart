import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:insightquill/providers/app_provider.dart';
import 'package:insightquill/services/database_service.dart';
import 'package:insightquill/models/course.dart';
import 'package:insightquill/models/quiz.dart';
import 'package:insightquill/models/user.dart';
import 'package:insightquill/models/timetable.dart';
import 'package:insightquill/screens/quiz_creation_page.dart';
import 'package:insightquill/screens/quiz_analytics_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'dart:async';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  final DatabaseService _dataService = DatabaseService();
  int _currentIndex = 0;
  Timer? _tickTimer;

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    // Refresh time-sensitive sections every second (for live timers)
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appProvider = Provider.of<AppProvider>(context);
    final user = appProvider.currentUser!;


    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Faculty Dashboard',
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: Icon(
              Icons.logout,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildOverviewTab(user.id, theme),
          _buildQuizzesTab(user.id, theme),
          _buildAnalyticsTab(user.id, theme),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz),
            label: 'Quizzes',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(String userId, ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchOverviewData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No data found.'));
        }

        final courses = snapshot.data!['courses'] as List<Course>;
        final upcomingClasses = snapshot.data!['upcomingClasses'] as List<Timetable>;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(theme),
                const SizedBox(height: 20),
                _buildStatsCards(courses, theme),
                const SizedBox(height: 20),
                _buildCoursesSection(courses, theme),
                const SizedBox(height: 20),
                _buildCreateCourseButton(theme),
                const SizedBox(height: 20),
                _buildUpcomingClasses(upcomingClasses, theme),
                const SizedBox(height: 20),
                _buildRecentQuizzes(userId, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchOverviewData(String userId) async {
    final faculty = await _dataService.getFacultyByUserId(userId);
    if (faculty == null) {
      return {
        'courses': <Course>[],
        'upcomingClasses': <Timetable>[],
      };
    }
    final courses = await _dataService.getCoursesByFaculty(faculty.id);
    final timetables = await _dataService.getTimetableByFaculty(faculty.id);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Keep only classes today that are either upcoming (not started yet) or ongoing (now between start/end)
    final upcomingClasses = timetables.where((t) {
      final start = DateTime(today.year, today.month, today.day, t.startTime.hour, t.startTime.minute);
      final end = DateTime(today.year, today.month, today.day, t.endTime.hour, t.endTime.minute);
      final isToday = t.dayOfWeek.toLowerCase() == _getDayName(now.weekday).toLowerCase();
      final isOngoing = now.isAfter(start) && now.isBefore(end);
      final isUpcoming = now.isBefore(start);
      return isToday && (isUpcoming || isOngoing);
    }).toList()
      ..sort((a, b) {
        final aStart = DateTime(today.year, today.month, today.day, a.startTime.hour, a.startTime.minute);
        final bStart = DateTime(today.year, today.month, today.day, b.startTime.hour, b.startTime.minute);
        return aStart.compareTo(bStart);
      });

    return {
      'courses': courses,
      'upcomingClasses': upcomingClasses,
    };
  }

  Widget _buildWelcomeCard(ThemeData theme) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final user = appProvider.currentUser!;

    return FutureBuilder<Faculty?>(
      future: _dataService.getFacultyById(user.id),
      builder: (context, snapshot) {
        final faculty = snapshot.data;
        return Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    faculty != null ? "${faculty.firstName[0]}${faculty.lastName[0]}" : "NA",
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        faculty != null ? "Dr. ${faculty.firstName} ${faculty.lastName}" : "Faculty",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        faculty?.departmentId ?? '', // This should be department name
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(List<Course> courses, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Courses',
            value: courses.length.toString(),
            icon: Icons.book,
            color: theme.colorScheme.tertiary,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Total Students',
            value: courses.fold<int>(0, (sum, c) => sum + c.enrolledStudents.length).toString(),
            icon: Icons.people,
            color: theme.colorScheme.secondary,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateCourseButton(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: () async {
          final nameController = TextEditingController();
          final codeController = TextEditingController();
          final programIdController = TextEditingController();
          final departmentController = TextEditingController();
          final startTimeController = TextEditingController();
          final endTimeController = TextEditingController();
          String dayOfWeek = 'Monday';

          await showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Create Course'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Course Name'),
                      ),
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Course Code'),
                      ),
                      TextField(
                        controller: programIdController,
                        decoration: const InputDecoration(labelText: 'Program ID'),
                      ),
                      TextField(
                        controller: departmentController,
                        decoration: const InputDecoration(labelText: 'Department'),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Class Timings', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startTimeController,
                              decoration: const InputDecoration(hintText: 'Start (HH:MM)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: endTimeController,
                              decoration: const InputDecoration(hintText: 'End (HH:MM)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: dayOfWeek,
                        items: const [
                          'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
                        ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => dayOfWeek = v ?? 'Monday',
                        decoration: const InputDecoration(labelText: 'Day of Week'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final appProvider = Provider.of<AppProvider>(context, listen: false);
                      final userId = appProvider.currentUser!.id;
                      final faculty = await _dataService.getFacultyByUserId(userId);

                      final name = nameController.text.trim();
                      final code = codeController.text.trim();
                      final programId = programIdController.text.trim();
                      final department = departmentController.text.trim();

                      if (name.isEmpty || code.isEmpty || programId.isEmpty || department.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all fields')),
                        );
                        return;
                      }

                      // Parse HH:MM times
                      DateTime? startTime;
                      DateTime? endTime;
                      try {
                        final now = DateTime.now();
                        if (startTimeController.text.trim().isNotEmpty && endTimeController.text.trim().isNotEmpty) {
                          final sParts = startTimeController.text.trim().split(':').map((e)=>int.parse(e)).toList();
                          final eParts = endTimeController.text.trim().split(':').map((e)=>int.parse(e)).toList();
                          startTime = DateTime(now.year, now.month, now.day, sParts[0], sParts[1]);
                          endTime = DateTime(now.year, now.month, now.day, eParts[0], eParts[1]);
                        }
                      } catch (_) {}

                      if (faculty == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Faculty profile not found for current user')),
                        );
                        return;
                      }

                      final created = await _dataService.createCourse(
                        programId: programId,
                        name: name,
                        code: code,
                        facultyId: faculty.id,
                        department: department,
                      );

                      if (created != null) {
                        // Optional: create a timetable entry for provided timings
                        if (startTime != null && endTime != null) {
                          final facultyName = faculty.firstName + ' ' + faculty.lastName;
                          await _dataService.createTimetable(
                            courseId: created.id,
                            courseName: created.name,
                            facultyName: facultyName,
                            startTime: startTime,
                            endTime: endTime,
                            dayOfWeek: dayOfWeek,
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Course created successfully')),
                        );
                        if (mounted) {
                          setState(() {});
                        }
                        Navigator.pop(dialogContext);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to create course')),
                        );
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          );
        },
        icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        label: Text(
          'Create Course',
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesSection(List<Course> courses, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Courses',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          Card(
            elevation: 0,
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No courses yet. Create one to get started.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          ...courses.map((c) => _buildCourseRow(c, theme)).toList(),
      ],
    );
  }

  Widget _buildCourseRow(Course course, ThemeData theme) {
    final hasStudents = course.roster.isNotEmpty || course.enrolledStudents.isNotEmpty;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${course.name} (${course.code})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    hasStudents ? 'Students: ${course.roster.isNotEmpty ? course.roster.length : course.enrolledStudents.length}' : 'No students uploaded',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            if (!hasStudents)
              ElevatedButton.icon(
                onPressed: () => _uploadStudentsForCourse(course),
                icon: Icon(Icons.upload_file, color: theme.colorScheme.onPrimary),
                label: Text('Upload Students', style: TextStyle(color: theme.colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
              ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Delete course',
              onPressed: () => _confirmAndDeleteCourse(course),
              icon: Icon(Icons.delete, color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadStudentsForCourse(Course course) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes ?? await result.files.single.xFile.readAsBytes();
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      final firstSheet = excel.sheets.values.first;
      // Parse roster rows with rich columns
      final List<Map<String, dynamic>> roster = [];
      bool headerParsed = false;
      List<String> headers = [];
      for (final row in firstSheet.rows) {
        final cells = row.map((c) => c?.value?.toString() ?? '').toList();
        if (!headerParsed) {
          headers = cells.map((h) => h.trim()).toList();
          headerParsed = true;
          continue;
        }
        if (cells.every((c) => c.trim().isEmpty)) continue;
        final map = <String, dynamic>{};
        for (int i = 0; i < headers.length && i < cells.length; i++) {
          map[headers[i]] = cells[i].trim();
        }
        // Normalize required fields
        final registerNo = _firstNonEmpty(map, ['REGISTER NO', 'REGISTER_NO', 'REG NO', 'REG_NO', 'REG']);
        final name = _firstNonEmpty(map, ['NAME', 'STUDENT NAME', 'STUDENT_NAME']);
        final email = _firstNonEmpty(map, ['EMAIL', 'E-MAIL', 'MAIL']);
        if (registerNo.isEmpty && name.isEmpty && email.isEmpty) continue;
        map['REGISTER NO'] = registerNo;
        map['NAME'] = name;
        map['EMAIL'] = email;
        // Default attendance
        map['ATTENDANCE'] = 'Absent';
        roster.add(map);
      }

      if (roster.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid student rows found in Excel')));
        return;
      }

      // For testing: mark a few as Present
      for (int i = 0; i < roster.length; i++) {
        if (i % 5 == 0) {
          roster[i]['ATTENDANCE'] = 'Present';
        }
      }

      await _dataService.updateCourse(course.id, {
        'roster': roster,
        'enrolled_students': roster
            .map((e) => e['REGISTER NO'] ?? '')
            .where((e) => (e as String).isNotEmpty)
            .toList(),
      });

      if (mounted) setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded ${roster.length} students to ${course.code}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload students: $e')));
    }
  }

  String _firstNonEmpty(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      if (row.containsKey(k) && (row[k]?.toString().trim().isNotEmpty ?? false)) {
        return row[k].toString().trim();
      }
    }
    return '';
  }

  Future<void> _confirmAndDeleteCourse(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete ${course.code} - ${course.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final ok = await _dataService.deleteCourse(course.id);
      if (ok) {
        if (mounted) setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course deleted')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete course')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting course: $e')));
    }
  }

  Widget _buildUpcomingClasses(List<Timetable> upcomingClasses, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Classes',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (upcomingClasses.isEmpty)
          Card(
            elevation: 0,
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No upcoming or ongoing classes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          )
        else
          ...upcomingClasses.map((timetable) => _buildClassCard(timetable, theme)),
      ],
    );
  }

  Widget _buildClassCard(Timetable timetable, ThemeData theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(today.year, today.month, today.day, timetable.startTime.hour, timetable.startTime.minute);
    final end = DateTime(today.year, today.month, today.day, timetable.endTime.hour, timetable.endTime.minute);
    final isOngoing = now.isAfter(start) && now.isBefore(end);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOngoing
                    ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isOngoing ? Icons.play_circle_fill : Icons.schedule,
                color: isOngoing ? theme.colorScheme.tertiary : theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timetable.courseName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${DateFormat.jm().format(timetable.startTime)} - ${DateFormat.jm().format(timetable.endTime)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOngoing ? theme.colorScheme.tertiary.withValues(alpha: 0.2) : theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOngoing ? 'Class ongoing' : 'Class upcoming',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isOngoing ? theme.colorScheme.tertiary : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timetable.classroom,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentQuizzes(String userId, ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: () async {
        final faculty = await _dataService.getFacultyByUserId(userId);
        if (faculty == null) return {'hide': true, 'quizzes': <Quiz>[]};
        final courses = await _dataService.getCoursesByFaculty(faculty.id);
        if (courses.isEmpty) return {'hide': true, 'quizzes': <Quiz>[]};
        final quizzes = await _dataService.getQuizzesByFaculty(faculty.id);
        final courseIds = courses.map((c) => c.id).toSet();
        final filtered = quizzes.where((q) => courseIds.contains(q.courseId)).toList();
        return {'hide': false, 'quizzes': filtered};
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final shouldHide = snapshot.data!['hide'] as bool;
        if (shouldHide) return const SizedBox.shrink();

        final quizzes = (snapshot.data!['quizzes'] as List<Quiz>).take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Quizzes',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (quizzes.isEmpty)
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No quizzes created yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              )
            else
              ...quizzes.map((quiz) => _buildQuizCard(quiz, theme)),
          ],
        );
      },
    );
  }

  Widget _buildQuizCard(Quiz quiz, ThemeData theme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                quiz.quizTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: quiz.status == 'active'
                    ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                quiz.status,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: quiz.status == 'active'
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesTab(String userId, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'My Quizzes',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizCreationPage()),
                ),
                icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
                label: Text(
                  'Create Quiz',
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Quiz>>(
            future: () async {
              final faculty = await _dataService.getFacultyByUserId(userId);
              if (faculty == null) return <Quiz>[];
              // Filter out quizzes whose courses have been removed
              final courses = await _dataService.getCoursesByFaculty(faculty.id);
              if (courses.isEmpty) return <Quiz>[];
              final courseIds = courses.map((c) => c.id).toSet();
              final quizzes = await _dataService.getQuizzesByFaculty(faculty.id);
              return quizzes.where((q) => courseIds.contains(q.courseId)).toList();
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No quizzes created yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first quiz to get started',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final quizzes = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  return _buildDetailedQuizCard(quiz, theme);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedQuizCard(Quiz quiz, ThemeData theme) {
    return FutureBuilder<Timetable?>(
      future: _getTimetableForQuiz(quiz),
      builder: (context, timetableSnapshot) {
        if (timetableSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator())));
        }
        if (timetableSnapshot.hasError) {
          return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Error loading timetable'))));
        }

        final timetable = timetableSnapshot.data; // may be null if not set

        return FutureBuilder<Course?>(
          future: _dataService.getCourseById(quiz.courseId),
          builder: (context, courseSnapshot) {
            if (courseSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator())));
            }
            if (courseSnapshot.hasError || !courseSnapshot.hasData) {
              return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Error loading course'))));
            }

            final course = courseSnapshot.data;

            return StreamBuilder<List<StudentQuizResult>>(
              stream: _dataService.streamSubmissionsByQuiz(quiz.id),
              builder: (context, submissionsSnapshot) {
                if (submissionsSnapshot.connectionState == ConnectionState.waiting && !submissionsSnapshot.hasData) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator())));
                }
                if (submissionsSnapshot.hasError) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Error loading submissions'))));
                }

                final submissions = submissionsSnapshot.data ?? [];

                // Calculate auto session window: start 3 min after class start, run 7 minutes
                final now = DateTime.now();
                DateTime? autoStart;
                DateTime? autoEnd;
                bool hasStarted = false;
                bool hasEnded = false;
                bool isOngoing = false;
                if (timetable != null) {
                  autoStart = DateTime(now.year, now.month, now.day, timetable.startTime.hour, timetable.startTime.minute)
                      .add(const Duration(minutes: 3));
                  autoEnd = autoStart.add(const Duration(minutes: 7));
                  hasStarted = now.isAfter(autoStart);
                  hasEnded = now.isAfter(autoEnd);
                  isOngoing = hasStarted && !hasEnded && !quiz.isPaused && !quiz.isCancelled;
                }

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz.quizTitle,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    course?.name ?? 'Unknown Course',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                if (!quiz.attendanceUploaded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Attendance pending', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onErrorContainer)),
                                  ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildQuizInfo('Questions', '10', Icons.quiz, theme),
                            const SizedBox(width: 16),
                            _buildQuizInfo('Duration', '7m', Icons.timer, theme),
                            const SizedBox(width: 16),
                            _buildQuizInfo('Submissions', submissions.length.toString(), Icons.assignment_turned_in, theme),
                            const SizedBox(width: 16),
                            _buildQuizInfo('Status', timetable == null ? 'no timetable' : (isOngoing ? 'running' : (hasEnded ? 'ended' : 'scheduled')), Icons.schedule, theme),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: quiz.status == 'active'
                                    ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
                                    : quiz.status == 'cancelled'
                                        ? theme.colorScheme.error.withValues(alpha: 0.2)
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                quiz.status,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: quiz.status == 'active'
                                      ? theme.colorScheme.tertiary
                                      : quiz.status == 'cancelled'
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (timetable == null)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text('Set timetable to enable auto-start', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                              ),
                            if (timetable != null && !hasStarted)
                              TextButton(
                                onPressed: () async {
                                  final session = QuizSession(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    quizId: quiz.id,
                                    startTime: DateTime.now(),
                                    endTime: DateTime.now().add(const Duration(minutes: 7)),
                                    status: 'running',
                                  );
                                  await _dataService.createQuizSession(session);
                                  if (mounted) setState(() {});
                                },
                                child: const Text('Start now'),
                              ),
                            if (isOngoing)
                              TextButton(
                                onPressed: () async {
                                  final latest = await _dataService.getLatestSessionForQuiz(quiz.id);
                                  if (latest != null) {
                                    await _dataService.updateQuizSessionFields(latest.id, {
                                      'end_time': DateTime.now(),
                                      'status': 'ended',
                                    });
                                  }
                                  await _dataService.updateQuizFields(quiz.id, {'is_paused': true});
                                  if (mounted) setState(() {});
                                },
                                child: const Text('End now'),
                              ),
                            if (quiz.isActive && quiz.attendanceUploaded)
                              TextButton(
                                onPressed: () async {
                                  await _dataService.updateQuizFields(quiz.id, {'is_paused': !quiz.isPaused});
                                  if (mounted) setState(() {});
                                },
                                child: Text(quiz.isPaused ? 'Resume' : 'Pause'),
                              ),
                            if (submissions.isNotEmpty)
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuizAnalyticsPage(quiz: quiz),
                                  ),
                                ),
                                child: Text(
                                  'View Analytics',
                                  style: TextStyle(color: theme.colorScheme.primary),
                                ),
                              ),
                          ],
                        ),
                        if (isOngoing && autoStart != null && autoEnd != null) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: ((now.millisecondsSinceEpoch - autoStart.millisecondsSinceEpoch) /
                                    (autoEnd.millisecondsSinceEpoch - autoStart.millisecondsSinceEpoch))
                                .clamp(0.0, 1.0),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Time left: ' +
                                Duration(milliseconds: (autoEnd.millisecondsSinceEpoch - now.millisecondsSinceEpoch).clamp(0, 7 * 60 * 1000))
                                    .toString()
                                    .split('.')
                                    .first,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Timetable?> _getTimetableForQuiz(Quiz quiz) async {
    // Prefer by course to avoid missing/invalid timetable IDs
    final timetables = await _dataService.getTimetablesByCourse(quiz.courseId);
    if (timetables.isEmpty) return null;
    // Pick the first timetable entry for this course
    return timetables.first;
  }

  Widget _buildQuizInfo(String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(String facultyId, ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchAnalyticsData(facultyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No data found.'));
        }

        final quizzes = snapshot.data!['quizzes'] as List<Quiz>;
        final courses = snapshot.data!['courses'] as List<Course>;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics Overview',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAnalyticsOverview(quizzes, courses, theme),
                const SizedBox(height: 24),
                Text(
                  'Quiz Performance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...quizzes.map((quiz) => _buildQuizAnalyticsCard(quiz, theme)),
                const SizedBox(height: 24),
                Text(
                  'Student Feedback',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...courses.map((course) => _buildFeedbackCard(course, facultyId, theme)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchAnalyticsData(String facultyId) async {
    final courses = await _dataService.getCoursesByFaculty(facultyId);
    final courseIds = courses.map((c) => c.id).toSet();
    final quizzes = await _dataService.getQuizzesByFaculty(facultyId);
    final filteredQuizzes = quizzes.where((q) => courseIds.contains(q.courseId)).toList();
    return {
      'quizzes': filteredQuizzes,
      'courses': courses,
    };
  }

  Widget _buildAnalyticsOverview(List<Quiz> quizzes, List<Course> courses, ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchAnalyticsOverviewData(quizzes, courses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final totalSubmissions = snapshot.data!['totalSubmissions'] as int;
        final averageScore = snapshot.data!['averageScore'] as double;
        final totalFeedbacks = snapshot.data!['totalFeedbacks'] as int;

        return Row(
          children: [
            Expanded(child: _buildAnalyticsCard('Quizzes', quizzes.length.toString(), Icons.quiz, theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildAnalyticsCard('Submissions', totalSubmissions.toString(), Icons.assignment_turned_in, theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildAnalyticsCard('Avg Score', '${averageScore.toStringAsFixed(1)}%', Icons.trending_up, theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildAnalyticsCard('Feedbacks', totalFeedbacks.toString(), Icons.feedback, theme)),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchAnalyticsOverviewData(List<Quiz> quizzes, List<Course> courses) async {
    int totalSubmissions = 0;
    double averageScore = 0.0;
    int totalFeedbacks = 0;

    for (final quiz in quizzes) {
      final submissions = await _dataService.getSubmissionsByQuiz(quiz.id);
      totalSubmissions += submissions.length;
      if (submissions.isNotEmpty) {
        averageScore += submissions.fold<double>(0, (sum, s) => sum + s.percentageScore) / submissions.length;
      }
    }

    // The getFeedbackSummary method was removed from data_service. This will need to be re-implemented.
    // For now, we will just return 0 for totalFeedbacks.
    // for (final course in courses) {
    //   final feedback = _dataService.getFeedbackSummary(course.facultyId, course.id);
    //   totalFeedbacks += feedback.totalFeedbacks;
    // }

    if (quizzes.isNotEmpty) {
      averageScore = averageScore / quizzes.length;
    }

    return {
      'totalSubmissions': totalSubmissions,
      'averageScore': averageScore,
      'totalFeedbacks': totalFeedbacks,
    };
  }

  Widget _buildAnalyticsCard(String label, String value, IconData icon, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizAnalyticsCard(Quiz quiz, ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchQuizAnalyticsData(quiz),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator())));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No data found.'));
        }

        final course = snapshot.data!['course'] as Course?;
        final submissions = snapshot.data!['submissions'] as List<StudentQuizResult>;

        if (submissions.isEmpty) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.quizTitle,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    course?.name ?? 'Unknown Course',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No submissions yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final averageScore = submissions.fold<double>(0, (sum, s) => sum + s.percentageScore) / submissions.length;
        final highestScore = submissions.map((s) => s.percentageScore).reduce((a, b) => a > b ? a : b);
        final lowestScore = submissions.map((s) => s.percentageScore).reduce((a, b) => a < b ? a : b);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.quizTitle,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            course?.name ?? 'Unknown Course',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizAnalyticsPage(quiz: quiz),
                        ),
                      ),
                      child: Text('View Details'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreMetric('Average', '${averageScore.toStringAsFixed(1)}%', theme),
                    ),
                    Expanded(
                      child: _buildScoreMetric('Highest', '${highestScore.toStringAsFixed(1)}%', theme),
                    ),
                    Expanded(
                      child: _buildScoreMetric('Lowest', '${lowestScore.toStringAsFixed(1)}%', theme),
                    ),
                    Expanded(
                      child: _buildScoreMetric('Students', '${submissions.length}', theme),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Recent Submissions:',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...submissions.take(3).map((submission) {
                  return FutureBuilder<Student?>(
                      future: _dataService.getStudentById(submission.studentId),
                      builder: (context, studentSnapshot) {
                        final student = studentSnapshot.data;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  student != null ? "${student.firstName} ${student.lastName}" : 'Unknown Student',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '${submission.score.toInt()}/10', // Placeholder
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: submission.percentageScore >= 60
                                      ? theme.colorScheme.tertiary
                                      : theme.colorScheme.error,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${submission.percentageScore.toStringAsFixed(1)}%',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchQuizAnalyticsData(Quiz quiz) async {
    final submissions = await _dataService.getSubmissionsByQuiz(quiz.id);
    final timetable = await _getTimetableForQuiz(quiz);
    final course = timetable != null ? await _dataService.getCourseById(timetable.courseId) : null;

    return {
      'submissions': submissions,
      'course': course,
    };
  }

  Widget _buildScoreMetric(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(Course course, String facultyId, ThemeData theme) {
    // The getFeedbackSummary method was removed from data_service. This will need to be re-implemented.
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.name,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No feedback received yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AppProvider>(context, listen: false).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}