import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/stat_card.dart';
import '../../components/task_card.dart';
import '../../components/section_header.dart';
import '../../components/skeleton_loader.dart';
import '../../components/reject_dialog.dart';
import 'all_new_task_page.dart';
import 'all_tasks_page.dart';
import '../common/task_detail_page.dart';

class StudentPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAcceptTask;
  final bool isBlocked;
  final VoidCallback onAcknowledge;
  const StudentPage({
    super.key,
    required this.onAcceptTask,
    this.isBlocked = false,
    required this.onAcknowledge,
  });

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  bool _isLoading = true;

  List<Map<String, dynamic>> todayTasks = [
    {
      "title": "Advanced Calculus Quiz",
      "sub": "Mathematics • 10:30 AM",
      "color": AppTheme.brandAccent,
      "icon": Icons.auto_awesome_outlined,
    },
    {
      "title": "Lab Submission",
      "sub": "Organic Chemistry • 02:00 PM",
      "color": Colors.purpleAccent,
      "icon": Icons.biotech_outlined,
    },
    {
      "title": "Data Structures Assignment",
      "sub": "CS • 04:00 PM",
      "color": AppTheme.success,
      "icon": Icons.code_rounded,
    },
  ];

  List<Map<String, dynamic>> requestTasks = [
    {
      "title": "Peer Review",
      "sub": "From: Dr. Aris • Due Tomorrow",
      "color": Colors.lightBlue,
      "icon": Icons.people_outline_rounded,
    },
    {
      "title": "Workshop Registration",
      "sub": "From: Events Office • Today",
      "color": AppTheme.warning,
      "icon": Icons.event_seat_rounded,
    },
  ];

  int completedCount = 12;

  @override
  void initState() {
    super.initState();
    // Simulate API load
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _handleApprove(int index) {
    setState(() {
      var task = requestTasks.removeAt(index);
      completedCount++;
      widget.onAcceptTask({
        "title": task['title'],
        "sub": task['sub'].split('•')[0],
        "start": 14.0,
        "dur": 60.0,
        "icon": task['icon'],
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Task added to your schedule!")),
    );
  }

  void _handleReject(int index) {
    setState(() => requestTasks.removeAt(index));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Request declined")));
  }

  void _showRejectDialog(int index) {
    RejectDialog.show(
      context,
      taskTitle: requestTasks[index]['title'],
      reasons: [
        "Exam Preparation",
        "Class Overlap",
        "Personal Emergency",
        "Other",
      ],
      onConfirm: (reason, details) => _handleReject(index),
    );
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
              backgroundColor: AppTheme.brandAccent.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                CustomAppBar(
                  title: "Annish Litisha",
                  date: formattedDate,
                  notificationCount: 4,
                  profileImageUrl:
                      'https://img.freepik.com/premium-vector/purple-circle-with-white-person-icon_876006-6.jpg?w=360',
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
                if (_isLoading)
                  const SliverToBoxAdapter(child: DashboardSkeleton())
                else
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
                                  label: "Total Tasks",
                                  value: completedCount.toString(),
                                  icon: Icons.assignment_rounded,
                                  color: AppTheme.brandAccent,
                                ),
                                StatCard(
                                  label: "Pending",
                                  value: requestTasks.length.toString().padLeft(
                                    2,
                                    '0',
                                  ),
                                  icon: Icons.schedule_rounded,
                                  color: AppTheme.warning,
                                ),
                                StatCard(
                                  label: "Overdue",
                                  value: "01",
                                  icon: Icons.bolt_rounded,
                                  color: AppTheme.danger,
                                ),
                                StatCard(
                                  label: "Current GPA",
                                  value: "3.9",
                                  icon: Icons.auto_graph_rounded,
                                  color: AppTheme.success,
                                ),
                              ],
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 32),

                        // --- Today's Tasks (max 2) ---
                        SectionHeader(
                          title: "Today's Tasks",
                          count: todayTasks.length,
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllTasksArchivePage(),
                            ),
                          ),
                        ),
                        ...todayTasks.take(2).map((task) {
                          final String heroTag =
                              "task_${task['title']}_${task['sub']}";
                          return TaskCard(
                            title: task['title'],
                            sub: task['sub'],
                            accent: task['color'],
                            icon: task['icon'],
                            heroTag: heroTag,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskDetailsPage(
                                  taskData: {
                                    "title": task['title'],
                                    "sub": task['sub'],
                                    "accent": task['color'],
                                    "icon": task['icon'],
                                    "startDate": "Feb 06, 08:00 AM",
                                    "deadline": "Feb 10, 11:59 PM",
                                    "completionType": "OTP",
                                    "heroTag": heroTag,
                                    "isRequest": false,
                                  },
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 32),

                        // --- New Task Requests (max 2) ---
                        if (requestTasks.isNotEmpty) ...[
                          SectionHeader(
                            title: "New Task Requests",
                            isStatus: true,
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllNewTasksPage(
                                  onAccept: widget.onAcceptTask,
                                ),
                              ),
                            ),
                          ),
                          ...requestTasks.take(2).toList().asMap().entries.map((
                            entry,
                          ) {
                            int idx = entry.key;
                            var task = entry.value;
                            final String heroTag =
                                "task_req_${task['title']}_$idx";
                            return TaskCard(
                              title: task['title'],
                              sub: task['sub'],
                              accent: task['color'],
                              icon: task['icon'],
                              heroTag: heroTag,
                              isRequest: true,
                              onAccept: widget.isBlocked
                                  ? null
                                  : () => _handleApprove(idx),
                              onReject: widget.isBlocked
                                  ? null
                                  : () => _showRejectDialog(idx),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailsPage(
                                    taskData: {
                                      "title": task['title'],
                                      "sub": task['sub'],
                                      "accent": task['color'],
                                      "icon": task['icon'],
                                      "startDate": "Feb 06, 08:00 AM",
                                      "deadline": "Feb 07, 11:59 PM",
                                      "completionType": "APPROVAL",
                                      "heroTag": heroTag,
                                      "isRequest": true,
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 32),
                        ],

                        // --- Overdue Tasks (max 2 items shown) ---
                        SectionHeader(
                          title: "Overdue Tasks",
                          color: AppTheme.danger,
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllTasksArchivePage(),
                            ),
                          ),
                        ),
                        TaskCard(
                          title: "Ethics Essay",
                          sub: "Deadline: 3 days ago",
                          accent: AppTheme.danger,
                          icon: Icons.priority_high_rounded,
                          onTap: () {},
                        ),

                        const SizedBox(height: 32),

                        // --- Pending Documentation (max 2) ---
                        SectionHeader(
                          title: "Pending Documentation",
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllTasksArchivePage(),
                            ),
                          ),
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

  Widget _docItem(String title, String status, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSub, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyMain.copyWith(fontSize: 14)),
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
          ),
          const Icon(Icons.more_horiz_rounded, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
