class TaskDetailModel {
  final int taskId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final int score;
  final int penaltyPerHour;
  final bool isPackage;
  final bool isPauseAllowed;
  final bool isDocument;
  final bool isMandatory;
  final bool isApproved;
  final bool isFaculty;
  final bool isDeleted;
  final bool isEscalate;
  final int? venueId;
  final int? resourceId;
  final int creatorId;
  final int? approverId;
  final int? facultyId;
  final TaskCreator creator;
  final dynamic approver;
  final dynamic faculty;
  final String?
  venue; // Changed from dynamic/null to String? based on usage in UI, though API returns null or object usually. Let's assume name or object. API says "venue": null. Let's make it dynamic or a class. UI expects string. Ideally backend sends object. Let's make it map safely.
  final dynamic resource;
  final List<TaskType> taskTypes;
  final List<TaskAssignee> assignees;
  final AssignmentStats assignmentStats;
  final List<String> closureRules;
  final String createdAt;

  TaskDetailModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.score,
    required this.penaltyPerHour,
    required this.isPackage,
    required this.isPauseAllowed,
    required this.isDocument,
    required this.isMandatory,
    required this.isApproved,
    required this.isFaculty,
    required this.isDeleted,
    required this.isEscalate,
    this.venueId,
    this.resourceId,
    required this.creatorId,
    this.approverId,
    this.facultyId,
    required this.creator,
    this.approver,
    this.faculty,
    this.venue,
    this.resource,
    required this.taskTypes,
    required this.assignees,
    required this.assignmentStats,
    required this.closureRules,
    required this.createdAt,
  });

  factory TaskDetailModel.fromJson(Map<String, dynamic> json) {
    // Robustly extract facultyId from root or nested object
    int? fId = int.tryParse(json['faculty_id']?.toString() ?? '');
    if (fId == null && json['faculty'] is Map) {
      fId = int.tryParse(json['faculty']['user_id']?.toString() ?? '');
    }

    return TaskDetailModel(
      taskId: json['task_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: (json['priority'] ?? '').toString(),
      status: json['status'] ?? '',
      score: (num.tryParse(json['score']?.toString() ?? '0') ?? 0).toInt(),
      penaltyPerHour: (num.tryParse(json['penalty_per_hour']?.toString() ?? '0') ?? 0).toInt(),
      isPackage: json['is_package'] == true || json['is_package'] == 1 || json['is_package'].toString() == 'true',
      isPauseAllowed: json['is_pause_allowed'] == true || json['is_pause_allowed'] == 1 || json['is_pause_allowed'].toString() == 'true',
      isDocument: json['is_document'] == true || json['is_document'] == 1 || json['is_document'].toString() == 'true',
      isMandatory: json['is_mandatory'] == true || json['is_mandatory'] == 1 || json['is_mandatory'].toString() == 'true',
      isApproved: json['is_approved'] == true || json['is_approved'] == 1 || json['is_approved'].toString() == 'true',
      isFaculty: json['is_faculty'] == true || json['is_faculty'] == 1 || json['is_faculty'].toString() == 'true',
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1 || json['is_deleted'].toString() == 'true',
      isEscalate: json['is_escalate'] == true || json['is_escalate'] == 1 || json['is_escalate'].toString() == 'true',
      venueId: json['venue_id'],
      resourceId: json['resource_id'],
      creatorId: int.tryParse(json['creator_id']?.toString() ?? '') ?? 0,
      approverId: int.tryParse(json['approver_id']?.toString() ?? ''),
      facultyId: fId,
      creator: TaskCreator.fromJson(json['creator'] ?? {}),
      approver: json['approver'],
      faculty: json['faculty'],
      venue: json['venue'] is Map
          ? json['venue']['name']
          : null, // Extract name if object, else null
      resource: json['resource'],
      taskTypes:
          (json['task_types'] as List?)
              ?.map((e) => TaskType.fromJson(e))
              .toList() ??
          [],
      assignees:
          (json['assignees'] as List?)
              ?.map((e) => TaskAssignee.fromJson(e))
              .toList() ??
          [],
      assignmentStats: AssignmentStats.fromJson(json['assignment_stats'] ?? {}),
      closureRules:
          (json['closure_rules'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class TaskCreator {
  final int userId;
  final String role;
  final String name;
  final String email;

  TaskCreator({
    required this.userId,
    required this.role,
    required this.name,
    required this.email,
  });

  factory TaskCreator.fromJson(Map<String, dynamic> json) {
    return TaskCreator(
      userId: json['user_id'] ?? 0,
      role: json['role'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class TaskType {
  final int id;
  final String taskName;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String recurrence;

  TaskType({
    required this.id,
    required this.taskName,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.recurrence,
  });

  factory TaskType.fromJson(Map<String, dynamic> json) {
    return TaskType(
      id: json['id'] ?? 0,
      taskName: json['task_name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      recurrence: json['recurrence'] ?? '',
    );
  }
}

class TaskAssignee {
  final int assignmentId;
  final int userId;
  final String role;
  final String name;
  final String email;
  final String status;
  final String acceptedAt;
  final String? proof;
  final String? submittedTime;

  TaskAssignee({
    required this.assignmentId,
    required this.userId,
    required this.role,
    required this.name,
    required this.email,
    required this.status,
    required this.acceptedAt,
    this.proof,
    this.submittedTime,
  });

  factory TaskAssignee.fromJson(Map<String, dynamic> json) {
    return TaskAssignee(
      assignmentId: json['assignment_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      role: json['role'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? '',
      acceptedAt: json['accepted_at'] ?? '',
      proof: json['proof'],
      submittedTime: json['submitted_time'],
    );
  }
}

class AssignmentStats {
  final int total;
  final int pending;
  final int accepted;
  final int completed;
  final int rejected;

  AssignmentStats({
    required this.total,
    required this.pending,
    required this.accepted,
    required this.completed,
    required this.rejected,
  });

  factory AssignmentStats.fromJson(Map<String, dynamic> json) {
    return AssignmentStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      accepted: json['accepted'] ?? 0,
      completed: json['completed'] ?? 0,
      rejected: json['rejected'] ?? 0,
    );
  }
}
