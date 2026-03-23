import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../models/venue_history_model.dart';
import '../../components/skeleton_loader.dart';

class VenueHistoryViewAllPage extends StatefulWidget {
  final int venueId;
  final String venueName;

  const VenueHistoryViewAllPage({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  @override
  State<VenueHistoryViewAllPage> createState() =>
      _VenueHistoryViewAllPageState();
}

class _VenueHistoryViewAllPageState extends State<VenueHistoryViewAllPage> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  VenueHistoryResponse? _historyData;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      // Fetch long history (30 days for view all)
      final data = await _taskService.getVenueHistory(
        venueId: widget.venueId,
        days: 30,
      );
      setState(() {
        _historyData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "${widget.venueName} History",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textMain,
        elevation: 0,
      ),
      body: _isLoading
          ? const _HistorySkeleton()
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              child: _historyData == null || _historyData!.history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: AppTheme.textSub.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No history records found",
                            style: TextStyle(color: AppTheme.textSub),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _historyData!.history.length,
                      itemBuilder: (context, index) {
                        final item = _historyData!.history[index];
                        return _buildHistoryItem(item);
                      },
                    ),
            ),
    );
  }

  Widget _buildHistoryItem(VenueHistoryItem item) {
    final statusCol = item.status == 'COMPLETED'
        ? AppTheme.success
        : (item.status == 'REJECTED' ? AppTheme.danger : AppTheme.warning);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceColor, width: 2),
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
                  item.title,
                  style: const TextStyle(
                    color: AppTheme.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  item.userName ?? "Unknown User",
                  style: const TextStyle(color: AppTheme.textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatItemDate(item.date),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  String _formatItemDate(String dateStr) {
    if (dateStr.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (e) {
      debugPrint("Error parsing date: $dateStr - $e");
      return dateStr;
    }
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 8,
      itemBuilder: (_, __) => const SkeletonTaskCard(),
    );
  }
}
