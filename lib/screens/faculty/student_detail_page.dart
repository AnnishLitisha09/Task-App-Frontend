import 'package:flutter/material.dart';
import '../../services/student_service.dart';
import '../../models/student_model.dart';
import '../../theme/app_theme.dart';

class StudentDetailPage extends StatefulWidget {
  final int studentId;

  const StudentDetailPage({super.key, required this.studentId});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  final StudentService _studentService = StudentService();
  StudentDetail? _studentDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await _studentService.getStudentDetails(widget.studentId);
      if (mounted) {
        setState(() {
          _studentDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_studentDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Student not found")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Student Profile",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(_studentDetail!),
            const SizedBox(height: 32),

            // Stats Grid
            _buildStatsGrid(_studentDetail!),
            const SizedBox(height: 32),

            // Active Tasks
            _buildSectionHeader("Directives Today"),
            const SizedBox(height: 16),
            if (_studentDetail!.directives.isEmpty)
              _buildEmptyState("No directives assigned today.")
            else
              ..._studentDetail!.directives.map((task) => _buildTaskItem(task)),

            const SizedBox(height: 32),

            // History
            _buildSectionHeader("Self Logs Today"),
            const SizedBox(height: 16),
            if (_studentDetail!.selfLogs.isEmpty)
              _buildEmptyState("No self logs tracked today.")
            else
              ..._studentDetail!.selfLogs.map((task) => _buildTaskItem(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(StudentDetail student) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(student.avatarUrl ?? ""),
          backgroundColor: AppTheme.brandAccent.withOpacity(0.1),
        ),
        const SizedBox(height: 16),
        Text(
          student.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${student.department} • ${student.registerNumber}",
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(StudentDetail student) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Overall Score",
            student.totalScore.toStringAsFixed(1),
            AppTheme.success,
            Icons.bolt,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Total Penalty",
            "-${student.totalPenalty.toStringAsFixed(1)}",
            AppTheme.danger,
            Icons.history_toggle_off,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(dynamic task) {
    if (task == null) return const SizedBox.shrink();

    final title = task['title'] ?? task['task_title'] ?? "Untitled Task";
    final category = task['category'] ?? "General";
    final status = task['status'] ?? "PENDING";
    final isEscalate =
        task['is_escalate'] == true || task['isEscalate'] == true;

    Color statusColor;
    if (status.toString().toUpperCase() == "COMPLETED") {
      statusColor = AppTheme.success;
    } else if (status.toString().toUpperCase() == "REJECTED") {
      statusColor = AppTheme.danger;
    } else {
      statusColor = const Color(0xFF64748B); // Fallback Slate color
    }

    return InkWell(
      onTap: () {
        // You can integrate TaskDetailsPage here if you have taskId
        // Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsPage(...)))
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEscalate
                    ? AppTheme.danger.withOpacity(0.1)
                    : AppTheme.brandAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isEscalate
                    ? Icons.priority_high_rounded
                    : Icons.assignment_outlined,
                color: isEscalate ? AppTheme.danger : AppTheme.brandAccent,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isEscalate
                          ? AppTheme.danger
                          : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
