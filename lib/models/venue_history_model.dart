class VenueHistoryResponse {
  final int historyRangeDays;
  final String from;
  final String to;
  final int totalHistoryItems;
  final List<VenueHistoryItem> history;

  VenueHistoryResponse({
    required this.historyRangeDays,
    required this.from,
    required this.to,
    required this.totalHistoryItems,
    required this.history,
  });

  factory VenueHistoryResponse.fromJson(Map<String, dynamic> json) {
    return VenueHistoryResponse(
      historyRangeDays: (json['history_range_days'] as num?)?.toInt() ?? 0,
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      totalHistoryItems: (json['total_history_items'] as num?)?.toInt() ?? 0,
      history:
          (json['history'] as List?)
              ?.map((e) => VenueHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class VenueHistoryItem {
  final int taskId;
  final String title;
  final String description;
  final String status;
  final String date;
  final String startTime;
  final String endTime;
  final String? userName;

  VenueHistoryItem({
    required this.taskId,
    required this.title,
    required this.description,
    required this.status,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.userName,
  });

  factory VenueHistoryItem.fromJson(Map<String, dynamic> json) {
    String timing = json['timing']?.toString() ?? '';
    String fallbackFrom = '';
    String fallbackTo = '';
    if (timing.isNotEmpty && timing.contains(' - ')) {
      final parts = timing.split(' - ');
      fallbackFrom = parts.first;
      fallbackTo = parts.last;
    }

    return VenueHistoryItem(
      taskId: (json['task_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status:
          json['venue_approval_status']?.toString() ??
          json['status']?.toString() ??
          '',
      date: json['date']?.toString() ?? '',
      startTime:
          json['start_time']?.toString() ??
          json['from_time']?.toString() ??
          fallbackFrom,
      endTime:
          json['end_time']?.toString() ??
          json['to_time']?.toString() ??
          fallbackTo,
      userName:
          json['booked_by']?.toString() ??
          json['user_name']?.toString() ??
          'Unknown User',
    );
  }
}
