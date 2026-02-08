import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // Add this to your pubspec.yaml for easy date formatting
import 'all_new_task_page.dart';
import 'all_tasks_page.dart';
import '../common/task_detail_page.dart';

class StudentPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAcceptTask;
  const StudentPage({super.key, required this.onAcceptTask});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
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

  // --- State Data ---
  // We move tasks into lists so we can remove them when approved/rejected
  List<Map<String, dynamic>> todayTasks = [
    {
      "title": "Advanced Calculus Quiz",
      "sub": "Mathematics • 10:30 AM",
      "color": const Color(0xFF6366F1),
      "icon": Icons.auto_awesome_outlined,
    },
    {
      "title": "Lab Submission",
      "sub": "Organic Chemistry • 02:00 PM",
      "color": Colors.purpleAccent,
      "icon": Icons.biotech_outlined,
    },
  ];

  List<Map<String, dynamic>> requestTasks = [
    {
      "title": "Peer Review",
      "sub": "From: Dr. Aris • Due Tomorrow",
      "color": Colors.lightBlue,
      "icon": Icons.people_outline_rounded,
    },
  ];

  int completedCount = 12;

  // --- Logic Methods ---
  void _handleApprove(int index) {
    setState(() {
      var task = requestTasks.removeAt(index);
      // Update Stats
      completedCount++;
      // Notify parent/callback
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
    setState(() {
      requestTasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Automatically fetch today's date
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(formattedDate),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStatsGrid(),
                      const SizedBox(height: 32),

                      // 1. TODAY'S TASKS
                      _buildSectionHeader(
                        "Today's Tasks",
                        count: todayTasks.length,
                        onViewAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllTasksArchivePage(),
                          ),
                        ),
                      ),
                      ...todayTasks.map(
                        (task) => _taskItem(
                          context,
                          task['title'],
                          task['sub'],
                          task['color'],
                          task['icon'],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 2. NEW REQUESTS
                      // 2. NEW REQUESTS
                      if (requestTasks.isNotEmpty) ...[
                        _buildSectionHeader(
                          "New Task Requests",
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
                        // Use asMap().entries to get the index for the logic methods
                        ...requestTasks.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var task = entry.value;
                          return _taskItem(
                            context,
                            task['title'],
                            task['sub'],
                            task['color'],
                            task['icon'],
                            isRequest: true,
                            // Link the buttons to your logic methods
                            onApprove: () => _handleApprove(idx),
                            onRejectTrigger: () => _handleReject(idx),
                          );
                        }),
                        const SizedBox(height: 32),
                      ],
                      // 3. OVERDUE
                      _buildSectionHeader(
                        "Overdue Tasks",
                        color: destructive,
                        onViewAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllTasksArchivePage(),
                          ),
                        ),
                      ),
                      _taskItem(
                        context,
                        "Ethics Essay",
                        "Deadline: 3 days ago",
                        destructive,
                        Icons.priority_high_rounded,
                      ),

                      const SizedBox(height: 32),

                      // 4. DOCUMENTATION
                      _buildSectionHeader(
                        "Pending Documentation",
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

  // --- APP BAR Component ---
  Widget _buildAppBar(String dateStr) {
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
                  dateStr,
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
        _statTile(
          "Total Tasks",
          completedCount.toString(),
          Icons.assignment_rounded,
          brandAccent,
        ),
        _statTile(
          "Pending",
          requestTasks.length.toString().padLeft(2, '0'),
          Icons.schedule_rounded,
          warningColor,
        ),
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

  Widget _taskItem(
    BuildContext context,
    String title,
    String sub,
    Color accent,
    IconData icon, {
    bool isRequest = false,
    VoidCallback? onApprove,
    VoidCallback? onRejectTrigger,
  }) {
    final String heroTag = "task_${title}_$sub";

    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // UPDATED: Now it always navigates, regardless of whether it's a request or not
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsPage(
                taskData: {
                  "title": title,
                  "sub": sub,
                  "accent": accent,
                  "icon": icon,
                  "startDate": "Feb 06, 08:00 AM",
                  "deadline": isRequest
                      ? "Feb 07, 11:59 PM"
                      : "Feb 10, 11:59 PM",
                  "completionType": isRequest ? "APPROVAL" : "OTP",
                  "heroTag": heroTag,
                  "isRequest": isRequest, // Pass this to the detail page
                },
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Container(
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
                if (isRequest) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _miniActionButton("Reject", destructive, () {
                          _showRejectDialog(
                            context,
                            title,
                            destructive: destructive,
                            surfaceColor: surfaceColor,
                            textSub: textSub,
                            textMain: textMain,
                            brandPrimary: brandPrimary,
                            onConfirmDecline: onRejectTrigger ?? () {},
                          );
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
          ),
        ),
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

// --- MODIFIED DIALOG TO ACCEPT CALLBACK ---
void _showRejectDialog(
  BuildContext context,
  String taskTitle, {
  required Color destructive,
  required Color surfaceColor,
  required Color textSub,
  required Color textMain,
  required Color brandPrimary,
  required VoidCallback onConfirmDecline,
}) {
  String? selectedReason;
  final TextEditingController otherController = TextEditingController();
  final List<String> reasons = [
    "Exam Preparation",
    "Class Overlap",
    "Personal Emergency",
    "Missing Prerequisites",
    "Health Issue",
    "Other",
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => BackdropFilter(
        filter: ColorFilter.mode(
          brandPrimary.withOpacity(0.2),
          BlendMode.srcOver,
        ),
        child: Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 32,
            right: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSub.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Unable to Assist?",
                style: TextStyle(
                  color: textMain,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll let the requester know you can't take on '$taskTitle' right now.",
                style: TextStyle(color: textSub, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: reasons.map((reason) {
                  bool isSelected = selectedReason == reason;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedReason = reason),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? destructive : surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? destructive
                              : textSub.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textMain,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (selectedReason == "Other")
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: TextField(
                    controller: otherController,
                    autofocus: true,
                    maxLines: 3,
                    onChanged: (val) => setModalState(() {}),
                    style: TextStyle(color: textMain, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Briefly explain why...",
                      hintStyle: TextStyle(color: textSub.withOpacity(0.5)),
                      filled: true,
                      fillColor: surfaceColor,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Go Back",
                        style: TextStyle(
                          color: textSub,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          (selectedReason == null ||
                              (selectedReason == "Other" &&
                                  otherController.text.trim().isEmpty))
                          ? null
                          : () {
                              onConfirmDecline(); // Trigger the removal from list
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Request declined"),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: destructive,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: destructive,
                        disabledBackgroundColor: destructive.withOpacity(0.15),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Confirm Decline",
                        style: TextStyle(
                          color:
                              (selectedReason == null ||
                                  (selectedReason == "Other" &&
                                      otherController.text.trim().isEmpty))
                              ? destructive.withOpacity(0.5)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
