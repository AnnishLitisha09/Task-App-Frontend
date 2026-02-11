import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/stat_card.dart';
import '../../components/task_card.dart';
import '../../components/section_header.dart';

class RoleUserPage extends StatefulWidget {
  final String title;
  final String scope; // 'institution', 'department', 'infrastructure'

  const RoleUserPage({super.key, required this.title, required this.scope});

  @override
  State<RoleUserPage> createState() => _RoleUserPageState();
}

class _RoleUserPageState extends State<RoleUserPage> {
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
                  notificationCount: 1, // Mock count
                ),
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
                _bentoMetricTile("840", "Students", Icons.school_rounded, AppTheme.success),
                const SizedBox(width: 12),
                _bentoMetricTile("92%", "Avg. Attendance", Icons.analytics_rounded, AppTheme.brandAccent),
              ],
            ),
          ],
        );
      case 'infrastructure':
        return Row(
          children: [
            StatCard(
              label: "Venue Usage",
              value: "85%",
              icon: Icons.stadium_rounded,
              color: AppTheme.success,
            ),
            const SizedBox(width: 12),
            StatCard(
              label: "Bookings",
              value: "24",
              icon: Icons.calendar_today_rounded,
              color: AppTheme.brandAccent,
            ),
          ],
        );
      default:
        return _featuredDeptCard("General", "System Active");
    }
  }

  List<Widget> _buildLogicDrivenTasks() {
    List<Widget> sections = [];
    final String scope = widget.scope.toLowerCase();

    if (scope == 'institution') {
      sections.add(SectionHeader(title: "Today's Schedule", onViewAll: () {}));
      sections.add(const TaskCard(
        title: "Board of Governors",
        sub: "Conference Hall • 11:00 AM",
        accent: AppTheme.brandAccent,
        icon: Icons.groups_rounded,
      ));

      sections.add(const SizedBox(height: 24));
      sections.add(SectionHeader(title: "Pending Approvals", onViewAll: () {}));
      sections.add(const TaskCard(
        title: "FY26 Budget Draft",
        sub: "Dept: Mechanical • \$45,000",
        accent: AppTheme.warning,
        icon: Icons.account_balance_wallet_outlined,
        isApproval: true,
      ));
      sections.add(const TaskCard(
        title: "New Faculty Hire",
        sub: "Dr. Sarah Smith • Computer Science",
        accent: AppTheme.success,
        icon: Icons.person_add_rounded,
        isApproval: true,
      ));
    } else if (scope == 'department') {
      sections.add(SectionHeader(title: "Dept. Priorities", onViewAll: () {}));
      sections.add(const TaskCard(
        title: "Mid-Term Grading",
        sub: "Pending for 3 courses",
        accent: AppTheme.warning,
        icon: Icons.grade_rounded,
      ));

      sections.add(SectionHeader(title: "Today's Schedule", onViewAll: () {}));
      sections.add(const TaskCard(
        title: "Board of Governors",
        sub: "Conference Hall • 11:00 AM",
        accent: AppTheme.brandAccent,
        icon: Icons.groups_rounded,
      ));

      sections.add(const SizedBox(height: 24));
      sections.add(SectionHeader(title: "Quick Approvals", onViewAll: () {}));
      sections.add(const TaskCard(
        title: "Student Leave: Mark V.",
        sub: "Sick Leave • 2 Days",
        accent: AppTheme.brandAccent,
        icon: Icons.event_available_rounded,
        isApproval: true,
      ));
    } else if (scope == 'infrastructure') {
      sections.add(SectionHeader(title: "Today's Bookings", onViewAll: () {}));
      sections.add(const TaskCard(
        title: "Seminar Hall A",
        sub: "Workshop • 02:00 PM",
        accent: AppTheme.brandAccent,
        icon: Icons.meeting_room_rounded,
      ));

      sections.add(const SizedBox(height: 24));
      sections.add(SectionHeader(title: "Venue Requests", onViewAll: () {}));
      sections.add(const TaskCard(
        title: "Auditorium Request",
        sub: "Annual Cultural Fest",
        accent: AppTheme.success,
        icon: Icons.stadium_rounded,
        isApproval: true,
      ));
      sections.add(SectionHeader(title: "Booking History", onViewAll: () {}));
      sections.add(const TaskCard(
        title: "Seminar Hall A",
        sub: "Workshop • 02:00 PM",
        accent: AppTheme.brandAccent,
        icon: Icons.meeting_room_rounded,
      ));
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
        border: Border.all(color: AppTheme.brandAccent.withOpacity(0.1), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              const Icon(Icons.auto_awesome, color: AppTheme.brandAccent, size: 20),
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
              Text(
                status,
                style: AppTheme.bodySub,
              ),
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
                  style: AppTheme.bodyMain.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  style: AppTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }
}

