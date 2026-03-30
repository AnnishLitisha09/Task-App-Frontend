class StudentDashboard {
  final bool success;
  final StudentDetails studentDetails;
  final String department;
  final AssignedFaculty assignedFaculty;
  final Counts counts;
  final List<TodayTask> todaysSchedule;
  final List<OverdueTask> overdueTasks;
  final List<PendingForApproval> pendingForApproval;

  StudentDashboard({
    required this.success,
    required this.studentDetails,
    required this.department,
    required this.assignedFaculty,
    required this.counts,
    required this.todaysSchedule,
    required this.overdueTasks,
    required this.pendingForApproval,
  });

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    return StudentDashboard(
      success: json['success'] ?? false,
      studentDetails: StudentDetails.fromJson(
        json['student_details'] ?? 
        json['faculty_details'] ?? 
        json['staff_details'] ?? 
        {}
      ),
      department: json['department'] ?? '',
      assignedFaculty: AssignedFaculty.fromJson(json['assigned_faculty'] ?? {}),
      counts: Counts.fromJson(json['counts'] ?? {}),
      todaysSchedule: (json['todays_schedule'] as List? ?? [])
          .map((i) => TodayTask.fromJson(i))
          .toList(),
      overdueTasks: (json['overdue_tasks'] as List? ?? [])
          .map((i) => OverdueTask.fromJson(i))
          .toList(),
      pendingForApproval: [
        ...(json['pending_for_approval'] as List? ?? [])
            .map((i) => PendingForApproval.fromJson(i)),
        ...(json['escalated_tasks'] as List? ?? [])
            .map((i) {
               if (i is Map<String, dynamic>) {
                 final map = Map<String, dynamic>.from(i);
                 map['is_escalate'] = true;
                 return PendingForApproval.fromJson(map);
               }
               return PendingForApproval.fromJson(i);
            })
      ],
    );
  }
}

class StudentDetails {
  final int userId;
  final String name;
  final String regNo;
  final String email;
  final int year;
  final String score;
  final String penalty;
  final String cGpa;

  StudentDetails({
    required this.userId,
    required this.name,
    required this.regNo,
    required this.email,
    required this.year,
    required this.score,
    required this.penalty,
    required this.cGpa,
  });

  factory StudentDetails.fromJson(Map<String, dynamic> json) {
    return StudentDetails(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      regNo: json['reg_no'] ?? '',
      email: json['email'] ?? '',
      year: json['year'] ?? 0,
      score: json['score'] ?? '0.00',
      penalty: json['penalty'] ?? '0.00',
      cGpa: json['c_gpa'] ?? '0.00',
    );
  }
}

class AssignedFaculty {
  final String name;
  final String email;
  final String regNo;
  final String designation;

  AssignedFaculty({
    required this.name,
    required this.email,
    required this.regNo,
    required this.designation,
  });

  factory AssignedFaculty.fromJson(Map<String, dynamic> json) {
    return AssignedFaculty(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      regNo: json['reg_no'] ?? '',
      designation: json['designation'] ?? '',
    );
  }
}

class Counts {
  final int todayScheduleCount;
  final int overdueTasksCount;
  final int pendingApprovalCount;

  Counts({
    required this.todayScheduleCount,
    required this.overdueTasksCount,
    required this.pendingApprovalCount,
  });

  factory Counts.fromJson(Map<String, dynamic> json) {
    return Counts(
      todayScheduleCount: json['today_schedule_count'] ?? 0,
      overdueTasksCount: json['overdue_tasks_count'] ?? 0,
      pendingApprovalCount: json['pending_approval_count'] ?? 0,
    );
  }
}

class OverdueTask {
  final int assignmentId;
  final int taskId;
  final String title;
  final String category;
  final String priority;
  final String status;
  final String timing;
  final String date;

  OverdueTask({
    required this.assignmentId,
    required this.taskId,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.timing,
    required this.date,
  });

  factory OverdueTask.fromJson(Map<String, dynamic> json) {
    return OverdueTask(
      assignmentId: json['assignment_id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? '',
      status: json['status'] ?? json['assignment_status'] ?? '',
      timing: _parseTimingString(json),
      date: json['date'] ?? json['start_date']?.split('T')[0] ?? '',
    );
  }
}

class PendingForApproval {
  final int taskId;
  final String title;
  final String category;
  final String priority;
  final String date;
  final String timing;
  final bool isEscalated;

  PendingForApproval({
    required this.taskId,
    required this.title,
    required this.category,
    required this.priority,
    required this.date,
    required this.timing,
    this.isEscalated = false,
  });

  factory PendingForApproval.fromJson(Map<String, dynamic> json) {
    return PendingForApproval(
      taskId: json['task_id'] ?? 0,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? '',
      date: json['date'] ?? json['start_date']?.split('T')[0] ?? '',
      timing: _parseTimingString(json),
      isEscalated: json['is_escalate'] == true || json['isEscalate'] == true,
    );
  }
}

class TodayTask {
  final int taskId;
  final String title;
  final String category;
  final String timing;
  final String status;
  final Map<String, dynamic>? actionButton;

  TodayTask({
    required this.taskId,
    required this.title,
    required this.category,
    required this.timing,
    required this.status,
    this.actionButton,
  });

  factory TodayTask.fromJson(Map<String, dynamic> json) {
    return TodayTask(
      taskId: json['task_id'] ?? 0,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      timing: _parseTimingString(json),
      status: json['status'] ?? json['assignment_status'] ?? '',
      actionButton: json['action_button'],
    );
  }
}

// Global helper to parse timing from various API formats
String _parseTimingString(Map<String, dynamic> json) {
  final rawTiming = json['timing'];

  if (rawTiming is String) {
    return rawTiming;
  }

  if (rawTiming is Map) {
    final start = rawTiming['start_time'] ?? '';
    final end = rawTiming['end_time'] ?? '';
    if (start.isNotEmpty && end.isNotEmpty) {
      return "$start - $end";
    }
    return start.isNotEmpty ? start : (end.isNotEmpty ? end : 'Anytime');
  }

  // Fallback to top-level fields
  final startTime = json['start_time'] ?? '';
  final endTime = json['end_time'] ?? '';
  if (startTime.isNotEmpty && endTime.isNotEmpty) {
    return "$startTime - $endTime";
  }
  return startTime.isNotEmpty
      ? startTime
      : (endTime.isNotEmpty ? endTime : 'Anytime');
}
