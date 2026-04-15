import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/stat_card.dart';
import '../../components/task_card.dart';
import '../../components/section_header.dart';
import '../../components/skeleton_loader.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../services/resource_service.dart';
import '../../services/task_service.dart';
import '../../services/venue_notifier.dart';
import '../../models/venue_dashboard_model.dart';
import '../../models/venue_history_model.dart';
import '../../models/institutional_dashboard_model.dart';
import '../common/task_detail_page.dart';
import '../../models/departmental_dashboard_model.dart';
import './venue_history_page.dart';
import './venue_approvals_page.dart';
import './venue_availability_page.dart';
import '../faculty/all_schedule_page.dart';
import '../common/generic_view_all_page.dart';
import '../faculty/all_proofs_page.dart';
import '../faculty/all_directives_page.dart';
import '../faculty/task_verification_page.dart';
import '../faculty/verify_users_proof_page.dart';
import 'package:provider/provider.dart';
import '../../store/app_store.dart';

class RoleUserPage extends StatefulWidget {
  final String title;
  final String scope; // 'institution', 'department', 'infrastructure'
  final bool isBlocked;
  final VoidCallback onAcknowledge;

  const RoleUserPage({
    super.key,
    required this.title,
    required this.scope,
    this.isBlocked = false,
    required this.onAcknowledge,
  });

  @override
  State<RoleUserPage> createState() => _RoleUserPageState();
}

class _RoleUserPageState extends State<RoleUserPage> {
  final TaskService _taskService = TaskService();
  final ResourceService _resourceService = ResourceService();

  // ─── Getters delegating to Global AppStore ──────────────────────────────
  VenueDetailsResponse? get _venueDetails =>
      context.read<AppStore>().venueDashboard;
  VenueHistoryResponse? get _globalHistory =>
      context.read<AppStore>().venueHistory;
  DepartmentalDashboard? get _deptDetails =>
      context.read<AppStore>().deptDashboard;
  InstitutionalDashboard? get _institutionDashboard =>
      context.read<AppStore>().institutionDashboard;
  List<dynamic> get _escalations => context.read<AppStore>().escalations;
  List<dynamic> get _pendingProofs => context.read<AppStore>().pendingProofs;
  int get _unreadNotifications => context.read<AppStore>().unreadNotifications;

  VenueDetailItem? get _selectedRoleVenue {
    final details = _venueDetails;
    if (details == null || details.venues.isEmpty) return null;
    final currentId = VenueNotifier.currentVenueId;
    if (currentId != null) {
      return details.venues.firstWhere(
        (v) => v.venueId == currentId,
        orElse: () => details.venues.first,
      );
    }
    return details.venues.first;
  }

  bool get _isLoading {
    final scope = widget.scope.toLowerCase();
    if (scope == 'institution')
      return context.read<AppStore>().isLoading('institutionDashboard');
    if (scope == 'department')
      return context.read<AppStore>().isLoading('deptDashboard');
    return context.read<AppStore>().isLoading('venueDashboard');
  }

  bool get _isInitialLoad {
    final scope = widget.scope.toLowerCase();
    if (scope == 'institution')
      return _isLoading && _institutionDashboard == null;
    if (scope == 'department') return _isLoading && _deptDetails == null;
    return _isLoading && _venueDetails == null;
  }

  bool get _isHistoryLoading =>
      context.read<AppStore>().isLoading('venueHistory');

  String? get _error {
    final store = context.read<AppStore>();
    final scope = widget.scope.toLowerCase();
    if (scope == 'infrastructure') return store.errorOf('venueDashboard');
    if (scope == 'department') return store.errorOf('deptDashboard');
    if (scope == 'institution') return store.errorOf('institutionDashboard');
    return null;
  }

