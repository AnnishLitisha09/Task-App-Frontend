import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/task_service.dart';

class PersonalCalendarPage extends StatefulWidget {
  const PersonalCalendarPage({super.key});

  @override
  State<PersonalCalendarPage> createState() => _PersonalCalendarPageState();
}

class _PersonalCalendarPageState extends State<PersonalCalendarPage> {
  DateTime _selectedDate = DateTime.now();
  final double hourHeight = 85.0; // Slightly taller for a more premium feel
  final Color brandAccent = const Color(0xFF6366F1); // Indigo
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  // API data state
  List<Map<String, dynamic>> _calendarEvents = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMonthlySchedule();
  }

  Future<void> _fetchMonthlySchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final TaskService taskService = TaskService();
      final response = await taskService.getMonthlySchedule(_selectedDate);

      if (mounted) {
        setState(() {
          _calendarEvents = _mapTasksToEvents(response['tasks'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load schedule';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _mapTasksToEvents(List<dynamic> tasks) {
    List<Map<String, dynamic>> events = [];

    for (var task in tasks) {
      // Parse start and end times
      final timing = task['timing'];
      if (timing == null) continue;

      final startTime = timing['start_time']?.toString() ?? '00:00:00';
      final endTime = timing['end_time']?.toString() ?? '00:00:00';

      // Convert HH:MM:SS to hour decimal
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');

      final double startHour =
          double.parse(startParts[0]) + (double.parse(startParts[1]) / 60);
      final double endHour =
          double.parse(endParts[0]) + (double.parse(endParts[1]) / 60);
      final double duration = (endHour - startHour) * 60; // in minutes

      // Determine color based on status
      Color taskColor;
      final status = task['status']?.toString() ?? 'pending';
      switch (status) {
        case 'accepted':
          taskColor = const Color(0xFF3B82F6); // Blue
          break;
        case 'completed':
          taskColor = const Color(0xFF10B981); // Green
          break;
        case 'pending':
        default:
          taskColor = const Color(0xFFF59E0B); // Orange
      }

      events.add({
        'title': task['title'] ?? 'Untitled Task',
        'sub': task['description'] ?? task['category'] ?? '',
        'start': startHour,
        'dur': duration,
        'color': taskColor,
        'task_id': task['task_id'],
        'assignment_id': task['assignment_id'],
      });
    }

    // --- OVERLAP CALCULATION ---
    events.sort(
      (a, b) => (a['start'] as double).compareTo(b['start'] as double),
    );

    List<List<Map<String, dynamic>>> groups = [];
    for (var event in events) {
      if (groups.isEmpty) {
        groups.add([event]);
        continue;
      }
      var currentGroup = groups.last;
      double groupMaxEnd = 0;
      for (var e in currentGroup) {
        double end = e['start'] + e['dur'] / 60;
        if (end > groupMaxEnd) groupMaxEnd = end;
      }
      if (event['start'] < groupMaxEnd) {
        currentGroup.add(event);
      } else {
        groups.add([event]);
      }
    }

    for (var group in groups) {
      List<List<Map<String, dynamic>>> cols = [];
      for (var event in group) {
        bool placed = false;
        for (var c in cols) {
          double lastEnd = c.last['start'] + c.last['dur'] / 60;
          if (lastEnd <= event['start']) {
            c.add(event);
            placed = true;
            break;
          }
        }
        if (!placed) {
          cols.add([event]);
        }
      }
      double totalCols = cols.length.toDouble();
      for (int i = 0; i < cols.length; i++) {
        for (var event in cols[i]) {
          event['colIndex'] = i;
          event['totalCols'] = totalCols;
        }
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: brandAccent.withOpacity(0.05), width: 1),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeColumn(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              _buildRefinedGrid(),
                              ..._calendarEvents.map(
                                (task) => _buildLightEventCard(
                                  task,
                                  constraints.maxWidth,
                                ),
                              ),
                              _buildModernTimeIndicator(),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6366F1),
                    ),
                  ),
                ),
              if (_errorMessage != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: brandAccent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${_calendarEvents.length} events scheduled",
                  style: TextStyle(
                    fontSize: 12,
                    color: slate500.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }
      ),
      actions: [
        IconButton(
          onPressed: _showDatePicker,
          icon: Icon(
            Icons.calendar_month_rounded,
            color: brandAccent.withOpacity(0.8),
          ),
          tooltip: 'Select Date',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: brandAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchMonthlySchedule();
    }
  }

  Widget _buildLightEventCard(Map<String, dynamic> task, double maxWidth) {
    double start = (task['start'] as num).toDouble();
    double duration = (task['dur'] as num).toDouble() / 60;
    Color taskColor = task['color'] ?? brandAccent;

    int colIndex = task['colIndex'] ?? 0;
    double totalCols = task['totalCols']?.toDouble() ?? 1.0;

    double horizontalPadding = 22.0; 
    double availableWidth = maxWidth - horizontalPadding;
    double cardWidth = availableWidth / totalCols;
    double left = 10 + (colIndex * cardWidth);

    // FIX: Ensure minimum height and prevent overflow for short tasks
    double cardHeight = (duration * hourHeight) - 4;
    if (cardHeight < 30) cardHeight = 30; // Minimum usable height

    return Positioned(
      top: start * hourHeight + 2,
      left: left,
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: taskColor.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: taskColor.withOpacity(0.12), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              Container(
                width: 3.5,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: taskColor,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: duration < 0.4 ? 2 : 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        task['title'] ?? "Event",
                        style: TextStyle(
                          color: taskColor.withAlpha(220),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (duration > 0.6) ...[
                        const SizedBox(height: 1),
                        Text(
                          task['sub'] ?? "",
                          style: TextStyle(
                            color: slate500.withOpacity(0.55),
                            fontSize: 10,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().moveY(begin: 5, end: 0),
    );
  }

  Widget _buildTimeColumn() {
    return Container(
      width: 60,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: List.generate(
          24,
          (i) => Container(
            height: hourHeight,
            alignment: Alignment.topCenter,
            child: Text(
              "${i.toString().padLeft(2, '0')}:00",
              style: TextStyle(
                color: slate500.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefinedGrid() {
    return Column(
      children: List.generate(
        24,
        (index) => Container(
          height: hourHeight,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: brandAccent.withOpacity(0.03),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTimeIndicator() {
    final now = DateTime.now();
    final double top = (now.hour + (now.minute / 60)) * hourHeight;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: brandAccent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(height: 1, color: brandAccent.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }
}
