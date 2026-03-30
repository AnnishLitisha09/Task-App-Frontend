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
  bool _hasChanges = false;
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


  void _showUpdateDialog(int venueId, String currentStatus) {
    // Normalize mapping from legacy/vague statuses to officially supported ones
    String selectedStatus = currentStatus.toLowerCase();
    if (selectedStatus == 'free' || selectedStatus == 'available') {
      selectedStatus = 'open';
    } else if (selectedStatus == 'maintenance') {
      selectedStatus = 'under maintenance';
    } else if (selectedStatus == 'closed') {
      selectedStatus = 'temporarily closed';
    }
    
    // Safety check: ensure the status exists in our list. If not, default to open.
    const validStatuses = [
      'open', 
      'under maintenance', 
      'temporarily closed', 
      'renovation', 
      'full day booked'
    ];
    if (!validStatuses.contains(selectedStatus)) {
      selectedStatus = 'open';
    }

    final reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.brandAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppTheme.brandAccent, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Venue Control", style: AppTheme.h1),
                            Text("Manage operational state", style: AppTheme.bodySub),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Target Stage".toUpperCase(),
                      style: AppTheme.overline.copyWith(color: AppTheme.textSub, fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dividerColor, width: 2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.unfold_more_rounded, color: AppTheme.textSub),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedStatus = val);
                          },
                          items: [
                            'open', 
                            'under maintenance', 
                            'temporarily closed', 
                            'renovation', 
                            'full day booked'
                          ].map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s.replaceAll('_', ' ').toUpperCase(), 
                              style: AppTheme.bodyMain.copyWith(fontSize: 14),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Remark (Optional)".toUpperCase(),
                      style: AppTheme.overline.copyWith(color: AppTheme.textSub, fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: AppTheme.bodyMain.copyWith(fontSize: 14, fontWeight: FontWeight.normal),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Add internal note for log history...",
                        hintStyle: AppTheme.bodySub,
                        contentPadding: const EdgeInsets.all(20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.dividerColor, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.dividerColor, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.brandAccent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text("Cancel", style: TextStyle(color: AppTheme.textSub)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateStatus(venueId, selectedStatus, reason: reasonController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("Save", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _updateStatus(int venueId, String newStatus, {String? reason}) async {
    try {
      await _resourceService.updateVenueStatus(venueId, newStatus, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Venue status successfully updated to ${newStatus.toUpperCase()}"),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _hasChanges = true;
          _fetchData(); // Refresh
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Infrastructure Control",
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
              displacement: 20,
              color: AppTheme.brandAccent,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _data?.venues.length ?? 0,
                itemBuilder: (context, index) {
                  final venue = _data!.venues[index];
                  String displayStatus =
                      venue.currentStatus.replaceAll('_', ' ').toUpperCase();
                  final color = _getStatusColor(displayStatus);
                  final history = _venueHistories[venue.venueId] ?? [];
                  final isHistLoading = _historyLoading[venue.venueId] ?? false;

                  return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: AppTheme.cardDecoration.copyWith(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(Icons.business_rounded, color: color, size: 32),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(venue.name, style: AppTheme.h2),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              displayStatus,
                                              style: AppTheme.overline.copyWith(color: color, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Material(
                                    color: AppTheme.brandPrimary,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onTap: () => _showUpdateDialog(venue.venueId, venue.currentStatus),
                                      borderRadius: BorderRadius.circular(16),
                                      child: const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isHistLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: LinearProgressIndicator(minHeight: 1),
                              ),
                            if (history.isNotEmpty)
                              _buildTimelineSection(history),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 120).ms)
                      .moveY(begin: 30, end: 0, curve: Curves.easeOutBack);
                },
              ),
            ),
      ),
    );
  }

  Widget _buildTimelineSection(List<Map<String, dynamic>> history) {
    return Container(
      width: double.infinity,
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text("OPERATION LOGS", style: AppTheme.overline.copyWith(letterSpacing: 2)),
          const SizedBox(height: 16),
          ...history.take(2).map((log) {
            String logStatus = (log['status'] ?? 'Updated').toString().toUpperCase();
            DateTime logDate = DateTime.tryParse(log['created_at']?.toString() ?? '') ?? DateTime.now();
            final logColor = _getStatusColor(logStatus);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: logColor,
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(width: 1, height: 30, color: AppTheme.dividerColor),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              log['issue_title'] ?? "State Change",
                              style: AppTheme.bodySub.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const Spacer(),
                            Text(
                              "${logDate.day}/${logDate.month} ${logDate.hour}:${logDate.minute.toString().padLeft(2, '0')}",
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                        if (log['description'] != null && log['description'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              log['description'],
                              style: AppTheme.bodySub.copyWith(fontSize: 10, color: AppTheme.textSub),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
