import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/task_card.dart';
import '../../components/section_header.dart';
import '../../components/skeleton_loader.dart';
import '../../components/unified_reject_dialog.dart';
import '../common/task_detail_page.dart';
import '../../models/faculty_info.dart';
import '../common/user_selection_page.dart';
import '../../services/task_service.dart';
import 'all_directives_page.dart';
import 'all_escalations_page.dart';
import 'all_schedule_page.dart';
import 'all_proofs_page.dart';
import 'task_verification_page.dart';
import 'verify_users_proof_page.dart';
import '../common/score_performance_page.dart';
import '../common/generic_view_all_page.dart';
import '../../components/stat_card.dart';
import '../../store/app_store.dart';

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
  // Store is the single source of truth — no local duplicates.
  // We only keep UI-only state here (accept optimistic update index).

  @override
  void initState() {
    super.initState();
    // Schedule lazy background fetches AFTER the first frame so the page
    // renders immediately with whatever is already cached.
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  AppStore get _store => context.read<AppStore>();

  /// Lazy hydration — only fetches sections that aren't already fresh.
  Future<void> _hydrate() async {
    await _store.ensureUserRole();
    await Future.wait([
      _store.fetchFacultyStats(),
      _store.fetchPendingProofs(),
      _store.fetchPendingVerifications(),
      _store.fetchAuthorityApprovals(),
      _store.fetchUnreadNotifications(),
    ]);
  }

  /// Pull-to-refresh: force-reload all faculty sections in parallel.
  Future<void> _refreshAll() async {
    await _store.ensureUserRole(force: true);
    await Future.wait([
      _store.fetchFacultyStats(force: true),
      _store.fetchPendingProofs(force: true),
      _store.fetchPendingVerifications(force: true),
      _store.fetchAuthorityApprovals(force: true),
      _store.fetchUnreadNotifications(),
    ]);
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _acceptTask(int index) async {
    final store = _store;
    final stats = store.facultyStats;
    if (stats == null) return;
    final task = stats.pendingTasks[index];
    final taskId = task['task_id'];
    if (taskId == null) return;

    // Optimistic update on the store's list directly
    stats.pendingTasks.removeAt(index);
    stats.allTasksToday.insert(0, task);
    stats.dailyStats.totalTasksAssignedToday = stats.allTasksToday.length;
    stats.dailyStats.pendingTasksCount = stats.pendingTasks.length;
    store.triggerUpdate(); // AppStore exposes this public wrapper

    try {
      await TaskService().acceptTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task accepted successfully"),
            backgroundColor: AppTheme.success,
          ),
        );
        // Only re-fetch the stats section, not the whole page
        await store.fetchFacultyStats(force: true);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error accepting task: $errorMsg"),
            backgroundColor: AppTheme.danger,
          ),
        );
        await store.fetchFacultyStats(force: true); // Revert/Sync
      }
    }
  }

  List<String> _getTransferableRoles() {
    final role = context.read<AppStore>().userRole?.toLowerCase() ?? '';
    const hierarchy = [
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
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => UserSelectionPage(
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
        builder: (context) => const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
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
          final errorMsg = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error transferring task: $errorMsg"),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }

  void _showRejectDialog(int index) {
    final stats = context.read<AppStore>().facultyStats;
    if (stats == null) return;
    final task = stats.pendingTasks[index];
    final taskId = task['task_id'];
    final taskTitle = task['title'] ?? 'Task';
    if (taskId == null) return;
    UnifiedRejectDialog.show(
      context,
      taskTitle: taskTitle,
      onTransfer: () => _handleTransfer(taskId, taskTitle),
      onReject: (reason, details) async {
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
            final errorMsg = e.toString().replaceAll('Exception: ', '');
            _snack("Error rejecting task: $errorMsg", AppTheme.danger);
          }
        }
      },
    );
  }

  // ─── Micro helpers ────────────────────────────────────────────────────────
  void _loadingDialog() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
  );

  void _snack(String msg, Color color) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  void _blockedSnack() =>
      _snack("Please acknowledge your schedule first.", AppTheme.warning);

  // ─── Real content ─────────────────────────────────────────────────────────

  Widget _sectionDivider() => Container(
    margin: const EdgeInsets.only(bottom: 28),
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppTheme.brandAccent.withValues(alpha: 0.0),
          AppTheme.brandAccent.withValues(alpha: 0.12),
          AppTheme.brandAccent.withValues(alpha: 0.0),
        ],
      ),
    ),
  );

  Widget _emptyHint(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.textSub.withValues(alpha: 0.4),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSub,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildAnimatedContent({
    required String? userRole,
    required List<dynamic> pending,
    required List<dynamic> allTasks,
    required List<dynamic> pendingPreview,
    required List<dynamic> escalationsPreview,
    required List<dynamic> schedulePreview,
    required List<dynamic> proofsPreview,
    required List<dynamic> authorityApprovals,
    required List<dynamic> pendingVerifications,
    required dynamic daily,
    required FacultyInfo? info,
    required bool isInitialLoad,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // ── Stat cards ───────────────────────────────────────────────────
          isInitialLoad
          ? const SkeletonStatGrid()
          : GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                label: "Total Penalty",
                value: isInitialLoad ? "..." : "₹${info?.penalty ?? '0.00'}",
                icon: Icons.money_off_csred_rounded,
                color: AppTheme.danger,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScorePerformancePage(),
                  ),
                ).then((result) { if (mounted && result == true) _refreshAll(); }),
              ),
              StatCard(
                label: "Pending",
                value: isInitialLoad
                    ? "..."
                    : (daily?.pendingTasksCount ?? 0).toString().padLeft(
                        2,
                        '0',
                      ),
                icon: Icons.schedule_rounded,
                color: AppTheme.warning,
              ),
              StatCard(
                label: "Mentees",
                value: isInitialLoad
                    ? "..."
                    : (info?.menteeCount ?? 0).toString().padLeft(2, '0'),
                icon: Icons.people_alt_rounded,
                color: AppTheme.brandAccent,
              ),
              StatCard(
                label: "Tasks Today",
                value: isInitialLoad
                    ? "..."
                    : (daily?.totalTasksAssignedToday ?? 0).toString().padLeft(
                        2,
                        '0',
                      ),
                icon: Icons.assignment_rounded,
                color: AppTheme.success,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 36),

          // ── Today's Schedule ─────────────────────────────────────────────
          SectionHeader(
            title: "Today's Schedule",
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AllSchedulePage(userRole: userRole ?? 'faculty'),
              ),
            ).then((result) { if (mounted && result == true) _refreshAll(); }),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.04),

          if (isInitialLoad)
            const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()])
          else if (schedulePreview.isEmpty)
            _emptyHint(
              "No tasks scheduled for today",
            ).animate().fadeIn(delay: 340.ms)
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
                    actionButton: item['action_button'],
                    recurrence: item['time']?['recurrence'] ?? item['recurrence'],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
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
                            'userRole': userRole ?? 'Faculty',
                          },
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refreshAll(); }),
                  )
                  .animate()
                  .fadeIn(delay: (340 + idx * 70).ms, duration: 400.ms)
                  .slideX(begin: 0.06, curve: Curves.easeOutCubic);
            }),

          _sectionDivider(),

          // ── Incoming Directives ──────────────────────────────────────────
          SectionHeader(
            title: "Incoming Directives",
            isStatus: true,
            count: pending.length,
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllDirectivesPage(
                  isBlocked: widget.isBlocked,
                  userRole: userRole ?? 'faculty',
                  onRefreshParent: _refreshAll,
                ),
              ),
            ).then((result) { if (mounted && result == true) _refreshAll(); }),
          ).animate().fadeIn(delay: 360.ms).slideX(begin: -0.04),

          if (isInitialLoad)
            const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()])
          else if (pendingPreview.isEmpty)
            _emptyHint("No pending directives").animate().fadeIn(delay: 400.ms)
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
                    actionButton: data['action_button'],
                    recurrence: data['time']?['recurrence'] ?? data['recurrence'],
                    isRequest: true,
                    onAccept: () {
                      if (widget.isBlocked) {
                        _blockedSnack();
                        return;
                      }
                      _acceptTask(idx);
                    },
                    onReject: () {
                      if (widget.isBlocked) {
                        _blockedSnack();
                        return;
                      }
                      _showRejectDialog(idx);
                    },
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
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
                            'userRole': userRole ?? 'Faculty',
                          },
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refreshAll(); }),
                  )
                  .animate()
                  .fadeIn(delay: (400 + idx * 70).ms, duration: 400.ms)
                  .slideX(begin: 0.06, curve: Curves.easeOutCubic);
            }),

          _sectionDivider(),

          // ── Escalated Tasks ──────────────────────────────────────────────
          SectionHeader(
            title: "Escalated Tasks",
            isStatus: true,
            count: escalationsPreview.length,
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AllEscalationsPage(userRole: userRole ?? 'faculty'),
              ),
            ).then((result) { if (mounted && result == true) _refreshAll(); }),
          ).animate().fadeIn(delay: 420.ms).slideX(begin: -0.04),

          if (isInitialLoad)
            const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()])
          else if (escalationsPreview.isEmpty)
            _emptyHint("No escalated tasks").animate().fadeIn(delay: 460.ms)
          else
            ...escalationsPreview.asMap().entries.map((e) {
              final idx = e.key;
              final esc = e.value;
              final heroTag = "escalation_${esc['task_id']}_$idx";
              return TaskCard(
                    title: esc['title'] ?? "Escalated Task",
                    sub:
                        esc['escalated_reason'] ??
                        esc['description'] ??
                        "High Priority",
                    accent: AppTheme.danger,
                    icon: Icons.priority_high_rounded,
                    heroTag: heroTag,
                    actionButton: esc['action_button'],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': esc['task_id'],
                            'title': esc['title'],
                            'sub': esc['description'],
                            'accent': AppTheme.danger,
                            'icon': Icons.priority_high_rounded,
                            'heroTag': heroTag,
                            'startDate': esc['start_date'] ?? "N/A",
                            'deadline': esc['end_date'] ?? "N/A",
                            'completionType': esc['type'] ?? "INFO",
                            'isRequest': false,
                            'isEscalated': true,
                            'authority': "Administration",
                            'userRole': 'Faculty',
                          },
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refreshAll(); }),
                  )
                  .animate()
                  .fadeIn(delay: (460 + idx * 70).ms, duration: 400.ms)
                  .slideX(begin: 0.06, curve: Curves.easeOutCubic);
            }),

          _sectionDivider(),

          // ── Authority Approvals ───────────────────────────────────────
          if (authorityApprovals.isNotEmpty) ...[
            SectionHeader(
              title: "Authority Approvals",
              isStatus: true,
              count: authorityApprovals.length,
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenericViewAllPage(
                    title: "Authority Approvals",
                    tasks: authorityApprovals,
                    viewMode: 'approver',
                    accentColor: AppTheme.warning,
                    onTaskAction: (taskId, approve) async {
                      try {
                        if (approve) {
                          await TaskService().acceptTask(taskId);
                        } else {
                          await TaskService().rejectTask(
                            taskId,
                            "Rejected by Authority",
                          );
                        }
                        _refreshAll();
                      } catch (e) {
                        debugPrint("Error in authority action: $e");
                      }
                    },
                  ),
                ),
              ).then((result) { if (mounted && result == true) _refreshAll(); }),
            ).animate().fadeIn(delay: 480.ms).slideX(begin: -0.04),
            ...authorityApprovals.take(1).map<Widget>((task) {
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
                  await TaskService().rejectTask(
                    task['task_id'],
                    "Rejected by Authority",
                  );
                  _refreshAll();
                },
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailsPage(
                      taskData: {
                        'task_id': task['task_id'],
                        'title': task['title'],
                      },
                      viewMode: 'approver',
                    ),
                  ),
                ).then((result) { if (mounted && result == true) _refreshAll(); }),
              );
            }),
            _sectionDivider(),
          ],

          // ── Pending Verifications ───────────────────────────────────────
          if (pendingVerifications.isNotEmpty) ...[
            SectionHeader(
              title: "Pending Verifications",
              isStatus: true,
              count: pendingVerifications.length,
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TaskVerificationPage(),
                ),
              ).then((result) { if (mounted && result == true) _refreshAll(); }),
            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.04),
            ...pendingVerifications.take(1).map((verify) {
              final heroTag = "verify_${verify['assignment_id']}_dash";
              return TaskCard(
                title: verify['title'] ?? 'Task Review',
                sub:
                    'By: ${verify['assignee_name']} (${verify['assignee_role']})',
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
                  ).then((result) { if (mounted && result == true) _refreshAll(); });
                  if (result == 'refreshed') _refreshAll();
                },
              );
            }),
            _sectionDivider(),
          ],

          // ── Pending Proofs ───────────────────────────────────────────────
          SectionHeader(
            title: "Pending Proofs",
            isStatus: true,
            count: proofsPreview.length,
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllProofsPage()),
            ).then((result) { if (mounted && result == true) _refreshAll(); }),
          ).animate().fadeIn(delay: 540.ms).slideX(begin: -0.04),

          if (isInitialLoad)
            const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()])
          else if (proofsPreview.isEmpty)
            _emptyHint(
              "No pending proofs to review",
            ).animate().fadeIn(delay: 580.ms)
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
                    sub:
                        proof['description'] ??
                        'Proof Status: ${proof['proof_status'] ?? 'Pending'}',
                    accent: Colors.orange,
                    icon: Icons.photo_camera_rounded,
                    heroTag: heroTag,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
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
                            'deadline': dlStr,
                            'completionType': "PROOF_REVIEW",
                            'isRequest': false,
                            'userRole': 'Faculty',
                            'is_document': proof['is_document'],
                            'status': proof['status'],
                            'proof_status': proof['proof_status'],
                          },
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refreshAll(); }),
                  )
                  .animate()
                  .fadeIn(delay: (580 + idx * 70).ms, duration: 400.ms)
                  .slideX(begin: 0.06, curve: Curves.easeOutCubic);
            }),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        final stats = store.facultyStats;
        final userRole = store.userRole;
        final info = stats?.facultyInfo;
        final daily = stats?.dailyStats;
        final pending = stats?.pendingTasks ?? [];
        final allTasks = stats?.allTasksToday ?? [];

        // Tasks are already securely scoped to the current user by the backend.
        List<dynamic> filteredSchedule = allTasks;

        final pendingPreview = pending.take(2).toList();
        final escalationsPreview = store.escalations.take(2).toList();
        final schedulePreview = filteredSchedule.take(2).toList();
        final proofsPreview = store.pendingProofs.take(2).toList();
        final formattedDate = DateFormat('EEEE, MMM dd').format(DateTime.now());
        final isLoading = store.isLoading('facultyStats');

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
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
                  ).withValues(alpha: 0.05),
                ),
              ),
              Positioned(
                top: 60,
                right: -100,
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: AppTheme.success.withValues(alpha: 0.04),
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
                        notificationCount: store.unreadNotifications,
                        profileImageUrl: info != null
                            ? 'https://ui-avatars.com/api/?name=${info.name.replaceAll(' ', '+')}&background=random'
                            : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                      ),
                      // Show skeleton only on first load with no cache
                      if (widget.isBlocked)
                        SliverToBoxAdapter(child: _buildBlockedMessage())
                      else
                        _buildAnimatedContent(
                          userRole: userRole,
                          pending: pending,
                          allTasks: filteredSchedule,
                          pendingPreview: pendingPreview,
                          escalationsPreview: escalationsPreview,
                          schedulePreview: schedulePreview,
                          proofsPreview: proofsPreview,
                          daily: daily,
                          info: info,
                          authorityApprovals: store.authorityApprovals,
                          pendingVerifications: store.pendingVerifications,
                          isInitialLoad: isLoading && stats == null,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockedMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_person_rounded,
            size: 64,
            color: AppTheme.danger.withValues(alpha: 0.8),
          ),
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
            style: AppTheme.bodySub.copyWith(
              color: AppTheme.textSub.withValues(alpha: 0.7),
            ),
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
