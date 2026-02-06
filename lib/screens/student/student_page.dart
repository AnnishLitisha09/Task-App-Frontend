import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'all_new_task_page.dart';

class StudentPage extends StatelessWidget {
  final Function(Map<String, dynamic>) onAcceptTask;
  const StudentPage({super.key, required this.onAcceptTask});

  // --- Charming Design Tokens ---
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color dividerColor = const Color(0xFFF1F5F9);
  final Color destructive = const Color(0xFFF43F5E);
  final Color successColor = const Color(0xFF10B981);
  final Color warningColor = const Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStatsGrid(),
                      const SizedBox(height: 32),

                      // 1. TODAY'S TASKS
                      _buildSectionHeader(
                        "Today's Tasks",
                        count: 3,
                        onViewAll: () {},
                      ),
                      _taskItem(
                        "Advanced Calculus Quiz",
                        "Mathematics • 10:30 AM",
                        brandAccent,
                        Icons.auto_awesome_outlined,
                      ),
                      _taskItem(
                        "Lab Submission",
                        "Organic Chemistry • 02:00 PM",
                        Colors.purpleAccent,
                        Icons.biotech_outlined,
                      ),

                      const SizedBox(height: 32),

                      // 2. NEW REQUESTS (Now with Reject/Approve logic)
                      _buildSectionHeader(
                        "New Task Requests",
                        isStatus: true,
                        onViewAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AllNewTasksPage(onAccept: onAcceptTask),
                          ),
                        ),
                      ),
                      _taskItem(
                        "Peer Review",
                        "From: Dr. Aris • Due Tomorrow",
                        Colors.lightBlue,
                        Icons.people_outline_rounded,
                        isRequest: true,
                        onApprove: () {
                          onAcceptTask({
                            "title": "Peer Review",
                            "sub": "Dr. Aris",
                            "start": 14.0, // Example start time
                            "dur": 60.0,
                            "icon": Icons.people_outline_rounded,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Task added to your schedule!"),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // 3. OVERDUE
                      _buildSectionHeader(
                        "Overdue Tasks",
                        color: destructive,
                        onViewAll: () {},
                      ),
                      _taskItem(
                        "Ethics Essay",
                        "Deadline: 3 days ago",
                        destructive,
                        Icons.priority_high_rounded,
                      ),

                      const SizedBox(height: 32),

                      // 4. DOCUMENTATION
                      _buildSectionHeader(
                        "Pending Documentation",
                        onViewAll: () {},
                      ),
                      _docItem(
                        "Registration Form",
                        "Signature Required",
                        Icons.history_edu_rounded,
                      ),
                      _docItem(
                        "Medical Waiver",
                        "Verification Pending",
                        Icons.verified_user_rounded,
                      ),
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

  // --- APP BAR Component ---
  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [brandAccent, brandAccent.withOpacity(0.2)],
                ),
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  'https://img.freepik.com/premium-vector/purple-circle-with-white-person-icon_876006-6.jpg?w=360',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Friday, Feb 06",
                  style: TextStyle(
                    color: textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Annish Litisha",
                  style: TextStyle(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildNotificationBadge(4),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBadge(int count) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, color: textMain, size: 22),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: destructive,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STATS Component ---
  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _statTile("Total Tasks", "12", Icons.assignment_rounded, brandAccent),
        _statTile("Pending", "04", Icons.schedule_rounded, warningColor),
        _statTile("Overdue", "01", Icons.bolt_rounded, destructive),
        _statTile("Current GPA", "3.9", Icons.auto_graph_rounded, successColor),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
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

  Widget _buildSectionHeader(
    String title, {
    int? count,
    Color? color,
    bool isStatus = false,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color ?? textMain,
            ),
          ),
          if (isStatus) ...[
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: brandAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(
              "View All",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: brandAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED TASK ITEM ---
  Widget _taskItem(
    String title,
    String sub,
    Color accent,
    IconData icon, {
    bool isRequest = false,
    VoidCallback? onApprove,
  }) {
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 22),
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
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        color: textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRequest)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: textSub.withOpacity(0.3),
                ),
            ],
          ),
          // --- NEW ACTION BUTTONS ---
          if (isRequest) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _miniActionButton("Reject", destructive, () {
                    // Link your rejection modal here
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniActionButton(
                    "Approve",
                    successColor,
                    onApprove ?? () {},
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _miniActionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _docItem(String title, String status, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textSub, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: brandAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz_rounded, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
