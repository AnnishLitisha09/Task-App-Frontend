import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../../components/skeleton_loader.dart';
import '../common/task_detail_page.dart';

class AllSchedulePage extends StatefulWidget {
  final String userRole;

  const AllSchedulePage({super.key, required this.userRole});

  @override
  State<AllSchedulePage> createState() => _AllSchedulePageState();
}

class _AllSchedulePageState extends State<AllSchedulePage> {
  List<dynamic> _groupedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _processTasks(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      _groupedItems = [];
      return;
    }

    // Sort by start_time
    tasks.sort((a, b) {
      final aType = a['task_type'] as Map<String, dynamic>? ?? {};
      final bType = b['task_type'] as Map<String, dynamic>? ?? {};
      String tA = aType['start_time'] ?? '23:59';
      String tB = bType['start_time'] ?? '23:59';
      return tA.compareTo(tB);
    });

    List<dynamic> result = [];
    String currentHeader = '';

    for (var t in tasks) {
      final tType = t['task_type'] as Map<String, dynamic>? ?? {};
      String start = tType['start_time'] ?? 'Time TBD';
      String end = tType['end_time'] ?? '';

      if (start.length > 5) start = start.substring(0, 5);
      if (end.length > 5) end = end.substring(0, 5);

      String header = end.isNotEmpty ? '$start - $end' : start;
      if (header != currentHeader) {
        currentHeader = header;
        result.add({'isHeader': true, 'title': currentHeader});
      }
      result.add(t);
    }

    _groupedItems = result;
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/faculty/stats/daily'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parsed = data is List ? data[0] : data;
        if (mounted) {
          setState(() {
            List<dynamic> rawTasks = (parsed['all_tasks_today'] as List?) ?? [];
            _processTasks(rawTasks);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.brandPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Today's Schedule",
          style: TextStyle(
            color: AppTheme.brandPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                ],
              ),
            )
          : _groupedItems.isEmpty
          ? const Center(
              child: Text(
                'No tasks scheduled for today',
                style: TextStyle(color: AppTheme.textSub),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppTheme.brandAccent,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _groupedItems.length,
                itemBuilder: (context, index) {
                  final dynamic item = _groupedItems[index];

                  if (item is Map && item['isHeader'] == true) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 12),
                      child: Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }

                  final data = item as Map<String, dynamic>;
                  final heroTag = 'schedule_all_${data['task_id']}_$index';
                  return TaskCard(
                    title: data['title'] ?? 'Task',
                    sub: data['status'] ?? 'Scheduled',
                    accent: AppTheme.success,
                    icon: Icons.calendar_today_rounded,
                    heroTag: heroTag,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': data['task_id'],
                            'title': data['title'],
                            'sub': data['status'],
                            'accent': AppTheme.success,
                            'icon': Icons.calendar_today_rounded,
                            'heroTag': heroTag,
                            'startDate':
                                (data['task_type'] ?? {})['start_date'] ??
                                'N/A',
                            'deadline':
                                (data['task_type'] ?? {})['end_date'] ?? 'N/A',
                            'completionType': 'INFO',
                            'isRequest': false,
                            'userRole': widget.userRole,
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
