import 'package:flutter/material.dart';
import '../../models/task_action_button.dart';

import 'package:intl/intl.dart';
import '../../models/task_detail_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import 'task_closure_page.dart' show TaskClosurePage;
import '../../models/exhaustive_task_model.dart';
import 'task_otp_page.dart';
import 'user_selection_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../faculty/verify_users_proof_page.dart';
import '../../components/skeleton_loader.dart';

// Activity Lifecycle Status
enum ActivityStatus { NOT_STARTED, IN_PROGRESS, PAUSED, COMPLETED }

class TaskDetailsPage extends StatefulWidget {
  final Map<String, dynamic> taskData;
  final String viewMode; // e.g., 'standard', 'incharge'

  const TaskDetailsPage({
    super.key,
    required this.taskData,
    this.viewMode = 'standard',
  });

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
  bool _isTaskToday = false; // BUG-12 FIX: cached instead of computed on every rebuild

  TaskDetailModel? _taskDetail;
  bool _isLoading = true;
  int? _currentUserId;
  String? _currentUserRole;
  List<dynamic> _activityLogs = [];

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetail(fromInit: true);
  }

  Future<void> _fetchTaskDetail({bool refreshLogs = true, bool fromInit = false}) async {
    if (!fromInit) {
      _hasChanges = true;
    }
    try {
      final taskId =
          widget.taskData['task_id']?.toString() ??
          widget.taskData['id']?.toString() ??
          "0"; // Handle various key names
      final service = TaskService();
      final detail = await service.getTaskDetail(taskId);
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        int? uid = prefs.getInt('userId');
        String? urole = prefs.getString('userRole');

        // Fallback: If missing from prefs, fetch from profile
        if (uid == null || urole == null) {
          try {
            final profile = await UserService().getUserProfile();
            uid = profile.profileData.id;
            urole = profile.role;
            // Save them for next time too
            await prefs.setInt('userId', uid);
            await prefs.setString('userRole', urole);
          } catch (e) {
            debugPrint("Could not fetch fallback profile: $e");
          }
        }

        // Initialize activity status from assignment status
        ActivityStatus status = ActivityStatus.NOT_STARTED;
        DateTime? startTime;
        if (detail.assignees.isNotEmpty) {
          final myAssign = detail.assignees.firstWhere(
            (a) => a.userId == uid,
            orElse: () => detail.assignees.first,
          );

          final s = myAssign.status.toLowerCase();
          if (s == 'in_progress' || s == 'started') {
            status = ActivityStatus.IN_PROGRESS;
            // BUG-08 FIX: acceptedAt is now nullable
            startTime = myAssign.acceptedAt != null ? DateTime.tryParse(myAssign.acceptedAt!) : null;
          } else if (s == 'paused') {
            status = ActivityStatus.PAUSED;
            startTime = myAssign.acceptedAt != null ? DateTime.tryParse(myAssign.acceptedAt!) : null;
          } else if (s == 'completed' || s == 'closed') {
            status = ActivityStatus.COMPLETED;
            startTime = myAssign.acceptedAt != null ? DateTime.tryParse(myAssign.acceptedAt!) : null;
          } else if (s == 'pending') {
            status = ActivityStatus.NOT_STARTED;
          }
        }

        // Only fetch exhaustive details (logs) if explicitly requested
        if (refreshLogs) {
          try {
            final exhaustive = await service.getExhaustiveTaskDetail(int.parse(taskId));
            _activityLogs = exhaustive.historyLogs;
          } catch (e) {
            debugPrint("Could not fetch exhaustive logs: $e");
          }
        }

        // BUG-13 FIX: Normalize role to lowercase on assignment to prevent case mismatch
        setState(() {
          _taskDetail = detail;
          _isLoading = false;
          _currentUserId = uid;
          _currentUserRole = urole?.toLowerCase(); // always lowercase
          _activityStatus = status;
          _activityStartTime = startTime;
          // BUG-12 FIX: compute isTaskToday once here instead of every rebuild
          _isTaskToday = _computeIsTaskToday(detail);
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

  /// BUG-12 FIX: Compute once per data load \u2014 avoids DateTime.parse on every rebuild.
  bool _computeIsTaskToday(TaskDetailModel detail) {
    final taskType = detail.taskTypes.isNotEmpty ? detail.taskTypes.first : null;
    final dateStr = taskType?.startDate ?? widget.taskData['startDate']?.toString();
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final taskDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      return taskDate.year == now.year &&
             taskDate.month == now.month &&
             taskDate.day == now.day;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _hasChanges);
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildCustomAppBar(context),
          body: const TaskDetailSkeleton(),
        ),
      );
    }

    // Determine the type once for efficiency
    // Fallback to widget.taskData if _taskDetail is null (though loaded) or use _taskDetail directly
    final String type =
        (_taskDetail?.taskTypes.isNotEmpty == true
                ? _taskDetail!.taskTypes.first.taskName
                : (widget.taskData['completionType'] ?? "OTP"))
            .toUpperCase();

    // ── Authority Approval: task needs sign-off from HOD/Dean/Principal BEFORE execution ──
    final bool isApprovalWorkflow =
        type.contains("APPROVAL") ||
        (_taskDetail?.isApproved == false &&
            _taskDetail?.status == 'Pending' &&
            _taskDetail?.actionButton?.type == 'approve_task');

    // ── Request (Accept/Reject by the assignee) ──
    final bool isRequest =
        widget.taskData['isRequest'] == true ||
        _taskDetail?.actionButton?.type == 'request';

    // ── Proof Submission Check: manager checking submitted proof docs ──
    // This is DIFFERENT from authority approval. The task is already running/done.
    final bool isSubmissionCheck =
        _taskDetail?.actionButton?.type == 'verify_proof';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildCustomAppBar(context),
        body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 8, 24, widget.viewMode == 'viewonly' ? 24 : 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.viewMode != 'incharge') ...[
                  _buildPriorityBadge(isApprovalWorkflow),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                _buildHeaderSection(),
                const SizedBox(height: 24),
                _buildVenueSection(), // NEW: Added Venue
                const SizedBox(height: 16),
                _buildTimeFrameSection(),
                const SizedBox(height: 24),
                _buildScoreCard(type),
                const SizedBox(height: 32),
                _buildSectionLabel("Activity Log"),
                const SizedBox(height: 12),
                _buildActivityLog(),
                const SizedBox(height: 32),
                _buildSectionLabel("Assignment Description"),
                const SizedBox(height: 12),
                _buildDescriptionBox(
                  isApprovalWorkflow,
                ), // UPDATED: Adaptive text
                const SizedBox(height: 32),
                _buildCreatorSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if ('Standard' != 'NoAction' && widget.viewMode != 'viewonly')
            _buildFloatingBottomAction(
              // Only pass isApproval=true for authority-level approval tasks
              // and for incharge request handling
              (isApprovalWorkflow && !isSubmissionCheck) ||
                  (widget.viewMode == 'incharge' && isRequest),
            ),
        ],
      ),
    ));
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
            onPressed: () => Navigator.pop(context, _hasChanges),
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
        if (_activityStatus != ActivityStatus.COMPLETED &&
            widget.viewMode != 'viewonly' &&
            !['student', 'staff'].contains(_currentUserRole?.toLowerCase()))
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz_rounded, color: textSub),
            onSelected: _handleMenuAction,
            itemBuilder: (context) {
              final bool isPendingProof = widget.taskData['isPendingProof'] == true ||
                  widget.taskData['completionType'] == 'PROOF_SUBMIT';

              if (isPendingProof) {
                return [
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text("Cancel Task", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              }

              return [
                const PopupMenuItem(
                  value: 'transfer',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 20),
                      SizedBox(width: 12),
                      Text("Transfer Task"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text("Cancel Task", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _handleMenuAction(String value) async {
    if (value == 'transfer') {
      _showTransferDialog();
    } else if (value == 'cancel') {
      _showCancelDialog();
    }
  }

  Future<void> _showTransferDialog() async {
    final List<Map<String, dynamic>>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserSelectionPage(
          multiSelect: false,
          allowedRoles: ['faculty', 'student', 'staff'],
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final user = result.first;
      final userId = user['user_id'] ?? user['id'];
      if (userId == null) return;

      final reason = await _showReasonDialog("Transfer Task", "Reason for transferring this task:");
      if (reason != null && reason.isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          await TaskService().transferTask(_taskDetail!.taskId, userId, reason);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Task transferred to ${user['name']}"), backgroundColor: successColor),
            );
            Navigator.pop(context, "transferred");
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            final errorMsg = e.toString().replaceAll('Exception: ', '');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Transfer failed: $errorMsg"), backgroundColor: destructive),
            );
          }
        }
      }
    }
  }

  Future<void> _showCancelDialog() async {
    final reason = await _showReasonDialog("Cancel Task", "Reason for cancelling this task:");
    if (reason != null && reason.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await TaskService().cancelTaskApproval(_taskDetail!.taskId, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text("Task cancelled successfully"), backgroundColor: successColor),
          );
          Navigator.pop(context, "cancelled");
        }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            final errorMsg = e.toString().replaceAll('Exception: ', '');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Cancellation failed: $errorMsg"), backgroundColor: destructive),
            );
          }
        }
    }
  }

  Future<String?> _showReasonDialog(String title, String label) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueSection() {
    final venueName =
        _taskDetail?.venue?['name']?.toString() ??
        widget.taskData['venue']?.toString() ??
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
          Expanded(
            child: Column(
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Icon(Icons.history_rounded, color: brandAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ACTIVITY TIMELINE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: textSub,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activityStatus == ActivityStatus.COMPLETED
                          ? "Task Completed"
                          : _activityStatus == ActivityStatus.PAUSED
                              ? "Currently Paused"
                              : _activityStatus == ActivityStatus.IN_PROGRESS
                                  ? "Currently Active"
                                  : "Awaiting Start",
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
          if (_activityLogs.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            ..._activityLogs.take(3).map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    log is HistoryLog && log.action.toLowerCase().contains('start') ? Icons.play_arrow_rounded :
                    log is HistoryLog && log.action.toLowerCase().contains('pause') ? Icons.pause_rounded :
                    log is HistoryLog && (log.action.toLowerCase().contains('end') || log.action.toLowerCase().contains('close')) ? Icons.stop_rounded : Icons.info_outline,
                    size: 14,
                    color: textSub,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log is HistoryLog ? "${log.action}: ${log.details}" : "Status Update",
                      style: TextStyle(fontSize: 12, color: textMain.withOpacity(0.7)),
                    ),
                  ),
                  Text(
                    log is HistoryLog ? DateFormat('jm').format(DateTime.parse(log.timestamp)) : "",
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
                ],
              ),
            )),
          ] else if (_activityStartTime != null) ...[
             const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Icon(Icons.play_circle_outline, color: textSub, size: 14),
                const SizedBox(width: 8),
                Text(
                  "Started at ${DateFormat('jm').format(_activityStartTime!)}",
                  style: TextStyle(fontSize: 12, color: textMain.withOpacity(0.7)),
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
      child: _buildBottomContent(isApproval),
    );
  }

  Widget _buildBottomContent(bool isApproval) {
    // If the server-side actionButton has a clear type, always trust it first
    // to avoid conflating 'authority approval' with 'proof submission checking'
    final String? actionType = _taskDetail?.actionButton?.type;
    if (actionType != null) {
      // Directly route to the switch-based renderer which cleanly separates all cases
      return _buildStandardAction();
    }

    // Legacy fallback for edge cases where actionButton is null
    if (isApproval) return _buildApprovalActions();

    final List<TaskAssignee> assignees = _taskDetail?.assignees ?? [];
    bool isAssignedToMe = assignees.any(
      (TaskAssignee a) => a.userId == _currentUserId,
    );

    bool isManager =
        _currentUserId != null &&
        (_currentUserId == _taskDetail?.creatorId ||
            (_taskDetail?.facultyId != null &&
                _currentUserId == _taskDetail?.facultyId));

    bool requiresOtp(String role) {
      final r = role.toLowerCase();
      return r == 'student' || r == 'students';
    }

    bool hasOtpUsersAssigned = assignees.any((a) => requiresOtp(a.role));

    if (_activityStatus == ActivityStatus.COMPLETED) {
      return _buildStandardAction();
    }

    // Determine what to show
    bool canExecute = isAssignedToMe || isManager;

    final bool isPendingProof = widget.taskData['isPendingProof'] == true ||
        widget.taskData['completionType'] == 'PROOF_SUBMIT';

    // BUG-12 FIX: Use cached _isTaskToday instead of recomputing every rebuild
    bool canShowOtpManager = isManager && hasOtpUsersAssigned && !isPendingProof && _isTaskToday;

    if (canExecute) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildStandardAction()),
          if (canShowOtpManager) ...[
            const SizedBox(width: 8),
            _buildOtpManagementFloatingButton(),
          ],
        ],
      );
    } else if (canShowOtpManager) {
      // Just a manager - show OTP generation as main primary action
      return _buildGeneratorActions();
    }

    return _buildStandardAction();
  }

  Widget _buildOtpManagementFloatingButton() {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        color: brandAccent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: brandAccent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
        onPressed: _showOtpGenerationModal,
      ),
    );
  }

  void _showOtpGenerationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brandAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: brandAccent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "GENERATE OTP CODES",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildModalActionButton(
                    label: "START OTP",
                    icon: Icons.vpn_key_rounded,
                    color: brandAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _openOtpPage(
                        OtpPageMode.generate,
                        overrideOtpType: 'START',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModalActionButton(
                    label: "END OTP",
                    icon: Icons.verified_rounded,
                    color: brandAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _openOtpPage(
                        OtpPageMode.generate,
                        overrideOtpType: 'END',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratorActions() {
    return _buildSingleButton(
      label: "GENERATE OTP CODES",
      icon: Icons.qr_code_scanner_rounded,
      color: brandAccent,
      onPressed: _showOtpGenerationModal,
    );
  }

  Future<bool?> _openOtpPage(
    OtpPageMode mode, {
    String? overrideOtpType,
  }) async {
    final taskId =
        _taskDetail?.taskId ??
        int.tryParse(
          widget.taskData['id']?.toString() ??
              widget.taskData['task_id']?.toString() ??
              "0",
        ) ??
        0;

    int? assignmentId;
    if (mode == OtpPageMode.verify) {
      final List<TaskAssignee> assignees = _taskDetail?.assignees ?? [];
      if (assignees.isNotEmpty) {
        final myAssignee = assignees.firstWhere(
          (TaskAssignee a) => a.userId == _currentUserId,
          orElse: () => assignees.first,
        );
        assignmentId = myAssignee.assignmentId;
      }

      if (assignmentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No assignment found for this task.")),
        );
        return false;
      }
    }

    final String otpType =
        overrideOtpType ??
        (_activityStatus == ActivityStatus.NOT_STARTED ? 'START' : 'END');

    int? obtainedScore;
    int? penalty;
    if (otpType == 'END') {
      final scores = _calculateScoreAndPenalty();
      obtainedScore = scores['obtainedScore'];
      penalty = scores['penalty'];
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskOtpPage(
          taskId: taskId,
          assignmentId: assignmentId,
          mode: mode,
          otpType: otpType,
          taskTitle: _taskDetail?.title ?? "",
          isDocument: _taskDetail?.isDocument ?? false,
          obtainedScore: obtainedScore,
          penalty: penalty,
        ),
      ),
    );

    if (result == true) {
      // Update local state for both Generator and Verifier on success
      if (otpType == 'START') {
        setState(() {
          _activityStatus = ActivityStatus.IN_PROGRESS;
          _activityStartTime = DateTime.now();
        });
        _fetchTaskDetail(refreshLogs: false); // Fast refresh action buttons only
      } else {
        // Ending activity
        _finalizeCompletionLocally();
      }
    }
    return result;
  }

  void _finalizeCompletionLocally() {
    setState(() {
      _activityStatus = ActivityStatus.COMPLETED;
    });
    _fetchTaskDetail(refreshLogs: false);
    // In End Activity flow, the student might also need to upload proof if required.
    // verifyOTP in END type already marks backend as completed, scores etc.
  }

  // Layout for Approval Tasks (Accept / Reject)
  Widget _buildApprovalActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Reject Button
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () => _handleApprovalAction(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: destructive.withOpacity(0.1),
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
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Accept Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _handleApprovalAction(true),
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
        ),
      ],
    );
  }

  /// Approve the task as the designated higher-authority approver.
  Future<void> _approveTask() async {
    final taskId =
        int.tryParse(
          widget.taskData['task_id']?.toString() ??
              widget.taskData['id']?.toString() ??
              '',
        ) ??
        0;
    if (taskId == 0) return;

    setState(() => _isLoading = true);
    try {
      await TaskService().approveTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task approved successfully!'),
            backgroundColor: Color(0xFF22c55e),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchTaskDetail();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve task: $e')),
        );
      }
    }
  }

  Future<void> _handleApprovalAction(bool approve) async {
    final taskId =
        int.tryParse(
          widget.taskData['task_id']?.toString() ??
              widget.taskData['id']?.toString() ??
              "",
        ) ??
        0;

    if (taskId == 0) return;

    setState(() => _isLoading = true);
    try {
      final service = TaskService();
      if (approve) {
        await service.acceptTask(taskId);
      } else {
        await service.rejectTask(taskId, "Rejected by manager");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? "Task Approved" : "Task Rejected"),
            backgroundColor: approve ? successColor : destructive,
          ),
        );
        Navigator.pop(context, approve ? "approved" : "rejected");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: destructive),
        );
      }
    }
  }

  // Dynamic Layout Based on Activity Status
  Widget _buildStandardAction() {
    // Fallback or additional actions like "Can't Finish?"
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_activityStatus == ActivityStatus.IN_PROGRESS ||
            _activityStatus == ActivityStatus.PAUSED)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: _rejectTaskByUser,
              icon: Icon(
                Icons.report_problem_outlined,
                size: 16,
                color: destructive,
              ),
              label: Text(
                "CANNOT COMPLETE TASK",
                style: TextStyle(
                  color: destructive,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        _buildActualActionButtons(),
      ],
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: successColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: successColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Task Completed',
            style: TextStyle(
              color: successColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActualActionButtons() {
    final TaskActionButton? actionButton = _taskDetail?.actionButton;

    if (actionButton == null) {
      return const SizedBox.shrink();
    }

    switch (actionButton.type) {
      // ── Accept / Reject (pending assignment) ──────────────────────────────
      case 'request':
        return _buildApprovalActions();

      // ── Approve Task (designated authority approver) ───────────────────────
      case 'approve_task':
        return _buildSingleButton(
          label: 'Approve Task',
          icon: Icons.verified_rounded,
          color: successColor,
          onPressed: _approveTask,
        );

      // ── Review Proof Submissions (manager views submitted docs) ────────────
      case 'verify_proof':
        return _buildSingleButton(
          label: actionButton.label,
          icon: Icons.fact_check_rounded,
          color: brandAccent,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                 builder: (_) => VerifyUsersProofPage(
                  taskId: _taskDetail!.taskId,
                  taskTitle: _taskDetail!.title,
                ),
              ),
            );
            if (result == 'refreshed' || result == true) {
              _fetchTaskDetail();
            }
          },
        );

      // ── Execute Directive (escalated/managed task) ────────────────────────────────
      case 'manage':
      case 'escalated':
        return _buildEscalatedActions();

      // ── Submit Proof (accepted, awaiting proof upload) ────────────────────
      case 'pending_proof':
        return _buildSingleButton(
          label: actionButton.label,
          icon: Icons.upload_file_rounded,
          color: Colors.orange,
          onPressed: _submitPendingProof,
        );

      // ── Generate OTP ──────────────────────────────────────────────────────
      case 'generate_otp':
        return _buildSingleButton(
          label: actionButton.label,
          icon: Icons.vpn_key_rounded,
          color: brandAccent,
          onPressed: _showOtpDialog,
        );

      // ── Activity Lifecycle ────────────────────────────────────────────────
      case 'activity':
        // State badges (no action button)
        if (actionButton.action == 'missed') return _buildMissedBadge();
        if (actionButton.action == 'too_early') return _buildPendingStartBadge();
        if (actionButton.action == 'completed') return _buildCompletedBadge();

        // ── Long task: Pause/Resume + End/Submit (2 buttons) ─────────────────
        if (actionButton.action == 'pause' || actionButton.action == 'resume') {
          final bool isProofTask = _taskDetail?.isDocument == true ||
              (_taskDetail?.closureRules.contains('photo_upload') ?? false);
          final bool requiresOtp = _taskDetail?.closureRules.contains('otp') ?? false;

          // Split buttons for long tasks too
          final bool isFastTrackAction = _currentUserRole?.toLowerCase() == 'faculty' || _currentUserRole?.toLowerCase() == 'staff';
          
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSingleButton(
                  label: actionButton.action == 'pause' ? 'Pause' : 'Resume',
                  icon: actionButton.action == 'pause'
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: actionButton.action == 'pause' ? Colors.orange : brandAccent,
                  onPressed:
                      actionButton.action == 'pause' ? _pauseActivity : _resumeActivity,
                ),
              ),
              const SizedBox(width: 8),
              if (isProofTask) ...[
                Expanded(
                  flex: 3,
                  child: _buildSingleButton(
                    label: 'Submit Proof',
                    icon: Icons.upload_file_rounded,
                    color: Colors.blue,
                    onPressed: (requiresOtp && !isFastTrackAction) ? () => _openOtpPage(OtpPageMode.verify, overrideOtpType: 'END') : _endActivity,
                  ),
                ),
                const SizedBox(width: 8),
                _buildSecondaryButton(
                  label: 'End',
                  icon: Icons.stop_rounded,
                  color: brandAccent,
                  onPressed: (requiresOtp && !isFastTrackAction) ? () => _openOtpPage(OtpPageMode.verify, overrideOtpType: 'END') : _endActivity,
                ),
              ] else ...[
                Expanded(
                  flex: 3,
                  child: _buildSingleButton(
                    label: 'End Activity',
                    icon: Icons.stop_rounded,
                    color: brandAccent,
                    onPressed: (requiresOtp && !isFastTrackAction) ? () => _openOtpPage(OtpPageMode.verify, overrideOtpType: 'END') : _endActivity,
                  ),
                ),
              ],
            ],
          );
        }

        // ── OTP Tasks: Start & End ───────────────────────────────────────────
        if (actionButton.action == 'start_otp') {
          final bool isFastTrackAction = _currentUserRole?.toLowerCase() == 'faculty' || _currentUserRole?.toLowerCase() == 'staff';
          return _buildSingleButton(
            label: isFastTrackAction ? 'Start Activity' : actionButton.label,
            icon: isFastTrackAction ? Icons.play_arrow_rounded : Icons.vpn_key_rounded,
            color: brandAccent,
            onPressed: isFastTrackAction ? _startActivity : () => _openOtpPage(OtpPageMode.verify, overrideOtpType: 'START'),
          );
        }
        
        if (actionButton.action == 'end_otp') {
          final bool isFastTrackAction = _currentUserRole?.toLowerCase() == 'faculty' || _currentUserRole?.toLowerCase() == 'staff';
          final bool isProofTask = actionButton.label.contains('Submit Proof') || _taskDetail?.isDocument == true;
          
          if (isProofTask) {
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildSingleButton(
                      label: 'Submit Proof',
                      icon: Icons.upload_file_rounded,
                      color: Colors.blue,
                      onPressed: isFastTrackAction ? _endActivity : () => _openOtpPage(OtpPageMode.verify, overrideOtpType: 'END'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSecondaryButton(
                    label: 'End',
                    icon: Icons.verified_rounded,
                    color: brandAccent,
                    onPressed: isFastTrackAction ? _endActivity : () => _openOtpPage(OtpPageMode.verify, overrideOtpType: 'END'),
                  ),
                ],
              );
          }
           
          return _buildSingleButton(
            label: isFastTrackAction ? 'End Activity' : actionButton.label,
            icon: isFastTrackAction ? Icons.stop_rounded : Icons.verified_rounded,
            color: brandAccent,
            onPressed: isFastTrackAction ? _endActivity : () => _openOtpPage(OtpPageMode.verify, overrideOtpType: 'END'),
          );
        }

        // ── Regular in_progress + proof: single combined button ───────────────
        if (actionButton.action == 'submit_proof') {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSingleButton(
                  label: 'Submit Proof',
                  icon: Icons.upload_file_rounded,
                  color: Colors.blue,
                  onPressed: _endActivity,
                ),
              ),
              const SizedBox(width: 8),
              _buildSecondaryButton(
                label: 'End',
                icon: Icons.stop_rounded,
                color: brandAccent,
                onPressed: _endActivity,
              ),
            ],
          );
        }

        // ── Regular in_progress + no proof: single end button ────────────────
        if (actionButton.action == 'end') {
          return _buildSingleButton(
            label: 'End Activity',
            icon: Icons.stop_rounded,
            color: brandAccent,
            onPressed: _endActivity,
          );
        }

        // ── Start Activity ───────────────────────────────────────────────────
        return _buildSingleButton(
          label: actionButton.label,
          icon: Icons.play_arrow_rounded,
          color: brandAccent,
          onPressed: _startActivity,
        );

      default:
        return const SizedBox.shrink();
    }
  }




  Widget _buildSecondaryButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? label,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        minimumSize: const Size(64, 64),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: color.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ],
      ),
    );
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
    final bool isPendingProof = widget.taskData['isPendingProof'] == true ||
        widget.taskData['completionType'] == 'PROOF_SUBMIT';

    String label = isApproval ? "MANUAL APPROVAL" : "REQUIRED AUTHENTICATION";
    Color color = isApproval ? successColor : destructive;

    if (isPendingProof) {
      label = "PROOF SUBMISSION PENDING";
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
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

    final role = _currentUserRole?.toLowerCase() ?? '';
    final bool isStudent = role == 'student';
    // Students ALWAYS need OTP for starting (as per new objective)
    if (isStudent) {
      // Use the new TaskOtpPage for Start Activity Verification
      await _openOtpPage(OtpPageMode.verify);
    } else {
      // No OTP required, start directly
      try {
        await TaskService().startActivity(_taskDetail!.taskId);
        
        setState(() {
          _activityStatus = ActivityStatus.IN_PROGRESS;
          _activityStartTime = DateTime.now();
        });
        _fetchTaskDetail(refreshLogs: false); // Fast refresh action buttons only

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Activity started!'),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pauseActivity() async {
    try {
      await TaskService().pauseTask(_taskDetail!.taskId);
      setState(() {
        _activityStatus = ActivityStatus.PAUSED;
      });
      _fetchTaskDetail(refreshLogs: false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Activity paused'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pause: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resumeActivity() async {
    try {
      await TaskService().resumeTask(_taskDetail!.taskId);
      setState(() {
        _activityStatus = ActivityStatus.IN_PROGRESS;
      });
      _fetchTaskDetail(refreshLogs: false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Activity resumed'),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resume: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Opens the proof upload page directly for tasks where the activity was
  /// already completed but the document/proof hasn't been submitted yet.
  Future<void> _submitPendingProof() async {
    final taskId = _taskDetail?.taskId ?? 
        int.tryParse(widget.taskData['task_id']?.toString() ?? '') ?? 0;
    final assignmentId = widget.taskData['assignment_id'];

    if (taskId == 0) return;

    final scores = _calculateScoreAndPenalty();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskClosurePage(
          taskData: {
            ...widget.taskData,
            'task_id': taskId,
            if (assignmentId != null) 'assignment_id': assignmentId,
            'closureType': 'proof', // proof-only mode (no OTP step)
            'actionType': 'proof_submit',
            'isPendingProof': true,
            'isDocument': _taskDetail?.isDocument == true,
            'obtainedScore': scores['obtainedScore'],
            'penalty': scores['penalty'],
          },
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Proof submitted successfully!'),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchTaskDetail(refreshLogs: true);
    }
  }

  Future<void> _endActivity() async {
    List<String> rules = _taskDetail?.closureRules ?? [];
    if (rules.isEmpty) rules = ["otp"];
    
    final role = _currentUserRole?.toLowerCase() ?? '';
    bool needsOtp = role == 'student'; // Staff and Faculty do NOT need OTP for verification
    
    // STEP 1: Verify OTP if required
    if (needsOtp && rules.contains('otp')) {
      final verified = await _openOtpPage(OtpPageMode.verify);
      if (verified != true) return; // Stop if OTP failed
      
      // If student and task requires document, TaskOtpPage already handled it.
      if (_taskDetail?.isDocument == true) {
        return; // Already finalized in _openOtpPage -> _finalizeCompletionLocally
      }
    }

    // STEP 2: Proof Upload if required (For non-OTP flow, or faculty/staff)
    if (rules.contains('photo_upload') || _taskDetail?.isDocument == true) {
      final scores = _calculateScoreAndPenalty();
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskClosurePage(
            taskData: {
              ...widget.taskData,
              'task_id': _taskDetail?.taskId,
              'closureType': 'proof',
              'actionType': 'end',
              'isDocument': _taskDetail?.isDocument == true,
              'obtainedScore': scores['obtainedScore'],
              'penalty': scores['penalty'],
            },
          ),
        ),
      );

      if (result == true) {
        _finalizeCompletionLocally();
      }
    } else {
      // If no proof required AND No OTP was done (or we are faculty/staff and no rules applied), close via API
      if (!needsOtp || !rules.contains('otp')) {
         _finalizeTaskWithoutOtp();
      }
    }
  }

  Future<void> _finalizeTaskWithoutOtp() async {
    final taskId = _taskDetail?.taskId ?? 0;
    if (taskId == 0) return;

    final scores = _calculateScoreAndPenalty();

    setState(() => _isLoading = true);
    try {
      await TaskService().submitTaskProofFallback(
        taskId, 
        obtainedScore: scores['obtainedScore'],
        penalty: scores['penalty'],
      );
      _finalizeCompletionLocally();
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, int> _calculateScoreAndPenalty() {
    final int baseScore = _taskDetail?.score ?? 0;
    final int penaltyPerHour = _taskDetail?.penaltyPerHour ?? 0;

    final String? deadlineStr = _taskDetail?.taskTypes.firstOrNull?.endDate;
    final String? endTimeStr = _taskDetail?.taskTypes.firstOrNull?.endTime;

    DateTime? deadline;
    if (deadlineStr != null && deadlineStr.isNotEmpty) {
      deadline = DateTime.tryParse(deadlineStr);
      if (deadline != null && endTimeStr != null && endTimeStr.isNotEmpty) {
        final timeParts = endTimeStr.split(':');
        final hours = int.tryParse(timeParts[0]) ?? 0;
        final minutes = int.tryParse(timeParts[1]) ?? 0;
        deadline = DateTime(deadline.year, deadline.month, deadline.day, hours, minutes);
      }
    } else {
      // Fallback
      if (widget.taskData['deadline'] != null) {
        // Try to parse if it's an ISO string or similar, usually it's formatted though.
        deadline = DateTime.tryParse(widget.taskData['deadline']);
      }
    }

    int penalty = 0;
    int obtainedScore = baseScore;

    if (deadline != null) {
      final now = DateTime.now();
      if (now.isAfter(deadline)) {
        final hoursLate = now.difference(deadline).inHours;
        if (hoursLate > 0) {
          penalty = hoursLate * penaltyPerHour;
          obtainedScore = baseScore - penalty;
          if (obtainedScore < 0) obtainedScore = 0;
        }
      }
    }

    return {'obtainedScore': obtainedScore, 'penalty': penalty};
  }

  Future<void> _rejectTaskByUser() async {
    final TextEditingController reasonController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Cannot Finish?",
          style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please state the reason for rejecting/halting this task.",
              style: TextStyle(color: textSub, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 3,
              style: TextStyle(
                fontSize: 14,
                color: textMain,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: "Reason (e.g., Equipment damaged...)",
                hintStyle: TextStyle(color: textSub.withOpacity(0.5)),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Submit",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final taskId =
            int.tryParse(
              widget.taskData['task_id']?.toString() ??
                  widget.taskData['id']?.toString() ??
                  "",
            ) ??
            0;
        await TaskService().closeTask(
          taskId,
          isCompleted: false,
          reason: reasonController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Task marked as failed/rejected"),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, "rejected");
        }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            final errorMsg = e.toString().replaceAll('Exception: ', '');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: destructive),
            );
          }
        }
    }
  }
  Widget _buildEscalatedActions() {
    final label = _taskDetail?.actionButton?.label ?? "Execute Directive";
    return _buildSingleButton(
      label: label,
      icon: Icons.bolt_rounded,
      color: brandAccent,
      onPressed: _showEscalationManagementDialog,
    );
  }

  Future<void> _showEscalationManagementDialog() async {
    final taskId = _taskDetail?.taskId ??
        int.tryParse(widget.taskData['task_id']?.toString() ?? '') ??
        0;
    if (taskId == 0) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Escalation Management",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              "This task has been escalated. Choose how to proceed.",
              style: TextStyle(color: textSub, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _mgmtOption(
              "Self-Assign & Execute",
              "Take responsibility and start working on it now.",
              Icons.person_add_rounded,
              brandAccent,
              () {
                Navigator.pop(context);
                _handleExecuteDirective();
              },
            ),
            const SizedBox(height: 12),
            _mgmtOption(
              "Transfer Task",
              "Assign this task to someone else.",
              Icons.swap_horiz_rounded,
              Colors.blue,
              () async {
                Navigator.pop(context);
                final List<Map<String, dynamic>>? selected = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserSelectionPage(multiSelect: false)),
                );
                if (selected != null && selected.isNotEmpty) {
                  _transferTask(taskId, selected.first['user_id']);
                }
              },
            ),
            const SizedBox(height: 12),
            _mgmtOption(
              "Reschedule",
              "Change the date and time for this task.",
              Icons.event_repeat_rounded,
              Colors.orange,
              () {
                Navigator.pop(context);
                _showRescheduleDialog(taskId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _mgmtOption(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(sub, style: TextStyle(color: textSub, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSub),
          ],
        ),
      ),
    );
  }

  bool _isTaskInPast() {
    final type = _taskDetail?.taskTypes.firstOrNull;
    if (type == null) return false;

    // Model guarantees non-null strings (defaults to empty)
    final dateStr = type.endDate.isNotEmpty ? type.endDate : type.startDate;
    final timeStr = type.endTime.isNotEmpty ? type.endTime : type.startTime;

    if (dateStr.isEmpty) return false;

    DateTime? dt = DateTime.tryParse(dateStr);
    if (dt == null) return false;

    if (timeStr.isNotEmpty) {
      final parts = timeStr.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 59;
      dt = DateTime(dt.year, dt.month, dt.day, h, m);
    } else {
      dt = DateTime(dt.year, dt.month, dt.day, 23, 59);
    }

    return dt.isBefore(DateTime.now());
  }

  Future<void> _transferTask(int taskId, int targetUserId) async {
    // --- NEW: Escalation Timing Logic ---
    final bool isEscalated = (_taskDetail?.actionButton?.type == 'escalated') ||
        (widget.taskData['status']?.toString().toLowerCase() == 'escalated') ||
        (widget.taskData['is_escalate'] == true);

    if (isEscalated && _isTaskInPast()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Escalated tasks must be rescheduled to a future time before assignment."),
          backgroundColor: Colors.orange,
        ),
      );
      _showRescheduleDialog(taskId);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await TaskService().transferTask(taskId, targetUserId, "Escalation resolution transfer");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Task transferred successfully!"), backgroundColor: successColor),
        );
        _fetchTaskDetail(); // Full refresh — task owner changed, logs matter
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: destructive),
        );
      }
    }
  }

  Future<void> _showRescheduleDialog(int taskId) async {
    // 1. Pick new start date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: "SET NEW START DATE",
    );
    if (pickedDate == null) return;

    // 2. Pick new start time
    TimeOfDay? startT = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: "SET NEW START TIME",
    );
    if (startT == null) return;

    // 3. Pick new end time (on the same day)
    TimeOfDay? endT = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (startT.hour + 2) % 24, minute: startT.minute),
      helpText: "SET NEW END TIME (SAME DAY)",
    );
    if (endT == null) return;

    final startDT = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, startT.hour, startT.minute);
    final endDT = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, endT.hour, endT.minute);

    if (startDT.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Start time must be in the future!"), backgroundColor: Colors.orange),
      );
      return;
    }

    if (endDT.isBefore(startDT)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time!"), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await TaskService().rescheduleTaskExtended(
        taskId: taskId, 
        newStart: startDT, 
        newEnd: endDT,
        selfAssign: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Task rescheduled successfully!"), backgroundColor: successColor),
        );
        _fetchTaskDetail(); // Full refresh — schedule changed, logs matter
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: destructive),
        );
      }
    }
  }

  Future<void> _showOtpDialog() async {
    final taskId = _taskDetail?.taskId ??
        int.tryParse(widget.taskData['task_id']?.toString() ?? '') ??
        0;
    if (taskId == 0) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Generate OTP"),
        content: const Text("Would you like to generate a START or END OTP?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _generateOtp(taskId, "START");
            },
            child: const Text("START OTP"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _generateOtp(taskId, "END");
            },
            child: const Text("END OTP"),
          ),
        ],
      ),
    );
  }

  Future<void> _generateOtp(int taskId, String type) async {
    setState(() => _isLoading = true);
    try {
      final result = await TaskService().generateOTP(taskId, type);
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("$type OTP Generated"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Share this code with the assignee:"),
                const SizedBox(height: 16),
                Text(
                  result['otp'].toString(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
                ),
                const SizedBox(height: 8),
                Text("Expires in ${result['expires_in']}", style: TextStyle(color: textSub)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: destructive),
        );
      }
    }
  }

  Future<void> _handleExecuteDirective() async {
    final taskId = _taskDetail?.taskId ??
        int.tryParse(widget.taskData['task_id']?.toString() ?? '') ??
        0;
    if (taskId == 0) return;

    // --- NEW: Escalation Timing Logic ---
    if (_isTaskInPast()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Escalated tasks must be rescheduled to a future time before execution."),
          backgroundColor: Colors.orange,
        ),
      );
      _showRescheduleDialog(taskId);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await TaskService().selfAssignTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Task self-assigned successfully!"),
            backgroundColor: successColor,
          ),
        );
        // Refresh detail
        _fetchTaskDetail(); // Full refresh — new assignment, logs matter
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: destructive),
        );
      }
    }
  }

  Widget _buildMissedBadge() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: destructive.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: destructive.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: destructive, size: 24),
          const SizedBox(width: 12),
          Text(
            "Activity Missed",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: destructive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStartBadge() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: brandAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brandAccent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded, color: brandAccent, size: 24),
          const SizedBox(width: 12),
          Text(
            "Start Time Still Yet",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: brandAccent,
            ),
          ),
        ],
      ),
    );
  }
}
