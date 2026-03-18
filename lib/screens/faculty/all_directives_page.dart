import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../../components/skeleton_loader.dart';
import '../../components/unified_reject_dialog.dart';
import '../common/task_detail_page.dart';
import '../common/user_selection_page.dart';

class AllDirectivesPage extends StatefulWidget {
  final String userRole;
  final bool isBlocked;
  final VoidCallback? onRefreshParent;

  const AllDirectivesPage({
    super.key,
    required this.userRole,
    this.isBlocked = false,
    this.onRefreshParent,
  });

  @override
  State<AllDirectivesPage> createState() => _AllDirectivesPageState();
}

class _AllDirectivesPageState extends State<AllDirectivesPage> {
  final TaskService _taskService = TaskService();
  List<dynamic> _groupedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _processDirectives(List<dynamic> directives) {
    if (directives.isEmpty) {
      _groupedItems = [];
      return;
    }

    // Sort by start_date and start_time
    directives.sort((a, b) {
      final aTiming = a['timing'] as Map<String, dynamic>? ?? {};
      final bTiming = b['timing'] as Map<String, dynamic>? ?? {};
      
      String dA = aTiming['start_date'] ?? '9999-12-31';
      String dB = bTiming['start_date'] ?? '9999-12-31';
      int dateCompare = dA.compareTo(dB);
      if (dateCompare != 0) return dateCompare;

      String tA = aTiming['start_time'] ?? '23:59';
      String tB = bTiming['start_time'] ?? '23:59';
      return tA.compareTo(tB);
    });

    List<dynamic> result = [];
    String currentHeader = '';

    for (var d in directives) {
      final timing = d['timing'] as Map<String, dynamic>? ?? {};
      String start = timing['start_time'] ?? 'Time TBD';
      String end = timing['end_time'] ?? '';
      String date = timing['start_date'] ?? '';

      // Clean up seconds from hh:mm:ss if present
      if (start.length > 5) start = start.substring(0, 5);
      if (end.length > 5 && end.contains(':')) end = end.substring(0, 5);

      String formattedDate = '';
      if (date.isNotEmpty) {
        try {
          final dt = DateTime.parse(date);
          formattedDate = DateFormat('MMM dd').format(dt);
        } catch (_) {}
      }

      String header = formattedDate.isNotEmpty 
          ? (end.isNotEmpty ? '$formattedDate ($start - $end)' : '$formattedDate ($start)')
          : (end.isNotEmpty ? '$start - $end' : start);
      if (header != currentHeader) {
        currentHeader = header;
        result.add({'isHeader': true, 'title': currentHeader});
      }
      result.add(d);
    }

    _groupedItems = result;
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dynamic response = await _taskService.getFacultyDashboardStats();
      debugPrint("AllDirectivesPage: Received response: $response");

      if (mounted) {
        setState(() {
          List<dynamic> raw = [];
          final data = response is List ? response[0] : response;
          if (data is Map) {
            raw =
                (data['pending_approvals'] as List?) ??
                (data['pending_tasks'] as List?) ??
                (data['tasks'] as List?) ??
                [];
          }
          _processDirectives(raw);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("AllDirectivesPage Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptTask(dynamic taskId) async {
    // Optimistic UI update
    setState(() {
      _groupedItems.removeWhere(
        (item) => item is Map && item['task_id'] == taskId,
      );
      // re-process to clean up empty headers
      List<dynamic> remaining = _groupedItems
          .where((item) => item is Map && item['task_id'] != null)
          .toList();
      _processDirectives(remaining);
    });

    try {
      await _taskService.selfAssignTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task added to your list!'),
            backgroundColor: AppTheme.success,
          ),
        );
        // Refresh local data and notify parent (FacultyPage) to update "Today's Schedule"
        _fetch();
        widget.onRefreshParent?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
        _fetch();
      }
    }
  }

  void _showRejectDialog(Map task) {
    final taskId = task['task_id'];
    final taskTitle = task['title'] ?? 'Task';
    UnifiedRejectDialog.show(
      context,
      taskTitle: taskTitle,
      onTransfer: () async {
        final result = await Navigator.push<List<Map<String, dynamic>>>(
          context,
          MaterialPageRoute(
            builder: (_) => const UserSelectionPage(multiSelect: false),
          ),
        );
        if (result != null && result.isNotEmpty && mounted) {
          final user = result.first;
          final uid = user['user_id'] ?? user['id'];
          await _taskService.rejectTask(
            taskId,
            'Transferred to ${user['name']}',
            transferToUserId: uid,
          );
          _fetch();
          widget.onRefreshParent?.call();
        }
      },
      onReject: (reason, details) async {
        await _taskService.rejectTask(taskId, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task rejected: $reason'),
              backgroundColor: AppTheme.success,
            ),
          );
          _fetch();
          widget.onRefreshParent?.call();
        }
      },
    );
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
          'Incoming Directives',
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
                'No pending directives',
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

