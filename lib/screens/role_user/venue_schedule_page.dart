import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../models/venue_dashboard_model.dart';
import '../../components/task_card.dart';
import '../../components/skeleton_loader.dart';
import '../common/task_detail_page.dart';

class VenueSchedulePage extends StatefulWidget {
  const VenueSchedulePage({super.key});

  @override
  State<VenueSchedulePage> createState() => _VenueSchedulePageState();
}

class _VenueSchedulePageState extends State<VenueSchedulePage> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  List<dynamic> _groupedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  void _processBookings(List<BookingWithVenue> bookings) {
    if (bookings.isEmpty) {
      _groupedItems = [];
      return;
    }

    // Sort by fromTime
    bookings.sort((a, b) => a.booking.fromTime.compareTo(b.booking.fromTime));

    List<dynamic> result = [];
    String currentHeader = '';

    for (var b in bookings) {
      String start = b.booking.fromTime;
      String end = b.booking.toTime;

      // Clean up seconds if present
      if (start.length > 5) start = start.substring(0, 5);
      if (end.length > 5) end = end.substring(0, 5);

      String header = end.isNotEmpty ? '$start - $end' : start;
      if (header != currentHeader) {
        currentHeader = header;
        result.add({'isHeader': true, 'title': currentHeader});
      }
      result.add(b);
    }

    _groupedItems = result;
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoading = true);
    try {
      final details = await _taskService.getVenueDashboard();
      final List<BookingWithVenue> allToday = [];

      for (var venue in details.venues) {
        for (var booking in venue.today.confirmedBookings) {
          allToday.add(
            BookingWithVenue(venueName: venue.name, booking: booking),
          );
        }
      }

      setState(() {
        _processBookings(allToday);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching schedule: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Today's Schedule",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textMain,
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: DashboardSkeleton(),
            )
          : _groupedItems.isEmpty
          ? const Center(child: Text("No bookings for today"))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _groupedItems.length,
              itemBuilder: (context, index) {
                final item = _groupedItems[index];

                if (item is Map && item['isHeader'] == true) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }

                final bookingItem = item as BookingWithVenue;
                final bool isCompleted =
                    bookingItem.booking.status.toLowerCase() == 'completed';
                return TaskCard(
                  title: bookingItem.booking.title,
                  sub:
                      "${bookingItem.venueName} • By: ${bookingItem.booking.bookedBy}",
                  accent: isCompleted ? AppTheme.success : AppTheme.brandAccent,
                  icon: isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.meeting_room_rounded,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': bookingItem.booking.taskId,
                            'title': bookingItem.booking.title,
                          },
                          viewMode: 'incharge',
                        ),
                      ),
                    );
                    if (result != null) {
                      _fetchSchedule();
                    }
                  },
                );
              },
            ),
    );
  }
}

class BookingWithVenue {
  final String venueName;
  final ConfirmedBooking booking;

  BookingWithVenue({required this.venueName, required this.booking});
}
