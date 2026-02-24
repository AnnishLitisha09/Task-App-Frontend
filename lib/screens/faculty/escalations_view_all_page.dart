import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../common/task_detail_page.dart';

class EscalationsViewAllPage extends StatelessWidget {
  final List<dynamic> escalations;

  const EscalationsViewAllPage({
    super.key,
    required this.escalations,
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
              "Escalated Tasks",
              style: TextStyle(
                color: AppTheme.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (escalations.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  escalations.length.toString(),
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
      body: escalations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.priority_high_outlined,
                    size: 64,
                    color: AppTheme.textSub.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No escalated tasks",
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
              itemCount: escalations.length,
              itemBuilder: (context, idx) {
                final escalation = escalations[idx];
                final String heroTag =
                    "escalation_all_${escalation['task_id']}_$idx";
                return TaskCard(
                  title: escalation['title'] ?? "Escalated Task",
                  sub: escalation['escalated_reason'] ??
                      escalation['description'] ??
                      "High Priority",
                  accent: AppTheme.danger,
                  icon: Icons.priority_high_rounded,
                  heroTag: heroTag,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailsPage(
                        taskData: {
                          'task_id': escalation['task_id'],
                          'title': escalation['title'],
                          'sub': escalation['description'],
                          'accent': AppTheme.danger,
                          'icon': Icons.priority_high_rounded,
                          'heroTag': heroTag,
                          'startDate': escalation['start_date'] ?? "N/A",
                          'deadline': escalation['end_date'] ?? "N/A",
                          'completionType': escalation['type'] ?? "INFO",
                          'isRequest': false,
                          'authority': "Administration",
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
