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
import '../../models/venue_dashboard_model.dart';
import '../../models/venue_history_model.dart';
import '../../models/institutional_dashboard_model.dart';
import '../common/task_detail_page.dart';
import '../../services/user_service.dart';
import '../../models/departmental_dashboard_model.dart';
import './venue_history_page.dart';
import './venue_approvals_page.dart';
import './venue_schedule_page.dart';
import './venue_availability_page.dart';
import '../common/generic_view_all_page.dart';
import '../../services/notification_service.dart';


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
  final UserService _userService = UserService();
  final ResourceService _resourceService = ResourceService();
  VenueDetailsResponse? _venueDetails;
  VenueHistoryResponse? _globalHistory;
  DepartmentalDashboard? _deptDetails;
  InstitutionalDashboard? _institutionDashboard;
  List<dynamic> _escalations = [];
  VenueDetailItem? _selectedRoleVenue;
  List<dynamic> _pendingProofs = [];
  int _unreadNotifications = 0;
  bool _isLoading = false;
  bool _isHistoryLoading = true;
  String? _error;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    final String scope = widget.scope.toLowerCase();
    if (scope == 'infrastructure') {
      _fetchVenueDashboard();
    } else if (scope == 'department') {
      _fetchDepartmentalDashboard();
    } else if (scope == 'institution') {
      _fetchInstitutionalDashboard();
    }
  }

  Future<void> _fetchDepartmentalDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _userService.getDepartmentalDashboard(),
        _taskService.getEscalations(unread: true),
        _taskService.getPendingProofs(),
      ]);
      setState(() {
        _deptDetails = results[0] as DepartmentalDashboard;
        _escalations = results[1] as List<dynamic>;
        if (results[2] is List) {
          _pendingProofs = results[2];
        } else if (results[2] is Map) {
          if (results[2].containsKey('items')) {
            _pendingProofs = results[2]['items'];
          } else if (results[2].containsKey('data')) {
            _pendingProofs = results[2]['data'];
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchInstitutionalDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _userService.getInstitutionalDashboard(),
        _taskService.getEscalations(unread: true),
        _taskService.getPendingProofs(),
      ]);
      setState(() {
        _institutionDashboard = results[0] as InstitutionalDashboard;
        _escalations = results[1] as List<dynamic>;
        if (results[2] is List) {
          _pendingProofs = results[2];
        } else if (results[2] is Map) {
          if (results[2].containsKey('items')) {
            _pendingProofs = results[2]['items'];
          } else if (results[2].containsKey('data')) {
            _pendingProofs = results[2]['data'];
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchVenueDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _taskService.getVenueDashboard(),
        _taskService.getEscalations(unread: true),
        _taskService.getPendingProofs(),
      ]);

      setState(() {
        _venueDetails = results[0] as VenueDetailsResponse;
        _escalations = results[1] as List<dynamic>;
        if (results[2] is List) {
          _pendingProofs = results[2];
        } else if (results[2] is Map) {
          if (results[2].containsKey('items')) {
            _pendingProofs = results[2]['items'];
          } else if (results[2].containsKey('data')) {
            _pendingProofs = results[2]['data'];
          }
        }

        if (_venueDetails!.venues.isNotEmpty && _selectedRoleVenue == null) {
          _selectedRoleVenue = _venueDetails!.venues.first;
        } else if (_venueDetails!.venues.isNotEmpty &&
            _selectedRoleVenue != null) {
          _selectedRoleVenue = _venueDetails!.venues.firstWhere(
            (v) => v.venueId == _selectedRoleVenue!.venueId,
            orElse: () => _venueDetails!.venues.first,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }

    // Always trigger history and unread fetches to keep dashboard fresh
    final int? activeVenueId = _selectedRoleVenue?.venueId;
    _fetchScopedHistory(venueId: activeVenueId);
    _fetchUnreadNotifications(venueId: activeVenueId);
  }

  Future<void> _fetchUnreadNotifications({int? venueId}) async {
    try {
      final count = await _notificationService.getUnreadCount(
        venueId: widget.scope.toLowerCase() == 'infrastructure' ? venueId : null,
      );
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  Future<void> _fetchScopedHistory({int? venueId}) async {
    setState(() => _isHistoryLoading = true);
    try {
      final history = await _taskService.getVenueHistory(
        venueId: venueId,
        days: 7,
      );
      setState(() {
        _globalHistory = history;
        _isHistoryLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching scoped history: $e");
      setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> _refresh() {
    final scope = widget.scope.toLowerCase();
    _fetchUnreadNotifications(venueId: _selectedRoleVenue?.venueId);
    if (scope == 'institution') return _fetchInstitutionalDashboard();
    if (scope == 'department') return _fetchDepartmentalDashboard();
    return _fetchVenueDashboard();
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
                    venueId: widget.scope.toLowerCase() == 'infrastructure' ? _selectedRoleVenue?.venueId : null,
                    actions: widget.scope.toLowerCase() == 'infrastructure' ? [
                      IconButton(
                        onPressed: () => _handleDownloadReport(true),
                        icon: const Icon(Icons.analytics_rounded, color: AppTheme.brandAccent),
                        tooltip: "Venue Report",
                      ),
                      IconButton(
                        onPressed: () => _handleDownloadReport(false),
                        icon: const Icon(Icons.inventory_2_rounded, color: AppTheme.success),
                        tooltip: "Resource Report",
                      ),
                    ] : null,
                  ),
                  if (_isLoading)
                    const SliverToBoxAdapter(child: DashboardSkeleton())
                  else if (_error != null)
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
                            _buildScopeDynamicMetrics(),
                            const SizedBox(height: 32),
                            ..._buildLogicDrivenTasks(),
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
  }

  Widget _buildScopeDynamicMetrics() {
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
                    value: (stats?.totalDepartments ?? 0).toString(),
                    icon: Icons.account_balance_rounded,
                    color: AppTheme.brandAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: "Faculty",
                    value: (stats?.totalFaculty ?? 0).toString(),
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
                    value: (stats?.totalStudents ?? 0).toString(),
                    icon: Icons.school_rounded,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: "Pending Approvals",
                    value:
                        (_institutionDashboard
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _featuredDeptCard(
              _deptDetails?.department.name ?? "Department",
              "HOD Dashboard",
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: "Students",
                    value: (deptStats?.totalStudents ?? 0).toString(),
                    icon: Icons.school_rounded,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: "Faculty",
                    value: (deptStats?.totalFaculty ?? 0).toString(),
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
              value: _selectedRoleVenue != null ? "1" : totalVenues.toString(),
              icon: Icons.stadium_rounded,
              color: AppTheme.success,
            ),
            StatCard(
              label: "Requests",
              value: pendingRequestsCount.toString(),
              icon: Icons.pending_actions_rounded,
              color: AppTheme.warning,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VenueApprovalsPage()),
              ),
            ),
            StatCard(
              label: "Upcoming",
              value: activeTodayCount.toString(),
              icon: Icons.pie_chart_rounded,
              color: AppTheme.brandAccent,
            ),
            StatCard(
              label: "Venue Status",
              value: _selectedRoleVenue?.currentStatus.replaceAll('_', ' ').toUpperCase() ?? "Check",
              icon: Icons.meeting_room_rounded,
              color: Colors.deepPurpleAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VenueAvailabilityPage()),
              ),
            ),
          ],
        );
      default:
        return _featuredDeptCard("General", "System Active");
    }
  }

  Future<void> _handleGeneralTaskAction(int taskId, bool approve) async {
    try {
      if (approve) {
        await _taskService.acceptTask(taskId);
      } else {
        await _taskService.rejectTask(taskId, "Action by manager");
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
        _refresh(); // Re-sync state
      }
    }
  }

  Future<void> _handleDownloadReport(bool isVenue) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Generating ${isVenue ? 'Venue' : 'Resource'} Report...")),
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

  List<Widget> _buildLogicDrivenTasks() {
    List<Widget> sections = [];
    final String scope = widget.scope.toLowerCase();

    if (scope == 'institution') {
      // 1. Today's Schedule
      final schedule = _institutionDashboard?.todaysSchedule ?? [];
      sections.add(
        SectionHeader(
          title: "Today's Schedule",
          count: schedule.length,
          onViewAll: () {},
        ),
      );
      if (schedule.isEmpty) {
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
              onTap: () {},
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
      if (approvalList.isEmpty) {
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
                  ? () => _handleGeneralTaskAction(taskId, true)
                  : null,
              onReject: taskId != null
                  ? () => _handleGeneralTaskAction(taskId, false)
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
                    )
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
      if (_escalations.isEmpty) {
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
                    )
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
          ),
        ),
      );
      if (_pendingProofs.isEmpty) {
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
                      )
                  : null,
            ),
          );
        }
      }
    } else if (scope == 'department') {
      // 1. Today's Schedule
      final schedule = _deptDetails?.todaysSchedule ?? [];
      sections.add(
        SectionHeader(
          title: "Today's Schedule",
          count: _deptDetails?.todaysScheduleCount ?? 0,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GenericViewAllPage(
                title: "Today's Schedule",
                tasks: _deptDetails?.todaysSchedule ?? [],
                viewMode: 'viewonly',
                accentColor: AppTheme.brandAccent,
              ),
            ),
          ),
        ),
      );
      if (schedule.isEmpty) {
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
          final taskId = task['task_id'] ?? task['id'];
          sections.add(
            TaskCard(
              title: task['title']?.toString() ?? 'Task',
              sub: task['timing']?.toString() ?? task['time']?.toString() ?? '',
              accent: AppTheme.brandAccent,
              icon: Icons.event_rounded,
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {'task_id': taskId, 'title': task['title']},
                          viewMode: 'viewonly',
                        ),
                      ),
                    )
                  : null,
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      // 2. Authority Approval (HOD Level)
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
                onTaskAction: _handleGeneralTaskAction,
              ),
            ),
          ),
        ),
      );
      if (approvals.isEmpty) {
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
              onAccept: taskId != null
                  ? () => _handleGeneralTaskAction(taskId, true)
                  : null,
              onReject: taskId != null
                  ? () => _handleGeneralTaskAction(taskId, false)
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
                    )
                  : null,
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      // 3. Escalated Tasks
      final escalated = _deptDetails?.escalatedTasks ?? [];
      sections.add(
        SectionHeader(
          title: "Escalated Tasks",
          count: _deptDetails?.escalatedTasksCount ?? 0,
          isStatus: (_deptDetails?.escalatedTasksCount ?? 0) > 0,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GenericViewAllPage(
                title: "Escalated Tasks",
                tasks: _deptDetails?.escalatedTasks ?? [],
                viewMode: 'incharge',
                accentColor: AppTheme.danger,
              ),
            ),
          ),
        ),
      );
      if (escalated.isEmpty) {
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
        for (final task in escalated.take(2)) {
          final taskId = task['task_id'] ?? task['id'];
          sections.add(
            TaskCard(
              title: task['title']?.toString() ?? 'Escalated Task',
              sub: "Assignee: ${task['assignee_name'] ?? 'N/A'}",
              accent: AppTheme.danger,
              icon: Icons.priority_high_rounded,
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {'task_id': taskId, 'title': task['title']},
                          viewMode: 'incharge',
                        ),
                      ),
                    )
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
          ),
        ),
      );
      if (_pendingProofs.isEmpty) {
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
                      )
                  : null,
            ),
          );
        }
      }

      sections.add(const SizedBox(height: 24));

      // 5. Department Tasks
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
          ),
        ),
      );
      if (deptTasks.isEmpty) {
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
              onTap: taskId != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {'task_id': taskId, 'title': task['title']},
                          viewMode: 'viewonly',
                        ),
                      ),
                    )
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
              MaterialPageRoute(builder: (_) => const VenueSchedulePage()),
            ),
          ),
        );

        if (currentVenue.today.confirmedBookings.isEmpty) {
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
                  );
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
            ),
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
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.brandAccent.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandAccent.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VenueDetailItem>(
          value: _selectedRoleVenue,
          isExpanded: true,
          icon: const Icon(
            Icons.unfold_more_rounded,
            color: AppTheme.brandAccent,
            size: 20,
          ),
          items: _venueDetails!.venues.map((venue) {
            return DropdownMenuItem(
              value: venue,
              child: Row(
                children: [
                  Icon(
                    Icons.stadium_rounded,
                    size: 18,
                    color: AppTheme.brandAccent.withOpacity(0.7),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    venue.name,
                    style: const TextStyle(
                      color: AppTheme.textMain,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedRoleVenue = val;
              });
              _fetchScopedHistory(venueId: val.venueId);
            }
          },
        ),
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
