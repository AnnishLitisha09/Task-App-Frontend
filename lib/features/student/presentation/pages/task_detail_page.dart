import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/widgets/custom_button.dart';
import 'task_execution_page.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                        '#TASK-2024-001',
                        style: TextStyle(
                           color: Theme.of(context).textTheme.bodySmall?.color,
                           fontSize: 12,
                           fontWeight: FontWeight.bold
                        )
                       ),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(
                           color: Colors.orange.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(20),
                         ),
                         child: const Text('Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                       )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Update Physics Lab Inventory',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Academic • High Priority',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Info Grid
            Row(
              children: [
                Expanded(child: _buildInfoItem(context, 'Deadline', 'Today, 5 PM', Icons.timer_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoItem(context, 'Score', '50 Pts', Icons.stars, Colors.amber)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoItem(context, 'Owner', 'Dr. Alistair', Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoItem(context, 'Penalty', '-10 Pts/hr', Icons.warning_amber, Colors.red)),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              "Complete a full inventory check of the Physics Lab equipment. Ensure all microscopes, lenses, and measuring devices are accounted for. Report any damaged items immediately.",
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8), height: 1.5),
            ),
            
            const SizedBox(height: 24),

            // Timeline
            const Text("Status Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildTimelineItem(context, "Assigned", "Yesterday, 09:00 AM", isCompleted: true),
            _buildTimelineItem(context, "Accepted", "Yesterday, 09:30 AM", isCompleted: true),
            _buildTimelineItem(context, "Ideally Started", "Today, 10:00 AM", isCompleted: false, isCurrent: true),
            _buildTimelineItem(context, "Completed", "Pending", isCompleted: false),

            const SizedBox(height: 32),
            
            // Action Button
            CustomButton(
              text: "Begin Task Execution",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskExecutionPage()));
              },
            ).animate().shimmer(delay: 1.seconds, duration: 1.seconds),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon, [Color? iconColor]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color?.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, String title, String time, {bool isCompleted = false, bool isCurrent = false}) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 2,
              height: 16,
              color: isCompleted ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.3),
            ),
            Icon(
              isCompleted ? Icons.check_circle : (isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked),
              color: isCompleted || isCurrent ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.5),
              size: 20,
            ),
             Container(
              width: 2,
              height: 16,
               color: isCompleted ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.3),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: isCompleted || isCurrent ? FontWeight.bold : FontWeight.normal)),
            Text(time, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ],
    );
  }
}
