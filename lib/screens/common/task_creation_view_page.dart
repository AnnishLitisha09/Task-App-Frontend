import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/exhaustive_task_model.dart';
import '../../models/task_action_button.dart';
import '../../services/task_service.dart';

class TaskViewPage extends StatefulWidget {
  final Map<String, dynamic> taskData;

  const TaskViewPage({super.key, required this.taskData});

  @override
  State<TaskViewPage> createState() => _TaskViewPageState();
}

class _TaskViewPageState extends State<TaskViewPage> {
  final TaskService _taskService = TaskService();
  ExhaustiveTaskModel? _exhaustiveData;
  bool _isLoading = true;
  String? _error;

  final Color accent = const Color(0xFF6366F1);
  final Color bgSlate = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF0F172A);
  final Color textLight = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final taskId = widget.taskData['task_id'] ?? widget.taskData['taskId'] ?? widget.taskData['id'];
      if (taskId == null) throw Exception("Task ID is missing");

      final data = await _taskService.getExhaustiveTaskDetail(
        taskId is int ? taskId : int.parse(taskId.toString()),
      );

      if (mounted) {
        setState(() {
          _exhaustiveData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      appBar: AppBar(
        title: Text(
          _exhaustiveData?.taskInfo.title ?? "Directive Details",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _fetchDetails();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchDetails();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final task = _exhaustiveData!.taskInfo;
    final stats = _exhaustiveData!.assignmentStats;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildStatusBanner(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(task),
                const SizedBox(height: 32),

                _buildStatsGrid(stats),
                const SizedBox(height: 32),

                _sectionHeader("Execution Proof"),
                _buildProofGrid(_exhaustiveData!.closureMethods),
                const SizedBox(height: 32),

                _sectionHeader("Assignees"),
                _buildAssigneeList(_exhaustiveData!.assignments),
                const SizedBox(height: 32),

                if (_exhaustiveData!.subTasks.isNotEmpty) ...[
                  _sectionHeader("Package Sub-Tasks"),
                  _buildSubTasksList(_exhaustiveData!.subTasks),
                  const SizedBox(height: 32),
                ],

                _sectionHeader("History & Timeline"),
                _buildHistoryTimeline(_exhaustiveData!.historyLogs),
                const SizedBox(height: 32),

                if (_exhaustiveData!.escalations.isNotEmpty) ...[
                  _sectionHeader("System Escalations"),
                  _buildEscalationList(_exhaustiveData!.escalations),
                  const SizedBox(height: 32),
                ],

                _sectionHeader("Governance"),
                _buildGovernanceCard(_exhaustiveData!.people),
                const SizedBox(height: 40),

                _buildActionButton(task.status),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _exhaustiveData!.taskInfo.status;
    final Color bannerColor = status.toLowerCase() == 'active'
        ? Colors.indigo.shade50
        : Colors.green.shade50;
    final Color textColor = status.toLowerCase() == 'active'
        ? Colors.indigo.shade700
        : Colors.green.shade700;

    return Container(
      width: double.infinity,
      color: bannerColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: textColor, size: 20),
          const SizedBox(width: 12),
          Text(
            "TASK STATUS: ${status.toUpperCase()}",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(TaskInfo task) {
    final schedule = _exhaustiveData!.schedule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            _statusChip(task.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          task.description,
          style: TextStyle(color: textLight, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Schedule Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SCHEDULE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      schedule != null
                          ? "${DateFormat('MMM dd').format(DateTime.parse(schedule.startDate))} • ${schedule.startTime} - ${schedule.endTime}"
                          : "No schedule set",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_exhaustiveData!.venue != null) ...[
                const VerticalDivider(),
                Icon(Icons.location_on_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  _exhaustiveData!.venue!.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _priorityBadge(task.priority),
            const SizedBox(width: 12),
            Icon(Icons.category_outlined, size: 14, color: textLight),
            const SizedBox(width: 4),
            Text(
              task.category,
              style: TextStyle(
                color: textLight,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    bool isActive =
        status.toLowerCase() == 'active' || status.toLowerCase() == 'accepted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.blueGrey.shade700,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AssignmentStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Total", stats.totalCount.toString(), Colors.blue),
          _statItem("Accepted", stats.acceptedCount.toString(), Colors.green),
          _statItem("Rejected", stats.rejectedCount.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: textLight,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildProofGrid(List<String> methods) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: methods.isEmpty
            ? [const Text("No specific methods defined")]
            : methods.map((m) => _proofMethodRow(m)).toList(),
      ),
    );
  }

  Widget _proofMethodRow(String method) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.qr_code_scanner, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            method.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: textDark,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            "VERIFIED BY SYSTEM",
            style: TextStyle(
              color: textLight,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneeList(List<Assignment> assignments) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: assignments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          final assignee = assignment.assignee;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withOpacity(0.1),
                  child: Text(
                    assignee.name[0],
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignee.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      assignment.status.toUpperCase(),
                      style: TextStyle(
                        color: assignment.status.toLowerCase() == 'escalated'
                            ? Colors.red
                            : (assignment.status.toLowerCase() == 'accepted'
                                  ? Colors.green
                                  : Colors.orange),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTimeline(List<HistoryLog> logs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 2,
                  height: 10,
                  color: index == 0 ? Colors.transparent : Colors.grey.shade300,
                ),
                Icon(Icons.circle, size: 8, color: accent),
                Container(
                  width: 2,
                  height: 10,
                  color: index == logs.length - 1
                      ? Colors.transparent
                      : Colors.grey.shade300,
                ),
              ],
            ),
            title: Text(
              log.details,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${DateFormat('MMM d, hh:mm a').format(DateTime.parse(log.timestamp))} • ${log.actor.name}",
              style: TextStyle(fontSize: 11, color: textLight),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEscalationList(List<Escalation> escalations) {
    return Column(
      children: escalations
          .map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.reason,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          e.message,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGovernanceCard(PeopleInfo people) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _governanceRow(
            "Creator",
            people.creator.name,
            people.creator.role,
            Icons.person_outline,
          ),
          if (people.approver != null) ...[
            const Divider(height: 32),
            _governanceRow(
              "Approver",
              people.approver!.name,
              people.approver!.role,
              Icons.verified_user_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _governanceRow(String label, String name, String role, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: textLight,
              ),
            ),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              role.toUpperCase(),
              style: TextStyle(fontSize: 9, color: textLight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String status) {
    final TaskActionButton? actionButton = _exhaustiveData?.actionButton;
    if (actionButton == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () => _handleTaskManagement(
                  isDirective: actionButton.type == 'escalated',
                  forceReschedule: actionButton.action == 'reschedule',
                ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(
                actionButton.label.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: textLight,
        ),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final color = priority.toLowerCase() == 'high'
        ? Colors.red
        : (priority.toLowerCase() == 'medium' ? Colors.orange : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildSubTasksList(List<dynamic> subTasks) {
    return Column(
      children: subTasks.map((t) {
        final title = t['title'] ?? t['task_name'] ?? 'Sub-task';
        final desc = t['description'] ?? '';
        final status = (t['status'] ?? 'Inactive').toString().toUpperCase();
        
        final bool isActive = status == 'ACTIVE' || status == 'IN_PROGRESS';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? accent.withOpacity(0.3) : Colors.grey.shade100,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.play_circle_fill_rounded : Icons.lock_outline_rounded, 
                color: isActive ? accent : Colors.grey.shade300
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(desc, style: TextStyle(color: textLight, fontSize: 12, height: 1.3)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isTaskExpired() {
    if (_exhaustiveData?.schedule == null) return false;
    try {
      final schedule = _exhaustiveData!.schedule!;
      final dateStr = schedule.endDate.split('T')[0]; // Handle T00:00:00.000Z
      final timeStr = schedule.endTime;

      // Extract hours and minutes from "HH:mm:ss" or "HH:mm"
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final deadline = DateTime.parse(dateStr).add(Duration(hours: hour, minutes: minute));
      return DateTime.now().isAfter(deadline);
    } catch (e) {
      debugPrint("Error checking expiry: $e");
      return false;
    }
  }

  Future<void> _handleTaskManagement({required bool isDirective, bool forceReschedule = false}) async {
    final taskId = _exhaustiveData?.taskInfo.taskId ??
        int.tryParse(widget.taskData['task_id']?.toString() ?? widget.taskData['id']?.toString() ?? '') ??
        0;
    if (taskId == 0) return;

    if (forceReschedule || _isTaskExpired()) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Task Expired"),
          content: const Text("This task's scheduled time has passed. Would you like to reschedule it for yourself and execute?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Reschedule")),
          ],
        ),
      );

      if (confirm == true) {
        if (!mounted) return;
        await _showRescheduleDialog(taskId);
      }
      return;
    }

    // Direct self-assign if not expired
    setState(() => _isLoading = true);
    await _selfAssign(taskId);
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
      // Use the extended rescheduling logic which includes self-assignment
      await _taskService.rescheduleTaskExtended(
        taskId: taskId, 
        newStart: startDT, 
        newEnd: endDT,
        selfAssign: true,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task rescheduled and self-assigned successfully!"), backgroundColor: Colors.green),
        );
        _fetchDetails();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _selfAssign(int taskId) async {
    try {
      await _taskService.selfAssignTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task self-assigned successfully!"), backgroundColor: Colors.green),
        );
        _fetchDetails();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
  }
}
