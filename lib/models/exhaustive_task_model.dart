import 'task_action_button.dart';

class ExhaustiveTaskModel {
  final TaskInfo taskInfo;
  final ScheduleInfo? schedule;
  final VenueInfo? venue;
  final List<String> closureMethods;
  final List<int> closureIds;
  final PeopleInfo people;
  final SummaryStats summaryStats;
  final AssignmentStats assignmentStats;
  final List<Assignment> assignments;
  final List<HistoryLog> historyLogs;
  final List<Escalation> escalations;
  final List<dynamic> subTasks;
  final TaskActionButton? actionButton;

  ExhaustiveTaskModel({
    required this.taskInfo,
    this.schedule,
    this.venue,
    required this.closureMethods,
    required this.closureIds,
    required this.people,
    required this.summaryStats,
    required this.assignmentStats,
    required this.assignments,
    required this.historyLogs,
    required this.escalations,
    required this.subTasks,
    this.actionButton,
  });

  factory ExhaustiveTaskModel.fromJson(Map<String, dynamic> json) {
    // assignees can be a Map {grouped, all} or a list directly
    final dynamic rawAssignees = json['assignees'];
    final List<dynamic> assigneeList = (rawAssignees is Map)
        ? (rawAssignees['all'] as List? ?? [])
        : (rawAssignees as List? ?? []);

    return ExhaustiveTaskModel(
      taskInfo: TaskInfo.fromJson(json['task_info'] ?? {}),
      schedule: json['schedule'] != null ? ScheduleInfo.fromJson(json['schedule']) : null,
      venue: json['venue'] != null ? VenueInfo.fromJson(json['venue']) : null,
      closureMethods: List<String>.from(json['closure_methods'] ?? []),
      closureIds: List<int>.from(json['closure_ids'] ?? []),
      people: PeopleInfo.fromJson(json['people'] ?? {}),
      summaryStats: SummaryStats.fromJson(json['summary_stats'] ?? {}),
      assignmentStats: AssignmentStats.fromJson(json['summary_stats'] ?? json['assignment_stats'] ?? {}),
      assignments: assigneeList.map((e) => Assignment.fromJson(e)).toList(),
      historyLogs:
          (json['history_logs'] as List?)
              ?.map((e) => HistoryLog.fromJson(e))
              .toList() ??
          [],
      escalations:
          (json['escalations'] as List?)
              ?.map((e) => Escalation.fromJson(e))
              .toList() ??
          [],
      subTasks: json['sub_tasks'] ?? [],
      actionButton: json['action_button'] != null ? TaskActionButton.fromJson(json['action_button']) : null,
    );
  }
}

class TaskInfo {
  final int taskId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final bool isMandatory;
  final String originType;
  final String score;
  final String penaltyPerHour;
  final String createdAt;

  TaskInfo({
    required this.taskId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.isMandatory,
    required this.originType,
    required this.score,
    required this.penaltyPerHour,
    required this.createdAt,
  });

