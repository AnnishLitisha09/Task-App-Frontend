import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/stat_card.dart';
import '../../components/task_card.dart';
import '../../components/section_header.dart';
import '../../components/skeleton_loader.dart';
import '../../services/task_service.dart';
import '../../models/venue_dashboard_model.dart';
import '../../models/venue_history_model.dart';
import '../common/task_detail_page.dart';
import './venue_history_page.dart';
import './venue_approvals_page.dart';
import './venue_schedule_page.dart';

class RoleUserPage extends StatefulWidget {
  final String title;
  final String scope; // 'institution', 'department', 'infrastructure'

  const RoleUserPage({super.key, required this.title, required this.scope});

  @override
  State<RoleUserPage> createState() => _RoleUserPageState();
}

class _RoleUserPageState extends State<RoleUserPage> {
  final TaskService _taskService = TaskService();
  VenueDetailsResponse? _venueDetails;
  VenueHistoryResponse? _globalHistory;
  VenueDetailItem? _selectedRoleVenue;
  bool _isLoading = false;
  bool _isHistoryLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.scope.toLowerCase() == 'infrastructure') {
      _fetchVenueDashboard();
    }
  }

  Future<void> _fetchVenueDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _taskService.getVenueDashboard();
      setState(() {
        _venueDetails = data;
        if (data.venues.isNotEmpty && _selectedRoleVenue == null) {
          _selectedRoleVenue = data.venues.first;
        } else if (data.venues.isNotEmpty && _selectedRoleVenue != null) {
          _selectedRoleVenue = data.venues.firstWhere(
            (v) => v.venueId == _selectedRoleVenue!.venueId,
            orElse: () => data.venues.first,
          );
        }
        _isLoading = false;
      });
      _fetchScopedHistory(venueId: _selectedRoleVenue?.venueId);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                CustomAppBar(
                  title: widget.title,
                  date: formattedDate,
                  notificationCount: 1,
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
                              onPressed: _fetchVenueDashboard,
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
                        _buildScopeDynamicMetrics(),
                        const SizedBox(height: 32),
                        ..._buildLogicDrivenTasks(),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeDynamicMetrics() {
    switch (widget.scope.toLowerCase()) {
      case 'institution':
        return Row(
          children: [
            StatCard(
              label: "Active Depts",
              value: "12",
              icon: Icons.account_balance_rounded,
              color: AppTheme.brandAccent,
            ),
            const SizedBox(width: 12),
            StatCard(
              label: "Core Faculty",
              value: "148",
              icon: Icons.assignment_ind_rounded,
              color: AppTheme.warning,
            ),
          ],
        );
      case 'department':
        return Column(
          children: [
            _featuredDeptCard("Computer Science", "HOD Dashboard"),
            const SizedBox(height: 12),
            Row(
              children: [
                _bentoMetricTile(
                  "840",
                  "Students",
                  Icons.school_rounded,
                  AppTheme.success,
                ),
                const SizedBox(width: 12),
                _bentoMetricTile(
                  "92%",
                  "Avg. Attendance",
                  Icons.analytics_rounded,
                  AppTheme.brandAccent,
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
              label: "Usage",
              value: _selectedRoleVenue?.todayUsagePercentage ?? "0%",
              icon: Icons.speed_rounded,
              color: Colors.orangeAccent,
            ),
          ],
        );
      default:
        return _featuredDeptCard("General", "System Active");
    }
  }

  Future<void> _handleVenueTaskAction(int taskId, bool approve) async {
    // Fast reflex: Optimistically update local state if we have a selected venue
    if (_selectedRoleVenue != null) {
      setState(() {
        final taskIndex = _selectedRoleVenue!.pendingApprovalTasks.indexWhere(
          (t) => t.taskId == taskId,
        );
        if (taskIndex != -1) {
          final task = _selectedRoleVenue!.pendingApprovalTasks.removeAt(
            taskIndex,
          );
          if (approve) {
            _selectedRoleVenue!.today.confirmedBookings.insert(0, task);
            _selectedRoleVenue!.today.confirmedBookingsCount =
                _selectedRoleVenue!.today.confirmedBookings.length;
          }
          _selectedRoleVenue!.newRequestsPendingCount =
              _selectedRoleVenue!.pendingApprovalTasks.length;
        }
      });
    }

    try {
      final service = TaskService();
      if (approve) {
        await service.acceptTask(taskId);
      } else {
        await service.rejectTask(taskId, "Rejected by manager");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? "Booking Approved" : "Booking Rejected"),
            backgroundColor: approve ? AppTheme.success : AppTheme.danger,
          ),
        );
        _fetchVenueDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppTheme.danger,
          ),
        );
        _fetchVenueDashboard(); // Revert/Sync
      }
    }
  }

  List<Widget> _buildLogicDrivenTasks() {
    List<Widget> sections = [];
    final String scope = widget.scope.toLowerCase();

    if (scope == 'institution') {
      // --- Today's Schedule (max 2) ---
      sections.add(SectionHeader(title: "Today's Schedule", onViewAll: () {}));
      sections.add(
        const TaskCard(
          title: "Board of Governors",
          sub: "Conference Hall • 11:00 AM",
          accent: AppTheme.brandAccent,
          icon: Icons.groups_rounded,
        ),
      );

      sections.add(const SizedBox(height: 24));
      // --- Pending Approvals (max 2) ---
      sections.add(SectionHeader(title: "Pending Approvals", onViewAll: () {}));
      sections.add(
        const TaskCard(
          title: "FY26 Budget Draft",
          sub: "Dept: Mechanical • \$45,000",
          accent: AppTheme.warning,
          icon: Icons.account_balance_wallet_outlined,
          isApproval: true,
        ),
      );
      sections.add(
        const TaskCard(
          title: "New Faculty Hire",
          sub: "Dr. Sarah Smith • Computer Science",
          accent: AppTheme.success,
          icon: Icons.person_add_rounded,
          isApproval: true,
        ),
      );

      sections.add(const SizedBox(height: 24));
      // --- Escalated Tasks (max 2) ---
      sections.add(SectionHeader(title: "Escalated Tasks", onViewAll: () {}));
      sections.add(
        const TaskCard(
          title: "Campus Infrastructure Delay",
          sub: "Escalated from Dept. Maintenance • Critical",
          accent: AppTheme.danger,
          icon: Icons.priority_high_rounded,
          onTap: null,
        ),
      );
    } else if (scope == 'department') {
      // --- Dept. Priorities (max 2) ---
      sections.add(SectionHeader(title: "Dept. Priorities", onViewAll: () {}));
      sections.add(
        const TaskCard(
          title: "Mid-Term Grading",
          sub: "Pending for 3 courses",
          accent: AppTheme.warning,
          icon: Icons.grade_rounded,
        ),
      );

      sections.add(SectionHeader(title: "Today's Schedule", onViewAll: () {}));
      sections.add(
        const TaskCard(
          title: "Board of Governors",
          sub: "Conference Hall • 11:00 AM",
          accent: AppTheme.brandAccent,
          icon: Icons.groups_rounded,
        ),
      );

      sections.add(const SizedBox(height: 24));
      // --- Quick Approvals (max 2) ---
      sections.add(SectionHeader(title: "Quick Approvals", onViewAll: () {}));
      sections.add(
        const TaskCard(
          title: "Student Leave: Mark V.",
          sub: "Sick Leave • 2 Days",
          accent: AppTheme.brandAccent,
          icon: Icons.event_available_rounded,
          isApproval: true,
        ),
      );

      sections.add(const SizedBox(height: 24));
      // --- Escalated Tasks (max 2) ---
      sections.add(SectionHeader(title: "Escalated Tasks", onViewAll: () {}));
      sections.add(
        const TaskCard(
          title: "Lab Equipment Procurement",
          sub: "Escalated from Lab Assistant • Urgent",
          accent: AppTheme.danger,
          icon: Icons.priority_high_rounded,
          onTap: null,
        ),
      );
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

        // --- Pending Approvals (Selected Venue) ---
        sections.add(
          SectionHeader(
            title: "Pending Approvals",
            onViewAll: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VenueApprovalsPage()),
              );
              _fetchVenueDashboard();
            },
          ),
        );

        if (currentVenue.newRequestsPendingCount == 0 &&
            currentVenue.pendingApprovalTasks.isEmpty) {
          sections.add(
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No pending requests for this venue.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
          );
        } else {
          // Use pendingApprovalTasks if it's available, otherwise we fallback to a message or mock if count > 0
          for (var booking in currentVenue.pendingApprovalTasks.take(2)) {
            sections.add(
              TaskCard(
                title: booking.title,
                sub:
                    "${currentVenue.name} • ${booking.fromTime} - ${booking.toTime} • By: ${booking.bookedBy}",
                accent: AppTheme.warning,
                icon: Icons.bolt_rounded,
                isRequest: true,
                onAccept: () => _handleVenueTaskAction(booking.taskId, true),
                onReject: () => _handleVenueTaskAction(booking.taskId, false),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailsPage(
                        taskData: {
                          'task_id': booking.taskId,
                          'title': booking.title,
                          'isRequest': true,
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

        // --- Today's Schedule (Selected Venue) ---
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
                  "No other bookings scheduled today.",
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
                        item.date,
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
            style: AppTheme.h1.copyWith(fontSize: 26, letterSpacing: -1),
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

  Widget _bentoMetricTile(String val, String label, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: AppTheme.bentoDecoration(col),
        child: Row(
          children: [
            Icon(icon, color: col, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val,
                  style: AppTheme.h1.copyWith(fontSize: 20, height: 1.1),
                ),
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
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
}
