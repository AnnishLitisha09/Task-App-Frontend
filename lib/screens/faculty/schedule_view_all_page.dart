import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../common/task_detail_page.dart';

class ScheduleViewAllPage extends StatelessWidget {
  final List<dynamic> tasks;

  const ScheduleViewAllPage({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
          color: AppTheme.textMain,
        ),
        title: Row(
          children: [
            const Text(
              "Today's Schedule",
              style: TextStyle(
                color: AppTheme.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tasks.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: AppTheme.textSub.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No tasks scheduled for today",
                    style: TextStyle(
                      color: AppTheme.textSub,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: tasks.length,
              itemBuilder: (context, idx) {
                final item = tasks[idx];
                final String heroTag = "schedule_all_${item['task_id']}_$idx";
                return TaskCard(
                  title: item['title'] ?? 'Task',
                  sub: item['status'] ?? 'Scheduled',
                  accent: AppTheme.success,
                  icon: Icons.calendar_today_rounded,
                  heroTag: heroTag,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailsPage(
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
                );
              },
            ),
    );
  }
}
