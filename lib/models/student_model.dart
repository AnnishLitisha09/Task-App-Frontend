import '../models/task_detail_model.dart'; // Reuse for task list in details

class StudentSummary {
  final int id;
  final String name;
  final String email;
  final String registerNumber;
  final String? avatarUrl;
  final double totalScore;
  final double totalPenalty;
  final String department;
  final String year;

  StudentSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.registerNumber,
    this.avatarUrl,
    this.totalScore = 0,
    this.totalPenalty = 0,
    this.department = 'CSE',
    this.year = '3rd',
  });

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    return StudentSummary(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Student',
      email: json['email'] ?? '',
      registerNumber: json['register_number'] ?? 'N/A',
      avatarUrl: json['avatar_url'],
      totalScore: (json['total_score'] ?? 0).toDouble(),
      totalPenalty: (json['total_penalty'] ?? 0).toDouble(),
      department: json['department'] ?? 'CSE',
      year: json['year'] ?? '3rd',
    );
  }
}

class StudentDetail extends StudentSummary {
  final List<TaskDetailModel> activeTasks;
  final List<TaskDetailModel> completedTasks;
  final Map<String, dynamic> attendanceStats;

  StudentDetail({
    required super.id,
    required super.name,
    required super.email,
    required super.registerNumber,
    super.avatarUrl,
    super.totalScore,
    super.totalPenalty,
    super.department,
    super.year,
    this.activeTasks = const [],
    this.completedTasks = const [],
    this.attendanceStats = const {},
  });

  factory StudentDetail.fromJson(Map<String, dynamic> json) {
    var summary = StudentSummary.fromJson(json);

    return StudentDetail(
      id: summary.id,
      name: summary.name,
      email: summary.email,
      registerNumber: summary.registerNumber,
      avatarUrl: summary.avatarUrl,
      totalScore: summary.totalScore,
      totalPenalty: summary.totalPenalty,
      department: summary.department,
      year: summary.year,
      activeTasks:
          (json['active_tasks'] as List?)
              ?.map((e) => TaskDetailModel.fromJson(e))
              .toList() ??
          [],
      completedTasks:
          (json['completed_tasks'] as List?)
              ?.map((e) => TaskDetailModel.fromJson(e))
              .toList() ??
          [],
      attendanceStats: json['attendance_stats'] ?? {},
    );
  }
}
