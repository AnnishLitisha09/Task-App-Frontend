import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../components/skeleton_loader.dart';
import '../common/task_detail_page.dart';
import '../../services/venue_notifier.dart';

class AllSchedulePage extends StatefulWidget {
  final String userRole;

  const AllSchedulePage({super.key, required this.userRole});

  @override
  State<AllSchedulePage> createState() => _AllSchedulePageState();
}

class _AllSchedulePageState extends State<AllSchedulePage> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    VenueNotifier.venueNotifier.addListener(_fetch);
  }

  @override
  void dispose() {
    VenueNotifier.venueNotifier.removeListener(_fetch);
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final TaskService taskService = TaskService();
      final List<dynamic> raw = await taskService.getAllTasksToday();
      
      // Sort tasks by start time for the timeline
      raw.sort((a, b) {
        final aTiming = a['timing'] as Map<String, dynamic>? ?? {};
        final bTiming = b['timing'] as Map<String, dynamic>? ?? {};
        String tA = aTiming['start_time'] ?? '23:59';
        String tB = bTiming['start_time'] ?? '23:59';
        return tA.compareTo(tB);
      });

      if (mounted) {
        setState(() {
          _tasks = raw;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("AllSchedulePage Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Status helpers ─────────────────────────────────────────────────────────
  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppTheme.brandAccent; // Was success
      case 'in_progress':
      case 'in progress':
        return AppTheme.brandAccent;
      case 'overdue':
        return AppTheme.danger;
      case 'pending':
        return AppTheme.warning;
      case 'accepted':
        return AppTheme.info; // Was success
      default:
        return AppTheme.textSub;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'in_progress':
      case 'in progress':
        return Icons.timelapse_rounded;
      case 'overdue':
        return Icons.error_rounded;
      case 'pending':
        return Icons.radio_button_unchecked_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'N/A') return 'N/A';
    // If it's already HH:mm, just return it
    if (raw.length == 5 && raw.contains(':')) return raw;
    try {
      // Try parsing if it's a full ISO string
      final dt = DateTime.parse(raw);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMMM dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Decorative background blobs
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Custom header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        color: AppTheme.textMain,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Schedule",
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
                                color: AppTheme.textSub.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isLoading && _tasks.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.brandAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.brandAccent.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.checklist_rtl_rounded,
                                color: AppTheme.brandAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${_tasks.length} tasks",
                                style: const TextStyle(
                                  color: AppTheme.brandAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scaleXY(begin: 0.9),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.1, curve: Curves.easeOutCubic),

                const SizedBox(height: 8),

                // ── Progress summary bar ───────────────────────────────────
                if (!_isLoading && _tasks.isNotEmpty)
                  _buildProgressBar()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.15),

                const SizedBox(height: 8),

                // ── Task list or empty state ───────────────────────────────
                Expanded(
                  child: _isLoading 
                    ? _buildSkeleton()
                    : _tasks.isEmpty
                      ? _buildEmptyState()
                      : _buildCategorizedList(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SkeletonTaskCard(),
          SkeletonTaskCard(),
          SkeletonTaskCard(),
          SkeletonTaskCard(),
        ],
      ),
    );
  }

  // ── Progress summary bar ───────────────────────────────────────────────────
  Widget _buildProgressBar() {
    final completedCount = _tasks.where((t) => 
      t['status']?.toLowerCase() == 'completed').length;
    final total = _tasks.length;
    final progress = total > 0 ? completedCount / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daily Progress",
                style: TextStyle(
                  color: AppTheme.textMain.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: AppTheme.brandAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.brandAccent.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandAccent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Categorized List ──────────────────────────────────────────────────────
  Widget _buildCategorizedList(BuildContext context) {
    final floating = _tasks.where((t) {
      final timing = t['timing'] as Map<String, dynamic>? ?? {};
      return timing['task_name'] == 'Floating Task';
    }).toList();

    final longAndPackage = _tasks.where((t) {
      final timing = t['timing'] as Map<String, dynamic>? ?? {};
      final isPackage = t['is_package'] == true;
      final tn = timing['task_name'] ?? '';
      return tn.contains('Long Task') || tn == 'Package Task' || isPackage;
    }).toList();

    final timelineTasks = _tasks.where((t) {
      final timing = t['timing'] as Map<String, dynamic>? ?? {};
      final isPackage = t['is_package'] == true;
      final tn = timing['task_name'] ?? '';
      return tn != 'Floating Task' && !tn.contains('Long Task') && tn != 'Package Task' && !isPackage;
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppTheme.brandAccent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
        children: [
          if (floating.isNotEmpty) ...[
            _buildSectionHeader("Floating Tasks", Icons.cloud_queue_rounded, AppTheme.warning),
            ...floating.map((t) => _buildMinimalTaskCard(context, t, "Floating")),
            const SizedBox(height: 24),
          ],
          if (longAndPackage.isNotEmpty) ...[
            _buildSectionHeader("Long & Package Tasks", Icons.layers_rounded, AppTheme.brandAccent),
            ...longAndPackage.map((t) => _buildMinimalTaskCard(context, t, _getTaskDenotation(t))),
            const SizedBox(height: 24),
          ],
          if (timelineTasks.isNotEmpty) ...[
            _buildSectionHeader("Today's Timeline", Icons.access_time_filled_rounded, AppTheme.brandAccent),
            ...timelineTasks.map((t) => _buildMinimalTaskCard(context, t, null)),
          ],
        ],
      ),
    );
  }

  String _getTaskDenotation(Map<String, dynamic> task) {
    if (task['is_package'] == true || (task['timing']?['task_name'] == 'Package Task')) {
      return "Package";
    }
    return "Long Task";
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

  Widget _buildMinimalTaskCard(BuildContext context, Map<String, dynamic> item, String? typeLabel) {
    final status = item['status'] as String?;
    final statusColor = _statusColor(status);
    final statusIcon = _statusIcon(status);
    final timing = item['timing'] as Map<String, dynamic>? ?? {};
    final startTime = _formatTime(timing['start_time']);
    final endTime = _formatTime(timing['end_time']);
    final heroTag = "schedule_all_${item['task_id']}_${item.hashCode}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailsPage(
              taskData: {
                'task_id': item['task_id'],
                'title': item['title'],
                'sub': item['status'],
                'accent': statusColor,
                'icon': Icons.calendar_today_rounded,
                'heroTag': heroTag,
                'startDate': timing['start_date'] ?? "N/A",
                'deadline': timing['end_date'] ?? "N/A",
                'completionType': "INFO",
                'isRequest': false,
                'userRole': widget.userRole,
              },
            ),
          ),
        ).then((result) { if (mounted && result == true) _fetch(); }),
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
                              child: Text(
                                item['title'] ?? 'Task',
                                style: const TextStyle(
                                  color: AppTheme.textMain,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(statusIcon, size: 14, color: statusColor),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                            if (startTime != 'N/A') ...[
                              Icon(Icons.schedule_rounded, size: 12, color: AppTheme.textSub.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Text(
                                endTime != 'N/A' ? "$startTime - $endTime" : startTime,
                                style: TextStyle(
                                  color: AppTheme.textSub.withOpacity(0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              (status ?? 'Pending').toUpperCase(),
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



  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.brandAccent.withOpacity(0.08),
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 44,
              color: AppTheme.brandAccent.withOpacity(0.5),
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.06, duration: 1800.ms),
          const SizedBox(height: 20),
          const Text(
            "All clear for today!",
            style: TextStyle(
              color: AppTheme.textMain,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No tasks are scheduled for today.",
            style: TextStyle(
              color: AppTheme.textSub.withOpacity(0.7),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      )
      .animate()
      .fadeIn(duration: 500.ms)
      .scaleXY(begin: 0.92, curve: Curves.easeOutBack),
    );
  }
}

