import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        separatorBuilder: (c, i) => Divider(color: Colors.grey.withValues(alpha: 0.1)),
        itemBuilder: (context, index) {
          return _buildNotificationTile(context, index);
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, int index) {
    // Dummy Data
    final types = [Icons.task_alt, Icons.warning_amber_rounded, Icons.stars_rounded];
    final colors = [Theme.of(context).primaryColor, Colors.red, Colors.amber];
    final titles = ["Task Assigned", "Penalty Alert", "Points Credited"];
    
    final typeIcon = types[index % 3];
    final typeColor = colors[index % 3];
    final title = titles[index % 3];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(typeIcon, color: typeColor, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            "You have received a new notification regarding your recent activity.",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 6),
          Text(
            "2 hours ago",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
      onTap: () {},
    );
  }
}
