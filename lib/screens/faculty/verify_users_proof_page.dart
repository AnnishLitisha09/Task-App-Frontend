import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../models/task_detail_model.dart';

class VerifyUsersProofPage extends StatefulWidget {
  final int taskId;
  final String taskTitle;

  const VerifyUsersProofPage({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<VerifyUsersProofPage> createState() => _VerifyUsersProofPageState();
}

class _VerifyUsersProofPageState extends State<VerifyUsersProofPage> {
  final TaskService _taskService = TaskService();
  TaskDetailModel? _taskDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _taskService.getTaskDetail(widget.taskId.toString());
      if (mounted) {
        setState(() {
          _taskDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching task detail for verification: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReview(int assignmentId, bool approve) async {
    String? reason;
    if (!approve) {
      reason = await _showRejectReasonDialog();
      if (reason == null) return; // User cancelled
    }

    setState(() => _isLoading = true);
    try {
      await _taskService.reviewTaskProof(
        assignmentId,
        approve ? 'approved' : 'rejected',
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? "Proof approved successfully!" : "Proof rejected and user notified."),
            backgroundColor: approve ? AppTheme.success : Colors.orange,
          ),
        );
        _fetch(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<String?> _showRejectReasonDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Refuse Proof", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please provide a reason for rejecting this proof. The user will be notified to redo the task."),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter reason here...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: AppTheme.surfaceColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Reject Proof"),
          ),
        ],
      ),
    );
  }

  void _viewProof(String? proofPath) {
    if (proofPath == null || proofPath.isEmpty) return;
    
    final backendUrl = dotenv.env['BACKEND_URL']?.replaceAll('/api/', '') ?? 'http://localhost:3002';
    final proofUrl = proofPath.startsWith('http') ? proofPath : '$backendUrl/$proofPath';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: proofUrl.toLowerCase().endsWith('.pdf')
                    ? Container(
                        color: Colors.white,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, color: AppTheme.danger, size: 64),
                              SizedBox(height: 16),
                              Text("PDF Document View\n(Interactive view coming soon)", textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                    : InteractiveViewer(
                        child: Image.network(
                          proofUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(color: Colors.white));
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.white,
                            child: const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<TaskAssignee> submissions = _taskDetail?.assignees
            .where((a) => a.proof != null && a.proof!.isNotEmpty)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.brandPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Verify Submissions",
              style: TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              widget.taskTitle,
              style: TextStyle(color: AppTheme.textSub, fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const ListViewSkeleton()
          : submissions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      final assignee = submissions[index];
                      return _buildUserProofCard(assignee);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 64, color: AppTheme.textSub.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            "No pending submissions",
            style: TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            "All proofs for this task have been cleared.",
            style: TextStyle(color: AppTheme.textSub, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProofCard(TaskAssignee assignee) {
    final bool isCompleted = assignee.status.toLowerCase() == 'completed' || assignee.status.toLowerCase() == 'closed';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPrimary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppTheme.brandAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    assignee.name.isNotEmpty ? assignee.name[0].toUpperCase() : "?",
                    style: const TextStyle(
                      color: AppTheme.brandAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignee.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brandPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${assignee.role} • ${assignee.status.toUpperCase()}",
                      style: TextStyle(
                        color: isCompleted ? AppTheme.success : AppTheme.textSub,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // View Button
              Expanded(
                flex: 2,
                child: _actionButton(
                  label: "View",
                  icon: Icons.visibility_rounded,
                  color: AppTheme.brandAccent,
                  onTap: () => _viewProof(assignee.proof),
                ),
              ),
              if (!isCompleted) ...[
                const SizedBox(width: 12),
                // Reject Button
                Expanded(
                  flex: 3,
                  child: _actionButton(
                    label: "Reject",
                    icon: Icons.close_rounded,
                    color: AppTheme.danger,
                    onTap: () => _handleReview(assignee.assignmentId, false),
                  ),
                ),
                const SizedBox(width: 12),
                // Approve Button
                Expanded(
                  flex: 3,
                  child: _actionButton(
                    label: "Approve",
                    icon: Icons.check_rounded,
                    color: AppTheme.success,
                    isPrimary: true,
                    onTap: () => _handleReview(assignee.assignmentId, true),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListViewSkeleton extends StatelessWidget {
  const ListViewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
