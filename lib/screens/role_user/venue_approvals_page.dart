import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../models/venue_dashboard_model.dart';
import '../../components/task_card.dart';
import '../../components/skeleton_loader.dart';
import '../common/task_detail_page.dart';

class VenueApprovalsPage extends StatefulWidget {
  const VenueApprovalsPage({super.key});

  @override
  State<VenueApprovalsPage> createState() => _VenueApprovalsPageState();
}

class _VenueApprovalsPageState extends State<VenueApprovalsPage> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  bool _hasChanges = false;
  List<dynamic> _groupedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchApprovals();
  }

  void _processApprovals(List<BookingWithVenue> approvals) {
    if (approvals.isEmpty) {
      _groupedItems = [];
      return;
    }

    // Sort by fromTime
    approvals.sort((a, b) => a.booking.fromTime.compareTo(b.booking.fromTime));

    List<dynamic> result = [];
    String currentHeader = '';

    for (var a in approvals) {
      String start = a.booking.fromTime;
      String end = a.booking.toTime;

      // Clean up seconds if present
      if (start.length > 5) start = start.substring(0, 5);
      if (end.length > 5) end = end.substring(0, 5);

      String header = end.isNotEmpty ? '$start - $end' : start;
      if (header != currentHeader) {
        currentHeader = header;
        result.add({'isHeader': true, 'title': currentHeader});
      }
      result.add(a);
    }

    _groupedItems = result;
  }

  Future<void> _fetchApprovals() async {
    setState(() => _isLoading = true);
    try {
      final details = await _taskService.getVenueDashboard();
      final List<BookingWithVenue> allPending = [];

      for (var venue in details.venues) {
        for (var booking in venue.pendingApprovalTasks) {
          allPending.add(
            BookingWithVenue(venueName: venue.name, booking: booking),
          );
        }
      }

      setState(() {
        _processApprovals(allPending);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching approvals: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(int taskId, bool approve) async {
    // Optimistic UI update: Remove the item immediately
    int removedIndex = -1;

    setState(() {
      _hasChanges = true;
      removedIndex = _groupedItems.indexWhere(
        (item) => item is BookingWithVenue && item.booking.taskId == taskId,
      );
      if (removedIndex != -1) {
        _groupedItems.removeAt(removedIndex);
        // Clean up empty headers
        if (removedIndex < _groupedItems.length &&
            _groupedItems[removedIndex] is Map &&
            _groupedItems[removedIndex]['isHeader'] == true) {
          // header stayed, check if next is also header or end
          if (removedIndex + 1 >= _groupedItems.length ||
              (_groupedItems[removedIndex + 1] is Map &&
                  _groupedItems[removedIndex + 1]['isHeader'] == true)) {
            // skip cleaning for now or do it properly
          }
        }
        // re-process to be safe and clean
        List<BookingWithVenue> remaining = _groupedItems
            .whereType<BookingWithVenue>()
            .toList();
        _processApprovals(remaining);
      }
    });

    try {
      if (approve) {
        await _taskService.acceptTask(taskId);
      } else {
        await _taskService.rejectTask(taskId, "Rejected by manager");
      }
      // Re-fetch to ensure sync with server
      _fetchApprovals();
    } catch (e) {
      debugPrint("Error performing action: $e");
      // Revert if failed
      _fetchApprovals();
    }
  }

  @override
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
            "Pending Approvals",
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
                ? const Center(child: Text("No pending approvals found"))
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

                      final approvalItem = item as BookingWithVenue;
                      return TaskCard(
                        title: approvalItem.booking.title,
                        sub:
                            "${approvalItem.venueName} • By: ${approvalItem.booking.bookedBy}",
                        accent: AppTheme.warning,
                        icon: Icons.bolt_rounded,
                        isRequest: true,
                        onAccept: () =>
                            _handleAction(approvalItem.booking.taskId, true),
                        onReject: () =>
                            _handleAction(approvalItem.booking.taskId, false),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailsPage(
                                taskData: {
                                  'task_id': approvalItem.booking.taskId,
                                  'title': approvalItem.booking.title,
                                  'isRequest': true,
                                },
                                viewMode: 'incharge',
                              ),
                            ),
                          );
                          if (result == true) {
                            setState(() => _hasChanges = true);
                            _fetchApprovals();
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class BookingWithVenue {
  final String venueName;
  final ConfirmedBooking booking;

  BookingWithVenue({required this.venueName, required this.booking});
}
