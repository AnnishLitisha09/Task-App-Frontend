import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../services/resource_service.dart';
import '../../models/venue_dashboard_model.dart';
import '../../components/skeleton_loader.dart';
import '../../services/venue_notifier.dart';

class VenueAvailabilityPage extends StatefulWidget {
  const VenueAvailabilityPage({super.key});

  @override
  State<VenueAvailabilityPage> createState() => _VenueAvailabilityPageState();
}

class _VenueAvailabilityPageState extends State<VenueAvailabilityPage> {
  final TaskService _taskService = TaskService();
  final ResourceService _resourceService = ResourceService();
  bool _isLoading = true;
  VenueDetailsResponse? _data;

  // Real history mapping
  final Map<int, List<Map<String, dynamic>>> _venueHistories = {};
  final Map<int, bool> _historyLoading = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
    VenueNotifier.venueNotifier.addListener(_fetchData);
  }

  @override
  void dispose() {
    VenueNotifier.venueNotifier.removeListener(_fetchData);
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _taskService.getVenueDashboard();
      setState(() {
        _data = data;
        _isLoading = false;
      });
      
      // Fetch history for each venue
      if (_data != null) {
        for (var venue in _data!.venues) {
          _fetchVenueHistory(venue.venueId);
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchVenueHistory(int venueId) async {
    setState(() => _historyLoading[venueId] = true);
    try {
      final history = await _resourceService.getVenueStatusHistory(venueId);
      setState(() {
        _venueHistories[venueId] = history;
        _historyLoading[venueId] = false;
      });
    } catch (e) {
      debugPrint("Error fetching history for venue $venueId: $e");
      setState(() => _historyLoading[venueId] = false);
    }
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('available') || status.contains('free') || status == 'open') {
      return AppTheme.success;
    }
    if (status.contains('maintenance') || status.contains('renovation')) {
      return AppTheme.danger;
    }
    if (status.contains('closed') || status.contains('not in use')) {
      return Colors.grey;
    }
    if (status.contains('full day booked') || status.contains('fully booked')) {
      return AppTheme.warning;
    }
    return AppTheme.brandAccent; // partially booked, etc.
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Venue Management",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppTheme.textMain,
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: DashboardSkeleton(),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _data?.venues.length ?? 0,
                itemBuilder: (context, index) {
                  final venue = _data!.venues[index];
                  String displayStatus =
                      venue.currentStatus.replaceAll('_', ' ').toUpperCase();
                  final color = _getStatusColor(displayStatus);

                  return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: AppTheme.cardDecoration,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.all(20),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.meeting_room_rounded,
                                  color: color,
                                ),
                              ),
                              title: Text(venue.name, style: AppTheme.h2),
                              subtitle: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    displayStatus,
                                    style: AppTheme.caption.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .slideY(begin: 0.1);
                },
              ),
            ),
    );
  }

}
