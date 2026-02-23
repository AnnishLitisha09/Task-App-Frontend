class DailyReportModel {
  final int reportForUser;
  final String date;
  final int totalTask;
  final int directiveTaskCount;
  final int selfLogCount;
  final List<DailyReportTask> directiveTasks;
  final List<DailyReportTask> selfLogTasks;

  DailyReportModel({
    required this.reportForUser,
    required this.date,
    required this.totalTask,
    required this.directiveTaskCount,
    required this.selfLogCount,
    required this.directiveTasks,
    required this.selfLogTasks,
  });

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    return DailyReportModel(
      reportForUser: json['report_for_user'] ?? 0,
      date: json['date'] ?? '',
      totalTask: json['total_task'] ?? 0,
      directiveTaskCount: json['directive_task_count'] ?? 0,
      selfLogCount: json['self_log_count'] ?? 0,
      directiveTasks:
          (json['directive_tasks'] as List?)
              ?.map((e) => DailyReportTask.fromJson(e))
              .toList() ??
          [],
      selfLogTasks:
          (json['self_log_tasks'] as List?)
              ?.map((e) => DailyReportTask.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DailyReportTask {
  final int taskId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String originType;
  final String status;
  final bool isMandatory;
  final bool isDocument;
  final String score;
  final String penaltyPerHour;
  final int creatorId;
  final List<DailyReportAssignee> assignees;
  final String? venue;
  final DailyReportTime time;

  DailyReportTask({
    required this.taskId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.originType,
    required this.status,
    required this.isMandatory,
    required this.isDocument,
    required this.score,
    required this.penaltyPerHour,
    required this.creatorId,
    required this.assignees,
    this.venue,
    required this.time,
  });

  factory DailyReportTask.fromJson(Map<String, dynamic> json) {
    return DailyReportTask(
      taskId: json['task_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? '',
      originType: json['origin_type'] ?? '',
      status: json['status'] ?? '',
      isMandatory: json['is_mandatory'] ?? false,
      isDocument: json['is_document'] ?? false,
      score: json['score']?.toString() ?? "0.00",
      penaltyPerHour: json['penalty_per_hour']?.toString() ?? "0.00",
      creatorId: json['creator_id'] ?? 0,
      assignees:
          (json['assignees'] as List?)
              ?.map((e) => DailyReportAssignee.fromJson(e))
              .toList() ??
          [],
      venue: json['venue'] is Map
          ? json['venue']['name']?.toString()
          : json['venue']?.toString(),
      time: DailyReportTime.fromJson(json['time'] ?? {}),
    );
  }
}

class DailyReportAssignee {
  final int userId;
  final String status;
  final Map<String, dynamic> details;

  DailyReportAssignee({
    required this.userId,
    required this.status,
    required this.details,
  });

  factory DailyReportAssignee.fromJson(Map<String, dynamic> json) {
    return DailyReportAssignee(
      userId: json['user_id'] ?? 0,
      status: json['status'] ?? '',
      details: json['details'] ?? {},
    );
  }
}

class DailyReportTime {
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String recurrence;

  DailyReportTime({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.recurrence,
  });

  factory DailyReportTime.fromJson(Map<String, dynamic> json) {
    return DailyReportTime(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      recurrence: json['recurrence'] ?? '',
    );
  }
}
