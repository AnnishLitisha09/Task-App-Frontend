class VenueDashboardResponse {
  final String date;
  final int totalVenuesManaged;
  final List<VenueDashboardItem> venues;

  VenueDashboardResponse({
    required this.date,
    required this.totalVenuesManaged,
    required this.venues,
  });

  factory VenueDashboardResponse.fromJson(Map<String, dynamic> json) {
    return VenueDashboardResponse(
      date: json['date'] ?? '',
      totalVenuesManaged: json['total_venues_managed'] ?? 0,
      venues:
          (json['venues'] as List?)
              ?.map((e) => VenueDashboardItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class VenueDashboardItem {
  final int venueId;
  final String name;
  final String type;
  final String? location;
  final List<String> incharges;
  final VenueStats stats;
  final List<dynamic> bookedTasks;
  final List<dynamic> pendingApprovalTasks;

  VenueDashboardItem({
    required this.venueId,
    required this.name,
    required this.type,
    this.location,
    required this.incharges,
    required this.stats,
    required this.bookedTasks,
    required this.pendingApprovalTasks,
  });

  factory VenueDashboardItem.fromJson(Map<String, dynamic> json) {
    return VenueDashboardItem(
      venueId: json['venue_id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      location: json['location'],
      incharges:
          (json['incharges'] as List?)?.map((e) => e.toString()).toList() ?? [],
      stats: VenueStats.fromJson(json['stats'] ?? {}),
      bookedTasks: json['booked_tasks'] ?? [],
      pendingApprovalTasks: json['pending_approval_tasks'] ?? [],
    );
  }
}

class VenueStats {
  final int totalTasksAccepted;
  final int bookedCount;
  final int pendingApprovalCount;
  final String todayUsagePercentage;
  final int minutesUsedToday;

  VenueStats({
    required this.totalTasksAccepted,
    required this.bookedCount,
    required this.pendingApprovalCount,
    required this.todayUsagePercentage,
    required this.minutesUsedToday,
  });

  factory VenueStats.fromJson(Map<String, dynamic> json) {
    return VenueStats(
      totalTasksAccepted: json['total_tasks_accepted'] ?? 0,
      bookedCount: json['booked_count'] ?? 0,
      pendingApprovalCount: json['pending_approval_count'] ?? 0,
      todayUsagePercentage: json['today_usage_percentage'] ?? '0.00%',
      minutesUsedToday: json['minutes_used_today'] ?? 0,
    );
  }
}