  @override
  void initState() {
    super.initState();
    final String scope = widget.scope.toLowerCase();
    if (scope == 'infrastructure') {
      _fetchVenueDashboard();
      // Re-fetch whenever venue is switched globally
      VenueNotifier.venueNotifier.addListener(_onVenueChanged);
    } else if (scope == 'department') {
      _fetchDepartmentalDashboard();
      // If also a faculty, load their personal task data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureUserRolesAndHydrateFaculty();
      });
    } else if (scope == 'institution') {
      _fetchInstitutionalDashboard();
    }
  }

  bool get _isDualFacultyHod {
    final store = context.read<AppStore>();
    final roles = store.allRoles.map((r) => r.toLowerCase()).toList();
    return roles.contains('faculty') &&
        (roles.contains('hod') || store.userRole?.toLowerCase() == 'hod');
  }

  Future<void> _ensureUserRolesAndHydrateFaculty() async {
    final store = context.read<AppStore>();
    await store.ensureUserRole();
    if (_isDualFacultyHod) {
      await Future.wait([
        store.fetchFacultyStats(),
        store.fetchPendingVerifications(),
      ]);
    }
  }

  @override
  void dispose() {
    VenueNotifier.venueNotifier.removeListener(_onVenueChanged);
    super.dispose();
  }

  void _onVenueChanged() {
    if (widget.scope.toLowerCase() == 'infrastructure') {
      _fetchVenueDashboard();
    }
  }

  Future<void> _fetchDepartmentalDashboard({bool force = false}) async {
    final store = context.read<AppStore>();
    // Since backend is unified, fetchDeptDashboard hydrates all task sections
    await store.fetchDeptDashboard(force: force);
  }

  Future<void> _fetchInstitutionalDashboard({bool force = false}) async {
    final store = context.read<AppStore>();
    await Future.wait([
      store.fetchInstitutionDashboard(force: force),
      store.fetchEscalations(force: force),
      store.fetchPendingProofs(force: force),
    ]);
  }

  Future<void> _fetchVenueDashboard({bool force = false}) async {
    final store = context.read<AppStore>();
    await Future.wait([
      store.fetchVenueDashboard(force: force),
      store.fetchEscalations(force: force),
      store.fetchPendingProofs(force: force),
    ]);

    // Refresh history & unread automatically after venue loads
    final activeVenueId =
        _selectedRoleVenue?.venueId ?? VenueNotifier.currentVenueId;
    _fetchScopedHistory(venueId: activeVenueId, force: force);
    _fetchUnreadNotifications(venueId: activeVenueId);
  }

  Future<void> _fetchUnreadNotifications({int? venueId}) async {
    final store = context.read<AppStore>();
    await store.fetchUnreadNotifications(
      venueId: widget.scope.toLowerCase() == 'infrastructure' ? venueId : null,
    );
  }

  Future<void> _fetchScopedHistory({int? venueId, bool force = false}) async {
    final store = context.read<AppStore>();
    await store.fetchVenueHistory(venueId: venueId, force: force);
  }

  Future<void> _refresh() async {
    final scope = widget.scope.toLowerCase();
    _fetchUnreadNotifications(venueId: _selectedRoleVenue?.venueId);
    if (scope == 'institution')
      return _fetchInstitutionalDashboard(force: true);
    if (scope == 'department') return _fetchDepartmentalDashboard(force: true);
    return _fetchVenueDashboard(force: true);
  }

  // ─── Faculty-side helpers (used when dual role hod+faculty) ──────────────

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, MMM dd').format(DateTime.now());

    return Consumer<AppStore>(
      builder: (context, store, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: CircleAvatar(
                  radius: 200,
                  backgroundColor: AppTheme.brandAccent.withOpacity(0.03),
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppTheme.brandAccent,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      CustomAppBar(
                        title: widget.title,
                        date: formattedDate,
                        notificationCount: _unreadNotifications,
                        venueId: widget.scope.toLowerCase() == 'infrastructure'
                            ? _selectedRoleVenue?.venueId
                            : null,
                        actions: widget.scope.toLowerCase() == 'infrastructure'
                            ? [
                                IconButton(
                                  onPressed: () => _handleDownloadReport(true),
                                  icon: const Icon(
                                    Icons.analytics_rounded,
                                    color: AppTheme.brandAccent,
                                  ),
                                  tooltip: "Venue Report",
                                ),
                                IconButton(
                                  onPressed: () => _handleDownloadReport(false),
                                  icon: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: AppTheme.success,
                                  ),
                                  tooltip: "Resource Report",
                                ),
                              ]
                            : null,
                      ),
                      if (_error != null && _isInitialLoad)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: AppTheme.danger.withOpacity(0.5),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Failed to load dashboard',
                                    style: AppTheme.h2,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.textSub),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _refresh,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text("Retry"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.brandPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              const SizedBox(height: 12),
                              if (widget.isBlocked)
                                _buildBlockedMessage()
                              else ...[
                                _buildScopeDynamicMetrics(
                                  isInitialLoad: _isInitialLoad,
                                ),
                                const SizedBox(height: 32),
                                ..._buildLogicDrivenTasks(
                                  isInitialLoad: _isInitialLoad,
                                ),
                              ],
                              const SizedBox(height: 100),
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
      },
    );
  }

  Widget _buildScopeDynamicMetrics({required bool isInitialLoad}) {
    switch (widget.scope.toLowerCase()) {
      case 'institution':
        final stats = _institutionDashboard?.institutionalStats;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role badge
            if (_institutionDashboard?.role.isNotEmpty ?? false)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brandAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _institutionDashboard!.role,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.brandAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: "Departments",
                    value: isInitialLoad
                        ? "..."
                        : (stats?.totalDepartments ?? 0).toString(),
                    icon: Icons.account_balance_rounded,
                    color: AppTheme.brandAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: "Faculty",
                    value: isInitialLoad
                        ? "..."
                        : (stats?.totalFaculty ?? 0).toString(),
                    icon: Icons.assignment_ind_rounded,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: "Students",
                    value: isInitialLoad
                        ? "..."
                        : (stats?.totalStudents ?? 0).toString(),
                    icon: Icons.school_rounded,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: "Pending Approvals",
                    value: isInitialLoad
                        ? "..."
                        : (_institutionDashboard
                                      ?.personalActions
                                      .pendingMyApprovalCount ??
                                  0)
                              .toString(),
                    icon: Icons.pending_actions_rounded,
                    color: AppTheme.danger,
                  ),
                ),
              ],
            ),
          ],
        );
      case 'department':
        final deptStats = _deptDetails?.stats;
        final personalStats = _deptDetails?.facultyDetails;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _featuredDeptCard(
              _deptDetails?.department.name ?? "Department",
              "HOD Dashboard",
            ),
            const SizedBox(height: 16),
            if (personalStats != null) ...[
              _personalFacultyStatsRow(personalStats),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: "Students",
                    value: isInitialLoad
                        ? "..."
                        : (deptStats?.totalStudents ?? 0).toString(),
                    icon: Icons.school_rounded,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: "Faculty",
                    value: isInitialLoad
                        ? "..."
                        : (deptStats?.totalFaculty ?? 0).toString(),
                    icon: Icons.people_alt_rounded,
                    color: AppTheme.brandAccent,
                  ),
                ),
              ],
            ),
          ],
        );
      case 'infrastructure':
        final totalVenues = _venueDetails?.totalVenuesManaged ?? 0;
        int activeTodayCount = 0;
        int pendingRequestsCount = 0;
        if (_selectedRoleVenue != null) {
          activeTodayCount = _selectedRoleVenue!.today.confirmedBookingsCount;
          pendingRequestsCount = _selectedRoleVenue!.newRequestsPendingCount;
        } else if (_venueDetails != null) {
          for (var v in _venueDetails!.venues) {
            activeTodayCount += v.today.confirmedBookingsCount;
            pendingRequestsCount += v.newRequestsPendingCount;
          }
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            StatCard(
              label: _selectedRoleVenue != null ? "Selected" : "Managed",
              value: isInitialLoad
                  ? "..."
                  : (_selectedRoleVenue != null ? "1" : totalVenues.toString()),
              icon: Icons.stadium_rounded,
              color: AppTheme.success,
            ),
            StatCard(
              label: "Requests",
              value: isInitialLoad ? "..." : pendingRequestsCount.toString(),
              icon: Icons.pending_actions_rounded,
              color: AppTheme.warning,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VenueApprovalsPage()),
              ).then((result) { if (mounted && result == true) _refresh(); }),
            ),
            StatCard(
              label: "Upcoming",
              value: isInitialLoad ? "..." : activeTodayCount.toString(),
              icon: Icons.pie_chart_rounded,
              color: AppTheme.brandAccent,
            ),
            StatCard(
              label: "Venue Status",
              value: isInitialLoad
                  ? "..."
                  : (_selectedRoleVenue?.currentStatus
                            .replaceAll('_', ' ')
                            .toUpperCase() ??
                        "Check"),
              icon: Icons.meeting_room_rounded,
              color: Colors.deepPurpleAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VenueAvailabilityPage(),
                ),
              ).then((result) { if (mounted && result == true) _refresh(); }),
            ),
          ],
        );
      default:
        return _featuredDeptCard("General", "System Active");
    }
  }

  Future<void> _handleAcceptDirective(int taskId, bool accept) async {
    try {
      if (accept) {
        await _taskService.acceptTask(taskId);
      } else {
        await _taskService.rejectTask(taskId, "Rejected directive by user");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? "Directive Accepted" : "Directive Rejected"),
            backgroundColor: accept ? AppTheme.success : AppTheme.danger,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppTheme.danger,
          ),
        );
        _refresh();
      }
    }
  }

  Future<void> _handleApproveTask(int taskId, bool approve) async {
    try {
      if (approve) {
        await _taskService.approveTask(taskId);
      } else {
        await _taskService.rejectTask(taskId, "Rejected by authority");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? "Task Approved" : "Task Rejected"),
            backgroundColor: approve ? AppTheme.success : AppTheme.danger,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppTheme.danger,
          ),
        );
        _refresh();
      }
    }
  }

  Future<void> _handleDownloadReport(bool isVenue) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Generating ${isVenue ? 'Venue' : 'Resource'} Report...",
          ),
        ),
      );

      final List<int> bytes = isVenue
          ? await _resourceService.downloadVenueReport()
          : await _resourceService.downloadResourceReport();

      String? fileName = isVenue
          ? 'venue_utilisation_report_${DateTime.now().millisecondsSinceEpoch}.xlsx'
          : 'resource_utilisation_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report:',
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
      );

      if (outputFile != null) {
        if (!Platform.isAndroid && !Platform.isIOS) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Report saved successfully!"),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  List<Widget> _buildLogicDrivenTasks({required bool isInitialLoad}) {
    List<Widget> sections = [];
    final String scope = widget.scope.toLowerCase();

    if (scope == 'institution') {
      // 1. Today's Schedule
      final schedule = _institutionDashboard?.todaysSchedule ?? [];
      sections.add(
        SectionHeader(
          title: "Today's Schedule",
          count: schedule.length,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AllSchedulePage(
                userRole: context.read<AppStore>().userRole ?? 'User',
              ),
            ),
          ).then((result) { if (mounted && result == true) _refresh(); }),
        ),
      );
      if (isInitialLoad) {
        sections.add(
          const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
        );
      } else if (schedule.isEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No schedule for today",
                style: TextStyle(color: AppTheme.textSub),
              ),
            ),
          ),
        );
      } else {
        for (final task in schedule.take(2)) {
          sections.add(
            TaskCard(
              title: task['title']?.toString() ?? 'Task',
              sub: task['timing']?.toString() ?? task['time']?.toString() ?? '',
              accent: AppTheme.brandAccent,
              icon: Icons.event_rounded,
              priority: task['priority']?.toString(),
              taskTypeName: task['task_type']?.toString() ?? task['type']?.toString(),
              onTap: () {},
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      sections.add(const SizedBox(height: 24));

      // NEW: Incoming Directives (Assigned to me directly)
      final directivesList =
          _institutionDashboard?.personalActions.assignedToMeList ?? [];
      final directivesCount =
          _institutionDashboard?.personalActions.assignedToMeCount ?? 0;
      sections.add(
        SectionHeader(
          title: "Incoming Directives",
          count: directivesCount,
          isStatus: directivesCount > 0,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GenericViewAllPage(
                title: "Incoming Directives",
                tasks: directivesList,
                viewMode: 'approver',
                accentColor: AppTheme.brandAccent,
                onTaskAction: _handleAcceptDirective,
              ),
            ),
          ).then((result) { if (mounted && result == true) _refresh(); }),
        ),
      );
      if (isInitialLoad) {
        sections.add(
          const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
        );
      } else if (directivesList.isEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No pending directives",
                style: TextStyle(color: AppTheme.textSub),
              ),
            ),
          ),
        );
      } else {
        for (final task in directivesList.take(2)) {
          final taskId = task['task_id'] ?? task['id'];
          sections.add(
            TaskCard(
              title: task['title']?.toString() ?? 'Directive Task',
              sub: task['description']?.toString() ?? '',
              accent: AppTheme.brandAccent,
              icon: Icons.assignment_turned_in_rounded,
              isRequest: true,
              acceptLabel: "Executive Directive",
              priority: task['priority']?.toString(),
              taskTypeName: task['task_type']?.toString() ?? task['type']?.toString(),
              onAccept: taskId != null
                  ? () => _handleAcceptDirective(taskId, true)
                  : null,
              onReject: taskId != null
                  ? () => _handleAcceptDirective(taskId, false)
                  : null,
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {'task_id': taskId, 'title': task['title']},
                          viewMode:
                              'default', // Assignee just needs standard view
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refresh(); })
                  : null,
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      // 2. Pending Approvals (Standard)
      final approvalList =
          _institutionDashboard?.personalActions.pendingMyApprovalList ?? [];
      final approvalCount =
          _institutionDashboard?.personalActions.pendingMyApprovalCount ?? 0;
      sections.add(
        SectionHeader(
          title: "Pending Approvals",
          count: approvalCount,
          isStatus: approvalCount > 0,
          onViewAll: () {},
        ),
      );
      if (isInitialLoad) {
        sections.add(
          const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
        );
      } else if (approvalList.isEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No pending approvals",
                style: TextStyle(color: AppTheme.textSub),
              ),
            ),
          ),
        );
      } else {
        for (final task in approvalList.take(2)) {
          final taskId = task['task_id'] ?? task['id'];
          sections.add(
            TaskCard(
              title: task['title']?.toString() ?? 'Approval Request',
              sub: task['description']?.toString() ?? '',
              accent: AppTheme.warning,
              icon: Icons.assignment_ind_rounded,
              isApproval: true,
              onAccept: taskId != null
                  ? () => _handleApproveTask(taskId, true)
                  : null,
              onReject: taskId != null
                  ? () => _handleApproveTask(taskId, false)
                  : null,
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {'task_id': taskId, 'title': task['title']},
                          viewMode: 'approver',
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refresh(); })
                  : null,
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      // 3. Escalated Tasks
      sections.add(
        SectionHeader(
          title: "Escalated Tasks",
          count: _escalations.length,
          isStatus: _escalations.isNotEmpty,
          onViewAll: () {},
        ),
      );
      if (isInitialLoad) {
        sections.add(
          const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
        );
      } else if (_escalations.isEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No escalated tasks",
                style: TextStyle(color: AppTheme.textSub),
              ),
            ),
          ),
        );
      } else {
        for (final esc in _escalations.take(2)) {
          final taskId = esc['task_id'] ?? esc['id'];
          sections.add(
            TaskCard(
              title: esc['title']?.toString() ?? 'Escalated Task',
              sub:
                  esc['description']?.toString() ??
                  esc['reason']?.toString() ??
                  'Escalated • Requires attention',
              accent: AppTheme.danger,
              icon: Icons.priority_high_rounded,
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {'task_id': taskId, 'title': esc['title']},
                          viewMode: 'incharge',
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refresh(); })
                  : null,
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      // 4. Pending Proofs
      sections.add(
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
          ).then((result) { if (mounted && result == true) _refresh(); }),
        ),
      );
      if (isInitialLoad) {
        sections.add(
          const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
        );
      } else if (_pendingProofs.isEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No pending proofs",
                style: TextStyle(color: AppTheme.textSub),
              ),
            ),
          ),
        );
      } else {
        for (final proof in _pendingProofs.take(2)) {
          final taskId = proof['task_id'] ?? proof['id'];
          sections.add(
            TaskCard(
              title: proof['title']?.toString() ?? 'Proof Review',
              sub: "Status: ${proof['status'] ?? 'Pending'}",
              accent: AppTheme.success,
              icon: Icons.verified_rounded,
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': taskId,
                            'title': proof['title'],
                          },
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refresh(); })
                  : null,
            ),
          );
        }
      }
    } else if (scope == 'department') {
      final store = context.read<AppStore>();
      final facultyStats = _isDualFacultyHod ? store.facultyStats : null;
      final isFacultyLoading = _isDualFacultyHod &&
          store.isLoading('facultyStats') && facultyStats == null;
      final userRole = store.userRole;

      // ── 1. Today's Schedule (Unified Backend Response) ────────────────────
      final mergedSchedule = _deptDetails?.todaysSchedule ?? [];
      final mergedScheduleCount = _deptDetails?.todaysScheduleCount ?? 0;

      sections.add(
        SectionHeader(
          title: "Today's Schedule",
          count: mergedScheduleCount,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AllSchedulePage(
                userRole: userRole ?? 'Department',
              ),
            ),
          ).then((result) { if (mounted && result == true) _refresh(); }),
        ),
      );
      if (isInitialLoad || isFacultyLoading) {
        sections.add(
          const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
        );
      } else if (mergedSchedule.isEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No schedule for today",
                style: TextStyle(color: AppTheme.textSub),
              ),
            ),
          ),
        );
      } else {
        for (var i = 0; i < mergedSchedule.take(3).length; i++) {
          final task = mergedSchedule[i];
          final taskId = task['task_id'] ?? task['id'];
          sections.add(
            TaskCard(
              title: task['title']?.toString() ?? 'Task',
              sub: task['timing']?.toString() ?? task['time']?.toString() ?? '',
              accent: AppTheme.brandAccent,
              icon: Icons.event_rounded,
              actionButton: task['action_button'],
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': taskId,
                            'title': task['title'],
                            'startDate': task['start_date'] ?? 'N/A',
                            'deadline': task['end_date'] ?? 'N/A',
                            'userRole': userRole ?? 'Faculty',
                          },
                          viewMode: 'default',
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refresh(); })
                  : null,
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      // ── 2. Incoming Directives (Unified Backend Response) ──────────────────
      final mergedDirectives = _deptDetails?.assignedToMeTasks ?? [];
      final mergedDirectivesCount = _deptDetails?.assignedToMeCount ?? 0;

      sections.add(
        SectionHeader(
          title: "Incoming Directives",
          count: mergedDirectivesCount,
          isStatus: mergedDirectivesCount > 0,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AllDirectivesPage(
                isBlocked: widget.isBlocked,
                userRole: userRole ?? 'faculty',
                onRefreshParent: _refresh,
              ),
            ),
          ).then((result) { if (mounted && result == true) _refresh(); }),
        ),
      );
      if (isInitialLoad || isFacultyLoading) {
        sections.add(
          const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
        );
      } else if (mergedDirectives.isEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No pending directives",
                style: TextStyle(color: AppTheme.textSub),
              ),
            ),
          ),
        );
      } else {
        for (final task in mergedDirectives.take(3)) {
          final taskId = task['task_id'] ?? task['id'];
          sections.add(
            TaskCard(
              title: task['title']?.toString() ?? 'Directive Task',
              sub: "Assigned by: ${task['creator_name'] ?? 'N/A'}",
              accent: AppTheme.brandAccent,
              icon: Icons.assignment_turned_in_rounded,
              isRequest: true,
              acceptLabel: "Executive Directive",
              onAccept: taskId != null
                  ? () {
                      if (widget.isBlocked) return;
                      _handleAcceptDirective(taskId, true);
                    }
                  : null,
              onReject: taskId != null
                  ? () {
                      if (widget.isBlocked) return;
                      _handleAcceptDirective(taskId, false);
                    }
                  : null,
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': taskId,
                            'title': task['title'],
                            'sub': task['description'],
                            'userRole': userRole ?? 'Faculty',
                          },
                          viewMode: 'default',
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refresh(); })
                  : null,
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      // ── 3. Authority Approval (HOD only) ──────────────────────────────────
      final approvals = _deptDetails?.pendingApprovals ?? [];
      sections.add(
        SectionHeader(
          title: "Authority Approval",
          count: _deptDetails?.pendingApprovalsCount ?? 0,
          isStatus: (_deptDetails?.pendingApprovalsCount ?? 0) > 0,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GenericViewAllPage(
                title: "Authority Approval",
                tasks: _deptDetails?.pendingApprovals ?? [],
                viewMode: 'approver',
                accentColor: AppTheme.warning,
                onTaskAction: _handleApproveTask,
              ),
            ),
          ).then((result) { if (mounted && result == true) _refresh(); }),
        ),
      );
      if (isInitialLoad) {
        sections.add(
          const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
        );
      } else if (approvals.isEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No pending approvals",
                style: TextStyle(color: AppTheme.textSub),
              ),
            ),
          ),
        );
      } else {
        for (final task in approvals.take(2)) {
          final taskId = task['task_id'] ?? task['id'];
          sections.add(
            TaskCard(
              title: task['title']?.toString() ?? "Approval Request",
              sub: "Requested by: ${task['requested_by'] ?? 'N/A'}",
              accent: AppTheme.warning,
              icon: Icons.how_to_reg_rounded,
              isApproval: true,
              priority: task['priority']?.toString(),
              taskTypeName: task['task_type']?.toString() ?? task['type']?.toString(),
              onAccept: taskId != null
                  ? () => _handleApproveTask(taskId, true)
                  : null,
              onReject: taskId != null
                  ? () => _handleApproveTask(taskId, false)
                  : null,
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {'task_id': taskId, 'title': task['title']},
                          viewMode: 'approver',
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refresh(); })
                  : null,
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      // ── 4. Escalated Tasks (Unified Backend Response) ─────────────────────
      final mergedEscalated = _deptDetails?.escalatedTasks ?? [];
      sections.add(
        SectionHeader(
          title: "Escalated Tasks",
          count: mergedEscalated.length,
          isStatus: mergedEscalated.isNotEmpty,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GenericViewAllPage(
                title: "Escalated Tasks",
                tasks: mergedEscalated,
                viewMode: 'incharge',
                accentColor: AppTheme.danger,
              ),
            ),
          ).then((result) { if (mounted && result == true) _refresh(); }),
        ),
      );
      if (isInitialLoad || isFacultyLoading) {
        sections.add(
          const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
        );
      } else if (mergedEscalated.isEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No escalated tasks",
                style: TextStyle(color: AppTheme.textSub),
              ),
            ),
          ),
        );
      } else {
        for (final task in mergedEscalated.take(3)) {
          final taskId = task['task_id'] ?? task['id'];
          sections.add(
            TaskCard(
              title: task['title']?.toString() ?? 'Escalated Task',
              sub: "Assignee: ${task['assignee_name'] ?? 'N/A'}",
              accent: AppTheme.danger,
              icon: Icons.priority_high_rounded,
              priority: task['priority']?.toString(),
              taskTypeName: task['task_type']?.toString() ?? task['type']?.toString(),
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': taskId,
                            'title': task['title'],
                            'userRole': userRole ?? 'Faculty',
                          },
                          viewMode: 'incharge',
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refresh(); })
                  : null,
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      // ── 5. Pending Proofs ──────────────────────────────────────────────────
      sections.add(
        SectionHeader(
          title: "Pending Proofs",
          count: _pendingProofs.length,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AllProofsPage()),
          ).then((result) { if (mounted && result == true) _refresh(); }),
        ),
      );
      if (isInitialLoad) {
        sections.add(
          const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
        );
      } else if (_pendingProofs.isEmpty) {
        sections.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No pending proofs",
                style: TextStyle(color: AppTheme.textSub),
              ),
            ),
          ),
        );
      } else {
        for (final proof in _pendingProofs.take(2)) {
          final taskId = proof['task_id'] ?? proof['id'];
          final dl = proof['deadline'];
          final dlStr = dl != null
              ? "${dl['end_date'] ?? 'N/A'} ${dl['end_time'] ?? ''}"
              : "N/A";
          sections.add(
            TaskCard(
              title: proof['title']?.toString() ?? 'Proof Review',
              sub: proof['description']?.toString() ??
                  "Status: ${proof['status'] ?? 'Pending'}",
              accent: Colors.orange,
              icon: Icons.photo_camera_rounded,
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': taskId,
                            'assignment_id': proof['assignment_id'],
                            'title': proof['title'],
                            'sub': proof['description'] ?? 'Awaiting proof verification',
                            'deadline': dlStr,
                            'completionType': "PROOF_REVIEW",
                            'is_document': proof['is_document'],
                            'status': proof['status'],
                            'proof_status': proof['proof_status'],
                            'userRole': 'Faculty',
                          },
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refresh(); })
                  : null,
            ),
          );
        }
      }

      // ── 6. Pending Verifications (dual-role only) ─────────────────────────
      if (_isDualFacultyHod) {
        final pendingVerif = store.pendingVerifications;
        if (pendingVerif.isNotEmpty) {
          sections.add(const SizedBox(height: 24));
          sections.add(
            SectionHeader(
              title: "Pending Verifications",
              isStatus: true,
              count: pendingVerif.length,
              onViewAll: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TaskVerificationPage(),
                ),
              ).then((result) { if (mounted && result == true) _refresh(); }),
            ),
          );
          for (final verify in pendingVerif.take(1)) {
            final heroTag = "hod_fac_verify_${verify['assignment_id']}_dash";
            sections.add(
              TaskCard(
                title: verify['title'] ?? 'Task Review',
                sub: 'By: ${verify['assignee_name']} (${verify['assignee_role']})',
                accent: AppTheme.brandAccent,
                icon: Icons.fact_check_rounded,
                heroTag: heroTag,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerifyUsersProofPage(
                      taskId: verify['task_id'],
                      taskTitle: verify['title'] ?? 'Task Review',
                    ),
                  ),
                ).then((result) { if (mounted && result == true) _refresh(); }),
              ),
            );
          }
        }
      }

      sections.add(const SizedBox(height: 24));

      // ── 7. Department Tasks ────────────────────────────────────────────────
      final deptTasks = _deptDetails?.departmentTasks ?? [];
      sections.add(
        SectionHeader(
          title: "Department Tasks",
          count: _deptDetails?.departmentTasksCount ?? 0,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GenericViewAllPage(
                title: "Department Tasks",
                tasks: _deptDetails?.departmentTasks ?? [],
                viewMode: 'viewonly',
                accentColor: AppTheme.brandAccent,
              ),
            ),
          ).then((result) { if (mounted && result == true) _refresh(); }),
        ),
      );
      if (isInitialLoad) {
        sections.add(const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]));
      } else if (deptTasks.isEmpty) {
        sections.add(
          const Center(
            child: Text(
              "No department tasks",
              style: TextStyle(color: AppTheme.textSub),
            ),
          ),
        );
      } else {
        for (final task in deptTasks.take(2)) {
          final taskId = task['task_id'] ?? task['id'];
          sections.add(
            TaskCard(
              title: task['title']?.toString() ?? "Dept Task",
              sub: task['description']?.toString() ?? "No description",
              accent: AppTheme.brandAccent,
              icon: Icons.task_alt_rounded,
              priority: task['priority']?.toString(),
              taskTypeName: task['task_type']?.toString() ?? task['type']?.toString(),
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {'task_id': taskId, 'title': task['title']},
                          viewMode: 'viewonly',
                        ),
                      ),
                    ).then((result) { if (mounted && result == true) _refresh(); })
                  : null,
            ),
          );
        }
      }
    } else if (scope == 'infrastructure') {
      if (_venueDetails == null || _venueDetails!.venues.isEmpty) {
        sections.add(const Center(child: Text("No venue data available.")));
      } else {
        // --- Venue Selector ---
        if (_venueDetails!.totalVenuesManaged > 1) {
          sections.add(const SectionHeader(title: "Select Venue"));
          sections.add(_buildVenueDropdown());
          sections.add(const SizedBox(height: 24));
        }

        final currentVenue = _selectedRoleVenue ?? _venueDetails!.venues.first;

        // 1. Today's Schedule (Selected Venue)
        sections.add(
          SectionHeader(
            title: "Today's Schedule",
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllSchedulePage(
                  userRole: context.read<AppStore>().userRole ?? 'Infrastructure',
                ),
              ),
            ).then((result) { if (mounted && result == true) _refresh(); }),
          ),
        );

        if (isInitialLoad) {
          sections.add(
            const Column(children: [SkeletonTaskCard(), SkeletonTaskCard()]),
          );
        } else if (currentVenue.today.confirmedBookings.isEmpty) {
          sections.add(
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No bookings scheduled today.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
          );
        } else {
          for (var booking in currentVenue.today.confirmedBookings.take(2)) {
            final bool isCompleted =
                booking.status.toLowerCase() == 'completed';
            sections.add(
              TaskCard(
                title: booking.title,
                sub:
                    "${currentVenue.name} • ${booking.fromTime} - ${booking.toTime} • ${booking.status.toUpperCase()}",
                accent: isCompleted ? AppTheme.success : AppTheme.brandAccent,
                icon: isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.meeting_room_rounded,
                priority: booking.priority,
                taskTypeName: booking.taskType,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailsPage(
                        taskData: {
                          'task_id': booking.taskId,
                          'title': booking.title,
                        },
                        viewMode: 'incharge',
                      ),
                    ),
                  ).then((result) { if (mounted && result == true) _refresh(); });
                  if (result != null) {
                    _fetchVenueDashboard();
                  }
                },
              ),
            );
            sections.add(const SizedBox(height: 12));
          }
        }

        sections.add(const SizedBox(height: 24));

        sections.add(const SizedBox(height: 24));

        // --- Recent History ---
        sections.add(
          SectionHeader(
            title: "Recent History",
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VenueHistoryViewAllPage(
                  venueId: currentVenue.venueId,
                  venueName: currentVenue.name,
                ),
              ),
            ).then((result) { if (mounted && result == true) _refresh(); }),
          ),
        );

        if (_isHistoryLoading) {
          sections.addAll([const SkeletonTaskCard(), const SkeletonTaskCard()]);
        } else if (_globalHistory == null || _globalHistory!.history.isEmpty) {
          sections.add(const Center(child: Text("No history records found")));
        } else {
          for (var item in _globalHistory!.history.take(2)) {
            final statusCol = item.status == 'COMPLETED'
                ? AppTheme.success
                : (item.status == 'REJECTED'
                      ? AppTheme.danger
                      : AppTheme.warning);

            sections.add(
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailsPage(
                      taskData: {'task_id': item.taskId, 'title': item.title},
                      viewMode: 'incharge',
                    ),
                  ),
                ).then((result) { if (mounted && result == true) _refresh(); }),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surfaceColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: statusCol,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: AppTheme.textMain,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.userName ?? "Unknown User",
                              style: TextStyle(
                                color: AppTheme.textSub.withOpacity(0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatItemDate(item.date),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(),
            );
          }
        }
      }
    }

    return sections;
  }

  Widget _personalFacultyStatsRow(dynamic stats) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: "My Score",
            value: (stats['total_score'] ?? stats['score'] ?? 0).toString(),
            icon: Icons.stars_rounded,
            color: AppTheme.brandPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: "My Penalty",
            value: (stats['penalty'] ?? 0).toString(),
            icon: Icons.timer_off_rounded,
            color: AppTheme.danger,
          ),
        ),
      ],
    );
  }

  Widget _featuredDeptCard(String deptName, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.brandAccent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppTheme.brandAccent.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brandAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "DEPARTMENT LEAD",
                  style: TextStyle(
                    color: AppTheme.brandAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.auto_awesome,
                color: AppTheme.brandAccent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            deptName,
            style: AppTheme.h1.copyWith(fontSize: 22, letterSpacing: -1),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.circle, color: AppTheme.success, size: 8),
              const SizedBox(width: 6),
              Text(status, style: AppTheme.bodySub),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildVenueDropdown() {
    if (_venueDetails == null || _venueDetails!.venues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.brandAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.brandAccent.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.stadium_rounded,
            color: AppTheme.brandAccent,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assigned Workplace",
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.brandAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_venueDetails != null && _venueDetails!.venues.length > 1)
                  DropdownButtonHideUnderline(
                    child: DropdownButton<VenueDetailItem>(
                      value: _selectedRoleVenue,
                      isDense: true,
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppTheme.brandAccent,
                      ),
                      onChanged: (VenueDetailItem? newValue) {
                        if (newValue != null) {
                          VenueNotifier.switchVenue(
                            newValue.venueId,
                            newValue.name,
                          );
                        }
                      },
                      items: _venueDetails!.venues.map((VenueDetailItem venue) {
                        return DropdownMenuItem<VenueDetailItem>(
                          value: venue,
                          child: Text(
                            venue.name,
                            style: AppTheme.h2.copyWith(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else
                  Text(
                    _selectedRoleVenue?.name ?? "Venue",
                    style: AppTheme.h2.copyWith(fontSize: 16),
                  ),
              ],
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
              color: AppTheme.textSub.withOpacity(0.7),
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

  String _formatItemDate(String dateStr) {
    if (dateStr.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM dd').format(dt);
    } catch (e) {
      debugPrint("Error parsing date: $dateStr - $e");
      return dateStr;
    }
  }
}
