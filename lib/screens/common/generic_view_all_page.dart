import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import 'task_detail_page.dart';

class GenericViewAllPage extends StatefulWidget {
  final String title;
  final List<dynamic> tasks;
  final String viewMode; // 'approver', 'incharge', 'viewonly'
  final Color accentColor;
  final Future<void> Function(int taskId, bool approve)? onTaskAction;

  const GenericViewAllPage({
    super.key,
    required this.title,
    required this.tasks,
    this.viewMode = 'viewonly',
    this.accentColor = const Color(0xFF6366F1),
    this.onTaskAction,
  });

  @override
  State<GenericViewAllPage> createState() => _GenericViewAllPageState();
}

class _GenericViewAllPageState extends State<GenericViewAllPage> {
  late List<dynamic> _currentTasks;

  @override
  void initState() {
    super.initState();
    _currentTasks = List.from(widget.tasks);
  }

  List<dynamic> _groupTasksByTime() {
    if (_currentTasks.isEmpty) return [];

    final List<dynamic> sortedTasks = List.from(_currentTasks);
    sortedTasks.sort((a, b) {
      final String timeA =
          a['timing']?.toString() ?? a['time']?.toString() ?? '';
      final String timeB =
          b['timing']?.toString() ?? b['time']?.toString() ?? '';
      return timeA.compareTo(timeB);
    });

    List<dynamic> result = [];
    String currentHeader = '';

    for (var task in sortedTasks) {
      String fullTiming =
          task['timing']?.toString() ?? task['time']?.toString() ?? '';
      String timeHeader = "Scheduled";
      if (fullTiming.contains(' ')) {
        final parts = fullTiming.split(' ');
        if (parts.isNotEmpty) {
          final lastPart = parts.last;
          if (lastPart.contains(':')) {
            timeHeader = lastPart.substring(0, 5);
          }
        }
      }

      if (timeHeader != currentHeader) {
        currentHeader = timeHeader;
        result.add({'isHeader': true, 'title': currentHeader});
      }
      result.add(task);
    }

    return result;
  }

  Future<void> _handleLocalAction(int taskId, bool approve) async {
    if (widget.onTaskAction != null) {
      await widget.onTaskAction!(taskId, approve);
      setState(() {
        _currentTasks.removeWhere((t) => (t['task_id'] ?? t['id']) == taskId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupTasksByTime();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textMain,
      ),
      body: groupedItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 64,
                    color: AppTheme.textSub.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No tasks found in this section",
                    style: TextStyle(color: AppTheme.textSub),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: groupedItems.length,
              itemBuilder: (context, index) {
                final item = groupedItems[index];

                if (item is Map && item['isHeader'] == true) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final task = item as Map<String, dynamic>;
                final taskId = task['task_id'] ?? task['id'];

                return TaskCard(
                  title: task['title']?.toString() ?? 'Untitled Task',
                  sub:
                      task['description']?.toString() ??
                      (task['assignee_name'] != null
                          ? "Assignee: ${task['assignee_name']}"
                          : "Requested by: ${task['requested_by'] ?? 'N/A'}"),
                  accent: widget.accentColor,
                  icon: widget.title.contains('Escalated')
                      ? Icons.priority_high_rounded
                      : Icons.task_alt_rounded,
                  isApproval: widget.viewMode == 'approver',
                  onAccept: widget.viewMode == 'approver' && taskId != null
                      ? () => _handleLocalAction(taskId, true)
                      : null,
                  onReject: widget.viewMode == 'approver' && taskId != null
                      ? () => _handleLocalAction(taskId, false)
                      : null,
                  onTap: taskId != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailsPage(
                                taskData: {
                                  'task_id': taskId,
                                  'title': task['title'],
                                },
                                viewMode: widget.viewMode,
                              ),
                            ),
                          );
                        }
                      : null,
                );
              },
            ),
    );
  }
}
