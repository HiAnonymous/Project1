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
import 'package:insightquill/widgets/db_activity_dialog.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  final DatabaseService _dataService = DatabaseService();
  int _currentIndex = 0;
  bool _isDbBusy = false;
  String? _selectedCourseIdForFilter; // null = All courses
  // Removed global caching to avoid showing stale data after creation

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
  }

  @override
  void dispose() {
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
          int credits = 1;
          // Dynamic session inputs based on credits
          int sessionCount = 1;
          final List<TextEditingController> startControllers = [TextEditingController()];
          final List<TextEditingController> endControllers = [TextEditingController()];
          final List<String> days = ['Monday'];

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
                      Row(
                        children: [
                          Expanded(child: Text('Credits (classes per week)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                          DropdownButton<int>(
                            value: credits,
                            items: const [1,2,3,4,5,6].map((c) => DropdownMenuItem(value: c, child: Text('$c'))).toList(),
                            onChanged: (v) {
                              credits = v ?? 1;
                              // Adjust session arrays
                              sessionCount = credits;
                              while (startControllers.length < sessionCount) {
                                startControllers.add(TextEditingController());
                                endControllers.add(TextEditingController());
                                days.add('Monday');
                              }
                              while (startControllers.length > sessionCount) {
                                startControllers.removeLast();
                                endControllers.removeLast();
                                days.removeLast();
                              }
                              (dialogContext as Element).markNeedsBuild();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Weekly Sessions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      for (int i = 0; i < sessionCount; i++) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: startControllers[i],
                                decoration: InputDecoration(hintText: 'Start (HH:MM) • Session ${i+1}'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: endControllers[i],
                                decoration: const InputDecoration(hintText: 'End (HH:MM)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: days[i],
                          items: const [
                            'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
                          ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) {
                            days[i] = v ?? 'Monday';
                          },
                          decoration: const InputDecoration(labelText: 'Day of Week'),
                        ),
                        const SizedBox(height: 12),
                      ],
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

                      // Parse HH:MM times per session
                      final now = DateTime.now();
                      final parsedSessions = <Map<String, dynamic>>[];
                      for (int i = 0; i < sessionCount; i++) {
                        try {
                          if (startControllers[i].text.trim().isEmpty || endControllers[i].text.trim().isEmpty) continue;
                          final sParts = startControllers[i].text.trim().split(':').map((e)=>int.parse(e)).toList();
                          final eParts = endControllers[i].text.trim().split(':').map((e)=>int.parse(e)).toList();
                          final sTime = DateTime(now.year, now.month, now.day, sParts[0], sParts[1]);
                          final eTime = DateTime(now.year, now.month, now.day, eParts[0], eParts[1]);
                          parsedSessions.add({'start': sTime, 'end': eTime, 'day': days[i]});
                        } catch (_) {}
                      }

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
                        // Create multiple timetable entries based on credits/sessions
                        if (parsedSessions.isNotEmpty) {
                          final facultyName = faculty.firstName + ' ' + faculty.lastName;
                          for (final sess in parsedSessions) {
                            await _dataService.createTimetable(
                              courseId: created.id,
                              courseName: created.name,
                              facultyName: facultyName,
                              startTime: sess['start'] as DateTime,
                              endTime: sess['end'] as DateTime,
                              dayOfWeek: sess['day'] as String,
                            );
                          }
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Course created successfully')),
                        );
                        // Refresh overview cached future so the new course shows up immediately
                        final app = Provider.of<AppProvider>(context, listen: false);
                        _fetchOverviewData(app.currentUser!.id); // Re-fetch overview to update data
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
                onPressed: _isDbBusy ? null : () => _uploadStudentsForCourse(course),
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
    if (_isDbBusy) return;
    setState(() => _isDbBusy = true);
    try {
      final activity = showDbActivityDialog(
        context,
        title: 'Updating database',
        subtitle: 'Uploading roster for ${course.code} • ${course.name}',
      );
      activity.addLog('Reading Excel file...');
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes ?? await result.files.single.xFile.readAsBytes();
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      final firstSheet = excel.sheets.values.first;
      // Parse roster rows with rich columns
      final List<Map<String, dynamic>> roster = [];
      final List<String> registrationNumbers = [];
      final List<Map<String, String>> minimalStudents = [];
      bool headerParsed = false;
      List<String> headers = [];
      int totalRows = firstSheet.maxRows - 1; // minus header
      int processed = 0;
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
        if (registerNo.isNotEmpty) {
          registrationNumbers.add(registerNo);
          minimalStudents.add({'reg': registerNo, 'name': name, 'email': email});
        }
        processed++;
        if (totalRows > 0) activity.setProgress((processed / totalRows).clamp(0.0, 0.9));
      }

      if (roster.isEmpty) {
        activity.markError('No valid student rows found in Excel');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid student rows found in Excel')));
        return;
      }

      activity.addLog('Writing roster to course document...');
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

      activity.addLog('Ensuring student accounts and enrollments...');
      // Ensure users/students exist, then enroll
      int ensured = 0;
      for (final s in minimalStudents) {
        final userId = await _dataService.ensureStudentForRegistrationNumber(
          registrationNumber: s['reg'] ?? '',
          programId: course.programId,
          departmentId: course.department,
          name: s['name'],
          email: s['email'],
        );
        if (userId != null) {
          ensured++;
          await _dataService.createEnrollment(studentUserId: userId, courseId: course.id);
        }
        if (roster.isNotEmpty) activity.setProgress(0.9 + (ensured / roster.length) * 0.1);
      }

      if (mounted) setState(() {});
      activity.addLog('Completed. Ensured $ensured students, updated roster and enrollments.');
      activity.markDone('All changes saved to Firestore.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Uploaded ${roster.length} rows; ensured $ensured students and enrolled them to ${course.code}'),
      ));
    } catch (e) {
      // Try to close dialog with error
      try {
        showDbActivityDialog(context, title: 'Database error')
          ..markError(e.toString());
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload students: $e')));
    } finally {
      if (mounted) setState(() => _isDbBusy = false);
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
    return FutureBuilder<String>(
      future: _computeQuizTemporalStatus(quiz),
      builder: (context, snap) {
        final status = (snap.data ?? 'upcoming').toLowerCase();
        final display = status[0].toUpperCase() + status.substring(1);
        Color bg;
        Color fg;
        if (status == 'ongoing') {
          bg = theme.colorScheme.tertiary.withValues(alpha: 0.25);
          fg = theme.colorScheme.tertiary;
        } else if (status == 'ended') {
          bg = theme.colorScheme.error.withValues(alpha: 0.2);
          fg = theme.colorScheme.error;
        } else {
          bg = theme.colorScheme.secondary.withValues(alpha: 0.25);
          fg = theme.colorScheme.secondary;
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    quiz.quizTitle,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    display,
                    style: theme.textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  'Quizzes by Course',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Course filter dropdown will be populated once data loads below
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizCreationPage()),
                  );
                  if (mounted) setState(() {});
                },
                icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
                label: Text('Create Quiz', style: TextStyle(color: theme.colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: () async {
              final faculty = await _dataService.getFacultyByUserId(userId);
              if (faculty == null) return {'courses': <Course>[], 'quizzes': <Quiz>[]};
              final courses = await _dataService.getCoursesByFaculty(faculty.id);
              final quizzes = await _loadQuizzesForFaculty(userId);
              return {'courses': courses, 'quizzes': quizzes};
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final courses = (snapshot.data?['courses'] as List<Course>? ?? []);
              final quizzes = (snapshot.data?['quizzes'] as List<Quiz>? ?? []);
              if (courses.isEmpty) {
                return const Center(child: Text('No courses found'));
              }

              // De-duplicate courses by id (safety)
              final Map<String, Course> uniqueCourseMap = {
                for (final c in courses) c.id: c,
              };
              final uniqueCourses = uniqueCourseMap.values.toList();
              final availableIds = uniqueCourses.map((c) => c.id).toSet();
              final safeSelectedValue = (availableIds.contains(_selectedCourseIdForFilter)) ? _selectedCourseIdForFilter : null;

              // Build filter dropdown now that we have courses
              final dropdown = Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text('Course:', style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    DropdownButton<String?>(
                      value: safeSelectedValue,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All')),
                        ...uniqueCourses.map((c) => DropdownMenuItem<String?> (
                              value: c.id,
                              child: Text('${c.code} • ${c.name}'),
                            )),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedCourseIdForFilter = v);
                      },
                    ),
                  ],
                ),
              );

              // Group quizzes by course
              final Map<String, List<Quiz>> courseIdToQuizzes = {};
              for (final q in quizzes) {
                (courseIdToQuizzes[q.courseId] ??= []).add(q);
              }

              final filteredCourses = safeSelectedValue == null
                  ? uniqueCourses
                  : uniqueCourses.where((c) => c.id == safeSelectedValue).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 1 + filteredCourses.length,
                itemBuilder: (context, idx) {
                  if (idx == 0) return dropdown;
                  final course = filteredCourses[idx - 1];
                  final courseQuizzes = courseIdToQuizzes[course.id] ?? [];
                  if (courseQuizzes.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${course.code} • ${course.name}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Upcoming', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...courseQuizzes.map((q) => _buildStatusFilteredQuizCard(q, theme, desired: 'upcoming')),
                        const SizedBox(height: 12),
                        Text('Ongoing', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.tertiary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...courseQuizzes.map((q) => _buildStatusFilteredQuizCard(q, theme, desired: 'ongoing')),
                        const SizedBox(height: 12),
                        Text('Ended', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...courseQuizzes.map((q) => _buildStatusFilteredQuizCard(q, theme, desired: 'ended')),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Builds a quiz card only if its computed temporal status matches desired.
  Widget _buildStatusFilteredQuizCard(Quiz quiz, ThemeData theme, {required String desired}) {
    return FutureBuilder<String>(
      future: _computeQuizTemporalStatus(quiz),
      builder: (context, snap) {
        final status = (snap.data ?? 'upcoming').toLowerCase();
        if (status != desired) return const SizedBox.shrink();
        return _buildDetailedQuizCard(quiz, theme);
      },
    );
  }

  Future<List<Quiz>> _loadQuizzesForFaculty(String userId) async {
    final faculty = await _dataService.getFacultyByUserId(userId);
    if (faculty == null) return <Quiz>[];
    final courses = await _dataService.getCoursesByFaculty(faculty.id);
    if (courses.isEmpty) return <Quiz>[];
    final courseIds = courses.map((c) => c.id).toSet();
    final quizzes = await _dataService.getQuizzesByFaculty(faculty.id);
    return quizzes.where((q) => courseIds.contains(q.courseId)).toList();
  }

  Widget _buildDetailedQuizCard(Quiz quiz, ThemeData theme) {
    return FutureBuilder<Timetable?> (
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

                // Compute next weekly occurrence window based on timetable day/time
                final now = DateTime.now();
                DateTime? windowStart;
                DateTime? windowEnd;
                if (timetable != null) {
                  int targetWeekday = _weekdayNumber(timetable.dayOfWeek);
                  int today = now.weekday;
                  int addDays = (targetWeekday - today) % 7;
                  // If class today but already past end, push to next week occurrence
                  final candidateStart = DateTime(now.year, now.month, now.day, timetable.startTime.hour, timetable.startTime.minute).add(Duration(days: addDays));
                  final adjustedStart = candidateStart.add(const Duration(minutes: 3));
                  final adjustedEnd = adjustedStart.add(Duration(minutes: quiz.duration));
                  if (addDays == 0 && now.isAfter(adjustedEnd)) {
                    // use next week
                    windowStart = candidateStart.add(const Duration(days: 7));
                    final nextTestStart = windowStart.add(const Duration(minutes: 3));
                    windowEnd = nextTestStart.add(Duration(minutes: quiz.duration));
                  } else {
                    windowStart = candidateStart;
                    windowEnd = adjustedEnd;
                  }
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
                                const SizedBox(width: 8),
                                // Add quick stop button for ongoing quizzes
                                FutureBuilder<String>(
                                  future: _computeQuizTemporalStatus(quiz),
                                  builder: (context, statusSnapshot) {
                                    final status = (statusSnapshot.data ?? 'upcoming').toLowerCase();
                                    if (status == 'ongoing') {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                                        ),
                                        child: IconButton(
                                          onPressed: () => _showStopQuizConfirmation(quiz),
                                          icon: Icon(Icons.stop, color: theme.colorScheme.error, size: 20),
                                          tooltip: 'Stop Quiz Immediately',
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildQuizInfo('Questions', quiz.questions.length.toString(), Icons.quiz, theme),
                            const SizedBox(width: 16),
                            _buildQuizInfo('Duration', '${quiz.duration}m', Icons.timer, theme),
                            const SizedBox(width: 16),
                            _buildQuizInfo('Submissions', submissions.length.toString(), Icons.assignment_turned_in, theme),
                            const SizedBox(width: 16),
                            FutureBuilder<String>(
                              future: _computeQuizTemporalStatus(quiz),
                              builder: (context, statusSnapshot) {
                                final status = statusSnapshot.data ?? 'upcoming';
                                return _buildQuizInfo('Status', status, Icons.schedule, theme);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<String>(
                          future: _computeQuizTemporalStatus(quiz),
                          builder: (context, statusSnapshot) {
                            final temporalStatus = statusSnapshot.data ?? 'upcoming';
                            // Don't show any timer if quiz is ended
                            if (temporalStatus == 'ended') {
                              return const SizedBox.shrink();
                            }
                            
                            return FutureBuilder<QuizSession?>(
                              future: _dataService.getLatestSessionForQuiz(quiz.id),
                              builder: (context, sessionSnap) {
                                final now = DateTime.now();
                                DateTime? endAt;
                                if (sessionSnap.hasData && sessionSnap.data != null) {
                                  final session = sessionSnap.data!;
                                  if (session.status == 'paused') {
                                    final remainingMs = session.remainingMs ?? 0;
                                    final remaining = Duration(milliseconds: remainingMs);
                                    final mm = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
                                    final ss = (remaining.inSeconds.remainder(60)).toString().padLeft(2, '0');
                                    return Row(
                                      children: [
                                        Icon(Icons.pause_circle_filled, size: 16, color: theme.colorScheme.secondary),
                                        const SizedBox(width: 6),
                                        Text('Paused • $mm:$ss left', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
                                      ],
                                    );
                                  }
                                  if (session.status == 'running') {
                                    endAt = session.endTime;
                                  } else if (session.status == 'ended') {
                                    // Quiz has been manually stopped, don't show timer
                                    return const SizedBox.shrink();
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                } else if (windowStart != null && windowEnd != null) {
                                  // Auto-start at course start + 3 minutes with fixed 10-minute duration
                                  final autoStart = windowStart.add(const Duration(minutes: 3));
                                  if (now.isAfter(autoStart) && now.isBefore(windowEnd)) {
                                    final newSession = QuizSession(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      quizId: quiz.id,
                                      startTime: autoStart,
                                      endTime: autoStart.add(Duration(minutes: quiz.duration)),
                                      status: 'running',
                                    );
                                    _dataService.createQuizSession(newSession);
                                    endAt = newSession.endTime;
                                  }
                                }
                                if (endAt != null && now.isBefore(endAt)) {
                                  return _buildEndsInCountdown(endAt, theme);
                                }
                                return const SizedBox.shrink();
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            FutureBuilder<String>(
                              future: _computeQuizTemporalStatus(quiz),
                              builder: (context, statusSnapshot) {
                                final status = statusSnapshot.data ?? 'upcoming';
                                Color bgColor;
                                Color textColor;
                                if (status == 'ongoing') {
                                  bgColor = theme.colorScheme.tertiary.withValues(alpha: 0.25);
                                  textColor = theme.colorScheme.tertiary;
                                } else if (status == 'upcoming') {
                                  bgColor = theme.colorScheme.secondary.withValues(alpha: 0.25);
                                  textColor = theme.colorScheme.secondary;
                                } else if (status == 'ended') {
                                  bgColor = theme.colorScheme.error.withValues(alpha: 0.2);
                                  textColor = theme.colorScheme.error;
                                } else {
                                  bgColor = theme.colorScheme.onSurface.withValues(alpha: 0.1);
                                  textColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
                                }
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    status,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            if (timetable == null)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text('Set timetable to enable auto-start', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                              ),
                            if (timetable != null && windowStart != null && now.isBefore(windowStart))
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
                            FutureBuilder<QuizSession?>(
                              future: _dataService.getLatestSessionForQuiz(quiz.id),
                              builder: (context, latestSnap) {
                                final session = latestSnap.data;
                                final status = session?.status ?? 'none';
                                final ended = session != null && (status == 'ended' || DateTime.now().isAfter(session.endTime));
                                if (ended) return const SizedBox.shrink();
                                return Row(
                                  children: [
                                    if (status == 'running')
                                      TextButton(
                                        onPressed: () async {
                                          final latest = await _dataService.getLatestSessionForQuiz(quiz.id);
                                          if (latest != null) {
                                            final nowP = DateTime.now();
                                            final remaining = latest.endTime.difference(nowP);
                                            final remainingMs = remaining.inMilliseconds.clamp(0, quiz.duration * 60 * 1000);
                                            await _dataService.updateQuizSessionFields(latest.id, {
                                              'status': 'paused',
                                              'remaining_ms': remainingMs,
                                              'paused_at': nowP,
                                            });
                                            await _dataService.updateQuizFields(quiz.id, {'is_paused': true});
                                            if (mounted) setState(() {});
                                          }
                                        },
                                        child: const Text('Pause'),
                                      ),
                                    if (status == 'paused')
                                      TextButton(
                                        onPressed: () async {
                                          final latest = await _dataService.getLatestSessionForQuiz(quiz.id);
                                          if (latest != null) {
                                            final remainingMs = latest.remainingMs ?? (quiz.duration * 60 * 1000);
                                            final newEnd = DateTime.now().add(Duration(milliseconds: remainingMs));
                                            await _dataService.updateQuizSessionFields(latest.id, {
                                              'status': 'running',
                                              'end_time': newEnd,
                                              'paused_at': null,
                                            });
                                            await _dataService.updateQuizFields(quiz.id, {'is_paused': false});
                                            if (mounted) setState(() {});
                                          }
                                        },
                                        child: const Text('Unpause'),
                                      ),
                                    if (status == 'running' || status == 'paused')
                                      ElevatedButton.icon(
                                        onPressed: () => _showStopQuizConfirmation(quiz),
                                        icon: Icon(Icons.stop, color: theme.colorScheme.onError),
                                        label: Text('Stop Quiz', style: TextStyle(color: theme.colorScheme.onError)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.error,
                                          foregroundColor: theme.colorScheme.onError,
                                        ),
                                      ),
                                  ],
                                );
                              },
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
                        FutureBuilder<String>(
                          future: _computeQuizTemporalStatus(quiz),
                          builder: (context, statusSnapshot) {
                            final status = statusSnapshot.data ?? 'upcoming';
                            // Only show timer if quiz is actually ongoing (not stopped)
                            if (status == 'ongoing' && windowStart != null && !quiz.isPaused) {
                              return StreamBuilder<int>(
                                stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                                builder: (context, _) {
                                  final nowTick = DateTime.now();
                                  final start = windowStart!.add(const Duration(minutes: 3));
                                  final end = start.add(Duration(minutes: quiz.duration));
                                  final totalMs = (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch).toDouble();
                                  final elapsedMs = (nowTick.millisecondsSinceEpoch - start.millisecondsSinceEpoch).toDouble();
                                  final progress = (elapsedMs / totalMs).clamp(0.0, 1.0);
                                  final remaining = end.difference(nowTick);
                                  final display = remaining.isNegative
                                      ? '00:00:00'
                                      : remaining.toString().split('.').first;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(value: progress),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Time left: $display',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                            return const SizedBox.shrink(); // Hide timer when not ongoing
                          },
                        ),
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

  int _weekdayNumber(String day) {
    switch (day.toLowerCase()) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: return DateTime.now().weekday;
    }
  }

  // Computes a unified temporal status for a quiz: 'ongoing' | 'upcoming' | 'ended'.
  // This avoids relying on quiz.status which mixes lifecycle flags (e.g., attendance pending).
  Future<String> _computeQuizTemporalStatus(Quiz quiz) async {
    final now = DateTime.now();
    
    // First, check the latest session status - this takes priority
    final latest = await _dataService.getLatestSessionForQuiz(quiz.id);
    if (latest != null) {
      // If session is explicitly ended, quiz is ended regardless of time
      if (latest.status == 'ended') return 'ended';
      // If session is paused, the quiz is not ongoing
      if (latest.status == 'paused') return 'upcoming';
      // If session is running and time hasn't expired, it's ongoing
      if (latest.status == 'running' && now.isBefore(latest.endTime)) return 'ongoing';
      // If session time has expired, it's ended
      if (now.isAfter(latest.endTime)) return 'ended';
    }

    // Check if quiz is manually deactivated
    if (!quiz.isActive || quiz.isCancelled) return 'ended';
    
    // Fallback to timetable-based computation
    final timetable = await _getTimetableForQuiz(quiz);
    if (timetable != null) {
      final int targetWeekday = _weekdayNumber(timetable.dayOfWeek);
      final int addDays = (targetWeekday - now.weekday) % 7;
      DateTime start = DateTime(
        now.year,
        now.month,
        now.day,
        timetable.startTime.hour,
        timetable.startTime.minute,
      ).add(Duration(days: addDays));
      start = start.add(const Duration(minutes: 3));
      DateTime end = start.add(Duration(minutes: quiz.duration));
      if (addDays == 0 && now.isAfter(end)) {
        start = start.add(const Duration(days: 7));
        end = end.add(const Duration(days: 7));
      }
      final bool isOngoing = now.isAfter(start) && now.isBefore(end) && !quiz.isPaused && !quiz.isCancelled;
      if (isOngoing) return 'ongoing';
      if (now.isAfter(end)) return 'ended';
      return 'upcoming';
    }

    return 'upcoming';
  }

  Widget _buildEndsInCountdown(DateTime endAt, ThemeData theme) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final now = DateTime.now();
        if (!now.isBefore(endAt)) {
          return Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 6),
              Text('Ended', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.tertiary)),
            ],
          );
        }
        final remaining = endAt.difference(now);
        final mm = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
        final ss = (remaining.inSeconds.remainder(60)).toString().padLeft(2, '0');
        return Row(
          children: [
            Icon(Icons.timer, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text('Ends in $mm:$ss', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
          ],
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



  void _showStopQuizConfirmation(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Stop Quiz'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to stop "${quiz.quizTitle}" immediately?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Theme.of(context).colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will immediately end the quiz for all students and they will not be able to continue.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _stopQuizImmediately(quiz);
            },
            icon: const Icon(Icons.stop),
            label: const Text('Stop Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _stopQuizImmediately(Quiz quiz) async {
    try {
      // Get the latest session and end it
      final latest = await _dataService.getLatestSessionForQuiz(quiz.id);
      if (latest != null) {
        await _dataService.updateQuizSessionFields(latest.id, {
          'status': 'ended',
          'end_time': DateTime.now(),
        });
      }

      // Update quiz status
      await _dataService.updateQuizFields(quiz.id, {
        'is_paused': false,
        'is_active': false,
      });

      // Show success message and force UI refresh
      if (mounted) {
        setState(() {}); // Force immediate UI refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz "${quiz.quizTitle}" has been stopped successfully'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Additional refresh after a brief delay to ensure all FutureBuilders rebuild
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() {});
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop quiz: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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