                  // Is Header
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

                  // Is List Item
                  final data = item as Map<dynamic, dynamic>;
                  final heroTag = 'directive_all_${data['task_id']}_$index';

                  final timing =
                      data['timing'] as Map<String, dynamic>? ??
                      (data['task_type'] is Map
                          ? data['task_type'] as Map<String, dynamic>
                          : {});
                  final String dateStr = timing['start_date'] ?? "";
                  final String startTime = timing['start_time'] ?? "";
                  final String endTime = timing['end_time'] ?? "";
                  String timeInfo = "";
                  if (startTime.isNotEmpty && endTime.isNotEmpty) {
                    timeInfo =
                        " (${startTime.substring(0, 5)} - ${endTime.substring(0, 5)})";
                  } else if (startTime.isNotEmpty) {
                    timeInfo = " (${startTime.substring(0, 5)})";
                  }

                  // Fallback for intl package import if needed, but it should be globally available or parse date manually
                  // simple formatting if intl gets tricky, but we can do a basic substring formatting:
                  // 2026-02-25T00:00:00.000Z -> 2026-02-25
                  String displayDateStr = dateStr;
                  if (displayDateStr.isNotEmpty &&
                      displayDateStr.contains('T')) {
                    displayDateStr = displayDateStr.split('T').first;
                  }

                  final String dateDisplay = displayDateStr.isNotEmpty
                      ? "$displayDateStr$timeInfo"
                      : "";
                  final bool hasDesc =
                      data['description'] != null &&
                      data['description'].toString().isNotEmpty;
                  final String finalDesc = hasDesc
                      ? " • ${data['description']}"
                      : "";
                  final String subText = "$dateDisplay$finalDesc";

                  return TaskCard(
                    title: data['title'] ?? 'Task',
                    sub: subText,
                    accent: AppTheme.brandAccent,
                    icon: Icons.assignment_turned_in_rounded,
                    heroTag: heroTag,
                    isRequest: true,
                    acceptLabel: "Executive Directive",
                    onAccept: () {
                      if (widget.isBlocked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please acknowledge your schedule first.",
                            ),
                            backgroundColor: AppTheme.warning,
                          ),
                        );
                        return;
                      }
                      _acceptTask(data['task_id']);
                    },
                    onReject: () {
                      if (widget.isBlocked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please acknowledge your schedule first.",
                            ),
                            backgroundColor: AppTheme.warning,
                          ),
                        );
                        return;
                      }
                      _showRejectDialog(data);
                    },
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': data['task_id'],
                            'title': data['title'],
                            'sub': data['description'],
                            'accent': AppTheme.brandAccent,
                            'icon': Icons.assignment_turned_in_rounded,
                            'heroTag': heroTag,
                            'startDate': timing['start_date'] ?? 'N/A',
                            'deadline': timing['end_date'] ?? 'N/A',
                            'completionType': data['type'] ?? 'APPROVAL',
                            'isRequest': true,
                            'isEscalated': true,
                            'authority': 'Administration',
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
