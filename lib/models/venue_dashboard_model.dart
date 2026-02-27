class VenueDetailsResponse {
  final String date;
  final int totalVenuesManaged;
  final List<VenueDetailItem> venues;

  VenueDetailsResponse({
    required this.date,
    required this.totalVenuesManaged,
    required this.venues,
  });

  factory VenueDetailsResponse.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return VenueDetailsResponse(date: '', totalVenuesManaged: 0, venues: []);
    }
    return VenueDetailsResponse(
      date: json['date']?.toString() ?? '',
      totalVenuesManaged:
          int.tryParse(json['total_venues_managed']?.toString() ?? '') ?? 0,
      venues:
          (json['venues'] as List?)
              ?.where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => VenueDetailItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class VenueDetailItem {
  final int venueId;
  final String name;
  final String type;
  final String? location;
  final String? photo;
  final String currentStatus;
  final int overallTotalTasks;
  int newRequestsPendingCount;
  final String? todayUsagePercentage;
  final int? minutesUsedToday;
  final VenueTodayData today;
  final List<ConfirmedBooking> pendingApprovalTasks;

  VenueDetailItem({
    required this.venueId,
    required this.name,
    required this.type,
    this.location,
    this.photo,
    required this.currentStatus,
    required this.overallTotalTasks,
    required this.newRequestsPendingCount,
    this.todayUsagePercentage,
    this.minutesUsedToday,
    required this.today,
    this.pendingApprovalTasks = const [],
  });

  factory VenueDetailItem.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return VenueDetailItem(
        venueId: 0,
        name: '',
        type: '',
        currentStatus: 'available',
        overallTotalTasks: 0,
        newRequestsPendingCount: 0,
        today: VenueTodayData.fromJson(null),
      );
    }

    final stats = json['stats'] as Map<String, dynamic>?;

    return VenueDetailItem(
      venueId: int.tryParse(json['venue_id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      location: json['location']?.toString(),
      photo: json['photo']?.toString(),
      currentStatus: json['current_status']?.toString() ?? 'available',
      overallTotalTasks:
          int.tryParse(
            stats?['total_tasks_accepted']?.toString() ??
                json['overall_total_tasks']?.toString() ??
                '',
          ) ??
          0,
      newRequestsPendingCount:
          int.tryParse(
            stats?['pending_approval_count']?.toString() ??
                json['new_requests_pending_count']?.toString() ??
                '',
          ) ??
          0,
      todayUsagePercentage: stats?['today_usage_percentage']?.toString(),
      minutesUsedToday: int.tryParse(
        stats?['minutes_used_today']?.toString() ?? '',
      ),
      today: VenueTodayData.fromJson(
        json['booked_tasks'] != null
            ? {'confirmed_bookings': json['booked_tasks'], 'date': json['date']}
            : json['today'],
      ),
      pendingApprovalTasks:
          (json['pending_approval_tasks'] as List?)
              ?.where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => ConfirmedBooking.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class VenueTodayData {
  final String date;
  int confirmedBookingsCount;
  List<ConfirmedBooking> confirmedBookings;

  VenueTodayData({
    required this.date,
    required this.confirmedBookingsCount,
    required this.confirmedBookings,
  });

  factory VenueTodayData.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return VenueTodayData(
        date: '',
        confirmedBookingsCount: 0,
        confirmedBookings: [],
      );
    }
    return VenueTodayData(
      date: json['date']?.toString() ?? '',
      confirmedBookingsCount:
          int.tryParse(json['confirmed_bookings_count']?.toString() ?? '') ?? 0,
      confirmedBookings:
          (json['confirmed_bookings'] as List?)
              ?.where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => ConfirmedBooking.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ConfirmedBooking {
  final int taskId;
  final String title;
  final String fromTime;
  final String toTime;
  final String bookedBy;
  final String status;

  ConfirmedBooking({
    required this.taskId,
    required this.title,
    required this.fromTime,
    required this.toTime,
    required this.bookedBy,
    required this.status,
  });

  factory ConfirmedBooking.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return ConfirmedBooking(
        taskId: 0,
        title: '',
        fromTime: '',
        toTime: '',
        bookedBy: '',
        status: 'pending',
      );
    }

    final timing = json['timing'] as Map<String, dynamic>?;

    return ConfirmedBooking(
      taskId: int.tryParse(json['task_id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      fromTime:
          timing?['start_time']?.toString() ??
          json['from_time']?.toString() ??
          '',
      toTime:
          timing?['end_time']?.toString() ?? json['to_time']?.toString() ?? '',
      bookedBy: json['booked_by']?.toString() ?? 'Unknown User',
      status:
          json['venue_approval_status']?.toString() ??
          json['status']?.toString() ??
          'pending',
    );
  }
}
