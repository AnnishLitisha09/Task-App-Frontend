import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/animated_stat_card.dart';
import '../../components/task_card.dart';
import '../../components/section_header.dart';
import '../../components/skeleton_loader.dart';
import '../../components/unified_reject_dialog.dart';
import '../common/task_detail_page.dart';
import '../common/generic_view_all_page.dart';
import '../../models/faculty_dashboard_stats.dart';
import '../common/user_selection_page.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import 'all_directives_page.dart';
import 'all_escalations_page.dart';
import 'all_schedule_page.dart';
import 'all_proofs_page.dart';
import 'task_verification_page.dart';
import 'verify_users_proof_page.dart';
import '../common/score_performance_page.dart';


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

class _FacultyPageState extends State<FacultyPage>
    with SingleTickerProviderStateMixin {
  FacultyDashboardStats? _stats;
  List<dynamic> _pendingProofs = [];
  List<dynamic> _pendingVerifications = [];
  List<dynamic> _escalations = [];
  List<dynamic> _authorityApprovals = [];
  String? _userRole;
  List<String> _allRoles = [];
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
      _fetchPendingVerifications(),
      _fetchEscalations(),
      _fetchAuthorityApprovals(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? allRolesJson = prefs.getString('allRoles');
      if (allRolesJson != null) {
        _allRoles = List<String>.from(jsonDecode(allRolesJson));
      }
      
      final profile = await UserService().getUserProfile();
      if (mounted) setState(() => _userRole = profile.role);
    } catch (_) {}
  }

  Future<void> _fetchAuthorityApprovals() async {
    try {
      // Check if user has an authority role
      final authorityRoles = ['hod', 'dean', 'principal'];
      bool isAuthority = _allRoles.any((r) => authorityRoles.contains(r.toLowerCase())) ||
                        (_userRole != null && authorityRoles.contains(_userRole!.toLowerCase()));

      if (!isAuthority) {
        if (mounted) setState(() => _authorityApprovals = []);
        return;
      }

      final userService = UserService();
      final dashboard = await userService.getDepartmentalDashboard();
      if (mounted) {
        setState(() {
          _authorityApprovals = dashboard.pendingApprovals;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _authorityApprovals = []);
    }
  }

  Future<void> _fetchAuthorityApprovals() async {
    try {
      // Check if user has an authority role
      final authorityRoles = ['hod', 'dean', 'principal'];
      bool isAuthority = _allRoles.any((r) => authorityRoles.contains(r.toLowerCase())) ||
                        (_userRole != null && authorityRoles.contains(_userRole!.toLowerCase()));

      if (!isAuthority) {
        if (mounted) setState(() => _authorityApprovals = []);
        return;
      }

      final userService = UserService();
      final dashboard = await userService.getDepartmentalDashboard();
      if (mounted) {
        setState(() {
          _authorityApprovals = dashboard.pendingApprovals;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _authorityApprovals = []);
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

            // Sync other lists if they are present in the response
            if (_stats != null) {
              _pendingProofs = _stats!.pendingProofs;
              _escalations = _stats!.escalatedTasks;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching faculty stats: $e");
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchPendingProofs() async {
    try {
      final TaskService taskService = TaskService();
      final dynamic response = await taskService.getPendingProofs();
      if (mounted) {
        setState(() {
          if (response is Map) {
            if (response.containsKey('items')) {
              _pendingProofs = response['items'] as List;
            } else if (response.containsKey('tasks')) {
              _pendingProofs = response['tasks'] as List;
            } else {
              _pendingProofs = [];
            }
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

  Future<void> _fetchPendingVerifications() async {
    try {
      final TaskService taskService = TaskService();
      final dynamic response = await taskService.getPendingVerifications();
      if (mounted) {
        setState(() {
          if (response is List) {
            _pendingVerifications = response;
          } else {
            _pendingVerifications = [];
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _pendingVerifications = []);
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

  // ─── Handlers ─────────────────────────────────────────────────────────────

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
    const hierarchy = [
      'admin', 'principal', 'dean', 'hod', 'faculty', 'student', 'staff'
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
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => UserSelectionPage(
          multiSelect: false, allowedRoles: _getTransferableRoles(),
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

  // ─── Micro helpers ────────────────────────────────────────────────────────
  void _loadingDialog() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );

  void _blockedSnack() => _snack(
      "Please acknowledge your schedule first.", AppTheme.warning);

  // ─── Skeleton ─────────────────────────────────────────────────────────────

  Widget _shimmerBox({
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
          duration: 1400.ms,
          color: Colors.white.withOpacity(0.7),
          angle: 45,
        );
  }

  Widget _skeletonStatCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(28),
        border:
            Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _shimmerBox(width: 40, height: 40, radius: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(width: 52, height: 24, radius: 8),
              const SizedBox(height: 5),
              _shimmerBox(width: 72, height: 11, radius: 6),
            ],
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: Colors.white.withOpacity(0.5));
  }

  Widget _skeletonSectionHeader() => Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 4),
        child: Row(
          children: [
            _shimmerBox(width: 150, height: 18, radius: 8),
            const SizedBox(width: 8),
            _shimmerBox(width: 26, height: 18, radius: 6),
            const Spacer(),
            _shimmerBox(width: 58, height: 13, radius: 6),
          ],
        ),
      );

  Widget _skeletonTaskCard() => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBox(width: 46, height: 46, radius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(height: 15, radius: 7),
                  const SizedBox(height: 9),
                  _shimmerBox(width: 200, height: 12, radius: 6),
                  const SizedBox(height: 7),
                  _shimmerBox(width: 110, height: 10, radius: 5),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1400.ms, color: Colors.white.withOpacity(0.5));

  Widget _buildSkeletonBody() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Stat cards grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25,
            children: List.generate(4, (i) => _skeletonStatCard()
                .animate()
                .fadeIn(delay: (i * 80).ms)
                .slideY(begin: 0.15)),
          ),
          const SizedBox(height: 32),
          // 4 sections × (header + 2 cards)
          for (int s = 0; s < 4; s++) ...[
            _skeletonSectionHeader()
                .animate()
                .fadeIn(delay: (200 + s * 60).ms),
            _skeletonTaskCard()
                .animate()
                .fadeIn(delay: (260 + s * 60).ms)
                .slideX(begin: 0.05),
            _skeletonTaskCard()
                .animate()
                .fadeIn(delay: (320 + s * 60).ms)
                .slideX(begin: 0.05),
            const SizedBox(height: 32),
          ],
        ]),
      ),
    );
  }

  // ─── Real content ─────────────────────────────────────────────────────────

  Widget _sectionDivider() => Container(
        margin: const EdgeInsets.only(bottom: 28),
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppTheme.brandAccent.withOpacity(0.0),
            AppTheme.brandAccent.withOpacity(0.12),
            AppTheme.brandAccent.withOpacity(0.0),
          ]),
        ),
      );

  Widget _emptyHint(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppTheme.textSub.withOpacity(0.4), size: 16),
              const SizedBox(width: 6),
              Text(text,
                  style: const TextStyle(
                      color: AppTheme.textSub,
                      fontStyle: FontStyle.italic,
                      fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _viewMoreHint(String label, Color color, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8, left: 4),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.expand_more_rounded, color: color, size: 15),
                    const SizedBox(width: 4),
                    Text("+$label — View All",
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildAnimatedContent({
    required List<dynamic> pending,
    required List<dynamic> allTasks,
    required List<dynamic> pendingPreview,
    required List<dynamic> escalationsPreview,
    required List<dynamic> schedulePreview,
    required List<dynamic> proofsPreview,
    required dynamic daily,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // ── Stat cards ───────────────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25,
            children: [
              AnimatedStatCard(
                label: "Pending",
                value: (daily?.pendingTasksCount ?? 0).toString(),
                icon: Icons.move_to_inbox_rounded,
                color: AppTheme.brandAccent,
                delay: 0,
              )
                  .animate()
                  .fadeIn(delay: 0.ms, duration: 400.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOutCubic),
              AnimatedStatCard(
                label: "Tasks Today",
                value: (daily?.totalTasksAssignedToday ?? 0).toString(),
                icon: Icons.assignment_rounded,
                color: AppTheme.success,
                delay: 80,
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 400.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOutCubic),
              AnimatedStatCard(
                label: "Mentees",
                value: (daily?.menteeStudentsCount ?? 0).toString(),
                icon: Icons.people_alt_rounded,
                color: AppTheme.warning,
                delay: 160,
              )
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 400.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOutCubic),
              AnimatedStatCard(
                label: "Hours",
                value: "0",
                icon: Icons.access_time_filled_rounded,
                color: Colors.teal,
                delay: 240,
              )
                  .animate()
                  .fadeIn(delay: 240.ms, duration: 400.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOutCubic),
            ],
          ),
          const SizedBox(height: 36),

          // ── Incoming Directives ──────────────────────────────────────────
          SectionHeader(
            title: "Incoming Directives",
            isStatus: true,
            count: pending.length,
            onViewAll: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DirectivesViewAllPage(
                directives: pending, isBlocked: widget.isBlocked,
                userRole: _userRole ?? 'faculty',
                transferableRoles: _getTransferableRoles(),
                onRefresh: _refreshAll,
              ),
            )),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.04),

          if (pendingPreview.isEmpty)
            _emptyHint("No pending directives")
                .animate().fadeIn(delay: 340.ms)
          else
            ...pendingPreview.asMap().entries.map((e) {
              final idx = e.key;
              final data = e.value;
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
                    'task_id': data['task_id'], 'title': data['title'],
                    'sub': data['description'], 'accent': AppTheme.brandAccent,
                    'icon': Icons.assignment_turned_in_rounded, 'heroTag': heroTag,
                    'startDate': data['start_date'] ?? "N/A",
                    'deadline': data['end_date'] ?? "N/A",
                    'completionType': data['type'] ?? "APPROVAL",
                    'isRequest': true, 'authority': "Administration", 'userRole': 'Faculty',
                  }),
                )),
              )
                  .animate()
                  .fadeIn(delay: (340 + idx * 70).ms, duration: 400.ms)
                  .slideX(begin: 0.06, curve: Curves.easeOutCubic);
            }),

          if (pending.length > 2)
            _viewMoreHint("${pending.length - 2} more directives",
                AppTheme.brandAccent, () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DirectivesViewAllPage(
                directives: pending, isBlocked: widget.isBlocked,
                userRole: _userRole ?? 'faculty',
                transferableRoles: _getTransferableRoles(),
                onRefresh: _refreshAll,
              ),
            ))).animate().fadeIn(delay: 480.ms),

          _sectionDivider(),

          // ── Escalated Tasks ──────────────────────────────────────────────
          SectionHeader(
            title: "Escalated Tasks",
            isStatus: true,
            count: _escalations.length,
            onViewAll: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => EscalationsViewAllPage(escalations: _escalations),
            )),
          ).animate().fadeIn(delay: 360.ms).slideX(begin: -0.04),

          if (escalationsPreview.isEmpty)
            _emptyHint("No escalated tasks")
                .animate().fadeIn(delay: 400.ms)
          else
            ...escalationsPreview.asMap().entries.map((e) {
              final idx = e.key;
              final esc = e.value;
              final heroTag = "escalation_${esc['task_id']}_$idx";
              return TaskCard(
                title: esc['title'] ?? "Escalated Task",
                sub: esc['escalated_reason'] ?? esc['description'] ?? "High Priority",
                accent: AppTheme.danger,
                icon: Icons.priority_high_rounded,
                heroTag: heroTag,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TaskDetailsPage(taskData: {
                    'task_id': esc['task_id'], 'title': esc['title'],
                    'sub': esc['description'], 'accent': AppTheme.danger,
                    'icon': Icons.priority_high_rounded, 'heroTag': heroTag,
                    'startDate': esc['start_date'] ?? "N/A",
                    'deadline': esc['end_date'] ?? "N/A",
                    'completionType': esc['type'] ?? "INFO",
                    'isRequest': false, 'authority': "Administration", 'userRole': 'Faculty',
                  }),
                )),
              )
                  .animate()
                  .fadeIn(delay: (400 + idx * 70).ms, duration: 400.ms)
                  .slideX(begin: 0.06, curve: Curves.easeOutCubic);
            }),

          if (_escalations.length > 2)
            _viewMoreHint("${_escalations.length - 2} more escalations",
                AppTheme.danger, () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => EscalationsViewAllPage(escalations: _escalations),
            ))).animate().fadeIn(delay: 540.ms),

          _sectionDivider(),

          // ── Today's Schedule ─────────────────────────────────────────────
          SectionHeader(
            title: "Today's Schedule",
            onViewAll: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ScheduleViewAllPage(tasks: allTasks),
            )),
          ).animate().fadeIn(delay: 420.ms).slideX(begin: -0.04),

          if (schedulePreview.isEmpty)
            _emptyHint("No tasks scheduled for today")
                .animate().fadeIn(delay: 460.ms)
          else
            ...schedulePreview.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              final heroTag = "task_${item['task_id']}_today";
              return TaskCard(
                title: item['title'] ?? 'Task',
                sub: item['status'] ?? 'Scheduled',
                accent: AppTheme.success,
                icon: Icons.calendar_today_rounded,
                heroTag: heroTag,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TaskDetailsPage(taskData: {
                    'task_id': item['task_id'], 'title': item['title'],
                    'sub': item['status'], 'accent': AppTheme.success,
                    'icon': Icons.calendar_today_rounded, 'heroTag': heroTag,
                    'startDate': item['start_date'] ?? "N/A",
                    'deadline': item['end_date'] ?? "N/A",
                    'completionType': "INFO", 'isRequest': false, 'userRole': 'Faculty',
                  }),
                )),
              )
                  .animate()
                  .fadeIn(delay: (460 + idx * 70).ms, duration: 400.ms)
                  .slideX(begin: 0.06, curve: Curves.easeOutCubic);
            }),

          if (allTasks.length > 2)
            _viewMoreHint("${allTasks.length - 2} more tasks",
                AppTheme.success, () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ScheduleViewAllPage(tasks: allTasks),
            ))).animate().fadeIn(delay: 600.ms),

          _sectionDivider(),

          // ── Pending Proofs ───────────────────────────────────────────────
          SectionHeader(
            title: "Pending Proofs",
            isStatus: true,
            count: _pendingProofs.length,
            onViewAll: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PendingProofsViewAllPage(proofs: _pendingProofs),
            )),
          ).animate().fadeIn(delay: 480.ms).slideX(begin: -0.04),

          if (proofsPreview.isEmpty)
            _emptyHint("No pending proofs to review")
                .animate().fadeIn(delay: 520.ms)
          else
            ...proofsPreview.asMap().entries.map((e) {
              final idx = e.key;
              final proof = e.value;
              final heroTag = "proof_${proof['task_id']}_pending";
              final dl = proof['deadline'];
              final dlStr = dl != null
                  ? "${dl['end_date'] ?? 'N/A'} ${dl['end_time'] ?? ''}"
                  : "N/A";
              return TaskCard(
                title: proof['title'] ?? 'Proof Task',
                sub: proof['description'] ??
                    'Proof Status: ${proof['proof_status'] ?? 'Pending'}',
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
                    'icon': Icons.photo_camera_rounded, 'heroTag': heroTag,
                    'deadline': dlStr, 'completionType': "PROOF_REVIEW",
                    'isRequest': false, 'userRole': 'Faculty',
                    'is_document': proof['is_document'],
                    'status': proof['status'], 'proof_status': proof['proof_status'],
                  }),
                )),
              )
                  .animate()
                  .fadeIn(delay: (520 + idx * 70).ms, duration: 400.ms)
                  .slideX(begin: 0.06, curve: Curves.easeOutCubic);
            }),

          if (_pendingProofs.length > 2)
            _viewMoreHint("${_pendingProofs.length - 2} more proofs",
                Colors.orange, () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PendingProofsViewAllPage(proofs: _pendingProofs),
            ))).animate().fadeIn(delay: 660.ms),

          const SizedBox(height: 32),
        ]),
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
          // Decorative background circles
          Positioned(
            top: -120,
            right: -60,
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
          Positioned(
            top: 60,
            right: -100,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: AppTheme.success.withOpacity(0.04),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshAll,
              color: AppTheme.brandAccent,
              strokeWidth: 2.5,
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
                                      value:
                                          (_stats?.facultyInfo.menteeCount ?? 0)
                                              .toString(),
                                      icon: Icons.people_alt_rounded,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ScorePerformancePage(),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: StatCard(
                                        label: "Penalty",
                                        value:
                                            "₹${_stats?.facultyInfo.penalty ?? '0.00'}",
                                        icon: Icons.money_off_csred_rounded,
                                        color: AppTheme.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // 1. Today's Schedule
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
                              final timing =
                                  item['timing'] as Map<String, dynamic>? ??
                                  (item['task_type'] is Map
                                      ? item['task_type']
                                            as Map<String, dynamic>
                                      : {});
                              final String dateStr = timing['start_date'] ?? "";
                              final String startTime =
                                  timing['start_time'] ?? "";
                              final String endTime = timing['end_time'] ?? "";

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
                                            timing['start_date'] ?? "N/A",
                                        'deadline': timing['end_date'] ?? "N/A",
                                        'completionType': "INFO",
                                        "isRequest": false,
                                        'userRole': 'Faculty',
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }),

                          const SizedBox(height: 32),

                          // 2. Pending Approval (Incoming Directives)
                          SectionHeader(
                            title: "New Task Requests",
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

                              final timing =
                                  data['timing'] as Map<String, dynamic>? ??
                                  (data['task_type'] is Map
                                      ? data['task_type']
                                            as Map<String, dynamic>
                                      : {});
                              final String dateStr = timing['start_date'] ?? "";
                              final String startTime =
                                  timing['start_time'] ?? "";
                              final String endTime = timing['end_time'] ?? "";
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
                                            timing['start_date'] ?? "N/A",
                                        'deadline': timing['end_date'] ?? "N/A",
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
                            }),

                          const SizedBox(height: 32),

                          // 3. Authority Approval (HOD level)
                          if (_authorityApprovals.isNotEmpty) ...[
                            SectionHeader(
                              title: "Authority Approvals",
                              isStatus: true,
                              count: _authorityApprovals.length,
                              onViewAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GenericViewAllPage(
                                    title: "Authority Approvals",
                                    tasks: _authorityApprovals,
                                    viewMode: 'approver',
                                    accentColor: AppTheme.warning,
                                    onTaskAction: (taskId, approve) async {
                                      try {
                                        if (approve) {
                                          await TaskService().acceptTask(taskId);
                                        } else {
                                          await TaskService().rejectTask(taskId, "Rejected by Authority");
                                        }
                                        _refreshAll();
                                      } catch (e) {
                                        debugPrint("Error in authority action: $e");
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            ..._authorityApprovals.take(2).map<Widget>((task) {
                              return TaskCard(
                                title: task['title']?.toString() ?? "Approval Request",
                                sub: "Requested by: ${task['requested_by'] ?? 'N/A'}",
                                accent: AppTheme.warning,
                                icon: Icons.how_to_reg_rounded,
                                isApproval: true,
                                onAccept: () async {
                                  await TaskService().acceptTask(task['task_id']);
                                  _refreshAll();
                                },
                                onReject: () async {
                                  await TaskService().rejectTask(task['task_id'], "Rejected by Authority");
                                  _refreshAll();
                                },
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TaskDetailsPage(
                                      taskData: {'task_id': task['task_id'], 'title': task['title']},
                                      viewMode: 'approver',
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 32),
                          ],

                          // 4. Escalated Tasks
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
                            }),

                          const SizedBox(height: 32),

                          // 4.5 Task Verification
                          if (_pendingVerifications.isNotEmpty) ...[
                            SectionHeader(
                              title: "Task Verification",
                              count: _pendingVerifications.length,
                              onViewAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TaskVerificationPage(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._pendingVerifications.take(2).map((verify) {
                              final heroTag = "verify_${verify['assignment_id']}_dash";
                              return TaskCard(
                                title: verify['title'] ?? 'Task Review',
                                sub: 'By: ${verify['assignee_name']} (${verify['assignee_role']})',
                                accent: AppTheme.brandAccent,
                                icon: Icons.fact_check_rounded,
                                heroTag: heroTag,
                                onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VerifyUsersProofPage(
                                          taskId: verify['task_id'],
                                          taskTitle: verify['title'] ?? 'Task Review',
                                        ),
                                      ),
                                    );
                                  if (result == 'refreshed') _refreshAll();
                                },
                              );
                            }),
                            const SizedBox(height: 32),
                          ],

                          // 5. Pending Proofs
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
                              final timing =
                                  proof['timing'] ?? proof['deadline'];
                              final String deadlineStr = timing != null
                                  ? "${timing['end_date'] ?? 'N/A'} ${timing['end_time'] ?? ''}"
                                  : "N/A";

                              return TaskCard(
                                key: ValueKey(heroTag),
                                title: proof['title'] ?? 'Proof Task',
                                sub: proof['description'] ??
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
                                        'sub': proof['description'] ??
                                            'Awaiting proof verification',
                                        'accent': Colors.orange,
                                        'icon': Icons.photo_camera_rounded,
                                        'heroTag': heroTag,
                                        'deadline': deadlineStr,
                                        'completionType': "PROOF_REVIEW",
                                        'isPendingProof': true,
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
          Icon(Icons.lock_person_rounded, size: 64, color: AppTheme.danger.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            "Access Restricted",
            style: AppTheme.h2.copyWith(color: AppTheme.danger),
          ),
          const SizedBox(height: 12),
          Text(
            "Your account is restricted because today's tasks haven't been acknowledged. Please contact an administrator to acknowledge your schedule.",
            textAlign: TextAlign.center,
            style: AppTheme.bodyMain.copyWith(color: AppTheme.textSub),
          ),
          const SizedBox(height: 8),
          Text(
            "Once an admin acknowledges your schedule, you can refresh to gain access.",
            textAlign: TextAlign.center,
            style: AppTheme.bodySub.copyWith(color: AppTheme.textSub.withOpacity(0.7)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
