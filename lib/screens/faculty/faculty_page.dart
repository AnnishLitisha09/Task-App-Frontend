import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import '../common/task_detail_page.dart';

class FacultyPage extends StatefulWidget {
  const FacultyPage({super.key});

  @override
  State<FacultyPage> createState() => _FacultyPageState();
}

class _FacultyPageState extends State<FacultyPage> {
  // --- Design Tokens ---
  final Color brandAccent = const Color(0xFF6366F1);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color textMain = const Color(0xFF0F172A);
  final Color textSub = const Color(0xFF64748B);
  final Color successGreen = const Color(0xFF10B981);
  final Color softRed = const Color(0xFFF43F5E);
  final Color warningAmber = const Color(0xFFF59E0B);

  // --- Logic: Data Lists ---
  // These represent the "Incoming Directives"
  List<Map<String, dynamic>> directives = [
    {
      "id": 1,
      "authority": "Dean Academics",
      "task": "Approve Internal Assessment Schema",
      "sub": "High Priority • Due Today",
      "color": const Color(0xFF6366F1),
    },
    {
      "id": 2,
      "authority": "HOD - IT",
      "task": "Technical Seminar Guest Invite",
      "sub": "Review by Feb 12",
      "color": const Color(0xFFF59E0B),
    },
  ];

  // These represent "Today's Schedule"
  List<Map<String, dynamic>> schedule = [
    {
      "title": "Cloud Computing (Section A)",
      "sub": "Room 402 • 10:30 AM",
      "icon": Icons.cloud_queue_rounded,
      "color": const Color(0xFF6366F1),
    },
  ];

