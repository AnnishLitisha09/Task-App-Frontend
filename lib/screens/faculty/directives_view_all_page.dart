import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../../components/unified_reject_dialog.dart';
import '../common/task_detail_page.dart';
import '../common/user_selection_page.dart';
import '../../services/task_service.dart';

class DirectivesViewAllPage extends StatelessWidget {
  final List<dynamic> directives;
  final bool isBlocked;
  final String userRole;
  final List<String> transferableRoles;
  final VoidCallback onRefresh;

  const DirectivesViewAllPage({
    super.key,
    required this.directives,
    required this.isBlocked,
    required this.userRole,
    required this.transferableRoles,
    required this.onRefresh,
  });

  Future<void> _acceptTask(BuildContext context, dynamic data) async {
    final taskId = data['task_id'];
    if (taskId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await TaskService().acceptTask(taskId);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task accepted successfully"),
            backgroundColor: AppTheme.success,
          ),
        );
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error accepting task: $e"),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleTransfer(
    BuildContext context,
    int taskId,
    String title,
  ) async {
    final List<Map<String, dynamic>>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSelectionPage(
          multiSelect: false,
          allowedRoles: transferableRoles,
        ),
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      final selectedUser = result.first;
      final selectedUserId = selectedUser['user_id'] ?? selectedUser['id'];
      if (selectedUserId == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await TaskService().rejectTask(
          taskId,
          "Transferred to ${selectedUser['name']}",
          transferToUserId: selectedUserId,
        );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Task '$title' transferred to ${selectedUser['name']}",
              ),
              backgroundColor: AppTheme.success,
            ),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error transferring task: $e"),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }

  void _showRejectDialog(BuildContext context, dynamic data, int idx) {
    final taskId = data['task_id'];
    final taskTitle = data['title'] ?? 'Task';
    if (taskId == null) return;

    UnifiedRejectDialog.show(
      context,
      taskTitle: taskTitle,
      onTransfer: () => _handleTransfer(context, taskId, taskTitle),
      onReject: (reason, details) async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
        try {
          await TaskService().rejectTask(taskId, reason);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Task rejected: $reason"),
                backgroundColor: AppTheme.success,
              ),
            );
            onRefresh();
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error rejecting task: $e"),
                backgroundColor: AppTheme.danger,
              ),
            );
          }
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
          color: AppTheme.textMain,
        ),
        title: Row(
          children: [
            const Text(
              "Incoming Directives",
              style: TextStyle(
                color: AppTheme.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (directives.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.brandAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  directives.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: directives.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppTheme.textSub.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No pending directives",
                    style: TextStyle(
                      color: AppTheme.textSub,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: directives.length,
              itemBuilder: (context, idx) {
                final data = directives[idx];
                final String heroTag = "directive_all_${data['task_id']}_$idx";
                return TaskCard(
                  title: data['title'] ?? 'Task',
                  sub: data['description'] ?? 'No description',
                  accent: AppTheme.brandAccent,
                  icon: Icons.assignment_turned_in_rounded,
                  heroTag: heroTag,
                  isRequest: true,
                  onAccept: () {
                    if (isBlocked) {
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
                    _acceptTask(context, data);
                  },
                  onReject: () {
                    if (isBlocked) {
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
                    _showRejectDialog(context, data, idx);
                  },
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailsPage(
                        taskData: {
                          'task_id': data['task_id'],
                          'title': data['title'],
                          'sub': data['description'],
                          'accent': AppTheme.brandAccent,
                          'icon': Icons.assignment_turned_in_rounded,
                          'heroTag': heroTag,
                          'startDate': data['start_date'] ?? "N/A",
                          'deadline': data['end_date'] ?? "N/A",
                          'completionType': data['type'] ?? "APPROVAL",
                          'isRequest': true,
                          'authority': "Administration",
                          'userRole': 'Faculty',
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
