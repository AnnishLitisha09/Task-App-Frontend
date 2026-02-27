import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../models/venue_dashboard_model.dart';
import '../../components/skeleton_loader.dart';

class VenueAvailabilityPage extends StatefulWidget {
  const VenueAvailabilityPage({super.key});

  @override
  State<VenueAvailabilityPage> createState() => _VenueAvailabilityPageState();
}

class _VenueAvailabilityPageState extends State<VenueAvailabilityPage> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  VenueDetailsResponse? _data;

  final Map<int, String> _localStatuses = {};

  final Map<int, List<Map<String, String>>> _statusHistory = {
    4: [
      {
        'status': 'Available',
        'time': 'Feb 27, 09:00 AM',
        'reason': 'Maintenance Completed',
      },
      {
        'status': 'Under Maintenance',
        'time': 'Feb 26, 02:00 PM',
        'reason': 'AC Repair',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _taskService.getVenueDashboard();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('available') || status.contains('free'))
      return AppTheme.success;
    if (status.contains('maintenance')) return AppTheme.danger;
    if (status.contains('not in use') || status.contains('closed'))
      return Colors.grey;
    return AppTheme.warning; // Booked
  }

  void _showUpdateStatusPopup(VenueDetailItem venue) {
    String selectedStatus =
        _localStatuses[venue.venueId] ??
        venue.currentStatus.replaceAll('_', ' ').toUpperCase();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Update Status", style: AppTheme.h1.copyWith(fontSize: 24)),
              const SizedBox(height: 6),
              Text(venue.name, style: AppTheme.bodySub.copyWith(fontSize: 15)),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdown(
                  "Set Status",
                  [
                    'OPEN',
                    'TEMPORARILY_CLOSED',
                    'UNDER MAINTENANCE',
                    'RENOVATION',
                    'RESERVED',
                  ],
                  (v) {
                    setDialogState(() => selectedStatus = v!);
                  },
                  selectedStatus,
                ),
                const SizedBox(height: 24),
                _buildField(
                  "Reason / Note",
                  "Why is the status changing?",
                  reasonController,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: AppTheme.textSub,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _localStatuses[venue.venueId] = selectedStatus;
                  if (!_statusHistory.containsKey(venue.venueId)) {
                    _statusHistory[venue.venueId] = [];
                  }
                  _statusHistory[venue.venueId]!.insert(0, {
                    'status': selectedStatus,
                    'time': 'Just Now',
                    'reason': reasonController.text.isEmpty
                        ? 'Manual Update'
                        : reasonController.text,
                  });
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Save Status",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSub.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSub.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.brandPrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    ValueChanged<String?> onChanged,
    String current,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: items.contains(current) ? current : items.first,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSub.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSub.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.brandPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
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
                      _localStatuses[venue.venueId] ??
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_note_rounded,
                                      color: AppTheme.brandAccent,
                                    ),
                                    onPressed: () =>
                                        _showUpdateStatusPopup(venue),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 20),
                                  const SizedBox(height: 12),
                                  Text(
                                    "STATUS HISTORY",
                                    style: AppTheme.overline,
                                  ),
                                  const SizedBox(height: 16),
                                  ...((_statusHistory[venue.venueId] ??
                                          _statusHistory[4]!)
                                      .map((h) => _buildHistoryTimelineItem(h))
                                      .toList()),
                                ],
                              ),
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

  Widget _buildHistoryTimelineItem(Map<String, String> history) {
    final color = _getStatusColor(history['status']!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2.5),
                ),
              ),
              Container(
                width: 2.0,
                height: 50,
                color: AppTheme.textSub.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      history['status']!,
                      style: AppTheme.bodyMain.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      history['time']!,
                      style: AppTheme.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  history['reason']!,
                  style: AppTheme.bodySub.copyWith(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textMain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
