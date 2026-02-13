class PerformanceStats {
  final int totalScore;
  final int totalPenalty;
  final int totalEarnedScore;
  final List<DayTrend> last7Days;
  final List<TaskDetail> taskDetails;

  PerformanceStats({
    required this.totalScore,
    required this.totalPenalty,
    required this.totalEarnedScore,
    required this.last7Days,
    required this.taskDetails,
  });

  factory PerformanceStats.fromJson(Map<String, dynamic> json) {
    return PerformanceStats(
      totalScore: json['total_score'] ?? 0,
      totalPenalty: json['total_penalty'] ?? 0,
      totalEarnedScore: json['total_earned_score'] ?? 0,
      last7Days:
          (json['last_7_days'] as List?)
              ?.map((e) => DayTrend.fromJson(e))
              .toList() ??
          [],
      taskDetails:
          (json['task_details'] as List?)
              ?.map((e) => TaskDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DayTrend {
  final String date;
  final int score;

  DayTrend({required this.date, required this.score});

  factory DayTrend.fromJson(Map<String, dynamic> json) {
    return DayTrend(date: json['date'] ?? '', score: json['score'] ?? 0);
  }
}

class TaskDetail {
  final int taskId;
  final String title;
  final String status;
  final int baseScore;
  final int earnedScore;
  final int penaltyApplied;
  final String submittedTime;
  final String submissionType;

  TaskDetail({
    required this.taskId,
    required this.title,
    required this.status,
    required this.baseScore,
    required this.earnedScore,
    required this.penaltyApplied,
    required this.submittedTime,
    required this.submissionType,
  });

  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    return TaskDetail(
      taskId: json['task_id'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      baseScore: json['base_score'] ?? 0,
      earnedScore: json['earned_score'] ?? 0,
      penaltyApplied: json['penalty_applied'] ?? 0,
      submittedTime: json['submitted_time'] ?? '',
      submissionType: json['submission_type'] ?? '',
    );
  }
}
