import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../components/skeleton_loader.dart';
import '../../models/activity_history_model.dart';
import '../../models/staff_dashboard_model.dart';
import '../../services/user_service.dart';
import 'all_staff_schedule_page.dart';
import 'staff_history_page.dart';
import '../../services/task_service.dart';
import '../common/generic_view_all_page.dart';

class StaffPage extends StatefulWidget {
  final bool isBlocked;
  final VoidCallback onAcknowledge;

  const StaffPage({
    super.key,
    this.isBlocked = false,
    required this.onAcknowledge,
  });

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  // --- Style Palette ---
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color successColor = const Color(0xFF10B981);
  final Color warningColor = const Color(0xFFF59E0B);
  final Color destructive = const Color(0xFFF43F5E);

  bool _isLoading = true;
  String? _error;
  List<ActivityItem> _recentActivities = [];
  StaffDashboardResponse? _staffDashboard;
  List<dynamic> _escalations = [];
  List<dynamic> _pendingProofs = [];

  List<Map<String, dynamic>> todayTasks = [
    {
      "title": "Regular Site Inspection",
      "time": "09:00 AM - 11:00 AM",
      "color": const Color(0xFF6366F1),
      "icon": Icons.visibility_rounded,
    },
    {
      "title": "Staff Briefing",
      "time": "01:00 PM - 01:30 PM",
      "color": Colors.purple,
      "icon": Icons.groups_rounded,
    },
    {
      "title": "Waste Management Review",
      "time": "03:00 PM - 04:00 PM",
      "color": const Color(0xFF10B981),
      "icon": Icons.recycling_rounded,
    },
  ];

  List<Map<String, dynamic>> recentActivity = [
    {
      "title": "Waste Collection Done",
      "time": "Today, 08:20 AM",
      "color": const Color(0xFF10B981),
      "icon": Icons.check_circle_outline_rounded,
    },
    {
      "title": "Shift Started: John Doe",
      "time": "Today, 06:00 AM",
      "color": Colors.blueGrey,
      "icon": Icons.login_rounded,
    },
    {
      "title": "Routine Checkup",
      "time": "Yesterday, 05:00 PM",
      "color": const Color(0xFF6366F1),
      "icon": Icons.fact_check_outlined,
    },
  ];

  int totalTasksCompleted = 48;
  int activeEmployees = 12;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final userService = UserService();
      final taskService = TaskService();
      // Fetch simultaneously
      final results = await Future.wait([
        userService.getActivityHistory(),
        userService.getStaffDashboard(),
        taskService.getEscalations(unread: true),
        taskService.getPendingProofs(),
      ]);

      final history = results[0] as ActivityHistoryResponse;
      final staffData = results[1] as StaffDashboardResponse;
      final escalations = results[2] as List<dynamic>;
      final proofs = results[3];

      if (mounted) {
        setState(() {
          _staffDashboard = staffData;
          _recentActivities = [
            ...history.history.today,
            ...history.history.yesterday,
          ];
          _escalations = escalations;
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
      debugPrint("Error fetching staff dashboard data: $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
            right: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: brandAccent.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: brandAccent,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  _buildHeader(formattedDate),
                  if (_isLoading)
                    const SliverToBoxAdapter(child: DashboardSkeleton())
                  else if (_error != null)
                    SliverToBoxAdapter(child: _buildErrorState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (widget.isBlocked)
                            _buildBlockedMessage()
                          else ...[
                            _buildStatsGrid(),
                            const SizedBox(height: 32),

                            // 1. Today's Schedule
                          _buildSectionHeader(
                            "Today's Schedule",
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AllStaffSchedulePage(),
                              ),
                            ),
                          ),
                          if (_staffDashboard?.todaysSchedule.isEmpty ?? true)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Text(
                                  "No tasks for today",
                                  style: TextStyle(color: textSub),
                                ),
                              ),
                            )
                          else
                            ...(_staffDashboard!.todaysSchedule.take(2)).map(
                              (task) => _taskCard(
                                task.title,
                                task.timing,
                                _getActivityColor(task.title, null),
                                _getActivityIcon(task.title, null),
                              ),
                            ),

                          const SizedBox(height: 32),

                          // 2. Escalated Tasks
                          _buildSectionHeader(
                            "Escalated Tasks",
                            isStatus: _escalations.isNotEmpty,
                            onViewAll: () {},
                          ),
                          if (_escalations.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  "No escalated tasks",
                                  style: TextStyle(color: textSub),
                                ),
                              ),
                            )
                          else
                            ..._escalations.take(2).map(
                              (esc) => _taskCard(
                                esc['title'] ?? 'Task',
                                esc['description'] ?? 'Requires attention',
                                destructive,
                                Icons.priority_high_rounded,
                              ),
                            ),

                          const SizedBox(height: 32),

