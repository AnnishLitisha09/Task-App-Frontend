import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:task_app/screens/faculty/faculty_page.dart';
import 'package:task_app/screens/student/student_page.dart';
import 'package:task_app/screens/common/personal_calendar_page.dart';
import '../screens/common/score_performance_page.dart';
import '../screens/common/profile_page.dart';
import '../screens/common/task_management_page.dart';

class MainWrapper extends StatefulWidget {
  final String userRole;

  const MainWrapper({super.key, required this.userRole});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Shared state for accepted tasks
  List<Map<String, dynamic>> acceptedTasks = [
    {
      "title": "Project Kickoff",
      "sub": "Admin Room 1",
      "start": 9.0,
      "dur": 60.0,
      "icon": Icons.rocket_launch_rounded,
    },
  ];

  void _handleAcceptTask(Map<String, dynamic> task) {
    setState(() {
      acceptedTasks.add(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isFaculty = widget.userRole == 'faculty';

    final List<Widget> _pages = isFaculty
        ? [
            const FacultyPage(),
            PersonalCalendarPage(tasks: acceptedTasks),
            const TaskManagementPage(),
            const ProfilePage(role: 'faculty'),
          ]
        : [
            StudentPage(onAcceptTask: _handleAcceptTask),
            PersonalCalendarPage(tasks: acceptedTasks),
            const ScorePerformancePage(),
            const ProfilePage(role: 'student'),
          ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Content Area
          IndexedStack(index: _selectedIndex, children: _pages),

          // 2. Floating Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(isFaculty),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isFaculty) {
    return SafeArea(
      // Ensures it doesn't hit the bottom of the screen on modern phones
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          24,
          0,
          24,
          12,
        ), // Restored floating margin
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_rounded, "Home"),
                _navItem(1, Icons.calendar_today_rounded, "Schedule"),
                _navItem(
                  2,
                  isFaculty ? Icons.assignment_rounded : Icons.insights_rounded,
                  isFaculty ? "Directives" : "Score",
                ),
                _navItem(3, Icons.person_rounded, "Profile"),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      duration: 800.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    const Color primaryBlue = Color(0xFF6366F1);
    const Color inactiveGrey = Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: 350.ms,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryBlue.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? primaryBlue : inactiveGrey, size: 24)
                .animate(target: isSelected ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
