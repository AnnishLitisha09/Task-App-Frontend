class DepartmentalDashboard {
  final bool success;
  final String todayDate;
  final bool isTomorrowPreview;
  final DepartmentInfo department;
  final DeptStats stats;
  final int pendingApprovalsCount;
  final List<dynamic> pendingApprovals;
  final int escalatedTasksCount;
  final List<dynamic> escalatedTasks;
  final int todaysScheduleCount;
  final List<dynamic> todaysSchedule;
  final int departmentTasksCount;
  final List<dynamic> departmentTasks;
  final int assignedToMeCount;
  final List<dynamic> assignedToMeTasks;
  final int pendingProofsCount;
  final List<dynamic> pendingProofs;
  final int verificationTasksCount;
  final List<dynamic> verificationTasks;
  final dynamic facultyDetails;

  DepartmentalDashboard({
    required this.success,
    required this.todayDate,
    required this.isTomorrowPreview,
    required this.department,
    required this.stats,
    required this.pendingApprovalsCount,
    required this.pendingApprovals,
    required this.escalatedTasksCount,
    required this.escalatedTasks,
    required this.todaysScheduleCount,
    required this.todaysSchedule,
    required this.departmentTasksCount,
    required this.departmentTasks,
    required this.assignedToMeCount,
    required this.assignedToMeTasks,
    required this.pendingProofsCount,
    required this.pendingProofs,
    required this.verificationTasksCount,
    required this.verificationTasks,
    this.facultyDetails,
  });

  factory DepartmentalDashboard.fromJson(Map<String, dynamic> json) {
    return DepartmentalDashboard(
      success: json['success'] ?? false,
      todayDate: json['today_date'] ?? '',
      isTomorrowPreview: json['is_tomorrow_preview'] ?? false,
      department: DepartmentInfo.fromJson(json['department'] ?? {}),
      stats: DeptStats.fromJson(json['stats'] ?? {}),
      pendingApprovalsCount: json['awaiting_my_approval_count'] ?? json['pending_approvals_count'] ?? 0,
      pendingApprovals: json['awaiting_my_approval'] ?? json['pending_approvals'] ?? [],
      escalatedTasksCount: json['escalated_tasks_count'] ?? 0,
      escalatedTasks: json['escalated_tasks'] ?? [],
      todaysScheduleCount: json['todays_schedule_count'] ?? 0,
      todaysSchedule: json['todays_schedule'] ?? [],
      departmentTasksCount: json['department_tasks_count'] ?? 0,
      departmentTasks: json['department_tasks'] ?? [],
      assignedToMeCount: json['assigned_to_me_count'] ?? 0,
      assignedToMeTasks: json['assigned_to_me'] ?? [],
      pendingProofsCount: json['pending_proofs_count'] ?? 0,
      pendingProofs: json['pending_proofs'] ?? [],
      verificationTasksCount: json['verification_tasks_count'] ?? 0,
      verificationTasks: json['verification_tasks'] ?? [],
      facultyDetails: json['faculty_details'],
    );
  }
}

class DepartmentInfo {
  final int id;
  final String name;

  DepartmentInfo({required this.id, required this.name});

  factory DepartmentInfo.fromJson(Map<String, dynamic> json) {
    return DepartmentInfo(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class DeptStats {
  final int totalStudents;
  final int totalFaculty;

  DeptStats({required this.totalStudents, required this.totalFaculty});

  factory DeptStats.fromJson(Map<String, dynamic> json) {
    return DeptStats(
      totalStudents: json['total_students'] ?? 0,
      totalFaculty: json['total_faculty'] ?? 0,
    );
  }
}
