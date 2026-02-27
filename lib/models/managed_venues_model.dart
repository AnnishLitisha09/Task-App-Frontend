class ManagedVenuesResponse {
  final bool success;
  final int totalManaged;
  final List<ManagedVenueItem> venues;

  ManagedVenuesResponse({
    required this.success,
    required this.totalManaged,
    required this.venues,
  });

  factory ManagedVenuesResponse.fromJson(Map<String, dynamic> json) {
    return ManagedVenuesResponse(
      success: json['success'] ?? false,
      totalManaged: json['total_managed'] ?? 0,
      venues:
          (json['venues'] as List?)
              ?.map((e) => ManagedVenueItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ManagedVenueItem {
  final int venueId;
  final String name;
  final String type;
  final String? location;
  final String? image;
  final int todaysBookings;

  ManagedVenueItem({
    required this.venueId,
    required this.name,
    required this.type,
    this.location,
    this.image,
    required this.todaysBookings,
  });

  factory ManagedVenueItem.fromJson(Map<String, dynamic> json) {
    return ManagedVenueItem(
      venueId: json['venue_id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      location: json['location'],
      image: json['image'],
      todaysBookings: json['todays_bookings'] ?? 0,
    );
  }
}
