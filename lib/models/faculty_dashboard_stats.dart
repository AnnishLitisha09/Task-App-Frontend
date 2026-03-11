import 'faculty_info.dart';

class FacultyDashboardStats {
  final FacultyInfo facultyInfo;
  final DailyStats dailyStats;
  List<dynamic> allTasksToday;
  List<dynamic> pendingTasks;
  List<dynamic> pendingProofs;
  List<dynamic> escalatedTasks;

  FacultyDashboardStats({
    required this.facultyInfo,
    required this.dailyStats,
    required this.allTasksToday,
    required this.pendingTasks,
    required this.pendingProofs,
    required this.escalatedTasks,
  });

  factory FacultyDashboardStats.fromJson(Map<String, dynamic> json) {
    return FacultyDashboardStats(
      facultyInfo: FacultyInfo.fromJson(json['faculty_details'] ?? {}),
      dailyStats: DailyStats.fromJson(json['counts'] ?? {}),
      allTasksToday: json['todays_schedule'] ?? [],
      pendingTasks: json['pending_approvals'] ?? [],
      pendingProofs: json['pending_proof'] ?? [],
      escalatedTasks: json['escalated_tasks'] ?? [],
    );
  }
}

class DailyStats {
  int totalTasksAssignedToday;
  int pendingTasksCount;
  int pendingProofCount;
  int escalatedTasksCount;

  DailyStats({
    required this.totalTasksAssignedToday,
    required this.pendingTasksCount,
    required this.pendingProofCount,
    required this.escalatedTasksCount,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      totalTasksAssignedToday:
          (json['today_schedule_count'] as num?)?.toInt() ?? 0,
      pendingTasksCount:
          (json['pending_approvals_count'] as num?)?.toInt() ?? 0,
      pendingProofCount: (json['pending_proof_count'] as num?)?.toInt() ?? 0,
      escalatedTasksCount:
          (json['escalated_tasks_count'] as num?)?.toInt() ?? 0,
    );
  }
}
