import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../components/skeleton_loader.dart';
import '../../services/resource_service.dart';
import '../../services/venue_notifier.dart';

class MaintenanceLogsPage extends StatefulWidget {
  const MaintenanceLogsPage({super.key});

  @override
  State<MaintenanceLogsPage> createState() => _MaintenanceLogsPageState();
}

class _MaintenanceLogsPageState extends State<MaintenanceLogsPage> {
  final ResourceService _resourceService = ResourceService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _venues = [];
  
  // Filtering state
  DateTime? _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initData();
    VenueNotifier.venueNotifier.addListener(_fetchLogs);
  }

  @override
  void dispose() {
    VenueNotifier.venueNotifier.removeListener(_fetchLogs);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _fetchVenues();
    _fetchLogs();
  }

  Future<void> _fetchVenues() async {
    try {
      final venues = await _resourceService.getVenues();
      setState(() {
        _venues = venues;
      });
    } catch (e) {
      debugPrint("Error fetching venues: $e");
    }
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = _selectedDate == null 
          ? null 
          : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      
      final logs = await _resourceService.getMaintenanceLogs(
        venueId: null, // Removed venue filter per user request
        date: dateStr,
      );
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching maintenance logs: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showAddLogPopup() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final costController = TextEditingController();
    // Pre-select venue if only one exists or use global selection
    int? selectedVenueId = VenueNotifier.currentVenueId;
    if (selectedVenueId == null && _venues.length == 1) {
      selectedVenueId = _venues[0]['venue_id'] ?? _venues[0]['id'];
    }
    String selectedCategory = 'general';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          title: Text(
            "New Maintenance Log",
            style: AppTheme.h1.copyWith(fontSize: 24),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDropdown(
                    "Venue",
                    _venues
                        .where((v) => (v['venue_id'] ?? v['id']) == selectedVenueId)
                        .map((v) {
                           final n = v['name'] as String? ?? 'Unknown';
                           final s = v['booking_status'] ?? v['status'] ?? 'unknown';
                           return '$n (${s.toString().toUpperCase()})';
                        })
                        .toList(),
                    (v) {
                      // Handled by lock
                    },
                    selectedVenueId != null 
                        ? (() {
                             final v = _venues.firstWhere((v) => (v['venue_id'] ?? v['id']) == selectedVenueId);
                             final n = v['name'] as String? ?? 'Unknown';
                             final s = v['booking_status'] ?? v['status'] ?? 'unknown';
                             return '$n (${s.toString().toUpperCase()})';
                          })()
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    "Issue Title",
                    "e.g. Projector not working",
                    titleController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          "Category",
                          [
                            'electrical',
                            'plumbing',
                            'network',
                            'civil',
                            'furniture',
                            'general',
                          ],
                          (v) => setDialogState(() => selectedCategory = v!),
                          selectedCategory,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildField(
                          "Cost Est. (₹)",
                          "0",
                          costController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    "Description / Action Taken",
                    "Provide more details...",
                    descriptionController,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: AppTheme.textSub,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || selectedVenueId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Title and Venue are required")),
                  );
                  return;
                }
                
                try {
                   final payload = {
                    'venue_id': selectedVenueId,
                    'issue_title': titleController.text,
                    'category': selectedCategory,
                    'description': descriptionController.text,
                    'cost': double.tryParse(costController.text) ?? 0.0,
                    'status': 'pending',
                    'start_time': DateTime.now().toIso8601String().split('T')[0],
                  };
                  
                  await _resourceService.addMaintenanceLog(payload);
                  Navigator.pop(context);
                  _fetchLogs();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error saving log: $e")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Save Log",
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
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 12),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
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
    String? current,
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
          initialValue: current,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          isExpanded: true,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSub.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSub.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.brandAccent, width: 2),
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
          "Maintenance Activity",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppTheme.textMain,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLogPopup,
        backgroundColor: AppTheme.brandAccent,
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text(
          "Report Issue",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: DashboardSkeleton(),
                  )
                : _filteredLogs.isEmpty 
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchLogs,
                      color: AppTheme.brandAccent,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
                        itemCount: _filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = _filteredLogs[index];
                          final String status = (log['status'] ?? 'pending').toLowerCase();
                          final bool isDone = status == 'completed';
                          final color = isDone
                              ? AppTheme.success
                              : (status == 'in_progress' || status == 'ongoing'
                                    ? AppTheme.brandAccent
                                    : AppTheme.warning);

                          final String title = log['issue_title'] ?? 'Maintenance';
                          final String venue = log['Venue'] != null ? log['Venue']['name'] : 'Venue ${log['venue_id']}';
                          final String date = log['start_time'] ?? 'N/A';
                          final String cost = "₹${log['cost'] ?? 0}";
                          final String actionTaken = log['description'] ?? 'No details provided.';

                          return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: AppTheme.cardDecoration,
                                clipBehavior: Clip.antiAlias,
                                child: ExpansionTile(
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide.none,
                                  ),
                                  collapsedShape: const RoundedRectangleBorder(
                                    side: BorderSide.none,
                                  ),
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.build_circle_outlined,
                                      color: color,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: AppTheme.h1.copyWith(fontSize: 16),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: AppTheme.textSub,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            venue,
                                            style: AppTheme.bodySub.copyWith(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        cost,
                                        style: AppTheme.h1.copyWith(fontSize: 16),
                                      ),
                                      Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      color: AppTheme.surfaceColor.withOpacity(0.5),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "MAINTENANCE DETAILS",
                                            style: AppTheme.overline.copyWith(
                                              fontSize: 11,
                                            ),
                                          ),
                                           const SizedBox(height: 12),
                                          _detailRow("CATEGORY", (log['category'] ?? 'General').toUpperCase()),
                                          _detailRow("DATE", date),
                                          _detailRow("ID", "#LOG-${log['id'] ?? '??'}"),
                                           const Divider(height: 32),
                                          Text(
                                            "RECORDS / ACTION TAKEN",
                                            style: AppTheme.overline.copyWith(
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            actionTaken,
                                            style: AppTheme.bodySub.copyWith(
                                              color: AppTheme.textMain,
                                              height: 1.6,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .slideY(begin: 0.1, delay: (index * 100).ms)
                              .fadeIn();
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_searchQuery.isEmpty) return _logs;
    final query = _searchQuery.toLowerCase();
    return _logs.where((log) {
      final title = (log['issue_title'] ?? '').toString().toLowerCase();
      final venue = (log['Venue'] != null ? log['Venue']['name'] : 'Venue ${log['venue_id']}').toString().toLowerCase();
      final desc = (log['description'] ?? '').toString().toLowerCase();
      return title.contains(query) || venue.contains(query) || desc.contains(query);
    }).toList();
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Search maintenance logs...",
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.brandAccent),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                : null,
              filled: true,
              fillColor: AppTheme.surfaceColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.brandAccent,
                        onPrimary: Colors.white,
                        onSurface: AppTheme.textMain,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _fetchLogs();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.brandAccent),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null 
                      ? "All History" 
                      : "${_selectedDate!.day} ${_selectedDate!.month == 1 ? 'Jan' : _selectedDate!.month == 2 ? 'Feb' : _selectedDate!.month == 3 ? 'Mar' : _selectedDate!.month == 4 ? 'Apr' : _selectedDate!.month == 5 ? 'May' : _selectedDate!.month == 6 ? 'Jun' : _selectedDate!.month == 7 ? 'Jul' : _selectedDate!.month == 8 ? 'Aug' : _selectedDate!.month == 9 ? 'Sep' : _selectedDate!.month == 10 ? 'Oct' : _selectedDate!.month == 11 ? 'Nov' : 'Dec'} ${_selectedDate!.year}",
                    style: AppTheme.bodyMain.copyWith(
                      fontSize: 14,
                      color: _selectedDate == null ? AppTheme.textSub : AppTheme.textMain,
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = null);
                        _fetchLogs();
                      },
                      child: Icon(Icons.close_rounded, size: 16, color: AppTheme.textSub),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn().slideX(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 80, color: AppTheme.textSub.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text(
            "No maintenance activity for today",
            style: AppTheme.h2.copyWith(color: AppTheme.textSub),
          ),
          const SizedBox(height: 8),
          Text(
            "Everything looks good in your managed venues.",
            style: AppTheme.bodySub,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodySub.copyWith(
              color: AppTheme.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
