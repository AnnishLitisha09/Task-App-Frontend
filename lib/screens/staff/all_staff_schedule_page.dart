import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../components/skeleton_loader.dart';
import '../../models/staff_dashboard_model.dart';
import '../../services/user_service.dart';
import '../common/task_detail_page.dart';

class AllStaffSchedulePage extends StatefulWidget {
  const AllStaffSchedulePage({super.key});

  @override
  State<AllStaffSchedulePage> createState() => _AllStaffSchedulePageState();
}

class _AllStaffSchedulePageState extends State<AllStaffSchedulePage> {
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color successColor = const Color(0xFF10B981);
  final Color warningColor = const Color(0xFFF59E0B);

  List<StaffScheduleTask> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoading = true);
    try {
      final dashboard = await UserService().getStaffDashboard();
      if (mounted) {
        setState(() {
          _tasks = dashboard.todaysSchedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getTaskColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return successColor;
      case 'pending':
        return warningColor;
      case 'completed':
        return successColor;
      case 'rejected':
        return const Color(0xFFF43F5E);
      default:
        return brandAccent;
    }
  }

  IconData _getTaskIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('inspect')) return Icons.fact_check_outlined;
    if (t.contains('brief') || t.contains('meeting')) {
      return Icons.groups_rounded;
    }
    if (t.contains('waste') || t.contains('recycl')) {
      return Icons.recycling_rounded;
    }
    if (t.contains('security') || t.contains('round')) {
      return Icons.security_rounded;
    }
    if (t.contains('exam') || t.contains('invigilat')) {
      return Icons.school_rounded;
    }
    if (t.contains('practical') || t.contains('lab')) {
      return Icons.science_rounded;
    }
    return Icons.task_alt_rounded;
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
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Today's Schedule",
          style: TextStyle(
            color: brandPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSchedule,
        color: brandAccent,
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    SkeletonTaskCard(),
                    SkeletonTaskCard(),
                    SkeletonTaskCard(),
                    SkeletonTaskCard(),
                  ],
                ),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: const Color(0xFFF43F5E),
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Failed to load schedule",
                        style: TextStyle(
                          color: textMain,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _fetchSchedule,
                        child: Text(
                          "Retry",
                          style: TextStyle(color: brandAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _tasks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 60,
                      color: textSub.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No tasks scheduled for today",
                      style: TextStyle(
                        color: textSub,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(24),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final color = _getTaskColor(task.status);
                  final icon = _getTaskIcon(task.title);
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': task.taskId,
                            'title': task.title,
                          },
                        ),
                      ),
                    ),
                    child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: brandPrimary.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        color: textMain,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      task.timing,
                                      style: TextStyle(
                                        color: textSub,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  task.status.toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right_rounded, color: textSub, size: 20),
                            ],
                          ),
                        ),
                  )
                      .animate()
                      .fadeIn(delay: (60 * index).ms)
                      .slideX(begin: 0.05, end: 0);
                },
              ),
      ),
    );
  }
}
