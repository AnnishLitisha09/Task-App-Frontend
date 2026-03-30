class InstitutionalDashboard {
  final bool success;
  final String role;
  final InstitutionalStats institutionalStats;
  final PersonalActions personalActions;
  final List<dynamic> todaysSchedule;

  InstitutionalDashboard({
    required this.success,
    required this.role,
    required this.institutionalStats,
    required this.personalActions,
    required this.todaysSchedule,
  });

  factory InstitutionalDashboard.fromJson(Map<String, dynamic> json) {
    return InstitutionalDashboard(
      success: json['success'] ?? false,
      role: json['role']?.toString() ?? '',
      institutionalStats: InstitutionalStats.fromJson(
        json['institutional_stats'] ?? {},
      ),
      personalActions: PersonalActions.fromJson(json['personal_actions'] ?? {}),
      todaysSchedule: json['todays_schedule'] ?? [],
    );
  }
}

class InstitutionalStats {
  final int totalDepartments;
  final int totalStudents;
  final int totalFaculty;

  InstitutionalStats({
    required this.totalDepartments,
    required this.totalStudents,
    required this.totalFaculty,
  });

  factory InstitutionalStats.fromJson(Map<String, dynamic> json) {
    return InstitutionalStats(
      totalDepartments: (json['total_departments'] as num?)?.toInt() ?? 0,
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      totalFaculty: (json['total_faculty'] as num?)?.toInt() ?? 0,
    );
  }
}

class PersonalActions {
  final int pendingMyApprovalCount;
  final List<dynamic> pendingMyApprovalList;
  final int assignedToMeCount;
  final List<dynamic> assignedToMeList;

  PersonalActions({
    required this.pendingMyApprovalCount,
    required this.pendingMyApprovalList,
    required this.assignedToMeCount,
    required this.assignedToMeList,
  });

  factory PersonalActions.fromJson(Map<String, dynamic> json) {
    return PersonalActions(
      pendingMyApprovalCount:
          (json['pending_my_approval_count'] as num?)?.toInt() ?? 0,
      pendingMyApprovalList: json['pending_my_approval_list'] ?? [],
      assignedToMeCount: (json['assigned_to_me_count'] as num?)?.toInt() ?? 0,
      assignedToMeList: json['assigned_to_me'] ?? [],
    );
  }
}
