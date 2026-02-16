import 'package:flutter/material.dart';

import 'task_closure_page.dart' show TaskClosurePage;

class TaskDetailsPage extends StatefulWidget {
  final Map<String, dynamic> taskData;

  const TaskDetailsPage({super.key, required this.taskData});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  // Design Tokens
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color destructive = const Color(0xFFF43F5E);
  final Color successColor = const Color(0xFF10B981);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  // OTP State
  // ... inside _TaskDetailsPageState class

  @override
  Widget build(BuildContext context) {
    // Determine the type once for efficiency
    final String type = (widget.taskData['completionType'] ?? "OTP")
        .toUpperCase();
    final bool isApprovalWorkflow = type == "APPROVAL";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildCustomAppBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriorityBadge(isApprovalWorkflow),
                const SizedBox(height: 12),
                _buildHeaderSection(),
                const SizedBox(height: 24),
                _buildVenueSection(), // NEW: Added Venue
                const SizedBox(height: 16),
                _buildTimeFrameSection(),
                const SizedBox(height: 24),
                _buildScoreCard(type),
                const SizedBox(height: 32),
                _buildSectionLabel("Assignment Description"),
                const SizedBox(height: 12),
                _buildDescriptionBox(
                  isApprovalWorkflow,
                ), // UPDATED: Adaptive text
                const SizedBox(height: 32),
                _buildHistoryLogs(),
              ],
            ),
          ),
          _buildFloatingBottomAction(
            isApprovalWorkflow,
          ), // UPDATED: Adaptive button
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textMain,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        "Task Insight",
        style: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.more_horiz_rounded, color: textSub),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- NEW: Venue Section ---
  Widget _buildVenueSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: brandAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ASSIGNED VENUE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: textSub,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.taskData['venue'] ?? "Main Engineering Block, Room 402",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textMain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UPDATED: Adaptive Description ---
  Widget _buildDescriptionBox(bool isApproval) {
    String description = isApproval
        ? "This task requires administrative review. Upon completion, submit your proof or report. Your instructor will then manually approve or reject the submission based on the quality of work."
        : "This task requires a One-Time Password to close. Please enter the code provided by your instructor or sent to your academic dashboard to authorize submission.";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceColor),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 14,
          color: textMain.withOpacity(0.8),
          height: 1.6,
        ),
      ),
    );
  }

  // --- UPDATED: Floating Action Button ---
  Widget _buildFloatingBottomAction(bool isApproval) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withOpacity(0), Colors.white],
          ),
        ),
        child: isApproval
            ? _buildApprovalActions() // New Accept/Reject Layout
            : _buildStandardAction(), // Original End Activity Layout
      ),
    );
  }

  // Layout for Approval Tasks (Accept / Reject)
  Widget _buildApprovalActions() {
    return Row(
      children: [
        // Reject Button
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, "rejected"),
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive.withOpacity(0.9),
              foregroundColor: destructive,
              elevation: 0,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: destructive.withOpacity(0.2)),
              ),
            ),
            child: const Text(
              "Reject",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Accept Button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, "approved"),
            style: ElevatedButton.styleFrom(
              backgroundColor: successColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              "Accept Request",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  // Original Layout for OTP/Standard Tasks
  Widget _buildStandardAction() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskClosurePage(taskData: widget.taskData),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: brandAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        "End Activity",
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    );
  } // --- UPDATED: Badge color based on type ---

  Widget _buildPriorityBadge(bool isApproval) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isApproval ? successColor : destructive).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isApproval ? "MANUAL APPROVAL" : "REQUIRED AUTHENTICATION",
        style: TextStyle(
          color: isApproval ? successColor : destructive,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // Update ScoreCard to accept type
  Widget _buildScoreCard(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brandAccent.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scoreItem("CREDITS", "+50", successColor, Icons.bolt_rounded),
          _scoreItem(
            "PENALTY",
            "-1 / day",
            destructive,
            Icons.history_toggle_off_rounded,
          ),
          _scoreItem(
            "CLOSURE",
            type,
            brandAccent,
            Icons.verified_user_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFrameSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: surfaceColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _timeTile(
            "START DATE",
            widget.taskData['startDate'] ?? "Feb 06, 08:00 AM",
            Icons.calendar_today_rounded,
            brandAccent,
          ),
          Container(
            width: 1,
            height: 30,
            color: surfaceColor,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          _timeTile(
            "DEADLINE",
            widget.taskData['deadline'] ?? "Feb 10, 11:59 PM",
            Icons.alarm_on_rounded,
            destructive,
          ),
        ],
      ),
    );
  }

  Widget _timeTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: textSub,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Hero(
      tag:
          "task_${widget.taskData['title']}", // Must match the tag in FacultyPage
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.taskData['title'] ?? "Peer Review Analysis",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textMain,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(
                    'https://ui-avatars.com/api/?name=Dr+Aris&background=6366F1&color=fff',
                  ),
                ),
                const SizedBox(width: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: textSub, fontSize: 13),
                    children: [
                      const TextSpan(text: "Managed by "),
                      TextSpan(
                        text: "Dr. Aris",
                        style: TextStyle(
                          color: textMain,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreItem(String label, String val, Color col, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: col.withOpacity(0.5), size: 18),
        const SizedBox(height: 6),
        Text(
          val,
          style: TextStyle(
            color: col,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: textSub,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel("Activity Timeline"),
        const SizedBox(height: 16),
        _logEntry("Task assigned to Annish", "Feb 06, 09:00 AM", isFirst: true),
        _logEntry("Identity check initiated", "Feb 06, 11:00 AM", isLast: true),
      ],
    );
  }

  Widget _logEntry(
    String msg,
    String time, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isLast ? brandAccent : textSub.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: surfaceColor)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    msg,
                    style: TextStyle(
                      color: textMain,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(time, style: TextStyle(color: textSub, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: textSub,
        letterSpacing: 1.5,
      ),
    );
  }
}
