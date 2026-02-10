import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

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

  // --- State Data ---
  // To test the "No Requests" view, simply empty this list.
  List<Map<String, dynamic>> pendingRequests = [
    {
      "title": "Emergency Pipe Repair",
      "sub": "Block A • High Priority",
      "color": const Color(0xFFF59E0B),
      "icon": Icons.plumbing_rounded,
    },
  ];

  int totalTasksCompleted = 48;
  int activeEmployees = 12;

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, MMM dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Glow Decoration
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: brandAccent.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(formattedDate),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStatsGrid(),
                      const SizedBox(height: 32),

                      // 1. TODAY'S TASKS
                      _buildSectionHeader("Today's Schedule", onViewAll: () {}),
                      _taskCard(
                        "Regular Site Inspection",
                        "09:00 AM - 11:00 AM",
                        brandAccent,
                        Icons.visibility_rounded,
                      ),
                      _taskCard(
                        "Staff Briefing",
                        "01:00 PM - 01:30 PM",
                        Colors.purple,
                        Icons.groups_rounded,
                      ),

                      const SizedBox(height: 32),

                      // 3. RECENT HISTORY (Enhanced Layout)
                      _buildSectionHeader("Recent Activity", onViewAll: () {}),
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
                          children: [
                            _enhancedHistoryTile(
                              "Waste Collection Done",
                              "Today, 08:20 AM",
                              successColor,
                              Icons.check_circle_outline_rounded,
                              isFirst: true,
                            ),
                            _enhancedHistoryTile(
                              "Shift Started: John Doe",
                              "Today, 06:00 AM",
                              Colors.blueGrey,
                              Icons.login_rounded,
                            ),
                            _enhancedHistoryTile(
                              "Routine Checkup",
                              "Yesterday, 05:00 PM",
                              brandAccent,
                              Icons.fact_check_outlined,
                              isLast: true,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms),
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
                  "Manager View",
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
          totalTasksCompleted.toString(),
          Icons.assignment_turned_in_rounded,
          successColor,
        ),
        _statTile(
          "Pending",
          pendingRequests.length.toString().padLeft(2, '0'),
          Icons.pending_actions_rounded,
          warningColor,
        ),
        _statTile(
          "Employees",
          activeEmployees.toString(),
          Icons.people_alt_rounded,
          brandAccent,
        ),
        _statTile(
          "Efficiency",
          "94%",
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
}
