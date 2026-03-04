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
import '../../components/skeleton_loader.dart';
import '../../components/unified_reject_dialog.dart';
import '../common/task_detail_page.dart';
import '../../models/faculty_dashboard_stats.dart';
import '../common/user_selection_page.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import 'all_directives_page.dart';
import 'all_escalations_page.dart';
import 'all_schedule_page.dart';
import 'all_proofs_page.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchUserRole(),
      _fetchStats(),
      _fetchPendingProofs(),
      _fetchEscalations(),
    ]);
    if (mounted) setState(() => _isLoading = false);
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
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchPendingProofs() async {
    try {
      final TaskService taskService = TaskService();
      final dynamic response = await taskService.getPendingProofs();
      if (mounted) {
        setState(() {
          if (response is Map && response.containsKey('tasks')) {
            _pendingProofs = response['tasks'] as List;
          } else if (response is List) {
            _pendingProofs = response;
          } else {
            _pendingProofs = [];
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _pendingProofs = []);
    }
  }

  Future<void> _fetchEscalations() async {
    try {
      final TaskService taskService = TaskService();
      final escalations = await taskService.getEscalations();
      if (mounted) setState(() => _escalations = escalations);
    } catch (e) {
      if (mounted) setState(() => _escalations = []);
    }
  }

  // --- Logic: Handlers ---
  Future<void> _acceptTask(int index) async {
    if (_stats == null) return;
    final task = _stats!.pendingTasks[index];
    final taskId = task['task_id'];
    if (taskId == null) return;

    // Fast reflex: Optimistically update local state
    setState(() {
      final task = _stats!.pendingTasks.removeAt(index);
      _stats!.allTasksToday.insert(0, task);
      _stats!.dailyStats.totalTasksAssignedToday = _stats!.allTasksToday.length;
      _stats!.dailyStats.pendingTasksCount = _stats!.pendingTasks.length;
    });

    try {
      await TaskService().acceptTask(taskId);
      if (mounted) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error accepting task: $e"),
            backgroundColor: AppTheme.danger,
          ),
        );
        _refreshAll(); // Revert/Sync with server
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
          Navigator.pop(context);
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

  void _showRejectDialog(int index) {
    if (_stats == null) return;
    final task = _stats!.pendingTasks[index];
    final taskId = task['task_id'];
    final taskTitle = task['title'] ?? 'Task';
    if (taskId == null) return;

    UnifiedRejectDialog.show(
      context,
      taskTitle: taskTitle,
      onTransfer: () => _handleTransfer(taskId, taskTitle),
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
            Navigator.pop(context);
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
              backgroundColor: const Color.fromARGB(
                255,
                209,
                149,
                237,
              ).withOpacity(0.05),
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
                        ? 'https://ui-avatars.com/api/?name=${info.name.replaceAll(' ', '+')}&background=random'
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
                  if (_isLoading)
                    const SliverToBoxAdapter(child: DashboardSkeleton())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      label: "Pending",
                                      value: (daily?.pendingTasksCount ?? 0)
                                          .toString(),
                                      icon: Icons.move_to_inbox,
                                      color: AppTheme.brandAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StatCard(
                                      label: "Tasks Today",
                                      value:
                                          (daily?.totalTasksAssignedToday ?? 0)
                                              .toString(),
                                      icon: Icons.assignment_rounded,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      label: "Mentees",
                                      value: (daily?.menteeStudentsCount ?? 0)
                                          .toString(),
                                      icon: Icons.people_alt_rounded,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StatCard(
                                      label: "Hours",
                                      value: "0",
                                      icon: Icons.access_time_filled_rounded,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // --- Incoming Directives (max 2) ---
                          SectionHeader(
                            title: "Incoming Directives",
                            isStatus: true,
                            count: pending.length,
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AllDirectivesPage(
                                  userRole: _userRole ?? 'Faculty',
                                  isBlocked: widget.isBlocked,
                                  onRefreshParent: _refreshAll,
                                ),
                              ),
                            ),
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
                            ...pending.take(2).toList().asMap().entries.map<
                              Widget
                            >((entry) {
                              int idx = entry.key;
                              var data = entry.value;
                              final String heroTag =
                                  "directive_${data['task_id']}_$idx";

                              final taskType =
                                  data['task_type'] as Map<String, dynamic>? ??
                                  {};
                              final String dateStr =
                                  taskType['start_date'] ?? "";
                              final String startTime =
                                  taskType['start_time'] ?? "";
                              final String endTime = taskType['end_time'] ?? "";
                              String timeInfo = "";
                              if (startTime.isNotEmpty && endTime.isNotEmpty) {
                                timeInfo =
                                    " (${startTime.substring(0, 5)} - ${endTime.substring(0, 5)})";
                              } else if (startTime.isNotEmpty) {
                                timeInfo = " (${startTime.substring(0, 5)})";
                              }

                              final String formattedDate = dateStr.isNotEmpty
                                  ? DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(DateTime.parse(dateStr))
                                  : "";

                              final String dateDisplay =
                                  formattedDate.isNotEmpty
                                  ? "$formattedDate$timeInfo"
                                  : "";
                              final bool hasDesc =
                                  data['description'] != null &&
                                  data['description'].toString().isNotEmpty;
                              final String finalDesc = hasDesc
                                  ? " • ${data['description']}"
                                  : "";
                              final String subText = "$dateDisplay$finalDesc";

                              return TaskCard(
                                key: ValueKey(heroTag),
                                title: data['title'] ?? 'Task',
                                sub: subText,
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
                                        'task_id': data['task_id'],
                                        'title': data['title'],
                                        'sub': data['description'],
                                        'accent': AppTheme.brandAccent,
                                        'icon':
                                            Icons.assignment_turned_in_rounded,
                                        'heroTag': heroTag,
                                        'startDate':
                                            taskType['start_date'] ?? "N/A",
                                        'deadline':
                                            taskType['end_date'] ?? "N/A",
                                        'completionType':
                                            data['type'] ?? "APPROVAL",
                                        'isRequest': true,
                                        'authority': "Administration",
                                        'userRole': 'Faculty',
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),

                          const SizedBox(height: 32),

                          // --- Escalated Tasks (max 2) ---
                          SectionHeader(
                            title: "Escalated Tasks",
                            isStatus: true,
                            count: _escalations.length,
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AllEscalationsPage(
                                  userRole: _userRole ?? 'Faculty',
                                ),
                              ),
                            ),
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
                            ..._escalations.take(2).map<Widget>((escalation) {
                              final String heroTag =
                                  "escalation_${escalation['task_id'] ?? escalation['id']}_pending";
                              final String title =
                                  escalation['task_title']?.toString() ??
                                  escalation['title']?.toString() ??
                                  'Escalated Task';
                              final String sub =
                                  escalation['reason']?.toString() ??
                                  escalation['message']?.toString() ??
                                  escalation['escalated_reason']?.toString() ??
                                  'Requires attention';
                              final String dateStr =
                                  escalation['created_at'] != null
                                  ? escalation['created_at']
                                        .toString()
                                        .split('T')
                                        .first
                                  : 'N/A';
                              return TaskCard(
                                key: ValueKey(heroTag),
                                title: title,
                                sub: '$sub • $dateStr',
                                accent: AppTheme.danger,
                                icon: Icons.priority_high_rounded,
                                heroTag: heroTag,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TaskDetailsPage(
                                      taskData: {
                                        'task_id': escalation['task_id'],
                                        'title': title,
                                        'sub': sub,
                                        'accent': AppTheme.danger,
                                        'icon': Icons.priority_high_rounded,
                                        'heroTag': heroTag,
                                        'startDate': dateStr,
                                        'deadline':
                                            escalation['end_date'] ?? 'N/A',
                                        'completionType':
                                            escalation['status'] ??
                                            escalation['type'] ??
                                            'PENDING',
                                        'isRequest': false,
                                        'authority': 'Administration',
                                        'userRole': 'Faculty',
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),

                          const SizedBox(height: 32),

                          // --- Today's Schedule (max 2) ---
                          SectionHeader(
                            title: "Today's Schedule",
                            onViewAll: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AllSchedulePage(
                                    userRole: _userRole ?? 'Faculty',
                                  ),
                                ),
                              );
                              _refreshAll();
                            },
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
                            ...allTasks.take(2).map<Widget>((item) {
                              final String heroTag =
                                  "task_${item['task_id']}_today";
                              final taskType =
                                  item['task_type'] as Map<String, dynamic>? ??
                                  {};
                              final String dateStr =
                                  taskType['start_date'] ?? "";
                              final String startTime =
                                  taskType['start_time'] ?? "";
                              final String endTime = taskType['end_time'] ?? "";

                              String timeInfo = "";
                              if (startTime.isNotEmpty && endTime.isNotEmpty) {
                                timeInfo =
                                    " (${startTime.substring(0, 5)} - ${endTime.substring(0, 5)})";
                              } else if (startTime.isNotEmpty) {
                                timeInfo = " (${startTime.substring(0, 5)})";
                              }

                              final String formattedDate = dateStr.isNotEmpty
                                  ? DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(DateTime.parse(dateStr))
                                  : "";

                              final String dateDisplay =
                                  formattedDate.isNotEmpty
                                  ? "$formattedDate$timeInfo"
                                  : "";
                              final bool hasDesc =
                                  item['description'] != null &&
                                  item['description'].toString().isNotEmpty;
                              final String finalDesc = hasDesc
                                  ? " • ${item['description']}"
                                  : "";
                              final String subText = "$dateDisplay$finalDesc";

                              return TaskCard(
                                key: ValueKey(heroTag),
                                title: item['title'] ?? 'Task',
                                sub: subText,
                                accent: AppTheme.success,
                                icon: Icons.calendar_today_rounded,
                                heroTag: heroTag,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TaskDetailsPage(
                                      taskData: {
                                        'task_id': item['task_id'],
                                        'title': item['title'],
                                        'sub': item['status'],
                                        'accent': AppTheme.success,
                                        'icon': Icons.calendar_today_rounded,
                                        'heroTag': heroTag,
                                        'startDate':
                                            taskType['start_date'] ?? "N/A",
                                        'deadline':
                                            taskType['end_date'] ?? "N/A",
                                        'completionType': "INFO",
                                        "isRequest": false,
                                        'userRole': 'Faculty',
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),

                          const SizedBox(height: 32),

                          // --- Pending Proofs (max 2) ---
                          SectionHeader(
                            title: "Pending Proofs",
                            isStatus: true,
                            count: _pendingProofs.length,
                            onViewAll: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AllProofsPage(),
                                ),
                              );
                              _refreshAll();
                            },
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
                            ..._pendingProofs.take(2).map<Widget>((proof) {
                              final String heroTag =
                                  "proof_${proof['task_id']}_pending";
                              final deadline = proof['deadline'];
                              final String deadlineStr = deadline != null
                                  ? "${deadline['end_date'] ?? 'N/A'} ${deadline['end_time'] ?? ''}"
                                  : "N/A";

                              return TaskCard(
                                key: ValueKey(heroTag),
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
                            }).toList(),

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
