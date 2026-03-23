import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/stat_card.dart';
import '../../components/task_card.dart';
import '../../components/section_header.dart';
import '../../components/skeleton_loader.dart';
import '../../components/reject_dialog.dart';
import '../../services/student_service.dart';
import '../../services/task_service.dart';
import '../../models/student_dashboard_model.dart';
import 'student_tasks_list_page.dart';
import 'all_new_task_page.dart';
import '../common/task_detail_page.dart';
import '../common/generic_view_all_page.dart';
import '../common/score_performance_page.dart';
import '../../services/notification_service.dart';



class StudentPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAcceptTask;
  final bool isBlocked;
  final VoidCallback onAcknowledge;
  const StudentPage({
    super.key,
    required this.onAcceptTask,
    this.isBlocked = false,
    required this.onAcknowledge,
  });

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  bool _isLoading = true;
  StudentDashboard? _dashboard;
  List<dynamic> _pendingProofs = [];
  int _unreadNotifications = 0;
  final StudentService _studentService = StudentService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _studentService.getStudentDashboard(),
        TaskService().getPendingProofs(),
        _notificationService.getUnreadCount(),
      ]);

      if (mounted) {
        setState(() {
          _dashboard = results[0] as StudentDashboard;
          final proofs = results[1];
          _unreadNotifications = results[2] as int;
          if (proofs is List) {
            _pendingProofs = proofs;
          } else if (proofs is Map) {
            if (proofs.containsKey('items')) {
              _pendingProofs = proofs['items'];
            } else if (proofs.containsKey('data')) {
              _pendingProofs = proofs['data'];
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading dashboard: $e")));
      }
    }
  }

  bool _checkOverlap(String newTiming) {
    if (_dashboard == null) return false;

    for (var task in _dashboard!.todaysSchedule) {
      if (_isTimeOverlapping(newTiming, task.timing)) {
        return true;
      }
    }
    return false;
  }

  bool _isTimeOverlapping(String t1, String t2) {
    try {
      final r1 = _parseTiming(t1);
      final r2 = _parseTiming(t2);
      if (r1 == null || r2 == null) return false;

      // Overlap: start1 < end2 AND start2 < end1
      return r1[0] < r2[1] && r2[0] < r1[1];
    } catch (e) {
      return false;
    }
  }

  List<int>? _parseTiming(String timing) {
    try {
      final parts = timing.split('-');
      if (parts.length != 2) return null;

      return [
        _parseToMinutes(parts[0].trim()),
        _parseToMinutes(parts[1].trim()),
      ];
    } catch (e) {
      return null;
    }
  }

  int _parseToMinutes(String timeStr) {
    // Handles "09:00", "09:00 AM", "14:00"
    final clean = timeStr.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    bool isPM = clean.contains('PM');
    bool isAM = clean.contains('AM');
    final timeOnly = clean.replaceAll('AM', '').replaceAll('PM', '');
    final parts = timeOnly.split(':');
    int hours = int.parse(parts[0]);
    int minutes = parts.length > 1 ? int.parse(parts[1]) : 0;

    if (isPM && hours < 12) hours += 12;
    if (isAM && hours == 12) hours = 0;

    return hours * 60 + minutes;
  }

  Future<void> _handleAcceptTask(Map<String, dynamic> task) async {
    final String timing = task['timing'] ?? '';
    final int taskId = task['task_id'];

    if (_checkOverlap(timing)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Warning: This task overlaps with an existing schedule!",
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      await TaskService().acceptTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task accepted successfully!"),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to accept task: $e")));
      }
    }
  }

  Future<void> _handleApprove(int index) async {
    if (_dashboard == null) return;
    final task = _dashboard!.pendingForApproval[index];
    await _handleAcceptTask({
      'task_id': task.taskId,
      'timing': task.timing,
      'title': task.title,
    });
  }

  Future<void> _handleReject(int taskId, String reason) async {
    try {
      await TaskService().rejectTask(taskId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request declined"),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to decline request: $e")),
        );
      }
    }
  }

  void _showRejectDialog(int taskId, String title) {
    RejectDialog.show(
      context,
      taskTitle: title,
      reasons: [
        "Exam Preparation",
        "Class Overlap",
        "Personal Emergency",
        "Other",
      ],
      onConfirm: (reason, details) =>
          _handleReject(taskId, reason == "Other" ? details : reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, MMM dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: AppTheme.brandAccent.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchDashboard,
              color: AppTheme.brandAccent,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  CustomAppBar(
                    title: "Annish Litisha",
                    date: formattedDate,
                    notificationCount: _unreadNotifications,
                    profileImageUrl:
                        'https://img.freepik.com/premium-vector/purple-circle-with-white-person-icon_876006-6.jpg?w=360',
                  ),
                  if (_isLoading)
                    const SliverToBoxAdapter(child: DashboardSkeleton())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (widget.isBlocked)
                            _buildBlockedMessage()
                          else ...[
                            GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.4,
                                  children: [
                                    StatCard(
                                      label: "Total Score",
                                      value:
                                          _dashboard?.studentDetails.score ??
                                          "0",
                                      icon: Icons.assignment_rounded,
                                      color: AppTheme.brandAccent,
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ScorePerformancePage(),
                                          ),
                                        );
                                        _fetchDashboard(); // Refresh score when coming back
                                      },
                                    ),
                                    StatCard(
                                      label: "Pending",
                                      value:
                                          (_dashboard
                                                      ?.counts
                                                      .pendingApprovalCount ??
                                                  0)
                                              .toString()
                                              .padLeft(2, '0'),
                                      icon: Icons.schedule_rounded,
                                      color: AppTheme.warning,
                                    ),
                                    StatCard(
                                      label: "Overdue",
                                      value:
                                          (_dashboard
                                                      ?.counts
                                                      .overdueTasksCount ??
                                                  0)
                                              .toString()
                                              .padLeft(2, '0'),
                                      icon: Icons.bolt_rounded,
                                      color: AppTheme.danger,
                                    ),
                                    StatCard(
                                      label: "Current GPA",
                                      value:
                                          _dashboard?.studentDetails.cGpa ??
                                          "0.0",
                                      icon: Icons.auto_graph_rounded,
                                      color: AppTheme.success,
                                    ),
                                  ],
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),
                            const SizedBox(height: 32),

                            // 1. Today's Schedule
                            SectionHeader(
                              title: "Today's Schedule",
                              count: _dashboard?.todaysSchedule.length ?? 0,
                              onViewAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentTasksListPage(
                                    title: "Today's Schedule",
                                    tasks: _dashboard?.todaysSchedule ?? [],
                                    mode: 'today',
                                  ),
                                ),
                              ),
                            ),
                            if (_dashboard?.todaysSchedule.isEmpty ?? true)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    "No tasks for today",
                                    style: TextStyle(color: AppTheme.textSub),
                                  ),
                                ),
                              )
                            else
                              ...(_dashboard!.todaysSchedule.take(2)).map((
                                task,
                              ) {
                                final String heroTag = "today_${task.taskId}";
                                return TaskCard(
                                  title: task.title,
                                  sub:
                                      "Today • ${task.timing} • ${task.category}",
                                  accent: AppTheme.brandAccent,
                                  icon: Icons.calendar_today,
                                  heroTag: heroTag,
                                  actionButton: task.actionButton,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TaskDetailsPage(
                                          taskData: {
                                            'task_id': task.taskId,
                                            'title': task.title,
                                            'category': task.category,
                                            'timing': task.timing,
                                            'heroTag': heroTag,
                                            'status': task.status,
                                            'accent': AppTheme.brandAccent,
                                            'icon': Icons.calendar_today,
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),

                            const SizedBox(height: 32),

                            // 2. New Task Requests
                            Builder(
                              builder: (context) {
                                final newRequests =
                                    _dashboard?.pendingForApproval
                                        .where((t) => !t.isEscalated)
                                        .toList() ??
                                    [];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: "New Task Requests",
                                      isStatus: true,
                                      count: newRequests.length,
                                      onViewAll: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AllNewTasksPage(
                                            onAccept: (task) =>
                                                _handleAcceptTask(task),
                                            initialTasks: newRequests,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (newRequests.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: Text(
                                            "No new task requests",
                                            style: TextStyle(
                                              color: AppTheme.textSub,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      ...newRequests
                                          .take(2)
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                            final idx = entry.key;
                                            final task = entry.value;
                                            final realIdx = _dashboard!
                                                .pendingForApproval
                                                .indexOf(task);
                                            final String heroTag =
                                                "task_req_${task.taskId}_$idx";
                                            return TaskCard(
                                              title: task.title,
                                              sub:
                                                  "${task.date} • ${task.timing} • ${task.category}",
                                              accent: AppTheme.warning,
                                              icon: Icons
                                                  .assignment_late_outlined,
                                              heroTag: heroTag,
                                              isRequest: true,
                                              onAccept: () =>
                                                  _handleApprove(realIdx),
                                              onReject: () => _showRejectDialog(
                                                task.taskId,
                                                task.title,
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TaskDetailsPage(
                                                          taskData: {
                                                            'task_id':
                                                                task.taskId,
                                                            'title': task.title,
                                                            'category':
                                                                task.category,
                                                            'timing':
                                                                task.timing,
                                                            'heroTag': heroTag,
                                                            'status': 'PENDING',
                                                            'accent': AppTheme
                                                                .warning,
                                                            'icon': Icons
                                                                .assignment_late_outlined,
                                                          },
                                                        ),
                                                  ),
                                                );
                                              },
                                            );
                                          }),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // 3. Directives Pending (Escalated Only)
                            Builder(
                              builder: (context) {
                                final escalated =
                                    _dashboard?.pendingForApproval
                                        .where((t) => t.isEscalated)
                                        .toList() ??
                                    [];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: "Directives Pending",
                                      color: AppTheme.danger,
                                      count: escalated.length,
                                      onViewAll: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              StudentTasksListPage(
                                                title: "Directives Pending",
                                                tasks: escalated,
                                                mode: 'pending',
                                                onAccept: (task) =>
                                                    _handleAcceptTask(task),
                                                onReject: (id, title) =>
                                                    _handleReject(
                                                      id,
                                                      "Declined",
                                                    ),
                                              ),
                                        ),
                                      ),
                                    ),
                                    if (escalated.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: Text(
                                            "No pending directives",
                                            style: TextStyle(
                                              color: AppTheme.textSub,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      ...escalated
                                          .take(2)
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                            final idx = entry.key;
                                            final task = entry.value;
                                            final String heroTag =
                                                "dir_esc_${task.taskId}_$idx";
                                            return TaskCard(
                                              title: task.title,
                                              sub:
                                                  "🚨 Escalated • ${task.date} • ${task.timing}",
                                              accent: AppTheme.danger,
                                              icon: Icons.warning_amber_rounded,
                                              heroTag: heroTag,
                                              isRequest: true,
                                              onAccept: () => _handleApprove(
                                                _dashboard!.pendingForApproval
                                                    .indexOf(task),
                                              ),
                                              onReject: () => _showRejectDialog(
                                                task.taskId,
                                                task.title,
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TaskDetailsPage(
                                                          taskData: {
                                                            'task_id':
                                                                task.taskId,
                                                            'title': task.title,
                                                            'category':
                                                                task.category,
                                                            'timing':
                                                                task.timing,
                                                            'heroTag': heroTag,
                                                            'status':
                                                                'ESCALATED',
                                                            'accent':
                                                                AppTheme.danger,
                                                            'icon': Icons
                                                                .warning_amber_rounded,
                                                          },
                                                        ),
                                                  ),
                                                );
                                              },
                                            );
                                          }),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // 4. Overdue Tasks
                            SectionHeader(
                              title: "Overdue Tasks",
                              color: AppTheme.danger,
                              count: _dashboard?.overdueTasks.length ?? 0,
                              onViewAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentTasksListPage(
                                    title: "Overdue Tasks",
                                    tasks: _dashboard?.overdueTasks ?? [],
                                    mode: 'overdue',
                                  ),
                                ),
                              ),
                            ),
                            if (_dashboard?.overdueTasks.isEmpty ?? true)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    "No overdue tasks",
                                    style: TextStyle(color: AppTheme.textSub),
                                  ),
                                ),
                              )
                            else
                              ..._dashboard!.overdueTasks.take(2).map((task) {
                                return TaskCard(
                                  title: task.title,
                                  sub:
                                      "Deadline: ${task.date} • ${task.timing}",
                                  accent: AppTheme.danger,
                                  icon: Icons.priority_high_rounded,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TaskDetailsPage(
                                          taskData: {
                                            'task_id': task.taskId,
                                            'assignment_id': task.assignmentId,
                                            'title': task.title,
                                            'category': task.category,
                                            'timing': task.timing,
                                            'status': task.status,
                                            'accent': AppTheme.danger,
                                            'icon': Icons.priority_high_rounded,
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),

                            const SizedBox(height: 32),

                            // 5. Pending Proofs
                            SectionHeader(
                              title: "Pending Proofs",
                              count: _pendingProofs.length,
                              onViewAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GenericViewAllPage(
                                    title: "Pending Proofs",
                                    tasks: _pendingProofs,
                                    viewMode: 'viewonly',
                                    accentColor: AppTheme.success,
                                  ),
                                ),
                              ),
                            ),
                            if (_pendingProofs.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    "No pending proofs",
                                    style: TextStyle(color: AppTheme.textSub),
                                  ),
                                ),
                              )
                            else
                              ..._pendingProofs.take(2).map((proof) {
                                return TaskCard(
                                  title: proof['title'] ?? 'Proof Review',
                                  sub:
                                      "Status: ${proof['status'] ?? 'Pending'}",
                                  accent: AppTheme.success,
                                  icon: Icons.verified_rounded,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TaskDetailsPage(
                                          taskData: {
                                            'task_id': proof['task_id'],
                                            'title': proof['title'],
                                            'status': proof['status'],
                                            'isPendingProof': true,
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
                          ],
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_person_rounded,
            size: 64,
            color: AppTheme.danger.withOpacity(0.8),
          ),
          const SizedBox(height: 24),
          Text(
            "Access Restricted",
            style: AppTheme.h2.copyWith(color: AppTheme.danger),
          ),
          const SizedBox(height: 12),
          const Text(
            "Your account is restricted because today's tasks haven't been acknowledged. Please contact an administrator to acknowledge your schedule.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            "Once an admin acknowledges your schedule, you can refresh to gain access.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onAcknowledge,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Check Acknowledgment Status"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
