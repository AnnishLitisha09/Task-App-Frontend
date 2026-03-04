class ActivityHistoryResponse {
  final bool success;
  final int userId;
  final String timeframe;
  final ActivityCounts counts;
  final ActivityHistory history;

  ActivityHistoryResponse({
    required this.success,
    required this.userId,
    required this.timeframe,
    required this.counts,
    required this.history,
  });

  factory ActivityHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ActivityHistoryResponse(
      success: json['success'] ?? false,
      userId: json['user_id'] ?? 0,
      timeframe: json['timeframe'] ?? '',
      counts: ActivityCounts.fromJson(json['counts'] ?? {}),
      history: ActivityHistory.fromJson(json['history'] ?? {}),
    );
  }
}

class ActivityCounts {
  final int today;
  final int yesterday;
  final int total;

  ActivityCounts({
    required this.today,
    required this.yesterday,
    required this.total,
  });

  factory ActivityCounts.fromJson(Map<String, dynamic> json) {
    return ActivityCounts(
      today: json['today'] ?? 0,
      yesterday: json['yesterday'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class ActivityHistory {
  final List<ActivityItem> today;
  final List<ActivityItem> yesterday;

  ActivityHistory({required this.today, required this.yesterday});

  factory ActivityHistory.fromJson(Map<String, dynamic> json) {
    return ActivityHistory(
      today: (json['today'] as List? ?? [])
          .map((e) => ActivityItem.fromJson(e))
          .toList(),
      yesterday: (json['yesterday'] as List? ?? [])
          .map((e) => ActivityItem.fromJson(e))
          .toList(),
    );
  }
}

class ActivityItem {
  final String title;
  final String time;
  final String type;
  final String? status;
  final String? category;

  ActivityItem({
    required this.title,
    required this.time,
    required this.type,
    this.status,
    this.category,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      title: json['title'] ?? json['activity_name'] ?? 'Activity',
      time: json['time'] ?? json['timestamp'] ?? '',
      type: json['type'] ?? 'log',
      status: json['status'],
      category: json['category'],
    );
  }
}
