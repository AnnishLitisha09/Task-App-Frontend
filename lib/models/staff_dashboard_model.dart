class StaffDashboardResponse {
  final bool success;
  final StaffProfile profile;
  final StaffStats stats;
  final List<StaffScheduleTask> todaysSchedule;
  final List<dynamic> recentActivity;

  StaffDashboardResponse({
    required this.success,
    required this.profile,
    required this.stats,
    required this.todaysSchedule,
    required this.recentActivity,
  });

  factory StaffDashboardResponse.fromJson(Map<String, dynamic> json) {
    return StaffDashboardResponse(
      success: json['success'] ?? false,
      profile: StaffProfile.fromJson(json['profile'] ?? {}),
      stats: StaffStats.fromJson(json['stats'] ?? {}),
      todaysSchedule: (json['todays_schedule'] as List? ?? [])
          .map((i) => StaffScheduleTask.fromJson(i))
          .toList(),
      recentActivity: json['recent_activity'] ?? [],
    );
  }
}

class StaffProfile {
  final String name;
  final String email;
  final String designation;

  StaffProfile({
    required this.name,
    required this.email,
    required this.designation,
  });

  factory StaffProfile.fromJson(Map<String, dynamic> json) {
    return StaffProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      designation: json['designation'] ?? '',
    );
  }
}

class StaffStats {
  final int totalTasks;
  final int pendingTasks;
  final int completedTasks;
  final String efficiency;
  final int managedEmployeesCount;

  StaffStats({
    required this.totalTasks,
    required this.pendingTasks,
    required this.completedTasks,
    required this.efficiency,
    required this.managedEmployeesCount,
  });

  factory StaffStats.fromJson(Map<String, dynamic> json) {
    return StaffStats(
      totalTasks: json['total_tasks'] ?? 0,
      pendingTasks: json['pending_tasks'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      efficiency: json['efficiency']?.toString() ?? '0.00%',
      managedEmployeesCount: json['managed_employees_count'] ?? 0,
    );
  }
}

class StaffScheduleTask {
  final int taskId;
  final String title;
  final String status;
  final String timing;

  StaffScheduleTask({
    required this.taskId,
    required this.title,
    required this.status,
    required this.timing,
  });

  factory StaffScheduleTask.fromJson(Map<String, dynamic> json) {
    return StaffScheduleTask(
      taskId: json['task_id'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      timing: json['timing'] ?? '',
    );
  }
}
