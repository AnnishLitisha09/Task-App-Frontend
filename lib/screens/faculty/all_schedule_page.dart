import 'package:flutter/material.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../../components/skeleton_loader.dart';
import '../common/task_detail_page.dart';
import '../../services/venue_notifier.dart';

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
    VenueNotifier.venueNotifier.addListener(_fetch);
  }

  @override
  void dispose() {
    VenueNotifier.venueNotifier.removeListener(_fetch);
    super.dispose();
  }

  void _processTasks(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      _groupedItems = [];
      return;
    }

    // Sort by start_time
    tasks.sort((a, b) {
      final aTiming = a['timing'] as Map<String, dynamic>? ?? {};
      final bTiming = b['timing'] as Map<String, dynamic>? ?? {};
      String tA = aTiming['start_time'] ?? '23:59';
      String tB = bTiming['start_time'] ?? '23:59';
      return tA.compareTo(tB);
    });

    List<dynamic> result = [];
    String currentHeader = '';

    for (var t in tasks) {
      final timing = t['timing'] as Map<String, dynamic>? ?? {};
      String start = timing['start_time'] ?? 'Time TBD';
      String end = timing['end_time'] ?? '';

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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final TaskService taskService = TaskService();
      final dynamic response = await taskService.getFacultyDashboardStats();
      debugPrint("AllSchedulePage: Received response: $response");

      if (mounted) {
        setState(() {
          List<dynamic> raw = [];
          final data = response is List ? response[0] : response;
          if (data is Map) {
            raw =
                (data['todays_schedule'] as List?) ??
                (data['all_tasks_today'] as List?) ??
                (data['tasks'] as List?) ??
                [];
          }
          _processTasks(raw);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("AllSchedulePage Error: $e");
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
                  final timing =
                      data['timing'] as Map<String, dynamic>? ??
                      (data['task_type'] is Map
                          ? data['task_type'] as Map<String, dynamic>
                          : {});
                  return TaskCard(
                    title: data['title'] ?? 'Task',
                    sub: data['status'] ?? 'Scheduled',
                    accent: AppTheme.success,
                    icon: Icons.calendar_today_rounded,
                    heroTag: heroTag,
                    actionButton: data['action_button'],
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
                            'startDate': timing['start_date'] ?? 'N/A',
                            'deadline': timing['end_date'] ?? 'N/A',
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
