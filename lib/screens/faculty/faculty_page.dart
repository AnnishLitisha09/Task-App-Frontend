import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'directives_view_all_page.dart';
import 'escalations_view_all_page.dart';
import 'schedule_view_all_page.dart';
import 'pending_proofs_view_all_page.dart';

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
    if (mounted) setState(() => _isLoading = true);
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
        setState(() => _userRole = profile.role);
      }
    } catch (_) {}
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
      }
    } catch (_) {}
  }

  Future<void> _fetchPendingProofs() async {
    try {
      final response = await TaskService().getPendingProofs();
      if (mounted) {
        setState(() {
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
    } catch (_) {
      if (mounted) setState(() => _pendingProofs = []);
    }
  }

  Future<void> _fetchEscalations() async {
    try {
      final escalations = await TaskService().getEscalations();
      if (mounted) setState(() => _escalations = escalations);
    } catch (_) {
      if (mounted) setState(() => _escalations = []);
    }
  }

  // ─── Handlers ────────────────────────────────────────────────────────────
  Future<void> _acceptTask(int index) async {
    if (_stats == null) return;
    final task = _stats!.pendingTasks[index];
    final taskId = task['task_id'];
    if (taskId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await TaskService().acceptTask(taskId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Task accepted successfully"),
          backgroundColor: AppTheme.success,
        ));
        _refreshAll();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error accepting task: $e"),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  List<String> _getTransferableRoles() {
    final role = _userRole?.toLowerCase() ?? '';
    const hierarchy = ['admin', 'principal', 'dean', 'hod', 'faculty', 'student', 'staff'];
    final userIndex = hierarchy.indexOf(role);
    if (userIndex == -1) return ['students', 'staff'];
    const keyMap = {
      'hod': 'hods', 'student': 'students', 'faculty': 'faculty',
      'staff': 'staff', 'admin': 'admin', 'principal': 'principal', 'dean': 'dean',
    };
    return hierarchy.sublist(0, userIndex + 1).map((r) => keyMap[r] ?? r).toList();
  }

  Future<void> _handleTransfer(int taskId, String title) async {
    final List<Map<String, dynamic>>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserSelectionPage(
          multiSelect: false,
          allowedRoles: _getTransferableRoles(),
        ),
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;

    final selectedUser = result.first;
    final selectedUserId = selectedUser['user_id'] ?? selectedUser['id'];
    if (selectedUserId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await TaskService().rejectTask(
        taskId,
        "Transferred to ${selectedUser['name']}",
        transferToUserId: selectedUserId,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Task '$title' transferred to ${selectedUser['name']}"),
          backgroundColor: AppTheme.success,
        ));
        _refreshAll();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error transferring task: $e"),
          backgroundColor: AppTheme.danger,
        ));
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
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        try {
          await TaskService().rejectTask(taskId, reason);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Task rejected: $reason"),
              backgroundColor: AppTheme.success,
            ));
            _refreshAll();
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Error rejecting task: $e"),
              backgroundColor: AppTheme.danger,
            ));
          }
        }
      },
    );
  }

  // ─── Skeleton helpers ─────────────────────────────────────────────────────

  Widget _skeletonBox({
    double width = double.infinity,
    double height = 16,
    double radius = 10,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: Colors.white.withOpacity(0.6),
        );
  }

  // Skeleton for a single stat card
  Widget _skeletonStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _skeletonBox(width: 32, height: 32, radius: 10),
          const SizedBox(height: 8),
          _skeletonBox(width: 50, height: 22, radius: 8),
          const SizedBox(height: 4),
          _skeletonBox(width: 70, height: 12, radius: 6),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.5));
  }

  // Skeleton for a section header row
  Widget _skeletonSectionHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 4),
      child: Row(
        children: [
          _skeletonBox(width: 140, height: 18, radius: 8),
          const SizedBox(width: 8),
          _skeletonBox(width: 24, height: 18, radius: 6),
          const Spacer(),
          _skeletonBox(width: 56, height: 14, radius: 6),
        ],
      ),
    );
  }

  // Skeleton for a task card
  Widget _skeletonTaskCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonBox(width: 44, height: 44, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBox(height: 15, radius: 7),
                const SizedBox(height: 8),
                _skeletonBox(width: 180, height: 12, radius: 6),
                const SizedBox(height: 8),
                _skeletonBox(width: 100, height: 10, radius: 5),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.5));
  }

  Widget _buildSkeletonBody() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Stat cards grid skeleton
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: List.generate(4, (_) => _skeletonStatCard()),
          ),
          const SizedBox(height: 32),

          // Section 1: Incoming Directives
          _skeletonSectionHeader(),
          _skeletonTaskCard(),
          _skeletonTaskCard(),
          const SizedBox(height: 32),

          // Section 2: Escalated Tasks
          _skeletonSectionHeader(),
          _skeletonTaskCard(),
          _skeletonTaskCard(),
          const SizedBox(height: 32),

          // Section 3: Today's Schedule
          _skeletonSectionHeader(),
          _skeletonTaskCard(),
          _skeletonTaskCard(),
          const SizedBox(height: 32),

          // Section 4: Pending Proofs
          _skeletonSectionHeader(),
          _skeletonTaskCard(),
          _skeletonTaskCard(),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ─── Real content ─────────────────────────────────────────────────────────

  Widget _buildContent({
    required List<dynamic> pending,
    required List<dynamic> allTasks,
    required List<dynamic> pendingPreview,
    required List<dynamic> escalationsPreview,
    required List<dynamic> schedulePreview,
    required List<dynamic> proofsPreview,
    required daily,
  }) {
    return SliverPadding(
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
                value: (daily?.totalTasksAssignedToday ?? 0).toString(),
                icon: Icons.assignment_rounded,
                color: AppTheme.success,
              ),
              StatCard(
                label: "Mentees",
                value: (daily?.menteeStudentsCount ?? 0).toString(),
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

          // ─── Incoming Directives ─────────────────────────────────────────
          SectionHeader(
            title: "Incoming Directives",
            isStatus: true,
            count: pending.length,
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DirectivesViewAllPage(
                  directives: pending,
                  isBlocked: widget.isBlocked,
                  userRole: _userRole ?? 'faculty',
                  transferableRoles: _getTransferableRoles(),
                  onRefresh: _refreshAll,
                ),
              ),
            ),
          ),

          if (pendingPreview.isEmpty)
            _emptyHint("No pending directives")
          else
            ...pendingPreview.asMap().entries.map((entry) {
              final idx = entry.key;
              final data = entry.value;
              final heroTag = "directive_${data['task_id']}_$idx";
              return TaskCard(
                title: data['title'] ?? 'Task',
                sub: data['description'] ?? 'No description',
                accent: AppTheme.brandAccent,
                icon: Icons.assignment_turned_in_rounded,
                heroTag: heroTag,
                isRequest: true,
                onAccept: () {
                  if (widget.isBlocked) { _blockedSnack(); return; }
                  _acceptTask(idx);
                },
                onReject: () {
                  if (widget.isBlocked) { _blockedSnack(); return; }
                  _showRejectDialog(idx);
                },
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TaskDetailsPage(taskData: {
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
                  }),
                )),
              );
            }),

          if (pending.length > 2) _viewMoreHint(
            "${pending.length - 2} more directives",
            AppTheme.brandAccent,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DirectivesViewAllPage(
                directives: pending, isBlocked: widget.isBlocked,
                userRole: _userRole ?? 'faculty',
                transferableRoles: _getTransferableRoles(),
                onRefresh: _refreshAll,
              ),
            )),
          ),
          const SizedBox(height: 32),

          // ─── Escalated Tasks ─────────────────────────────────────────────
          SectionHeader(
            title: "Escalated Tasks",
            isStatus: true,
            count: _escalations.length,
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EscalationsViewAllPage(escalations: _escalations),
              ),
            ),
          ),

          if (escalationsPreview.isEmpty)
            _emptyHint("No escalated tasks")
          else
            ...escalationsPreview.map((escalation) {
              final heroTag = "escalation_${escalation['task_id']}_pending";
              return TaskCard(
                title: escalation['title'] ?? "Escalated Task",
                sub: escalation['escalated_reason'] ?? escalation['description'] ?? "High Priority",
                accent: AppTheme.danger,
                icon: Icons.priority_high_rounded,
                heroTag: heroTag,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TaskDetailsPage(taskData: {
                    'task_id': escalation['task_id'],
                    'title': escalation['title'],
                    'sub': escalation['description'],
                    'accent': AppTheme.danger,
                    'icon': Icons.priority_high_rounded,
                    'heroTag': heroTag,
                    'startDate': escalation['start_date'] ?? "N/A",
                    'deadline': escalation['end_date'] ?? "N/A",
                    'completionType': escalation['type'] ?? "INFO",
                    'isRequest': false,
                    'authority': "Administration",
                    'userRole': 'Faculty',
                  }),
                )),
              );
            }),

          if (_escalations.length > 2) _viewMoreHint(
            "${_escalations.length - 2} more escalations",
            AppTheme.danger,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => EscalationsViewAllPage(escalations: _escalations),
            )),
          ),
          const SizedBox(height: 32),

          // ─── Today's Schedule ────────────────────────────────────────────
          SectionHeader(
            title: "Today's Schedule",
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScheduleViewAllPage(tasks: allTasks),
              ),
            ),
          ),

          if (schedulePreview.isEmpty)
            _emptyHint("No tasks scheduled for today")
          else
            ...schedulePreview.map((item) {
              final heroTag = "task_${item['task_id']}_today";
              return TaskCard(
                title: item['title'] ?? 'Task',
                sub: item['status'] ?? 'Scheduled',
                accent: AppTheme.success,
                icon: Icons.calendar_today_rounded,
                heroTag: heroTag,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TaskDetailsPage(taskData: {
                    'task_id': item['task_id'],
                    'title': item['title'],
                    'sub': item['status'],
                    'accent': AppTheme.success,
                    'icon': Icons.calendar_today_rounded,
                    'heroTag': heroTag,
                    'startDate': item['start_date'] ?? "N/A",
                    'deadline': item['end_date'] ?? "N/A",
                    'completionType': "INFO",
                    'isRequest': false,
                    'userRole': 'Faculty',
                  }),
                )),
              );
            }),

          if (allTasks.length > 2) _viewMoreHint(
            "${allTasks.length - 2} more tasks",
            AppTheme.success,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ScheduleViewAllPage(tasks: allTasks),
            )),
          ),
          const SizedBox(height: 32),

          // ─── Pending Proofs ──────────────────────────────────────────────
          SectionHeader(
            title: "Pending Proofs",
            isStatus: true,
            count: _pendingProofs.length,
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PendingProofsViewAllPage(proofs: _pendingProofs),
              ),
            ),
          ),

          if (proofsPreview.isEmpty)
            _emptyHint("No pending proofs to review")
          else
            ...proofsPreview.map((proof) {
              final heroTag = "proof_${proof['task_id']}_pending";
              final deadline = proof['deadline'];
              final deadlineStr = deadline != null
                  ? "${deadline['end_date'] ?? 'N/A'} ${deadline['end_time'] ?? ''}"
                  : "N/A";
              return TaskCard(
                title: proof['title'] ?? 'Proof Task',
                sub: proof['description'] ?? 'Proof Status: ${proof['proof_status'] ?? 'Pending'}',
                accent: Colors.orange,
                icon: Icons.photo_camera_rounded,
                heroTag: heroTag,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TaskDetailsPage(taskData: {
                    'task_id': proof['task_id'],
                    'assignment_id': proof['assignment_id'],
                    'title': proof['title'],
                    'sub': proof['description'] ?? 'Awaiting proof verification',
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
                  }),
                )),
              );
            }),

          if (_pendingProofs.length > 2) _viewMoreHint(
            "${_pendingProofs.length - 2} more proofs",
            Colors.orange,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PendingProofsViewAllPage(proofs: _pendingProofs),
            )),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ─── Small helper widgets ─────────────────────────────────────────────────

  void _blockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Please acknowledge your schedule first."),
      backgroundColor: AppTheme.warning,
    ));
  }

  Widget _emptyHint(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          text,
          style: const TextStyle(color: AppTheme.textSub, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _viewMoreHint(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8, left: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          "+$label — View All",
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final info = _stats?.facultyInfo;
    final daily = _stats?.dailyStats;
    final pending = _stats?.pendingTasks ?? [];
    final allTasks = _stats?.allTasksToday ?? [];

    final pendingPreview = pending.take(2).toList();
    final escalationsPreview = _escalations.take(2).toList();
    final schedulePreview = allTasks.take(2).toList();
    final proofsPreview = _pendingProofs.take(2).toList();

    final formattedDate = DateFormat('EEEE, MMM dd').format(DateTime.now());

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

                  // Blocked banner
                  if (widget.isBlocked)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
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

                  // Body: skeleton OR real content
                  if (_isLoading)
                    _buildSkeletonBody()
                  else
                    _buildContent(
                      pending: pending,
                      allTasks: allTasks,
                      pendingPreview: pendingPreview,
                      escalationsPreview: escalationsPreview,
                      schedulePreview: schedulePreview,
                      proofsPreview: proofsPreview,
                      daily: daily,
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
