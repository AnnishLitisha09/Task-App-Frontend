import 'package:flutter/material.dart';

class FacultyDashboardPage extends StatelessWidget {
  const FacultyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Faculty Dashboard")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text("Welcome, Faculty!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("This dashboard is under construction."),
          ],
        ),
      ),
    );
  }
}
