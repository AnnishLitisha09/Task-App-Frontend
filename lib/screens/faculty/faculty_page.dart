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

  @override
  void initState() {
    super.initState();
    _fetchStats();
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

  // --- Logic: Handlers ---
  void _acceptTask(int index) {
    // Note: In a real app, this would call an API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Task accepted"),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _handleTransfer(String title) async {
    final List<Map<String, dynamic>>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserSelectionPage(
          multiSelect: false,
          allowedRoles: ["Faculty"], // Only transfer to Faculty
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final selectedUser = result.first;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Task '$title' transferred to ${selectedUser['name']}",
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        _fetchStats(); // Refresh to reflect changes
      }
    }
  }

  void _showRejectDialog(int index) {
    if (_stats == null) return;
    final taskTitle = _stats!.pendingTasks[index]['title'] ?? 'Task';

    UnifiedRejectDialog.show(
      context,
      taskTitle: taskTitle,
      onTransfer: () => _handleTransfer(taskTitle), // Trigger transfer
      onReject: (reason, details) {
        // Handle rejection logic here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Task rejected: $reason"),
            backgroundColor: AppTheme.danger,
          ),
        );
        _fetchStats(); // Refresh
      },
    );
  }

  void _showDirectiveActionSheet(BuildContext context, int index) {
    if (_stats == null) return;
    final task = _stats!.pendingTasks[index];
    final title = task['title'] ?? 'Task';
    final description = task['description'] ?? 'No description available';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: AppTheme.textSub, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    "Reject",
                    AppTheme.danger,
                    Icons.close_rounded,
                    () {
                      Navigator.pop(context);
                      _showRejectDialog(index);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _actionButton(
                    "Accept",
                    AppTheme.success,
                    Icons.check_rounded,
                    () {
                      Navigator.pop(context);
                      _acceptTask(index);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _actionTile(
              context,
              "Transfer Task",
              "Assign this directive to another faculty member",
              Icons.trending_up_rounded,
              AppTheme.brandAccent,
              () {
                Navigator.pop(context);
                _handleTransfer(title);
              },
            ),
            const SizedBox(height: 12),
            _actionTile(
              context,
              "View Full Details",
              "Open detailed view of this task",
              Icons.visibility_outlined,
              Colors.blueGrey,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailsPage(
                      taskData: {
                        'title': title,
                        'sub': description,
                        'accent': AppTheme.brandAccent,
                        'icon': Icons.assignment_turned_in_rounded,
                        'heroTag': "directive_${task['task_id']}_$index",
                        'startDate': task['start_date'] ?? "N/A",
                        'deadline': task['end_date'] ?? "N/A",
                        'completionType': task['type'] ?? "APPROVAL",
                        'isRequest': true,
                        'authority': "Administration",
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPrimary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      color: AppTheme.textSub,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textSub.withOpacity(0.3),
            ),
          ],
        ),
      ),
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
              onRefresh: _fetchStats,
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
                          count: 1, // Mock count
                          onViewAll: () {},
                        ),
                        TaskCard(
                          title: "Venue Security Audit",
                          sub: "Escalated by Prof. Aristhoth • High Priority",
                          accent: AppTheme.danger,
                          icon: Icons.priority_high_rounded,
                          onTap: () {},
                        ),

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
                          title: "Pending Paperwork",
                          onViewAll: () {},
                        ),
                        _docItem(
                          "Monthly Attendance Report",
                          "Required",
                          Icons.description_outlined,
                        ),
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

  Widget _docItem(String title, String status, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSub, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: AppTheme.bodyMain.copyWith(fontSize: 14)),
          ),
          Text(
            status,
            style: const TextStyle(
              color: AppTheme.brandAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
