import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/stat_card.dart';
import '../../components/task_card.dart';
import '../../components/section_header.dart';
import '../../components/unified_reject_dialog.dart';
import '../common/task_detail_page.dart';
import '../../models/faculty_dashboard_stats.dart';
import '../common/user_selection_page.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';

class FacultyPage extends StatefulWidget {
  final bool isBlocked;
  final VoidCallback onAcknowledge;
  const FacultyPage({
    super.key,
    this.isBlocked = false,
    required this.onAcknowledge,
  });

  @override
  State<FacultyPage> createState() => _FacultyPageState();
}

class _FacultyPageState extends State<FacultyPage> {
  FacultyDashboardStats? _stats;
  List<dynamic> _pendingProofs = [];
  List<dynamic> _escalations = [];
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchUserRole(),
      _fetchStats(),
      _fetchPendingProofs(),
      _fetchEscalations(),
    ]);
  }

  Future<void> _fetchUserRole() async {
    try {
      final profile = await UserService().getUserProfile();
      if (mounted) {
        setState(() {
          _userRole = profile.role;
        });
      }
    } catch (e) {
      // Fallback
    }
  }

  Future<void> _fetchStats() async {
    setState(() {});
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/faculty/stats/daily'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _stats = data is List
                ? FacultyDashboardStats.fromJson(data[0])
                : FacultyDashboardStats.fromJson(data);
          });
        }
      } else {
        throw Exception('Failed to load dashboard: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _fetchPendingProofs() async {
    try {
      final TaskService taskService = TaskService();
      final response = await taskService.getPendingProofs();
      if (mounted) {
        setState(() {
          // Handle new API response structure with 'tasks' array
          if (response is Map<String, dynamic> &&
              response.containsKey('tasks')) {
            _pendingProofs = response['tasks'] as List;
          } else if (response is List) {
            _pendingProofs = response;
          } else {
            _pendingProofs = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingProofs = [];
        });
      }
    }
  }

  Future<void> _fetchEscalations() async {
    try {
      final TaskService taskService = TaskService();
      final escalations = await taskService.getEscalations();
      if (mounted) {
        setState(() {
          _escalations = escalations;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _escalations = []);
      }
    }
  }

  // --- Logic: Handlers ---
  Future<void> _acceptTask(int index) async {
    if (_stats == null) return;
    final task = _stats!.pendingTasks[index];
    final taskId = task['task_id'];

    if (taskId == null) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await TaskService().acceptTask(taskId);
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task accepted successfully"),
            backgroundColor: AppTheme.success,
          ),
        );
        _refreshAll();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error accepting task: $e"),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  List<String> _getTransferableRoles() {
    final role = _userRole?.toLowerCase() ?? '';
    final List<String> hierarchy = [
      'admin',
      'principal',
      'dean',
      'hod',
      'faculty',
      'student',
      'staff',
    ];
    int userIndex = hierarchy.indexOf(role);
    // If unknown role, default strictly to students and staff
    if (userIndex == -1) return ['students', 'staff'];

    final Map<String, String> keyMap = {
      'hod': 'hods',
      'student': 'students',
      'faculty': 'faculty',
      'staff': 'staff',
      'admin': 'admin',
      'principal': 'principal',
      'dean': 'dean',
    };

    // Return roles equal to or higher than the user in hierarchy
    return hierarchy
        .sublist(0, userIndex + 1)
        .map((r) => keyMap[r] ?? r)
        .toList();
  }

  Future<void> _handleTransfer(int taskId, String title) async {
    final List<Map<String, dynamic>>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSelectionPage(
          multiSelect: false,
          allowedRoles: _getTransferableRoles(),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final selectedUser = result.first;
      final selectedUserId = selectedUser['user_id'] ?? selectedUser['id'];

      if (selectedUserId == null || !mounted) return;

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

        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Task '$title' transferred to ${selectedUser['name']}",
              ),
              backgroundColor: AppTheme.success,
            ),
          );
          _refreshAll();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading
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

  void _showRejectDialog(int index) {
    if (_stats == null) return;
    final task = _stats!.pendingTasks[index];
    final taskId = task['task_id'];
    final taskTitle = task['title'] ?? 'Task';

    if (taskId == null) return;

    UnifiedRejectDialog.show(
      context,
      taskTitle: taskTitle,
      onTransfer: () => _handleTransfer(taskId, taskTitle), // Trigger transfer
      onReject: (reason, details) async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          await TaskService().rejectTask(taskId, reason);
          if (mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Task rejected: $reason"),
                backgroundColor: AppTheme.success,
              ),
            );
            _refreshAll();
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading
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
    // We removed full-page loading/error guards to improve UX as requested.
    final info = _stats?.facultyInfo;
    final daily = _stats?.dailyStats;
    final pending = _stats?.pendingTasks ?? [];
    final allTasks = _stats?.allTasksToday ?? [];

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
              onRefresh: _refreshAll,
              color: AppTheme.brandAccent,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  CustomAppBar(
                    title: info?.name ?? "Faculty",
                    date: formattedDate,
                    notificationCount: pending.length,
                    profileImageUrl: info != null
                        ? 'https://i.pravatar.cc/150?u=faculty${info.id}'
                        : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                  ),
                  if (widget.isBlocked)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.danger.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppTheme.danger,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Action Required: Please acknowledge today's schedule to proceed.",
                                    style: AppTheme.bodyMain.copyWith(
                                      color: AppTheme.danger,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: widget.onAcknowledge,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.danger,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Acknowledge Now"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: [
                            StatCard(
                              label: "Pending",
                              value: (daily?.pendingTasksCount ?? 0).toString(),
                              icon: Icons.move_to_inbox,
                              color: AppTheme.brandAccent,
                            ),
                            StatCard(
                              label: "Tasks Today",
                              value: (daily?.totalTasksAssignedToday ?? 0)
                                  .toString(),
                              icon: Icons.assignment_rounded,
                              color: AppTheme.success,
                            ),
                            StatCard(
                              label: "Mentees",
                              value: (daily?.menteeStudentsCount ?? 0)
                                  .toString(),
                              icon: Icons.people_alt_rounded,
                              color: AppTheme.warning,
                            ),
                            StatCard(
                              label: "Hours",
                              value: "0",
                              icon: Icons.access_time_filled_rounded,
                              color: Colors.teal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        SectionHeader(
                          title: "Incoming Directives",
                          isStatus: true,
                          count: pending.length,
                          onViewAll: () {},
                        ),

                        if (pending.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "No pending directives",
                                style: TextStyle(
                                  color: AppTheme.textSub,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ...pending.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var data = entry.value;
                            final String heroTag =
                                "directive_${data['task_id']}_$idx";
                            return TaskCard(
                              title: data['title'] ?? 'Task',
                              sub: data['description'] ?? 'No description',
                              accent: AppTheme.brandAccent,
                              icon: Icons.assignment_turned_in_rounded,
                              heroTag: heroTag,
                              isRequest: true,
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
                                _acceptTask(idx);
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
                                _showRejectDialog(idx);
                              },
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailsPage(
                                    taskData: {
                                      'task_id':
                                          data['task_id'], // Added task_id
                                      'title': data['title'],
                                      'sub': data['description'],
                                      'accent': AppTheme.brandAccent,
                                      'icon':
                                          Icons.assignment_turned_in_rounded,
                                      'heroTag': heroTag,
                                      'startDate': data['start_date'] ?? "N/A",
                                      'deadline': data['end_date'] ?? "N/A",
                                      'completionType':
                                          data['type'] ?? "APPROVAL",
                                      'isRequest': true,
                                      'authority': "Administration",
                                      'userRole':
                                          'Faculty', // Ensure transfer option shows
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 32),

                        SectionHeader(
                          title: "Escalated Tasks",
                          isStatus: true,
                          count: _escalations.length,
                          onViewAll: () {},
                        ),
                        if (_escalations.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "No escalated tasks",
                                style: TextStyle(
                                  color: AppTheme.textSub,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._escalations.map((escalation) {
                            final String heroTag =
                                "escalation_${escalation['task_id']}_pending";
                            return TaskCard(
                              title: escalation['title'] ?? "Escalated Task",
                              sub:
                                  escalation['escalated_reason'] ??
                                  escalation['description'] ??
                                  "High Priority",
                              accent: AppTheme.danger,
                              icon: Icons.priority_high_rounded,
                              heroTag: heroTag,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailsPage(
                                    taskData: {
                                      'task_id': escalation['task_id'],
                                      'title': escalation['title'],
                                      'sub': escalation['description'],
                                      'accent': AppTheme.danger,
                                      'icon': Icons.priority_high_rounded,
                                      'heroTag': heroTag,
                                      'startDate':
                                          escalation['start_date'] ?? "N/A",
                                      'deadline':
                                          escalation['end_date'] ?? "N/A",
                                      'completionType':
                                          escalation['type'] ?? "INFO",
                                      'isRequest': false,
                                      'authority': "Administration",
                                      'userRole': 'Faculty',
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 32),

                        SectionHeader(
                          title: "Today's Schedule",
                          onViewAll: () {},
                        ),
                        if (allTasks.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "No tasks scheduled for today",
                                style: TextStyle(
                                  color: AppTheme.textSub,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ...allTasks.map((item) {
                            final String heroTag =
                                "task_${item['task_id']}_today";
                            return TaskCard(
                              title: item['title'] ?? 'Task',
                              sub: item['status'] ?? 'Scheduled',
                              accent: AppTheme.success,
                              icon: Icons.calendar_today_rounded,
                              heroTag: heroTag,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailsPage(
                                    taskData: {
                                      'task_id':
                                          item['task_id'], // Added task_id
                                      'title': item['title'],
                                      'sub': item['status'],
                                      'accent': AppTheme.success,
                                      'icon': Icons.calendar_today_rounded,
                                      'heroTag': heroTag,
                                      'startDate': item['start_date'] ?? "N/A",
                                      'deadline': item['end_date'] ?? "N/A",
                                      'completionType': "INFO",
                                      "isRequest": false,
                                      'userRole':
                                          'Faculty', // Ensure transfer option shows if needed
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 32),

                        SectionHeader(
                          title: "Pending Proofs",
                          isStatus: true,
                          count: _pendingProofs.length,
                          onViewAll: () {},
                        ),
                        if (_pendingProofs.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "No pending proofs to review",
                                style: TextStyle(
                                  color: AppTheme.textSub,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._pendingProofs.map((proof) {
                            final String heroTag =
                                "proof_${proof['task_id']}_pending";
                            // Extract deadline information
                            final deadline = proof['deadline'];
                            final String deadlineStr = deadline != null
                                ? "${deadline['end_date'] ?? 'N/A'} ${deadline['end_time'] ?? ''}"
                                : "N/A";

                            return TaskCard(
                              title: proof['title'] ?? 'Proof Task',
                              sub:
                                  proof['description'] ??
                                  'Proof Status: ${proof['proof_status'] ?? 'Pending'}',
                              accent: Colors.orange,
                              icon: Icons.photo_camera_rounded,
                              heroTag: heroTag,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailsPage(
                                    taskData: {
                                      'task_id': proof['task_id'],
                                      'assignment_id': proof['assignment_id'],
                                      'title': proof['title'],
                                      'sub':
                                          proof['description'] ??
                                          'Awaiting proof verification',
                                      'accent': Colors.orange,
                                      'icon': Icons.photo_camera_rounded,
                                      'heroTag': heroTag,
                                      'deadline': deadlineStr,
                                      'completionType': "PROOF_REVIEW",
                                      'isRequest': false,
                                      'userRole': 'Faculty',
                                      'is_document': proof['is_document'],
                                      'status': proof['status'],
                                      'proof_status': proof['proof_status'],
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 32),
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
}