  factory TaskInfo.fromJson(Map<String, dynamic> json) {
    return TaskInfo(
      taskId: json['task_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? '',
      status: json['status'] ?? '',
      isMandatory: json['is_mandatory'] ?? false,
      originType: json['origin_type'] ?? '',
      score: json['score']?.toString() ?? "0.00",
      penaltyPerHour: json['penalty_per_hour']?.toString() ?? "0.00",
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ScheduleInfo {
  final int id;
  final int taskId;
  final String taskName;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final dynamic timeQuotaHours;
  final int? venueId;
  final String recurrence;
  final String createdAt;
  final String updatedAt;

  ScheduleInfo({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    this.timeQuotaHours,
    this.venueId,
    required this.recurrence,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleInfo.fromJson(Map<String, dynamic> json) {
    return ScheduleInfo(
      id: json['id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      taskName: json['task_name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      timeQuotaHours: json['time_quota_hours'],
      venueId: json['venue_id'],
      recurrence: json['recurrence'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class VenueInfo {
  final int id;
  final String name;

  VenueInfo({required this.id, required this.name});

  factory VenueInfo.fromJson(Map<String, dynamic> json) {
    return VenueInfo(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class PeopleInfo {
  final Actor creator;
  final Actor? approver;

  PeopleInfo({required this.creator, this.approver});

  factory PeopleInfo.fromJson(Map<String, dynamic> json) {
    return PeopleInfo(
      creator: Actor.fromJson(json['creator'] ?? {}),
      approver: json['approver'] != null
          ? Actor.fromJson(json['approver'])
          : null,
    );
  }
}

class Actor {
  final int userId;
  final String role;
  final String name;

  Actor({required this.userId, required this.role, required this.name});

  factory Actor.fromJson(Map<String, dynamic> json) {
    return Actor(
      userId: json['user_id'] ?? 0,
      role: json['role'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class SummaryStats {
  final int assigned;
  final int pending;
  final int accepted;
  final int rejected;
  final int inProgress;
  final int completed;

  SummaryStats({
    required this.assigned,
    required this.pending,
    required this.accepted,
    required this.rejected,
    required this.inProgress,
    required this.completed,
  });

  factory SummaryStats.fromJson(Map<String, dynamic> json) {
    return SummaryStats(
      assigned: json['assigned'] ?? 0,
      pending: json['pending'] ?? 0,
      accepted: json['accepted'] ?? 0,
      rejected: json['rejected'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      completed: json['completed'] ?? 0,
    );
  }
}

class AssignmentStats {
  final int totalCount;
  final int acceptedCount;
  final int rejectedCount;
  final List<String> acceptedNames;
  final List<String> rejectedNames;

  AssignmentStats({
    required this.totalCount,
    required this.acceptedCount,
    required this.rejectedCount,
    required this.acceptedNames,
    required this.rejectedNames,
  });

  factory AssignmentStats.fromJson(Map<String, dynamic> json) {
    return AssignmentStats(
      totalCount: json['total_count'] ?? json['assigned'] ?? 0,
      acceptedCount: json['accepted_count'] ?? json['accepted'] ?? 0,
      rejectedCount: json['rejected_count'] ?? json['rejected'] ?? 0,
      acceptedNames: List<String>.from(json['accepted_names'] ?? []),
      rejectedNames: List<String>.from(json['rejected_names'] ?? []),
    );
  }
}

class Assignment {
  final int assignmentId;
  final Actor assignee;
  final String status;
  final String? reason;
  final String? proofUrl;
  final String? acceptedAt;
  final String? rejectedAt;
  final String? submittedTime;
  final String assignedAt;

  Assignment({
    required this.assignmentId,
    required this.assignee,
    required this.status,
    this.reason,
    this.proofUrl,
    this.acceptedAt,
    this.rejectedAt,
    this.submittedTime,
    required this.assignedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      assignmentId: json['assignment_id'] ?? 0,
      assignee: Actor.fromJson(json['assignee'] ?? {}),
      status: json['status'] ?? '',
      reason: json['reason'],
      proofUrl: json['proof_url'],
      acceptedAt: json['accepted_at'],
      rejectedAt: json['rejected_at'],
      submittedTime: json['submitted_time'],
      assignedAt: json['assigned_at'] ?? '',
    );
  }
}

class HistoryLog {
  final int logId;
  final String action;
  final String details;
  final Actor actor;
  final String timestamp;

  HistoryLog({
    required this.logId,
    required this.action,
    required this.details,
    required this.actor,
    required this.timestamp,
  });

  factory HistoryLog.fromJson(Map<String, dynamic> json) {
    return HistoryLog(
      logId: json['log_id'] ?? 0,
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      actor: Actor.fromJson(json['actor'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class Escalation {
  final int escalationId;
  final String reason;
  final String message;
  final String status;
  final Actor escalatedTo;
  final Actor escalatedAbout;
  final bool isRead;
  final String createdAt;

  Escalation({
    required this.escalationId,
    required this.reason,
    required this.message,
    required this.status,
    required this.escalatedTo,
    required this.escalatedAbout,
    required this.isRead,
    required this.createdAt,
  });

  factory Escalation.fromJson(Map<String, dynamic> json) {
    return Escalation(
      escalationId: json['escalation_id'] ?? 0,
      reason: json['reason'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      escalatedTo: Actor.fromJson(json['escalated_to'] ?? {}),
      escalatedAbout: Actor.fromJson(json['escalated_about'] ?? {}),
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}
