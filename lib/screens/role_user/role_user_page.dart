import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class RoleUserPage extends StatefulWidget {
  final String title;
  final String scope; // 'institution', 'department', 'infrastructure'

  const RoleUserPage({super.key, required this.title, required this.scope});

  @override
  State<RoleUserPage> createState() => _RoleUserPageState();
}

class _RoleUserPageState extends State<RoleUserPage> {
  // --- Modern Design Tokens ---
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color successColor = const Color(0xFF10B981);
  final Color warningColor = const Color(0xFFF59E0B);
  final Color dangerColor = const Color(0xFFF43F5E);

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, MMM dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Elegant background accent
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: brandAccent.withOpacity(0.03),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildCompactHeader(formattedDate),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 12),
                      _buildScopeDynamicMetrics(), // Logic for top cards
                      const SizedBox(height: 32),
                      ..._buildLogicDrivenTasks(), // Logic for list items
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

  // --- 1. Dynamic Top Metrics Logic ---
  // ... imports remain the same

  // --- 1. Updated Dynamic Top Metrics Logic ---
  Widget _buildScopeDynamicMetrics() {
    switch (widget.scope.toLowerCase()) {
      case 'institution': // Principal: Dept & Faculty Data
        return Row(
          children: [
            _metricCard(
              "Active Depts",
              "12",
              Icons.account_balance_rounded,
              brandAccent,
            ),
            const SizedBox(width: 12),
            _metricCard(
              "Core Faculty",
              "148",
              Icons.assignment_ind_rounded,
              Colors.orange,
            ),
          ],
        );
      case 'department': // HOD: Student Data Focus
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
                  successColor,
                ),
                const SizedBox(width: 12),
                _bentoMetricTile(
                  "92%",
                  "Avg. Attendance",
                  Icons.analytics_rounded,
                  brandAccent,
                ),
              ],
            ),
          ],
        );
      case 'infrastructure': // Incharge: Venue & Asset Focus
        return Row(
          children: [
            _metricCard(
              "Venue Usage",
              "85%",
              Icons.stadium_rounded,
              successColor,
            ),
            const SizedBox(width: 12),
            _metricCard(
              "Bookings",
              "24",
              Icons.calendar_today_rounded,
              brandAccent,
            ),
          ],
        );
      default:
        return _featuredDeptCard("General", "System Active");
    }
  }

  // --- 2. Logic Driven Task/History Sections ---
  // --- 2. Logic Driven Task/History Sections ---
  List<Widget> _buildLogicDrivenTasks() {
    List<Widget> sections = [];
    final String scope = widget.scope.toLowerCase();

    if (scope == 'institution') {
      // --- PRINCIPAL VIEW ---
      sections.add(_buildSectionHeader("Today's Schedule", onViewAll: () {}));
      sections.add(
        _taskTile(
          "Board of Governors",
          "Conference Hall • 11:00 AM",
          brandAccent,
          Icons.groups_rounded,
        ),
      );

      sections.add(const SizedBox(height: 24));
      sections.add(_buildSectionHeader("Pending Approvals", onViewAll: () {}));
      sections.add(
        _taskTile(
          "FY26 Budget Draft",
          "Dept: Mechanical • \$45,000",
          warningColor,
          Icons.account_balance_wallet_outlined,
          isApproval: true,
        ),
      );
      sections.add(
        _taskTile(
          "New Faculty Hire",
          "Dr. Sarah Smith • Computer Science",
          successColor,
          Icons.person_add_rounded,
          isApproval: true,
        ),
      );
    } else if (scope == 'department') {
      // --- HOD VIEW ---
      sections.add(_buildSectionHeader("Dept. Priorities", onViewAll: () {}));
      sections.add(
        _taskTile(
          "Mid-Term Grading",
          "Pending for 3 courses",
          warningColor,
          Icons.grade_rounded,
        ),
      );

      sections.add(_buildSectionHeader("Today's Schedule", onViewAll: () {}));
      sections.add(
        _taskTile(
          "Board of Governors",
          "Conference Hall • 11:00 AM",
          brandAccent,
          Icons.groups_rounded,
        ),
      );

      sections.add(const SizedBox(height: 24));
      sections.add(_buildSectionHeader("Quick Approvals", onViewAll: () {}));
      sections.add(
        _taskTile(
          "Student Leave: Mark V.",
          "Sick Leave • 2 Days",
          brandAccent,
          Icons.event_available_rounded,
          isApproval: true,
        ),
      );
    } else if (scope == 'infrastructure') {
      // --- INCHARGE VIEW ---
      sections.add(_buildSectionHeader("Today's Bookings", onViewAll: () {}));
      sections.add(
        _taskTile(
          "Seminar Hall A",
          "Workshop • 02:00 PM",
          brandAccent,
          Icons.meeting_room_rounded,
        ),
      );

      sections.add(const SizedBox(height: 24));
      sections.add(_buildSectionHeader("Venue Requests", onViewAll: () {}));
      sections.add(
        _taskTile(
          "Auditorium Request",
          "Annual Cultural Fest",
          successColor,
          Icons.stadium_rounded,
          isApproval: true,
        ),
      );
      sections.add(_buildSectionHeader("Booking History", onViewAll: () {}));
      sections.add(
        _taskTile(
          "Seminar Hall A",
          "Workshop • 02:00 PM",
          brandAccent,
          Icons.meeting_room_rounded,
        ),
      );
    }

    return sections;
  } // New Section Header with "View All" button

  Widget _buildSectionHeader(String label, {required VoidCallback onViewAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textSub,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "View All",
              style: TextStyle(
                color: brandAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Metric Card for Principal/Incharge
  Widget _metricCard(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 16),
            Text(
              val,
              style: TextStyle(
                color: textMain,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: textSub,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().scale(delay: 100.ms),
    );
  }

  // ... (Other helpers like _featuredDeptCard, _taskTile, _bentoMetricTile remain the same)
  // --- New Helper for HOD Student Stats ---
  Widget _bentoMetricTile(String val, String label, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: col.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: col.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: col, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val,
                  style: TextStyle(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: textSub,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }

  Widget _buildCompactHeader(String date) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: textMain,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _headerIconButton(Icons.notifications_none_rounded, hasDot: true),
          ],
        ),
      ),
    );
  }

  // ... existing imports and tokens

  // --- 1. Dynamic Top Metrics Logic ---

  // --- 2. Updated Logic for Tasks ---
  // --- UI Components (Light Theme Only) ---

  Widget _featuredDeptCard(String deptName, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: brandAccent.withOpacity(0.04), // Very light tint
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: brandAccent.withOpacity(0.1), width: 2),
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
                  color: brandAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "DEPARTMENT LEAD",
                  style: TextStyle(
                    color: brandAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.auto_awesome, color: brandAccent, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            deptName,
            style: TextStyle(
              color: textMain,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.circle, color: successColor, size: 8),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  color: textSub,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  // ... (Keep _metricCard, _taskTile, _bentoMetricTile as they were already Light Theme)
  Widget _taskTile(
    String title,
    String sub,
    Color col,
    IconData icon, {
    bool isApproval = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: col.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: col, size: 20),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(sub, style: TextStyle(color: textSub, fontSize: 12)),
                  ],
                ),
              ),
              if (!isApproval)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: textSub.withOpacity(0.3),
                ),
            ],
          ),
          if (isApproval) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    "Reject",
                    dangerColor,
                    Icons.close_rounded,
                    () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    "Approve",
                    successColor,
                    Icons.check_rounded,
                    () {},
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  // Helper for the new Approve/Reject buttons
  Widget _actionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, {bool hasDot = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: textMain, size: 22),
        ),
        if (hasDot)
          Positioned(
            right: 10,
            top: 10,
            child: CircleAvatar(radius: 4, backgroundColor: dangerColor),
          ),
      ],
    );
  }
}
