import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  List<dynamic> _groupedItems = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentTasks = List.from(widget.tasks);
    _groupedItems = _groupTasksByTime();
  }

  List<dynamic> _groupTasksByTime() {
    if (_currentTasks.isEmpty) return [];

    final List<dynamic> sortedTasks = List.from(_currentTasks);
    sortedTasks.sort((a, b) {
      // Sort by Date first
      final String dA = a['date']?.toString() ??
          a['start_date']?.toString() ??
          '9999-12-31';
      final String dB = b['date']?.toString() ??
          b['start_date']?.toString() ??
          '9999-12-31';
      int dateCompare = dA.compareTo(dB);
      if (dateCompare != 0) return dateCompare;

      // Then by Time
      final String timeA = a['timing']?.toString() ??
          a['time']?.toString() ??
          a['start_time']?.toString() ??
          '23:59';
      final String timeB = b['timing']?.toString() ??
          b['time']?.toString() ??
          b['start_time']?.toString() ??
          '23:59';
      return timeA.compareTo(timeB);
    });

    List<dynamic> result = [];
    String currentHeader = '';

    for (var task in sortedTasks) {
      String dateStr =
          task['date']?.toString() ?? task['start_date']?.toString() ?? '';
      String timeStr = task['timing']?.toString() ??
          task['time']?.toString() ??
          task['start_time']?.toString() ??
          'TBD';

      // Clean up timeStr
      if (timeStr.length > 5 && timeStr.contains(':')) {
        timeStr = timeStr.substring(0, 5);
      }

      String formattedDate = '';
      if (dateStr.isNotEmpty) {
        try {
          final dt = DateTime.parse(dateStr);
          formattedDate = DateFormat('MMM dd').format(dt);
        } catch (_) {}
      }

      String timeHeader = formattedDate.isNotEmpty
          ? "$formattedDate ($timeStr)"
          : timeStr;

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
      if (mounted) {
        setState(() {
          _hasChanges = true;
          _currentTasks.removeWhere((t) => (t['task_id'] ?? t['id']) == taskId);
          _groupedItems = _groupTasksByTime();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
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
        body: _groupedItems.isEmpty
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
                cacheExtent: 1000,
                itemCount: _groupedItems.length,
                itemBuilder: (context, index) {
                  final item = _groupedItems[index];

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
                      : widget.title.contains('Directive')
                          ? Icons.assignment_turned_in_rounded
                          : Icons.task_alt_rounded,
                  isApproval: widget.viewMode == 'approver' && !widget.title.contains('Directive'),
                  isRequest: widget.viewMode == 'approver' && widget.title.contains('Directive'),
                  acceptLabel: widget.title.contains('Directive') ? "Executive Directive" : null,
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
                                  ...task,
                                  'task_id': taskId,
                                  'title': task['title'],
                                  if (widget.title == "Pending Proofs") 'isPendingProof': true,
                                },
                                viewMode: widget.viewMode,
                              ),
                            ),
                          ).then((result) {
                            if (result == true && mounted) {
                              setState(() {
                                _hasChanges = true;
                                _currentTasks.removeWhere((t) => (t['task_id'] ?? t['id']) == taskId);
                              });
                            }
                          });
                        }
                      : null,
                );
              },
            ),
      ),
    );
  }
}
