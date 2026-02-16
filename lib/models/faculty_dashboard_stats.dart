import 'faculty_info.dart';

class FacultyDashboardStats {
  final FacultyInfo facultyInfo;
  final DailyStats dailyStats;
  final List<dynamic> allTasksToday;
  final List<dynamic> pendingTasks;

  FacultyDashboardStats({
    required this.facultyInfo,
    required this.dailyStats,
    required this.allTasksToday,
    required this.pendingTasks,
  });

  factory FacultyDashboardStats.fromJson(Map<String, dynamic> json) {
    return FacultyDashboardStats(
      facultyInfo: FacultyInfo.fromJson(json['faculty_info'] ?? {}),
      dailyStats: DailyStats.fromJson(json['daily_stats'] ?? {}),
      allTasksToday: json['all_tasks_today'] ?? [],
      pendingTasks: json['pending_tasks'] ?? [],
    );
  }
}

class DailyStats {
  final String date;
  final int totalTasksAssignedToday;
  final int pendingTasksCount;
  final int menteeStudentsCount;

  DailyStats({
    required this.date,
    required this.totalTasksAssignedToday,
    required this.pendingTasksCount,
    required this.menteeStudentsCount,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['date'] ?? '',
      totalTasksAssignedToday:
          (json['total_tasks_assigned_today'] as num?)?.toInt() ?? 0,
      pendingTasksCount: (json['pending_tasks_count'] as num?)?.toInt() ?? 0,
      menteeStudentsCount:
          (json['mentee_students_count'] as num?)?.toInt() ?? 0,
    );
  }
}
