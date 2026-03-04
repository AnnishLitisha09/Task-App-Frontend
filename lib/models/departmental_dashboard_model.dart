class DepartmentalDashboard {
  final bool success;
  final DepartmentInfo department;
  final DeptStats stats;
  final int pendingApprovalsCount;
  final List<dynamic> pendingApprovals;
  final int departmentTasksCount;
  final List<dynamic> departmentTasks;

  DepartmentalDashboard({
    required this.success,
    required this.department,
    required this.stats,
    required this.pendingApprovalsCount,
    required this.pendingApprovals,
    required this.departmentTasksCount,
    required this.departmentTasks,
  });

  factory DepartmentalDashboard.fromJson(Map<String, dynamic> json) {
    return DepartmentalDashboard(
      success: json['success'] ?? false,
      department: DepartmentInfo.fromJson(json['department'] ?? {}),
      stats: DeptStats.fromJson(json['stats'] ?? {}),
      pendingApprovalsCount: json['pending_approvals_count'] ?? 0,
      pendingApprovals: json['pending_approvals'] ?? [],
      departmentTasksCount: json['department_tasks_count'] ?? 0,
      departmentTasks: json['department_tasks'] ?? [],
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
