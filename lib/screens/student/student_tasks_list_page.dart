import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../../models/student_dashboard_model.dart';
import '../../services/student_service.dart';
import '../common/task_detail_page.dart';

class StudentTasksListPage extends StatefulWidget {
  final String title;
  final List<dynamic> tasks;
  final String mode; // 'today', 'overdue', 'pending'
  final Function(Map<String, dynamic>)? onAccept;
  final Function(int taskId, String title)? onReject;

  const StudentTasksListPage({
    super.key,
    required this.title,
    required this.tasks,
    required this.mode,
    this.onAccept,
    this.onReject,
  });

  @override
  State<StudentTasksListPage> createState() => _StudentTasksListPageState();
}

class _StudentTasksListPageState extends State<StudentTasksListPage> {
  late List<dynamic> _currentTasks;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentTasks = widget.tasks;
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final dashboard = await StudentService().getStudentDashboard();
      if (mounted) {
        setState(() {
          if (widget.mode == 'today') {
            _currentTasks = dashboard.todaysSchedule;
          } else if (widget.mode == 'overdue') {
            _currentTasks = dashboard.overdueTasks;
          } else if (widget.mode == 'pending') {
            _currentTasks = dashboard.pendingForApproval;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Refresh failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Process tasks for grouping if mode is today
    final List<dynamic> displayedItems = widget.mode == 'today'
        ? _groupTasksByTime(_currentTasks)
        : _currentTasks;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppTheme.textMain,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.brandAccent,
        child: displayedItems.isEmpty && !_isLoading
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: displayedItems.length,
                itemBuilder: (context, index) {
                  final item = displayedItems[index];

                  if (item is Map && item['isHeader'] == true) {
                    return _buildTimeHeader(item['title']);
                  }

                  return _buildTaskItem(context, item, index);
                },
              ),
      ),
    );
  }

  List<dynamic> _groupTasksByTime(List<dynamic> rawTasks) {
    if (rawTasks.isEmpty) return [];

    // Sort by timing
    final sorted = List.from(rawTasks);
    sorted.sort((a, b) {
      String tA = _getStartTime(a);
      String tB = _getStartTime(b);
      return tA.compareTo(tB);
    });

    List<dynamic> grouped = [];
    String currentTiming = '';

    for (var task in sorted) {
      String timing = _getTiming(task);
      if (timing != currentTiming) {
        currentTiming = timing;
        grouped.add({'isHeader': true, 'title': currentTiming});
      }
      grouped.add(task);
    }
    return grouped;
  }

  String _getStartTime(dynamic task) {
    String timing = _getTiming(task);
    if (timing.contains('-')) {
      return timing.split('-')[0].trim();
    }
    return timing;
  }

  String _getTiming(dynamic task) {
    if (task is TodayTask) return task.timing;
    if (task is OverdueTask) return task.timing;
    if (task is PendingForApproval) return task.timing;
    if (task is Map) {
      final rawTiming = task['timing'];
      if (rawTiming is String) return rawTiming;
      if (rawTiming is Map) {
        final start = rawTiming['start_time'] ?? '';
        final end = rawTiming['end_time'] ?? '';
        if (start.isNotEmpty && end.isNotEmpty) return "$start - $end";
        return start.isNotEmpty ? start : (end.isNotEmpty ? end : "Anytime");
      }
      final s = task['start_time'] ?? '';
      final e = task['end_time'] ?? '';
      if (s.isNotEmpty && e.isNotEmpty) return "$s - $e";
      return s.isNotEmpty ? s : (e.isNotEmpty ? e : "Anytime");
    }
    return "Anytime";
  }

  Widget _buildTimeHeader(String time) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        time,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppTheme.brandAccent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, dynamic task, int index) {
    String taskTitle = '';
    String sub = '';
    int taskId = 0;
    IconData icon = Icons.task_alt_rounded;
    Map<String, dynamic>? actionButton;
    bool isEscalated = false;

    if (task is TodayTask) {
      taskTitle = task.title;
      sub = "Today • ${task.timing} • ${task.category}";
      taskId = task.taskId;
      actionButton = task.actionButton;
    } else if (task is OverdueTask) {
      taskTitle = task.title;
      sub = "${task.date} • ${task.category}";
      taskId = task.taskId;
      icon = Icons.warning_amber_rounded;
    } else if (task is PendingForApproval) {
      taskTitle = task.title;
      isEscalated = task.isEscalated;
      if (isEscalated) {
        sub = "🚨 Escalated • ${task.date} • ${task.timing}";
        icon = Icons.warning_amber_rounded;
      } else {
        sub = "${task.date} • ${task.timing} • ${task.category}";
        icon = Icons.hourglass_empty_rounded;
      }
      taskId = task.taskId;
    } else if (task is Map) {
      taskTitle = (task['title'] ?? task['name'] ?? 'Task').toString();
      final tDate =
          task['date'] ??
          task['start_date']?.toString().split('T')[0] ??
          'Today';
      final tTime = _getTiming(task);
      sub = "$tDate • $tTime • ${task['category'] ?? widget.mode}";
      taskId = int.tryParse(task['task_id']?.toString() ?? '0') ?? 0;
      if (widget.mode == 'overdue') icon = Icons.warning_amber_rounded;
      if (widget.mode == 'pending') icon = Icons.hourglass_empty_rounded;
    }

    if (taskTitle.isEmpty) taskTitle = "Task #$index";
    if (sub.isEmpty) sub = widget.mode.toUpperCase();

    final String heroTag = "${widget.mode}_list_${taskId}_$index";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TaskCard(
        title: taskTitle,
        sub: sub,
        accent: (widget.mode == 'overdue' || isEscalated)
            ? AppTheme.danger
            : AppTheme.brandAccent,
        icon: icon,
        heroTag: heroTag,
        actionButton: actionButton,
        // Allow action buttons for all pending tasks including escalated ones
        isRequest: widget.mode == 'pending',
        onAccept: (widget.mode == 'pending' && widget.onAccept != null)
            ? () {
                if (task is PendingForApproval) {
                  widget.onAccept!({
                    'task_id': task.taskId,
                    'title': task.title,
                    'timing': task.timing,
                  });
                } else if (task is Map) {
                  widget.onAccept!(Map<String, dynamic>.from(task));
                }
                _refresh();
              }
            : null,
        onReject: (widget.mode == 'pending' && widget.onReject != null)
            ? () {
                if (task is PendingForApproval) {
                  widget.onReject!(task.taskId, task.title);
                } else if (task is Map) {
                  widget.onReject!(
                    int.tryParse(task['task_id']?.toString() ?? '0') ?? 0,
                    (task['title'] ?? '').toString(),
                  );
                }
                _refresh();
              }
            : null,
        onTap: () {
          if (taskId > 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => TaskDetailsPage(
                  taskData: {
                    'task_id': taskId,
                    'title': taskTitle,
                    'sub': sub,
                    'heroTag': heroTag,
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_rounded, size: 64, color: AppTheme.dividerColor),
              SizedBox(height: 16),
              Text(
                "No tasks found",
                style: TextStyle(color: AppTheme.textSub, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
