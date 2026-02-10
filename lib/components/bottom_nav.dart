import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_app/screens/faculty/faculty_page.dart';
import 'package:task_app/screens/role_user/all_department_page.dart';
import 'package:task_app/screens/role_user/role_user_page.dart';
import 'package:task_app/screens/staff/staff_history_page.dart';
import 'package:task_app/screens/staff/staff_page.dart';
import 'package:task_app/screens/student/student_page.dart';
import 'package:task_app/screens/common/personal_calendar_page.dart';
import '../screens/common/score_performance_page.dart';
import '../screens/common/profile_page.dart';
import '../screens/common/task_management_page.dart';
import '../screens/role_user/venue_details_page.dart';

class MainWrapper extends StatefulWidget {
  final String userRole;

  const MainWrapper({super.key, required this.userRole});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  bool _isLoading = true; // Added loading state

  // Data coming from SharedPreferences
  String _userTitle = '';
  String _scopeType = '';

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Fetching the keys we saved in the LoginPage
      _userTitle = prefs.getString('userTitle') ?? 'User';
      _scopeType = prefs.getString('userScope') ?? 'none';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    final String role = widget.userRole;
    List<Widget> pages;

    // --- ROLE-USER (AUTHORITY) LOGIC ---
    if (role == 'role-user') {
      pages = [
        RoleUserPage(title: _userTitle, scope: _scopeType), // Index 0: Hub
        const PersonalCalendarPage(tasks: []), // Index 2: Calendar
        _scopeType == 'institution'
            ? const AllDepartmentPage()
            : (_scopeType == 'infrastructure'
                  ? const VenueDetailsPage() // Create this screen later
                  : const TaskManagementPage()), // Department level
        _scopeType == 'institution'
            ? ProfilePage(
                role: 'role-user',
                title: _userTitle,
                scope: 'institution',
              )
            : (_scopeType == 'infrastructure'
                  ? ProfilePage(
                      role: 'role-user',
                      title: _userTitle,
                      scope: 'infrastructure',
                    )
                  : ProfilePage(
                      role: 'role-user',
                      title: _userTitle,
                      scope: 'department',
                    )),
      ];
    } // --- FACULTY LOGIC ---
    else if (role == 'faculty') {
      pages = [
        const FacultyPage(),
        const PersonalCalendarPage(tasks: []),
        const TaskManagementPage(),
        const ProfilePage(role: 'faculty'),
      ];
    } else if (role == 'staff') {
      pages = [
        const StaffPage(),
        const PersonalCalendarPage(tasks: []),
        const StaffHistoryPage(),
        const ProfilePage(role: 'staff'),
      ];
    }
    // --- STUDENT LOGIC ---
    else {
      pages = [
        StudentPage(onAcceptTask: (t) {}),
        const PersonalCalendarPage(tasks: []),
        const ScorePerformancePage(),
        const ProfilePage(role: 'student'),
      ];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: pages),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(role),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(String role) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        height: 72,
        decoration: _navDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _getNavItems(role),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to generate dynamic Nav Items based on permission
  List<Widget> _getNavItems(String role) {
    if (role == 'role-user') {
      return [
        _navItem(0, Icons.dashboard_rounded, "Home"),

        _navItem(1, Icons.calendar_today_rounded, "Schedule"),
        if (_scopeType == 'institution' || _scopeType == 'department')
          _navItem(2, Icons.assignment_rounded, "Directives")
        else
          _navItem(2, Icons.stadium_rounded, "Venues"),

        _navItem(3, Icons.person_rounded, "Profile"),
      ];
    }

    if (role == 'staff') {
      return [
        _navItem(0, Icons.engineering_rounded, "Tasks"),
        _navItem(1, Icons.event_available_rounded, "Schedule"),
        _navItem(2, Icons.history_rounded, "History"),
        _navItem(3, Icons.person_rounded, "Profile"),
      ];
    }
    // Default Faculty/Student Nav
    bool isFaculty = role == 'faculty';
    return [
      _navItem(0, Icons.dashboard_rounded, "Home"),
      _navItem(1, Icons.calendar_today_rounded, "Schedule"),
      _navItem(
        2,
        isFaculty ? Icons.assignment_rounded : Icons.insights_rounded,
        isFaculty ? "Directives" : "Score",
      ),
      _navItem(3, Icons.person_rounded, "Profile"),
    ];
  }

  BoxDecoration _navDecoration() {
    return BoxDecoration(
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
