import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';
import '../../models/venue_dashboard_model.dart';
import '../../theme/app_theme.dart';
import '../../components/skeleton_loader.dart';
import '../../services/venue_notifier.dart';
import '../common/task_detail_page.dart';

class VenueSchedulePage extends StatefulWidget {
  const VenueSchedulePage({super.key});

  @override
  State<VenueSchedulePage> createState() => _VenueSchedulePageState();
}

class _VenueSchedulePageState extends State<VenueSchedulePage> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  List<BookingWithVenue> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
    VenueNotifier.venueNotifier.addListener(_fetchSchedule);
  }

  @override
  void dispose() {
    VenueNotifier.venueNotifier.removeListener(_fetchSchedule);
    super.dispose();
  }

  Future<void> _fetchSchedule() async {
    if (!mounted) return;
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

      // Sort by fromTime
      allToday.sort((a, b) => a.booking.fromTime.compareTo(b.booking.fromTime));

      if (mounted) {
        setState(() {
          _bookings = allToday;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching venue schedule: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Status helpers ─────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.brandAccent; // Was success
      case 'in_progress':
      case 'in progress':
        return AppTheme.brandAccent;
      case 'confirmed':
        return AppTheme.brandAccent;
      case 'overdue':
        return AppTheme.danger;
      default:
        return AppTheme.brandAccent;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'confirmed':
        return Icons.meeting_room_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMMM dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandAccent.withOpacity(0.04),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                        color: AppTheme.textMain,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Venue Schedule",
                              style: TextStyle(
                                color: AppTheme.textMain,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              today,
                              style: TextStyle(
                                color: AppTheme.textSub.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isLoading && _bookings.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            "${_bookings.length} Bookings",
                            style: const TextStyle(
                              color: AppTheme.brandAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Main Content
                Expanded(
                  child: _isLoading 
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: DashboardSkeleton(),
                      )
                    : _bookings.isEmpty
                      ? _buildEmptyState()
                      : _buildTimeline(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    // Grouping for a better UX: Confirmed vs Pending
    final confirmed = _bookings.where((b) => b.booking.status.toLowerCase() == 'accepted').toList();
    final pending = _bookings.where((b) => b.booking.status.toLowerCase() == 'pending').toList();

    return RefreshIndicator(
      onRefresh: _fetchSchedule,
      color: AppTheme.brandAccent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
        children: [
          if (pending.isNotEmpty) ...[
            _buildSectionHeader("Awaiting Approval", Icons.pending_actions_rounded, AppTheme.warning),
            ...pending.map((b) => _buildMinimalBookingCard(b)),
            const SizedBox(height: 24),
          ],
          if (confirmed.isNotEmpty) ...[
            _buildSectionHeader("Today's Confirmed Slots", Icons.event_available_rounded, AppTheme.brandAccent),
            ...confirmed.map((b) => _buildMinimalBookingCard(b)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textSub.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: AppTheme.textSub.withOpacity(0.08), thickness: 1.5)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
  }

  Widget _buildMinimalBookingCard(BookingWithVenue item) {
    final booking = item.booking;
    final statusColor = _statusColor(booking.status);
    final statusIcon = _statusIcon(booking.status);

    String? typeLabel;
    if (booking.isPackage == true) {
      typeLabel = "Package";
    } else if (booking.taskType?.contains('Long Task') ?? false) {
      typeLabel = "Long Task";
    } else if (booking.taskType == 'Floating Task') {
      typeLabel = "Floating";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailsPage(
                taskData: {
                  'task_id': booking.taskId,
                  'title': booking.title,
                },
                viewMode: 'incharge',
              ),
            ),
          );
          if (result != null) _fetchSchedule();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.textSub.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Activity indicator bar
                Container(width: 4, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.title,
                                    style: const TextStyle(
                                      color: AppTheme.textMain,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${item.venueName} • ${booking.bookedBy}",
                                    style: TextStyle(
                                      color: AppTheme.textSub.withOpacity(0.6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(statusIcon, size: 14, color: statusColor),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (typeLabel != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (typeLabel == "Package" ? AppTheme.brandAccent : AppTheme.warning).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  typeLabel.toUpperCase(),
                                  style: TextStyle(
                                    color: typeLabel == "Package" ? AppTheme.brandAccent : AppTheme.warning,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Icon(Icons.schedule_rounded, size: 12, color: AppTheme.textSub.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(
                              "${booking.fromTime} - ${booking.toTime}",
                              style: TextStyle(
                                color: AppTheme.textSub.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              (booking.status == 'accepted' ? 'Confirmed' : booking.status).toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_rounded, size: 64, color: AppTheme.dividerColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            "No Bookings Today",
            style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text("Everything looks clear for the venues you manage."),
        ],
      ),
    );
  }
}

class BookingWithVenue {
  final String venueName;
  final ConfirmedBooking booking;

  BookingWithVenue({required this.venueName, required this.booking});
}