  // --- Logic: Handlers ---
  void _acceptTask(int index) {
    setState(() {
      var task = directives.removeAt(index);
      schedule.add({
        "title": task['task'],
        "sub": "Added from Directives",
        "icon": Icons.assignment_turned_in_rounded,
        "color": successGreen,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Task added to your schedule"),
        backgroundColor: successGreen,
      ),
    );
  }

  void _rejectTask(int index) {
    setState(() {
      directives.removeAt(index);
    });
    Navigator.pop(context); // Close the bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text("Task rejected"), backgroundColor: softRed),
    );
  }

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

                      // 1. INCOMING DIRECTIVES
                      _buildSectionHeader(
                        "Incoming Directives",
                        isStatus: true,
                        count: directives.length,
                        onViewAll: () {},
                      ),

                      if (directives.isEmpty)
                        _buildEmptyState("No pending directives")
                      else
                        ...directives.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var data = entry.value;
                          return _buildDirectiveCard(
                            data['authority'],
                            data['task'],
                            data['sub'],
                            data['color'],
                            onAccept: () => _acceptTask(idx),
                            onReject: () => _showRejectDialog(idx),
                          );
                        }),

                      const SizedBox(height: 32),

                      // 2. TODAY'S SCHEDULE
                      _buildSectionHeader("Today's Schedule", onViewAll: () {}),
                      ...schedule.map(
                        (item) => _taskItem(
                          item['title'],
                          item['sub'],
                          item['color'],
                          item['icon'],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 3. PENDING DOCUMENTATION
                      _buildSectionHeader(
                        "Pending Paperwork",
                        onViewAll: () {},
                      ),
                      _docItem(
                        "Monthly Attendance Report",
                        "Required",
                        Icons.description_outlined,
                      ),
                      _docItem(
                        "Lab Equipment Requisition",
                        "Awaiting Sign",
                        Icons.border_color_rounded,
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

  // --- UI Components ---

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?u=faculty1',
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sunday, Feb 08",
                  style: TextStyle(
                    color: textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Dr. Alan Turing",
                  style: TextStyle(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildNotificationBadge(directives.length),
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
          "Pending",
          "0${directives.length}",
          Icons.move_to_inbox,
          brandAccent,
        ),
        _statTile(
          "Classes",
          "0${schedule.length}",
          Icons.school_rounded,
          successGreen,
        ),
        _statTile("Students", "140", Icons.people_alt_rounded, warningAmber),
        _statTile("Hours", "32h", Icons.timer_rounded, Colors.teal),
      ],
    );
  }

  Widget _buildDirectiveCard(
    String auth,
    String task,
    String sub,
    Color accent, {
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    final String heroTag = "directive_${task}_${sub.hashCode}";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsPage(
              taskData: {
                'title': task,
                'sub': sub,
                'accent': accent,
                'icon': Icons.assignment_turned_in_rounded,
                'heroTag': heroTag,
                'startDate': "Feb 08, 10:30 AM",
                'deadline': "Feb 08, 12:30 PM",

                // ✅ IMPORTANT: Directive = approval based completion
                'completionType': "APPROVAL",
                'isRequest': true,
                'authority': auth,
              },
            ),
          ),
        );
      },

      child: Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: textMain.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: surfaceColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task,
                  style: TextStyle(
                    color: textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(sub, style: TextStyle(color: textSub, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _miniActionBtn("Reject", softRed, onReject),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniActionBtn("Accept", successGreen, onAccept),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _taskItem(
    String title,
    String sub,
    Color accent,
    IconData icon, {
    bool isRequest = false,
  }) {
    final String heroTag = "task_${title}_${sub.hashCode}";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsPage(
              taskData: {
                'title': title,
                'sub': sub,
                'accent': accent,
                'icon': icon,
                'heroTag': heroTag,
                'startDate': "Feb 08, 10:30 AM",
                'deadline': "Feb 08, 12:30 PM",
                // LOGIC: If it's a request from directives, set to APPROVAL
                'completionType': isRequest ? "APPROVAL" : "OTP",
                "isRequest": isRequest, // Pass this to the detail page
              },
            ),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: textMain.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
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
                      Text(sub, style: TextStyle(color: textSub, fontSize: 12)),
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
          ),
        ),
      ),
    );
  }
  // --- Shared Elements ---

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
          Icon(icon, color: color, size: 20),
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
                  fontSize: 10,
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
    bool isStatus = false,
    int? count,
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
              color: textMain,
            ),
          ),
          if (isStatus && (count ?? 0) > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: brandAccent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

  Widget _miniActionBtn(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
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
      ),
      child: Row(
        children: [
          Icon(icon, color: textSub, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textMain,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
    );
  }

  Widget _buildNotificationBadge(int count) {
    return Stack(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: textMain.withOpacity(0.06), blurRadius: 10),
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded, size: 22),
        ),
        if (count > 0)
          Positioned(
            right: 12,
            top: 12,
            child: CircleAvatar(radius: 4, backgroundColor: softRed),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          msg,
          style: TextStyle(color: textSub, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  void _showRejectDialog(int index) {
    String? selectedReason;
    final TextEditingController otherController = TextEditingController();
    final List<String> reasons = [
      "Scheduling Conflict",
      "Resource Unavailability",
      "Outside Expertise",
      "Other",
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Crucial for keyboard handling
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 32,
              right: 32,
              // This ensures the bottom sheet moves up when the keyboard opens
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(40),
              ),
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
                  "Decline Directive",
                  style: TextStyle(
                    color: textMain,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),

                // Reason Chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: reasons.map((reason) {
                    bool isSelected = selectedReason == reason;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedReason = reason;
                        });
                      },
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? softRed : surfaceColor,
                          borderRadius: BorderRadius.circular(14),
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

                // THE FIX: Textfield logic
                if (selectedReason == "Other")
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: TextField(
                      controller: otherController,
                      autofocus: true, // Keyboard pops up automatically
                      onChanged: (val) {
                        // Trigger setModalState so the 'Confirm' button enables/disables
                        setModalState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: "Please specify...",
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: textSub)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        // Logic: Button is enabled if a standard reason is picked
                        // OR if "Other" is picked and the text is not empty.
                        onPressed:
                            (selectedReason == null ||
                                (selectedReason == "Other" &&
                                    otherController.text.trim().isEmpty))
                            ? null
                            : () => _rejectTask(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: softRed,
                          disabledBackgroundColor: softRed.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Confirm Decline",
                          style: TextStyle(
                            color: Colors.white,
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
}
