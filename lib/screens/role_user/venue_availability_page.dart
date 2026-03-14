import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../services/resource_service.dart';
import '../../models/venue_dashboard_model.dart';
import '../../components/skeleton_loader.dart';

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

  void _showUpdateStatusPopup(VenueDetailItem venue) {
    String selectedStatus =
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
                    'TEMPORARILY CLOSED',
                    'UNDER MAINTENANCE',
                    'RENOVATION',
                    'FULL DAY BOOKED',
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
              onPressed: () async {
                try {
                  await _taskService.updateVenueStatus(
                    venue.venueId,
                    selectedStatus,
                    reasonController.text.isEmpty
                        ? 'Manual Update'
                        : reasonController.text,
                  );
                  Navigator.pop(context);
                  _fetchData(); // Reload UI to fetch the latest genuine status
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${venue.name} status updated.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
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
          initialValue: items.contains(current) ? current : items.first,
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
                                  if (_historyLoading[venue.venueId] == true)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandAccent),
                                        ),
                                      ),
                                    )
                                    else if (_venueHistories[venue.venueId] != null && _venueHistories[venue.venueId]!.isNotEmpty)
                                    ...(_venueHistories[venue.venueId]!
                                        .take(5) // Show latest 5
                                        .map(
                                          (h) => _buildHistoryTimelineItem(h),
                                        )
                                        .toList())
                                  else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        "No status changes recorded yet.",
                                        style: AppTheme.bodySub.copyWith(fontStyle: FontStyle.italic),
                                      ),
                                    ),
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

  Widget _buildHistoryTimelineItem(Map<String, dynamic> history) {
    final status = history['status']?.toString().replaceAll('_', ' ') ?? 'UNKNOWN';
    final color = _getStatusColor(status);
    String timeStr = 'N/A';
    try {
      final rawTime = history['created_at'] ?? history['start_time'];
      if (rawTime != null) {
        timeStr = rawTime.toString().substring(0, 16).replaceAll('T', ' ');
      }
    } catch (e) {
      debugPrint("Error formatting time: $e");
    }
    final category = history['category'] ?? 'General';
    final isStatusChange = category == 'Status Change';
        
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              Container(
                width: 1.5,
                height: 40,
                color: AppTheme.dividerColor,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isStatusChange ? "STATUS CHANGE" : category.toString().toUpperCase(),
                      style: AppTheme.bodyMain.copyWith(
                        color: isStatusChange ? color : AppTheme.brandAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: AppTheme.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  history['issue_title'] ?? status.toUpperCase(),
                  style: AppTheme.h2.copyWith(fontSize: 14),
                ),
                if (history['description'] != null || history['notes'] != null || history['reason'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    history['description'] ?? history['notes'] ?? history['reason'] ?? '',
                    style: AppTheme.bodySub.copyWith(
                      fontSize: 13,
                      color: AppTheme.textSub,
                    ),
                  ),
                ],
                if (history['resource_name'] != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Resource: ${history['resource_name']}",
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.brandPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
