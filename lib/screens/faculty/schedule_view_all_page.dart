import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../common/task_detail_page.dart';

class ScheduleViewAllPage extends StatelessWidget {
  final List<dynamic> tasks;

  const ScheduleViewAllPage({super.key, required this.tasks});

  // ── Status helpers ─────────────────────────────────────────────────────────
  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppTheme.success;
      case 'in_progress':
      case 'in progress':
        return AppTheme.brandAccent;
      case 'overdue':
        return AppTheme.danger;
      case 'pending':
        return AppTheme.warning;
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
      default:
        return Icons.schedule_rounded;
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'N/A') return 'N/A';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM dd, yyyy').format(dt);
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
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.success.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandAccent.withOpacity(0.05),
              ),
            ),
          ),

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
                          if (tasks.isNotEmpty)
                            Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.success,
                                        AppTheme.success.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.success.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${tasks.length} tasks",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.2),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.1, curve: Curves.easeOutCubic),

                const SizedBox(height: 8),

                // ── Progress summary bar ───────────────────────────────────
                if (tasks.isNotEmpty)
                  _buildProgressBar()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.15),

                const SizedBox(height: 8),

                // ── Task list or empty state ───────────────────────────────
                Expanded(
                  child: tasks.isEmpty
                      ? _buildEmptyState()
                      : _buildTimeline(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress summary bar ───────────────────────────────────────────────────
  Widget _buildProgressBar() {
    final completed = tasks
        .where((t) => t['status']?.toLowerCase() == 'completed')
        .length;
    final total = tasks.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.success.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$completed of $total completed",
                  style: const TextStyle(
                    color: AppTheme.textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "${(progress * 100).toInt()}%",
                  style: const TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: 1000.ms,
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppTheme.success.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.success),
                  minHeight: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timeline list ──────────────────────────────────────────────────────────
  Widget _buildTimeline(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: tasks.length,
      itemBuilder: (context, idx) {
        final item = tasks[idx];
        final status = item['status'] as String?;
        final heroTag = "schedule_all_${item['task_id']}_$idx";
        final statusColor = _statusColor(status);
        final statusIcon = _statusIcon(status);
        final isLast = idx == tasks.length - 1;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailsPage(
                taskData: {
                  'task_id': item['task_id'],
                  'title': item['title'],
                  'sub': item['status'],
                  'accent': AppTheme.success,
                  'icon': Icons.calendar_today_rounded,
                  'heroTag': heroTag,
                  'startDate': item['start_date'] ?? "N/A",
                  'deadline': item['end_date'] ?? "N/A",
                  'completionType': "INFO",
                  'isRequest': false,
                  'userRole': 'Faculty',
                },
              ),
            ),
          ),
          child:
              IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Timeline spine ───────────────────────────────────
                        SizedBox(
                          width: 42,
                          child: Column(
                            children: [
                              // Circle dot
                              Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: statusColor.withOpacity(0.12),
                                      border: Border.all(
                                        color: statusColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      statusIcon,
                                      color: statusColor,
                                      size: 16,
                                    ),
                                  )
                                  .animate(
                                    onPlay: (c) => c.repeat(reverse: true),
                                  )
                                  .scaleXY(
                                    begin: 1.0,
                                    end: 1.06,
                                    duration: 1600.ms,
                                    curve: Curves.easeInOut,
                                    delay: (idx * 200).ms,
                                  ),
                              // Connecting line
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          statusColor.withOpacity(0.5),
                                          statusColor.withOpacity(0.08),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // ── Task card ────────────────────────────────────────
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: statusColor.withOpacity(0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.07),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['title'] ?? 'Task',
                                        style: const TextStyle(
                                          color: AppTheme.textMain,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppTheme.textSub.withOpacity(0.4),
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Status chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (status ?? 'Scheduled').toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),

                                // Dates row
                                if (item['start_date'] != null ||
                                    item['end_date'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Row(
                                      children: [
                                        if (item['start_date'] != null) ...[
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            size: 13,
                                            color: AppTheme.textSub.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            _formatDate(item['start_date']),
                                            style: TextStyle(
                                              color: AppTheme.textSub
                                                  .withOpacity(0.7),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        if (item['end_date'] != null) ...[
                                          Icon(
                                            Icons.flag_rounded,
                                            size: 13,
                                            color: statusColor.withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            _formatDate(item['end_date']),
                                            style: TextStyle(
                                              color: statusColor.withOpacity(
                                                0.85,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 100 + idx * 60),
                    duration: 450.ms,
                  )
                  .slideX(
                    begin: 0.08,
                    curve: Curves.easeOutCubic,
                    delay: Duration(milliseconds: 100 + idx * 60),
                  ),
        );
      },
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.success.withOpacity(0.08),
                        ),
                        child: Icon(
                          Icons.event_available_rounded,
                          size: 44,
                          color: AppTheme.success.withOpacity(0.5),
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
