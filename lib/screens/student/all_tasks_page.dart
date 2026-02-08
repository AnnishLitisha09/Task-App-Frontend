import 'package:flutter/material.dart';

import 'task_detail_page.dart';

class AllTasksArchivePage extends StatelessWidget {
  const AllTasksArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Task History",
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF6366F1),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF6366F1),
            tabs: [
              Tab(text: "Active"),
              Tab(text: "Pending"),
              Tab(text: "Closed"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTaskList(), // You can pass filters here
            _buildTaskList(),
            _buildTaskList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) => _archiveTile(context),
    );
  }

  Widget _archiveTile(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => TaskDetailsPage(taskData: {})),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: Color(0xFF64748B)),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "System Analysis Draft",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    "Deadline: Feb 12",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Text(
              "+20",
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
