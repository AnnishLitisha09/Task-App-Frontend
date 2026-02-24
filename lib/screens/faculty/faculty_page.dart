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

class _FacultyPageState extends State<FacultyPage>
    with SingleTickerProviderStateMixin {
  FacultyDashboardStats? _stats;
  List<dynamic> _pendingProofs = [];
  List<dynamic> _escalations = [];
  String? _userRole;
  bool _isLoading = true;

  // Controls entry animation replay on data-load
  bool _contentVisible = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _contentVisible = false;
      });
    }
    await Future.wait([
      _fetchUserRole(),
      _fetchStats(),
      _fetchPendingProofs(),
      _fetchEscalations(),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _contentVisible = true;
      });
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final profile = await UserService().getUserProfile();
      if (mounted) setState(() => _userRole = profile.role);
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
          _pendingProofs = (response is Map && response.containsKey('tasks'))
              ? response['tasks'] as List
              : (response is List ? response : []);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _pendingProofs = []);
    }
  }

  Future<void> _fetchEscalations() async {
    try {
      final data = await TaskService().getEscalations();
      if (mounted) setState(() => _escalations = data);
    } catch (_) {
      if (mounted) setState(() => _escalations = []);
    }
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _acceptTask(int index) async {
    if (_stats == null) return;
    final taskId = _stats!.pendingTasks[index]['task_id'];
    if (taskId == null) return;
    _loadingDialog();
    try {
      await TaskService().acceptTask(taskId);
      if (mounted) {
        Navigator.pop(context);
        _snack("Task accepted successfully", AppTheme.success);
        _refreshAll();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _snack("Error accepting task: $e", AppTheme.danger);
      }
    }
  }

  List<String> _getTransferableRoles() {
    const hierarchy = [
      'admin', 'principal', 'dean', 'hod', 'faculty', 'student', 'staff'
    ];
    const keyMap = {
      'hod': 'hods', 'student': 'students', 'faculty': 'faculty',
      'staff': 'staff', 'admin': 'admin', 'principal': 'principal', 'dean': 'dean',
    };
    final idx = hierarchy.indexOf(_userRole?.toLowerCase() ?? '');
    if (idx == -1) return ['students', 'staff'];
    return hierarchy.sublist(0, idx + 1).map((r) => keyMap[r] ?? r).toList();
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
    if (result == null || result.isEmpty || !mounted) return;
    final user = result.first;
    final userId = user['user_id'] ?? user['id'];
    if (userId == null) return;
    _loadingDialog();
    try {
      await TaskService().rejectTask(taskId, "Transferred to ${user['name']}",
          transferToUserId: userId);
      if (mounted) {
        Navigator.pop(context);
        _snack("Task transferred to ${user['name']}", AppTheme.success);
        _refreshAll();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _snack("Error transferring task: $e", AppTheme.danger);
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
      onReject: (reason, _) async {
        _loadingDialog();
        try {
          await TaskService().rejectTask(taskId, reason);
          if (mounted) {
            Navigator.pop(context);
            _snack("Task rejected: $reason", AppTheme.success);
            _refreshAll();
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            _snack("Error rejecting task: $e", AppTheme.danger);
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
              radius: 170,
              backgroundColor: AppTheme.brandAccent.withOpacity(0.05),
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
                        ? 'https://i.pravatar.cc/150?u=faculty${info.id}'
                        : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                  ),

                  // Blocked banner
                  if (widget.isBlocked)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.danger.withOpacity(0.25)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppTheme.danger,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Action Required: Acknowledge today's schedule to proceed.",
                                    style: AppTheme.bodyMain.copyWith(
                                        color: AppTheme.danger, fontSize: 13),
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
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.05),
                    ),

                  // Body: skeleton OR animated content
                  if (_isLoading)
                    _buildSkeletonBody()
                  else
                    _buildAnimatedContent(
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
