import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/exhaustive_task_model.dart';
import '../../models/task_action_button.dart';
import '../../services/task_service.dart';
import 'user_selection_page.dart';

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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionHeader("Assignees"),
                    if (_exhaustiveData!.assignments.length > 5)
                      TextButton(
                        onPressed: () => _showAllAssignees(_exhaustiveData!.assignments),
                        child: Text(
                          "VIEW ALL",
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
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
        : accent.withOpacity(0.1);
    final Color textColor = status.toLowerCase() == 'active'
        ? Colors.indigo.shade700
        : accent;

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
          child: Column(
            children: [
              if (schedule?.recurrence != null && schedule!.recurrence.toLowerCase() != 'none' && schedule!.recurrence.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.cached_rounded, color: accent, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        "RECURRING: ${schedule!.recurrence.toUpperCase()}",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TIMELINE",
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
                    Container(
                      height: 30,
                      width: 1,
                      color: accent.withOpacity(0.1),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
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
        color: isActive ? accent.withOpacity(0.1) : Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isActive ? accent : Colors.blueGrey.shade700,
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
          _statItem("Accepted", stats.acceptedCount.toString(), accent),
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
    if (assignments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, color: Colors.grey[300], size: 32),
            const SizedBox(height: 8),
            Text(
              "NO ASSIGNEES FOUND",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 85,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: assignments.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          final assignee = assignment.assignee;
          final String initial =
              assignee.name.isNotEmpty ? assignee.name[0].toUpperCase() : '?';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accent.withOpacity(0.1),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignee.name.isNotEmpty ? assignee.name : 'Unknown User',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(assignment.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        assignment.status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(assignment.status),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'completed':
        return accent;
      case 'rejected':
      case 'escalated':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: textLight,
      ),
    );
  }

  void _showAllAssignees(List<Assignment> assignments) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        "ALL ASSIGNEES",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${assignments.length} Total",
                        style: TextStyle(
                          color: textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      final a = assignments[index];
                      final assignee = a.assignee;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgSlate,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: accent.withOpacity(0.1),
                              child: Text(
                                assignee.name.isNotEmpty
                                    ? assignee.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assignee.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    assignee.role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textLight,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(a.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                a.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(a.status),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
                            color: isActive ? accent.withOpacity(0.1) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isActive ? accent : Colors.grey.shade600,
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

    // 4. ASK FOR ASSIGNMENT
    bool? useSelf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Assignment Choice"),
        content: const Text("Who should handle this rescheduled task?"),
        actions: [
          TextButton(
            child: const Text("Me (Self)"),
            onPressed: () => Navigator.pop(ctx, true),
          ),
          ElevatedButton(
            child: const Text("Assign to Others"),
            onPressed: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    );

    if (useSelf == null) return;

    List<int>? pickedAssignees;
    if (!useSelf) {
      // Open UserSelectionPage
      final selectedUsers = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(builder: (_) => const UserSelectionPage()),
      );
      if (selectedUsers == null || selectedUsers.isEmpty) return;
      pickedAssignees = selectedUsers.map((u) => int.parse(u['user_id'].toString())).toList();
    }

    setState(() => _isLoading = true);
    try {
      // Use the extended rescheduling logic with custom assignees
      await _taskService.rescheduleTaskExtended(
        taskId: taskId, 
        newStart: startDT, 
        newEnd: endDT,
        selfAssign: useSelf,
        assigneeIds: pickedAssignees,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(useSelf 
              ? "Task rescheduled and self-assigned successfully!" 
              : "Task rescheduled and assigned successfully!"), 
            backgroundColor: Colors.green
          ),
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
