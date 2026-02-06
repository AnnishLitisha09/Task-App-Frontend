import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MyScorePage extends StatelessWidget {
  const MyScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Performance"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score Circle
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 10),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 10)
                  ]
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Total Score", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(
                      "850",
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    ),
                    const Text("Excellent", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 40),

            // Penalty Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Active Penalties", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        Text("0 Penalties recorded this month", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Task Wise Breakdown
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Task Performance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
            ),
            const SizedBox(height: 16),
            _buildPerformanceRow(context, "Academic", 0.8, Colors.blue),
            const SizedBox(height: 16),
            _buildPerformanceRow(context, "Service", 0.6, Colors.orange),
            const SizedBox(height: 16),
            _buildPerformanceRow(context, "Sports", 0.9, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(BuildContext context, String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text("${(value * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Theme.of(context).cardColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    ).animate().fadeIn().slideX();
  }
}