                          // 3. Pending Proofs
                          _buildSectionHeader(
                            "Pending Proofs",
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GenericViewAllPage(
                                  title: "Pending Proofs",
                                  tasks: _pendingProofs,
                                  viewMode: 'viewonly',
                                  accentColor: successColor,
                                ),
                              ),
                            ),
                          ),
                          if (_pendingProofs.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  "No pending proofs",
                                  style: TextStyle(color: textSub),
                                ),
                              ),
                            )
                          else
                            ..._pendingProofs.take(2).map(
                              (proof) => _taskCard(
                                proof['title'] ?? 'Proof Review',
                                "Status: ${proof['status'] ?? 'Pending'}",
                                successColor,
                                Icons.verified_rounded,
                              ),
                            ),

                          const SizedBox(height: 32),

                          // 4. Recent Activity
                          _buildSectionHeader(
                            "Recent Activity",
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StaffHistoryPage(),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: brandPrimary.withOpacity(0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: brandPrimary.withOpacity(0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: _recentActivities.isEmpty
                                  ? [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "No recent activities",
                                            style: TextStyle(
                                              color: textSub,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]
                                  : _recentActivities
                                        .take(2)
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          final idx = entry.key;
                                          final item = entry.value;
                                          final isFirst = idx == 0;
                                          final isLast =
                                              idx ==
                                              _recentActivities.take(2).length -
                                                  1;
                                          return _enhancedHistoryTile(
                                            item.title,
                                            item.time,
                                            _getActivityColor(
                                              item.title,
                                              item.category,
                                            ),
                                            _getActivityIcon(
                                              item.title,
                                              item.category,
                                            ),
                                            isFirst: isFirst,
                                            isLast: isLast,
                                          );
                                        })
                                        .toList(),
                            ),
                          ).animate().fadeIn(duration: 500.ms),
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

  // --- Components ---

  Widget _buildHeader(String date) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?u=staff1',
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _staffDashboard?.profile.name ?? "Manager View",
                  style: TextStyle(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _notificationIcon(3),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _statTile(
          "Total Tasks",
          (_staffDashboard?.stats.totalTasks ?? 0).toString(),
          Icons.assignment_turned_in_rounded,
          successColor,
        ),
        _statTile(
          "Pending",
          (_staffDashboard?.stats.pendingTasks ?? 0).toString().padLeft(2, '0'),
          Icons.pending_actions_rounded,
          warningColor,
        ),
        _statTile(
          "Employees",
          (_staffDashboard?.stats.managedEmployeesCount ?? 0).toString(),
          Icons.people_alt_rounded,
          brandAccent,
        ),
        _statTile(
          "Efficiency",
          _staffDashboard?.stats.efficiency ?? "0%",
          Icons.bolt_rounded,
          const Color(0xFF8B5CF6),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: textMain,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taskCard(String title, String time, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(time, style: TextStyle(color: textSub, fontSize: 12)),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: textSub.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _enhancedHistoryTile(
    String title,
    String time,
    Color color,
    IconData icon, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 10,
                color: isFirst ? Colors.transparent : textSub.withOpacity(0.1),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : textSub.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textMain,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(time, style: TextStyle(color: textSub, fontSize: 12)),
                ],
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: textSub.withOpacity(0.3),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _notificationIcon(int count) {
    return Container(
      height: 44,
      width: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: const Center(child: Icon(Icons.notifications_none_rounded)),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    bool isStatus = false,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textMain,
            ),
          ),
          if (isStatus) ...[
            const SizedBox(width: 8),
            const CircleAvatar(radius: 3, backgroundColor: Colors.orange),
          ],
          const Spacer(),
          TextButton(
            onPressed: onViewAll,
            child: Text(
              "View All",
              style: TextStyle(
                color: brandAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String title, String? category) {
    String t = title.toLowerCase();
    if (t.contains('waste')) return Icons.recycling_rounded;
    if (t.contains('meeting')) return Icons.groups_rounded;
    if (t.contains('inspect')) return Icons.fact_check_outlined;
    if (t.contains('shift')) return Icons.login_rounded;
    return Icons.history_rounded;
  }

  Color _getActivityColor(String title, String? category) {
    String t = title.toLowerCase();
    if (t.contains('waste')) return successColor;
    if (t.contains('meeting')) return Colors.purple;
    if (t.contains('inspect')) return brandAccent;
    if (t.contains('shift')) return Colors.blueGrey;
    return brandAccent;
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, color: destructive, size: 40),
            const SizedBox(height: 16),
            Text(
              "Failed to load recent activity",
              style: TextStyle(color: textMain, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? "Unknown error",
              textAlign: TextAlign.center,
              style: TextStyle(color: textSub, fontSize: 13),
            ),
            TextButton(
              onPressed: _fetchDashboardData,
              child: Text("Retry", style: TextStyle(color: brandAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_person_rounded,
              size: 64, color: const Color(0xFFEF4444).withOpacity(0.8)),
          const SizedBox(height: 24),
          const Text(
            "Access Restricted",
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
