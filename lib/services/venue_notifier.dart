import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global reactive venue state.
/// All pages that depend on the active venue should listen to [venueNotifier].
/// When a VenueIncharge switches their workplace in the Profile, this notifier
/// fires and every listening page re-fetches its data automatically.
class VenueNotifier {
  VenueNotifier._();

  /// The single source-of-truth for the currently selected venue ID.
  /// null means no specific venue is selected (uses backend default).
  static final ValueNotifier<int?> venueNotifier = ValueNotifier<int?>(null);

  /// Call this once at app startup (and after login) to seed the notifier
  /// from the persisted SharedPreferences value.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    venueNotifier.value = prefs.getInt('selectedVenueId');
  }

  /// Switches the active venue, persists the selection, and notifies all listeners.
  static Future<void> switchVenue(int venueId, String venueName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedVenueId', venueId);
    await prefs.setString('selectedVenueName', venueName);
    venueNotifier.value = venueId; // triggers all ValueListenableBuilder listeners
  }

  /// Returns the current venue ID synchronously from the notifier.
  static int? get currentVenueId => venueNotifier.value;
}
