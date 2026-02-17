import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../../models/task_detail_model.dart';
import '../../services/task_service.dart';
import 'task_closure_page.dart' show TaskClosurePage;

// Activity Lifecycle Status
enum ActivityStatus { NOT_STARTED, IN_PROGRESS, PAUSED, COMPLETED }

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

  // Activity Lifecycle State
  ActivityStatus _activityStatus = ActivityStatus.NOT_STARTED;
  DateTime? _activityStartTime;
  Duration _pausedDuration = Duration.zero;

  TaskDetailModel? _taskDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetail();
  }

  Future<void> _fetchTaskDetail() async {
    try {
      final taskId =
          widget.taskData['task_id']?.toString() ??
          widget.taskData['id']?.toString() ??
          "0"; // Handle various key names
      final service = TaskService();
      final detail = await service.getTaskDetail(taskId);
      if (mounted) {
        setState(() {
          _taskDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine the type once for efficiency
    // Fallback to widget.taskData if _taskDetail is null (though loaded) or use _taskDetail directly
    final String type =
        (_taskDetail?.taskTypes.isNotEmpty == true
                ? _taskDetail!.taskTypes.first.taskName
                : (widget.taskData['completionType'] ?? "OTP"))
            .toUpperCase();

    // Simple logic for approval based on task type or specific flag if available
    final bool isApprovalWorkflow =
        type.contains("APPROVAL") ||
        (_taskDetail?.isApproved == false && _taskDetail?.status == 'Pending');

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
                if (_activityStatus != ActivityStatus.NOT_STARTED) ...[
                  _buildSectionLabel("Activity Log"),
                  const SizedBox(height: 12),
                  _buildActivityLog(),
                  const SizedBox(height: 32),
                ],
                _buildSectionLabel("Assignment Description"),
                const SizedBox(height: 12),
                _buildDescriptionBox(
                  isApprovalWorkflow,
                ), // UPDATED: Adaptive text
                const SizedBox(height: 32),
                _buildCreatorSection(),
                const SizedBox(height: 24),
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
    final venueName =
        _taskDetail?.venue ??
        widget.taskData['venue'] ??
        "Main Engineering Block, Room 402";
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
                venueName,
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

  // --- NEW: Activity Log ---
  Widget _buildActivityLog() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brandAccent.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: brandAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer_outlined, color: brandAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activityStatus == ActivityStatus.COMPLETED
                          ? "TASK COMPLETED"
                          : "CURRENTLY ACTIVE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: textSub,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activityStartTime != null
                          ? "Started at ${DateFormat('jm').format(_activityStartTime!)}"
                          : "Awaiting start...",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_pausedDuration != Duration.zero) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Icon(Icons.pause_circle_outline, color: textSub, size: 18),
                const SizedBox(width: 12),
                Text(
                  "Total Pause: ${_pausedDuration.inMinutes} mins",
                  style: TextStyle(
                    fontSize: 13,
                    color: textSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- UPDATED: Adaptive Description ---
  Widget _buildDescriptionBox(bool isApproval) {
    String description;

    if (isApproval) {
      description =
          "This task requires administrative review. Upon completion, submit your proof or report. Your instructor will then manually approve or reject the submission based on the quality of work.";
    } else {
      List<String> rules = _taskDetail?.closureRules ?? [];
      if (rules.isEmpty) rules = ["otp"]; // Default

      if (rules.contains('photo_upload') && rules.contains('otp')) {
        description =
            "To complete this task, you must upload a proof photo AND enter the One-Time Password provided by your instructor.";
      } else if (rules.contains('photo_upload')) {
        description =
            "To complete this task, you must upload a valid proof photo. Ensure the image is clear and relevant to the task.";
      } else {
        description =
            "This task requires a One-Time Password to close. Please enter the code provided by your instructor or sent to your academic dashboard to authorize submission.";
      }
    }

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

  // Dynamic Layout Based on Activity Status
  Widget _buildStandardAction() {
    // Determine button layout based on activity status
    switch (_activityStatus) {
      case ActivityStatus.NOT_STARTED:
        return _buildSingleButton(
          label: "Start Activity",
          icon: Icons.play_arrow_rounded,
          color: brandAccent,
          onPressed: _startActivity,
        );

      case ActivityStatus.IN_PROGRESS:
        // Show both "End Activity" and optionally "Pause"
        if (_taskDetail?.isPauseAllowed == true) {
          return Row(
            children: [
              Expanded(
                child: _buildSingleButton(
                  label: "Pause",
                  icon: Icons.pause_rounded,
                  color: Colors.orange,
                  onPressed: _pauseActivity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildSingleButton(
                  label: "End Activity",
                  icon: Icons.stop_rounded,
                  color: destructive,
                  onPressed: _endActivity,
                ),
              ),
            ],
          );
        } else {
          return _buildSingleButton(
            label: "End Activity",
            icon: Icons.stop_rounded,
            color: destructive,
            onPressed: _endActivity,
          );
        }

      case ActivityStatus.PAUSED:
        return Row(
          children: [
            Expanded(
              child: _buildSingleButton(
                label: "Resume",
                icon: Icons.play_arrow_rounded,
                color: brandAccent,
                onPressed: _resumeActivity,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildSingleButton(
                label: "End Activity",
                icon: Icons.stop_rounded,
                color: destructive,
                onPressed: _endActivity,
              ),
            ),
          ],
        );

      case ActivityStatus.COMPLETED:
        // Task is completed, show completion message
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: successColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: successColor, size: 28),
              const SizedBox(width: 12),
              Text(
                'Task Completed',
                style: TextStyle(
                  color: successColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  // Helper to build a single button
  Widget _buildSingleButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- UPDATED: Badge color based on type ---

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
          _scoreItem(
            "CREDITS",
            "+${_taskDetail?.score ?? 50}",
            successColor,
            Icons.bolt_rounded,
          ),
          _scoreItem(
            "PENALTY",
            "-${_taskDetail?.penaltyPerHour ?? 1} / hr",
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
    final firstTaskType = _taskDetail?.taskTypes.firstOrNull;
    final String startVal =
        _formatDate(firstTaskType?.startDate, firstTaskType?.startTime) ??
        widget.taskData['startDate'] ??
        "Feb 06, 08:00 AM";

    final String endVal =
        _formatDate(firstTaskType?.endDate, firstTaskType?.endTime) ??
        widget.taskData['deadline'] ??
        "Feb 10, 11:59 PM";

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
            startVal,
            Icons.calendar_today_rounded,
            brandAccent,
          ),
          Container(
            width: 1,
            height: 30,
            color: surfaceColor,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          _timeTile("DEADLINE", endVal, Icons.alarm_on_rounded, destructive),
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
              _taskDetail?.title ??
                  widget.taskData['title'] ??
                  "Peer Review Analysis",
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
                _taskDetail?.creator != null
                    ? CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(
                          'https://ui-avatars.com/api/?name=${_taskDetail!.creator.name.replaceAll(' ', '+')}&background=6366F1&color=fff',
                        ),
                      )
                    : const CircleAvatar(
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
                        text: _taskDetail?.creator.name ?? "Dr. Aris",
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

  Widget _buildCreatorSection() {
    if (_taskDetail?.creator == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: brandAccent.withOpacity(0.1),
            child: Icon(Icons.person, color: brandAccent),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CREATED BY",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: textSub,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _taskDetail!.creator.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textMain,
                ),
              ),
              Text(
                _taskDetail!.creator.email,
                style: TextStyle(fontSize: 12, color: textSub),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _formatDate(String? isoDate, [String? timeStr]) {
    if (isoDate == null) return null;
    try {
      final date = DateTime.parse(isoDate);

      if (timeStr != null && timeStr.isNotEmpty) {
        final timeParts = timeStr.split(':');
        final hours = int.tryParse(timeParts[0]) ?? 0;
        final minutes = int.tryParse(timeParts[1]) ?? 0;
        final combined = DateTime(
          date.year,
          date.month,
          date.day,
          hours,
          minutes,
        );
        return DateFormat('MMM dd, hh:mm a').format(combined);
      }

      return DateFormat('MMM dd, hh:mm a').format(date);
    } catch (e) {
      return isoDate;
    }
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
        _logEntry(
          "Task created",
          _formatDate(_taskDetail?.createdAt) ?? "Feb 06, 09:00 AM",
          isFirst: true,
        ),
        if (_taskDetail?.assignees.isNotEmpty == true)
          _logEntry(
            "Assigned to ${_taskDetail!.assignees.first.name}",
            _formatDate(_taskDetail!.assignees.first.acceptedAt) ??
                "Feb 06, 11:00 AM",
            isLast: true,
          ),
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

  // Activity Lifecycle Methods
  Future<void> _startActivity() async {
    // Check if OTP is required for starting
    List<String> rules = _taskDetail?.closureRules ?? [];

    if (rules.contains('otp')) {
      // Navigate to OTP page to verify before starting
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskClosurePage(
            taskData: {
              ...widget.taskData,
              'closureType': 'otp',
              'actionType': 'start', // Indicate this is for starting
            },
          ),
        ),
      );

      // Only start if OTP was verified successfully
      if (result == true) {
        setState(() {
          _activityStatus = ActivityStatus.IN_PROGRESS;
          _activityStartTime = DateTime.now();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Activity started successfully!'),
              backgroundColor: successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // No OTP required, start directly
      setState(() {
        _activityStatus = ActivityStatus.IN_PROGRESS;
        _activityStartTime = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Activity started!'),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // TODO: Call API to start activity
    // await TaskService().startActivity(_taskDetail!.taskId);
  }

  Future<void> _pauseActivity() async {
    setState(() {
      _activityStatus = ActivityStatus.PAUSED;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Activity paused'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // TODO: Call API to pause activity
  }

  Future<void> _resumeActivity() async {
    setState(() {
      _activityStatus = ActivityStatus.IN_PROGRESS;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Activity resumed'),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // TODO: Call API to resume activity
  }

  Future<void> _endActivity() async {
    // Navigate to closure page based on closure rules
    List<String> rules = _taskDetail?.closureRules ?? [];
    if (rules.isEmpty) rules = ["otp"];

    // Determine which closure page to show
    String closureType = 'otp'; // Default
    if (rules.contains('photo_upload') && !rules.contains('otp')) {
      closureType = 'photo_upload';
    } else if (rules.contains('photo_upload') && rules.contains('otp')) {
      closureType = 'both';
    }

    // Navigate to closure page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskClosurePage(
          taskData: {
            ...widget.taskData,
            'closureType': closureType,
            'actionType': 'end', // Indicate this is for ending
          },
        ),
      ),
    );

    // If closure was successful, mark as completed
    if (result == true) {
      setState(() {
        _activityStatus = ActivityStatus.COMPLETED;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task completed successfully!'),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to dashboard
        Navigator.pop(context);
      }
    }

    // TODO: Call API to end activity
  }
}
