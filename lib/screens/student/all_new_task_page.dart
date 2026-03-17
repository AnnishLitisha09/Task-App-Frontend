import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../components/skeleton_loader.dart';

class AllNewTasksPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAccept;
  final List<dynamic>? initialTasks;

  const AllNewTasksPage({super.key, required this.onAccept, this.initialTasks});

  @override
  State<AllNewTasksPage> createState() => _AllNewTasksPageState();
}

class _AllNewTasksPageState extends State<AllNewTasksPage> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  List<dynamic> _groupedItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTasks != null && widget.initialTasks!.isNotEmpty) {
      _processTasks(widget.initialTasks!);
      _isLoading = false;
    } else {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final response = await _taskService.getPendingTasks();
      List<dynamic> rawTasks = [];

      if (response is List) {
        rawTasks = response;
      } else if (response is Map) {
        rawTasks =
            response['pending_for_approval'] ??
            response['pending_tasks'] ??
            response['tasks'] ??
            [];
      }

      _processTasks(rawTasks);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processTasks(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      _groupedItems = [];
      return;
    }

    // Convert all to standardized maps for sorting/grouping
    final List<Map<String, dynamic>> normalizedTasks = tasks.map((t) {
      if (t is Map<String, dynamic>) {
        // Ensure timing is a string for this page
        final Map<String, dynamic> result = Map.from(t);
        result['timing'] = _extractTimingFromMap(t);
        return result;
      }

      // Fallback for models
      try {
        return {
          'task_id': t.taskId,
          'title': t.title,
          'category': t.category,
          'priority': t.priority,
          'date': t.date,
          'timing': t.timing,
        };
      } catch (e) {
        return <String, dynamic>{'title': t.toString(), 'timing': 'Anytime'};
      }
    }).toList();

    // Sort by date and timing
    normalizedTasks.sort((a, b) {
      String dA = a['date'] ?? a['start_date']?.toString().split('T')[0] ?? '9999-12-31';
      String dB = b['date'] ?? b['start_date']?.toString().split('T')[0] ?? '9999-12-31';
      int dateCompare = dA.compareTo(dB);
      if (dateCompare != 0) return dateCompare;

      String tA = (a['timing'] == null || a['timing'].toString().isEmpty)
          ? '23:59'
          : a['timing'].toString();
      String tB = (b['timing'] == null || b['timing'].toString().isEmpty)
          ? '23:59'
          : b['timing'].toString();
      return tA.compareTo(tB);
    });

    List<dynamic> result = [];
    String currentHeader = '';

    for (var t in normalizedTasks) {
      String timing = (t['timing'] == null || t['timing'].toString().isEmpty)
          ? 'Anytime'
          : t['timing'].toString();
      
      String dateStr = t['date'] ?? t['start_date'] ?? '';
      String formattedDate = '';
      if (dateStr.isNotEmpty) {
        try {
          // Handle ISO string or YYYY-MM-DD
          final dt = DateTime.parse(dateStr.toString().contains('T') ? dateStr.toString() : dateStr.toString());
          formattedDate = DateFormat('MMM dd').format(dt);
        } catch (_) {}
      }

      String header = formattedDate.isNotEmpty ? "$formattedDate - $timing" : timing;

      if (header != currentHeader) {
        currentHeader = header;
        result.add({'isHeader': true, 'title': currentHeader});
      }
      result.add(t);
    }
    _groupedItems = result;
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          "Incoming Requests",
          style: TextStyle(
            color: AppTheme.textMain,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _groupedItems.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                itemCount: _groupedItems.length,
                itemBuilder: (context, index) {
                  final item = _groupedItems[index];

                  if (item is Map && item['isHeader'] == true) {
                    return _buildTimeHeader(item['title']);
                  }

                  return _buildRequestCard(context, item);
                },
              ),
            ),
    );
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

  Widget _buildRequestCard(BuildContext context, dynamic task) {
    final title = task['title'] ?? 'Task';
    final category = task['category'] ?? 'General';
    final taskId = task['task_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.brandAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppTheme.brandAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textMain,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${task['date'] ?? task['start_date']?.split('T')[0] ?? 'Today'} • ${task['timing'] ?? 'Anytime'} • $category",
                      style: const TextStyle(
                        color: AppTheme.textSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  context,
                  "Reject",
                  AppTheme.danger,
                  () => _showRejectDialog(context, title, taskId),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(context, "Accept", AppTheme.success, () {
                  widget.onAccept({
                    'task_id': taskId,
                    'title': title,
                    'timing': task['timing'],
                  });

                  // The acceptance API is usually handled by the callback in StudentPage
                  // which checks for overlaps first.
                  Navigator.pop(context);
                }),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _actionBtn(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String taskName, int taskId) {
    // Basic rejection dialog for now
    TextEditingController reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reject Request",
              style: TextStyle(
                color: AppTheme.textMain,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Why are you declining '$taskName'?",
              style: const TextStyle(color: AppTheme.textSub),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter your reason here...",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  await _taskService.rejectTask(taskId, reasonController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pop(this.context);
                    _fetch();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Confirm Rejection",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [SkeletonTaskCard(), SkeletonTaskCard(), SkeletonTaskCard()],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: AppTheme.dividerColor),
          SizedBox(height: 16),
          Text(
            "No new requests",
            style: TextStyle(color: AppTheme.textSub, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _extractTimingFromMap(Map<String, dynamic> task) {
    final rawTiming = task['timing'];
    if (rawTiming is String) return rawTiming;
    if (rawTiming is Map) {
      final start = rawTiming['start_time'] ?? '';
      final end = rawTiming['end_time'] ?? '';
      if (start.isNotEmpty && end.isNotEmpty) return "$start - $end";
      return start.isNotEmpty ? start : (end.isNotEmpty ? end : 'Anytime');
    }
    final s = task['start_time'] ?? '';
    final e = task['end_time'] ?? '';
    if (s.isNotEmpty && e.isNotEmpty) return "$s - $e";
    return s.isNotEmpty ? s : (e.isNotEmpty ? e : 'Anytime');
  }
}
