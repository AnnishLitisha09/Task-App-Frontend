import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'create_task_page.dart';
import 'task_creation_view_page.dart';

class TaskManagementPage extends StatefulWidget {
  const TaskManagementPage({super.key});

  @override
  State<TaskManagementPage> createState() => _TaskManagementPageState();
}

class _TaskManagementPageState extends State<TaskManagementPage> {
  final Color brandPrimary = const Color(0xFF6366F1);
  final Color bgSlate = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF0F172A);
  final Color textLight = const Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      // We keep the body clean and use a custom header
      body: Stack(
        children: [
          // Decorative background blur for elegance
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandPrimary.withOpacity(0.05),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. GORGEOUS TOP HEADER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 70, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGreeting(),
                          _buildCreateButton(), // Strategic placement at top-right
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildLightStatsRow(), // Replaces the heavy dark card
                    ],
                  ),
                ),
              ),

              // 2. SEARCH & FILTER BAR
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: _buildSearchBar(),
                ),
              ),

              // 3. TASK LIST
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildElegantTaskCard(index),
                    childCount: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Directives",
          style: TextStyle(
            color: textDark,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Manage your academic workflows",
          style: TextStyle(
            color: textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2);
  }

  Widget _buildCreateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: brandPrimary,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTaskPage()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.easeOut);
  }

  Widget _buildLightStatsRow() {
    return Row(
      children: [
        _statChip("12", "Active", brandPrimary),
        const SizedBox(width: 12),
        _statChip("05", "Review", const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _statChip("28", "Done", const Color(0xFF10B981)),
      ],
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: textDark.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: textLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: textDark.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: textLight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search tasks...",
                hintStyle: TextStyle(
                  color: textLight.withOpacity(0.5),
                  fontSize: 15,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          _actionCircle(Icons.tune_rounded), // Filter icon
        ],
      ),
    );
  }

  // ... existing imports

  Widget _buildElegantTaskCard(int index) {
    // Mocking dynamic data that matches your Creation Page state
    final String taskTitle = index == 0
        ? "System Architecture Exam"
        : "Monthly Audit Report";
    final String taskType = index % 2 == 0
        ? "Fixed Time Task"
        : "Recurring Task";
    final String priority = index == 0 ? "Critical" : "Medium";
    final String venue = index == 0 ? "Room 402" : "Main Hall";
    final List<String> methods = index == 0
        ? ["QR Scan", "Photo"]
        : ["Doc Upload"];

    final Map<String, dynamic> taskData = {
      'title': taskTitle,
      'category': 'Assessment',
      'taskType': taskType,
      'locationId': venue,
      'priority': priority,
      'completionMethods': methods,
      'selectedDate': DateTime(2026, 2, 12),
      'description':
          "Ensure all hardware is calibrated before the exam starts.",
      'ownerId': "Prof. Aristhoth",
      'approvalAuthority': "Dept. Head Sarah",
      'status': index == 0 ? "Pending" : "Completed", // Mocking status
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        // Ensures the splash effect stays inside the rounded corners
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              // CALLING THE VIEW PAGE HERE
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskViewPage(taskData: taskData),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP ROW: Category, Priority + THE NEW MENU
                  Row(
                    children: [
                      _badge("Assessment", brandPrimary),
                      const SizedBox(width: 12),
                      _priorityIndicator(priority),
                      const Spacer(),
                      _buildCardMenu(
                        index: index,
                        title: taskTitle,
                        type: taskType,
                        venue: venue,
                        priority: priority,
                        methods: methods,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. TITLE & VENUE
                  Text(
                    taskTitle,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        venue,
                        style: TextStyle(
                          color: textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.layers_outlined, size: 14, color: textLight),
                      const SizedBox(width: 4),
                      Text(
                        taskType,
                        style: TextStyle(
                          color: textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // 3. BOTTOM ROW: Closing Methods & Due Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: methods.map((m) => _methodIcon(m)).toList(),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "DUE DATE",
                            style: TextStyle(
                              color: textLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            "Feb 12, 2026",
                            style: TextStyle(
                              color: textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }

  // --- MENU HELPER ---
  Widget _buildCardMenu({
    required int index,
    required String title,
    required String type,
    required String venue,
    required String priority,
    required List<String> methods,
  }) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, color: textLight, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (value) {
        if (value == 'edit') {
          final Map<String, dynamic> dataToEdit = {
            'title': title, // Now using the passed argument
            'category': 'Assessment',
            'taskType': type,
            'locationId': venue,
            'priority': priority,
            'completionMethods': methods,
          };

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTaskPage(initialData: dataToEdit),
            ),
          );
        } else if (value == 'delete') {
          _showDeleteDialog(index);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: textDark, size: 20),
              const SizedBox(width: 12),
              const Text("Edit Directive"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  } // --- DELETE CONFIRMATION ---

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          "Delete Directive?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This action cannot be undone. All associated progress and documentation will be removed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              // Logic to remove from list
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  // --- NEW ATOMIC COMPONENTS FOR THE CARD ---

  Widget _priorityIndicator(String priority) {
    Color pColor;
    switch (priority) {
      case 'Critical':
        pColor = Colors.redAccent;
        break;
      case 'High':
        pColor = Colors.orangeAccent;
        break;
      case 'Low':
        pColor = Colors.blueAccent;
        break;
      default:
        pColor = Colors.greenAccent;
    }
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          priority.toUpperCase(),
          style: TextStyle(
            color: textDark,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _methodIcon(String method) {
    IconData icon;
    switch (method) {
      case 'QR Scan':
        icon = Icons.qr_code_scanner;
        break;
      case 'Photo':
        icon = Icons.camera_alt_outlined;
        break;
      case 'Doc Upload':
        icon = Icons.upload_file;
        break;
      default:
        icon = Icons.verified_outlined;
    }
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgSlate,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 16, color: brandPrimary),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _actionCircle(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgSlate,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: textDark),
    );
  }
}
