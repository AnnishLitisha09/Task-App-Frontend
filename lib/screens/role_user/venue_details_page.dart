import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/task_service.dart';
import '../../models/venue_dashboard_model.dart';
import '../../models/venue_history_model.dart';
import '../../theme/app_theme.dart';
import '../../components/skeleton_loader.dart';
import '../../components/task_card.dart';
import '../common/task_detail_page.dart';
import './venue_history_page.dart';
import './venue_schedule_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VenueDetailsPage extends StatefulWidget {
  final int? venueId;
  const VenueDetailsPage({super.key, this.venueId});

  @override
  State<VenueDetailsPage> createState() => _VenueDetailsPageState();
}

class _VenueDetailsPageState extends State<VenueDetailsPage> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  bool _isHistoryLoading = false;

  VenueDetailsResponse? _detailsData;
  VenueDetailItem? _selectedVenue;
  VenueHistoryResponse? _historyData;

  // --- Design Tokens ---
  final Color brandAccent = const Color(0xFF6366F1);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color successColor = const Color(0xFF10B981);
  final Color warningColor = const Color(0xFFF59E0B);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final details = await _taskService.getVenueDashboard();
      setState(() {
        _detailsData = details;
        if (details.venues.isNotEmpty) {
          if (_selectedVenue != null) {
            // Try to find the same venue in the new data
            _selectedVenue = details.venues.firstWhere(
              (v) => v.venueId == _selectedVenue!.venueId,
              orElse: () => details.venues.first,
            );
          } else if (widget.venueId != null) {
            // Use the venueId passed in the constructor
            _selectedVenue = details.venues.firstWhere(
              (v) => v.venueId == widget.venueId,
              orElse: () => details.venues.first,
            );
          } else {
            _selectedVenue = details.venues.first;
          }
        }
        _isLoading = false;
      });
      if (_selectedVenue != null) {
        _fetchHistory(_selectedVenue!.venueId);
      }
    } catch (e) {
      debugPrint("Error fetching venue details: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHistory(int venueId) async {
    setState(() => _isHistoryLoading = true);
    try {
      final history = await _taskService.getVenueHistory(venueId: venueId);
      setState(() {
        _historyData = history;
        _isHistoryLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching venue history: $e");
      setState(() => _isHistoryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: DashboardSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchInitialData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVenueSelector(),
                    const SizedBox(height: 24),
                    if (_selectedVenue != null) ...[
                      _buildStatusRow(),
                      const SizedBox(height: 24),
                      _buildQuickStats(),
                      const SizedBox(height: 32),
                      // --- Today's Schedule (all bookings, dashboard style) ---
                      _buildSectionHeader(
                        "Today's Schedule",
                        "View All",
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VenueSchedulePage(),
                          ),
                        ),
                      ),
                      if (_selectedVenue!.today.confirmedBookings.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "No bookings scheduled for today.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._selectedVenue!.today.confirmedBookings.take(2).map((
                          booking,
                        ) {
                          final bool isCompleted =
                              booking.status.toLowerCase() == 'completed';
                          return TaskCard(
                            title: booking.title,
                            sub:
                                "${booking.fromTime} - ${booking.toTime}  •  ${booking.status.toUpperCase()}  •  By: ${booking.bookedBy}",
                            accent: isCompleted ? successColor : brandAccent,
                            icon: isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.meeting_room_rounded,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskDetailsPage(
                                    taskData: {
                                      'task_id': booking.taskId,
                                      'title': booking.title,
                                      'isRequest': false,
                                    },
                                    viewMode: 'incharge',
                                  ),
                                ),
                              );
                              if (result != null) {
                                _fetchInitialData();
                              }
                            },
                          );
                        }),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        "Booking History",
                        "View All",
                        onAction: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VenueHistoryViewAllPage(
                                venueId: _selectedVenue!.venueId,
                                venueName: _selectedVenue!.name,
                              ),
                            ),
                          );
                          _fetchInitialData();
                        },
                      ),
                      if (_isHistoryLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_historyData == null ||
                          _historyData!.history.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Text(
                              "No history found for this venue",
                              style: TextStyle(color: AppTheme.textSub),
                            ),
                          ),
                        )
                      else
                        ..._historyData!.history
                            .take(2)
                            .map(
                              (item) => _buildHistoryItem(
                                item.title,
                                item.date,
                                item.status == 'COMPLETED'
                                    ? successColor
                                    : (item.status == 'REJECTED'
                                          ? Colors.redAccent
                                          : warningColor),
                                userName: item.userName,
                              ),
                            ),
                    ] else
                      const Center(child: Text("No venues assigned to you")),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueSelector() {
    if (_detailsData == null || _detailsData!.totalVenuesManaged <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brandAccent.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: brandAccent.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VenueDetailItem>(
          value: _selectedVenue,
          isExpanded: true,
          icon: Icon(Icons.unfold_more_rounded, color: brandAccent, size: 20),
          items: _detailsData!.venues.map((venue) {
            return DropdownMenuItem(
              value: venue,
              child: Row(
                children: [
                  Icon(
                    Icons.stadium_rounded,
                    size: 18,
                    color: brandAccent.withOpacity(0.7),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    venue.name,
                    style: TextStyle(
                      color: textMain,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedVenue = val;
              });
              _fetchHistory(val.venueId);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';
    final photoUrl = _selectedVenue?.photo != null
        ? (backendUrl.replaceAll('/api/', '') + _selectedVenue!.photo!)
        : 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTTGGNugQWH_yx2ZaReTajVjGsZLoUVK9SpkA&s';

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: brandAccent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.network(
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTTGGNugQWH_yx2ZaReTajVjGsZLoUVK9SpkA&s',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    final statusText =
        _selectedVenue?.currentStatus.replaceAll('_', ' ').toUpperCase() ??
        "AVAILABLE";
    final isBooked = _selectedVenue?.currentStatus == 'fully_booked';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedVenue?.name ?? "Venue",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              "CURRENT STATUS",
              style: TextStyle(
                color: textSub,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: isBooked ? warningColor : successColor,
                  size: 10,
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statTile(
          _selectedVenue?.overallTotalTasks.toString() ?? "0",
          "Total Bookings",
          brandAccent,
          Icons.calendar_month_rounded,
        ),
        const SizedBox(width: 12),
        _statTile(
          _selectedVenue?.newRequestsPendingCount.toString() ?? "0",
          "New Requests",
          warningColor,
          Icons.notification_important_rounded,
        ),
      ],
    );
  }

  Widget _statTile(String val, String label, Color col, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: col.withOpacity(0.1), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: col, size: 24),
            const SizedBox(height: 12),
            Text(
              val,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textMain,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textSub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }

  Widget _buildSectionHeader(
    String title,
    String action, {
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: textSub,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          InkWell(
            onTap: onAction,
            child: Text(
              action,
              style: TextStyle(
                color: brandAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    String title,
    String date,
    Color statusCol, {
    String? userName,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(color: statusCol, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  userName ?? "Unknown User",
                  style: TextStyle(
                    color: textSub.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
