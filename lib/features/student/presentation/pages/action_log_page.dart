import 'package:flutter/material.dart';

class ActionLogPage extends StatelessWidget {
  const ActionLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Action Log"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 2)
                        ]
                      ),
                    ),
                    if (index != 9)
                      Container(
                        width: 2,
                        height: 50,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Task Completed: Physics Assignment",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Submitted via dashboard",
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Today, 10:45 AM",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
