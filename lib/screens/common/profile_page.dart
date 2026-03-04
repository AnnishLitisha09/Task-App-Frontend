import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_app/screens/student/leave_application_page.dart';
import '../../models/user_profile_model.dart';
import '../../models/department_users_model.dart';
import '../../services/user_service.dart';
import '../../root_wrapper.dart';
import '../faculty/student_aproval_page.dart';
import '../faculty/students_page.dart';
import '../role_user/all_department_page.dart';
import '../role_user/all_faculty_page.dart';
import '../role_user/dept_directory_page.dart';
import '../role_user/view_dept_tasks.dart';
import '../student/on_duty_wallet_page.dart';
import '../student/self_log_history_page.dart';
import '../role_user/venue_availability_page.dart';
import '../role_user/resource_availability_page.dart';
import '../role_user/maintenance_logs_page.dart';

class ProfilePage extends StatefulWidget {
  final String role;
  final String? title;
  final String? scope;

  const ProfilePage({super.key, required this.role, this.title, this.scope});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _userProfile;
  List<String> _availableRoles = [];
  String _currentScopeDetails = 'none';
  DepartmentUsersResponse? _hodData;

  final Color brandAccent = const Color(0xFF6366F1);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color penaltyRed = const Color(0xFFF43F5E);
  final Color successGreen = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchHodStats() async {
    try {
      final data = await UserService().getHODDepartmentUsers();
      if (mounted) {
        setState(() {
          _hodData = data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching HOD stats: $e");
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allRolesString = prefs.getString('allRoles') ?? '';
      _currentScopeDetails = prefs.getString('scopeDetails') ?? 'none';

      final roles = allRolesString
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList();

      final service = UserService();
      final profile = await service.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _availableRoles = roles;
        });

        // If HOD, fetch department users for stats
        if (widget.role == 'role-user' && widget.scope == 'department') {
          _fetchHodStats();
        }
      }
    } catch (e) {
      // Handle error cleanly or show snackbar
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // If profile is loaded, use its role, otherwise fallback to widget.role

    // Helper booleans MUST be based on the injected routing role (widget.role), NOT the base API profile role,
    // otherwise settings blocks will bleed across different role dashboards when a user switches roles.
    final bool isFaculty = widget.role == 'faculty';
    final bool isStudent = widget.role == 'student';
    final bool isAuthority =
        widget.role == 'role-user' || widget.role == 'admin';
    final bool isStaff = widget.role == 'staff';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          _getPageTitle(isFaculty, isAuthority, isStaff),
          style: TextStyle(
            color: slate900,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_availableRoles.length > 1)
            IconButton(
              onPressed: () => _showRoleSwitcher(context),
              icon: Icon(Icons.switch_account_rounded, color: brandAccent),
              tooltip: "Switch Role",
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildIdentityHeader(isFaculty, isAuthority, isStaff),
            const SizedBox(height: 24),

            _buildPerformanceBar(widget.role),

            const SizedBox(height: 32),

            if (isAuthority)
              if (widget.scope == 'institution')
                _buildSettingsGroup("Institutional Management", [
                  _settingsTile(
                    Icons.people_outline,
                    "Department Directory",
                    "View all departments and their heads",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllDepartmentPage(),
                        ),
                      );
                    },
                  ),
                  _settingsTile(
                    Icons.analytics_outlined,
                    "Faculty Analytics",
                    "View overall performance metrics",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllFacultyPage(),
                        ),
                      );
                    },
                  ),
                ]),

            if (widget.scope == 'department')
              _buildSettingsGroup("Departmental Control", [
                _settingsTile(
                  Icons.groups_outlined,
                  "Department Roster",
                  "View and manage students & faculty",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeptDirectoryPage(),
                      ),
                    );
                  },
                ),
                _settingsTile(
                  Icons.assignment_turned_in_outlined,
                  "Departmental Tasks",
                  "View all tasks assigned to this dept",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewDeptTasks(),
                      ),
                    );
                  },
                ),
              ]),

            if (widget.scope == 'infrastructure')
              _buildSettingsGroup("Asset Management", [
                _settingsTile(
                  Icons.meeting_room_outlined,
                  "Venue Status & Availability",
                  "Manage room statuses and view history",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VenueAvailabilityPage(),
                    ),
                  ),
                ),
                _settingsTile(
                  Icons.inventory_2_outlined,
                  "Resource Inventory",
                  "Track devices, utilization and health",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResourceAvailabilityPage(),
                    ),
                  ),
                ),
                _settingsTile(
                  Icons.build_circle_outlined,
                  "Maintenance Logs",
                  "Detailed records of facility repairs",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MaintenanceLogsPage(),
                    ),
                  ),
                ),
              ]),

            if (isFaculty)
              _buildSettingsGroup("View Students", [
                _settingsTile(
                  Icons.assignment_ind_outlined,
                  "My Students",
                  "View assigned students",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentsPage(),
                      ),
                    );
                  },
                ),
                _settingsTile(
                  Icons.rate_review_outlined,
                  "Approve Requests",
                  "Review student OD forms",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentAprovalPage(),
                      ),
                    );
                  },
                ),
              ]),

            if (isStudent)
              _buildSettingsGroup("Resources & Requests", [
                _settingsTile(
                  Icons.edit_note_rounded,
                  "Self Log",
                  "Record personal learning activities",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelfLogHistoryPage(),
                      ),
                    );
                  },
                ),
                _settingsTile(
                  Icons.account_balance_wallet_outlined,
                  "On-Duty Wallet",
                  "12 Active coupons • Next expiry Feb 12",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnDutyWalletPage(),
                    ),
                  ),
                ),
                _settingsTile(
                  Icons.event_note_outlined,
                  "Leave Application",
                  "Apply for leave or view status",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeaveApplicationPage(),
                    ),
                  ),
                ),
              ]),

            _buildSettingsGroup("Security", [
              _settingsTile(
                Icons.logout_rounded,
                "Sign Out",
                "Log out of the ${widget.title ?? widget.role} portal",
                color: penaltyRed,
                onTap: () => _showLogoutConfirmation(context),
              ),
            ]),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  String _getPageTitle(bool isFaculty, bool isAuthority, bool isStaff) {
    if (isAuthority) return "${widget.title} Profile";
    if (isStaff) return "Staff Profile";
    return isFaculty ? "Faculty Profile" : "Student Identity";
  }

  Widget _buildIdentityHeader(bool isFaculty, bool isAuthority, bool isStaff) {
    String name = _userProfile?.profileData.name ?? "User";

    // Fallback if API hasn't loaded yet
    if (_userProfile == null) {
      name = isStaff
          ? "Robert Jenkins"
          : (isFaculty ? "Dr. Alan Turing" : "Annish Litisha");
    }

    String idLabel;
    final details = _userProfile?.profileData;

    if (isAuthority) {
      idLabel = widget.title ?? "Administrator";
    } else if (isFaculty) {
      idLabel =
          "Faculty ID: ${details?.regNo ?? '232CS1021'}\n${details?.department ?? 'CSE'}";
    } else if (isStaff) {
      idLabel = "Designation: ${details?.designation ?? 'Lab Assistant'}";
    } else {
      idLabel =
          "Register No: ${details?.regNo ?? '7376232IT110'}\n${details?.department ?? 'CSE'}";
    }

    if (isAuthority) {
      if (widget.scope == 'institution') {
        name = _userProfile?.profileData.name ?? "Administrator";
      } else if (widget.scope == 'department')
        name = _userProfile?.profileData.name ?? "Head of Department";
      else
        name = _userProfile?.profileData.name ?? "Role User";
    }

    return Column(
      children: [
        Hero(
          tag: 'profile-image',
          child: CircleAvatar(
            radius: 55,
            backgroundColor: const Color.fromARGB(255, 231, 223, 241),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: brandAccent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: slate900,
          ),
        ),
        Text(
          idLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: slate500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBar(String userRole) {
    List<Widget> stats = [];
    final details = _userProfile?.profileData;

    // Normalize role checking
    bool isRoleUser =
        userRole == 'role-user' ||
        (details != null && details.roleAssignments.isNotEmpty);
    bool isFaculty = userRole == 'faculty';
    bool isStaff = userRole == 'staff';

    if (isRoleUser) {
      // HOD / Principal Stats
      Map<String, dynamic> statData = details?.stats ?? {};

      if (widget.scope == 'infrastructure') {
        // ... existing infrastructure logic ...
        stats = [
          _performanceStat("45", "Total Venues", brandAccent),
          _vDivider(),
          _performanceStat("12", "Bookings Today", successGreen),
          _vDivider(),
          _performanceStat("02", "Under Repair", penaltyRed),
        ];
      } else {
        // Department / Institution Stats
        int studentCount =
            _hodData?.counts.totalStudents ??
            int.tryParse(statData['total_students']?.toString() ?? '0') ??
            0;
        int facultyCount =
            _hodData?.counts.totalFaculty ??
            int.tryParse(statData['total_faculty']?.toString() ?? '0') ??
            0;

        stats = [
          _performanceStat("$studentCount", "Students", successGreen),
          _vDivider(),
          _performanceStat("$facultyCount", "Faculty", brandAccent),
          _vDivider(),
        ];
      }
    } else if (isFaculty) {
      stats = [
        _performanceStat(
          "${details?.score ?? 850}", // Mock or real score
          "Score",
          successGreen,
        ),
        _vDivider(),
        _performanceStat(
          "${details?.penalty ?? 0}", // Mock or real penalty
          "Penalty",
          penaltyRed,
        ),
        _vDivider(),
        _performanceStat(
          "${details?.studentCount ?? 45}", // Mock or real student count
          "Students",
          brandAccent,
        ),
      ];
    } else if (isStaff) {
      stats = [
        _performanceStat(
          "${details?.completedTasks ?? 142}",
          "Completed",
          successGreen,
        ),
        _vDivider(),
        _performanceStat(
          "${details?.pendingTasks ?? 5}",
          "Pending",
          Colors.orange,
        ),
      ];
    } else {
      // Student Stats
      stats = [
        _performanceStat("${details?.score ?? 0}", "Total Score", brandAccent),
        _vDivider(),
        _performanceStat("0", "Penalties", penaltyRed),
        _vDivider(),
        _performanceStat("${details?.cGpa ?? 0}", "CGPA", successGreen),
      ];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(children: stats),
    ).animate().slideY(begin: 0.2, end: 0);
  }

  Widget _performanceStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(height: 30, width: 1, color: slate500.withOpacity(0.1));

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 24, 12),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: slate500,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: surfaceColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: slate900.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _settingsTile(
    IconData icon,
    String title,
    String sub, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? brandAccent).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color ?? brandAccent, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: slate900,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        sub,
        style: TextStyle(
          color: slate500,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: slate500.withOpacity(0.2),
        size: 14,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "Sign Out",
          style: TextStyle(color: slate900, fontWeight: FontWeight.w900),
        ),
        content: Text(
          "Are you sure you want to log out? All local session data will be cleared.",
          style: TextStyle(color: slate500, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: slate500, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await prefs.setBool('isLoggedIn', false);
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: penaltyRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Logout"),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Switch Role",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: slate900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Select a role to view the corresponding dashboard.",
                style: TextStyle(fontSize: 14, color: slate500),
              ),
              const SizedBox(height: 24),
              ..._availableRoles.map<Widget>((roleStr) {
                // Determine display names and icons
                String displayName = roleStr;
                IconData icon = Icons.person_rounded;
                Color color = brandAccent;

                if (displayName.toLowerCase() == 'faculty') {
                  icon = Icons.school_rounded;
                  color = Colors.blue;
                } else if (displayName.toLowerCase() == 'incharge') {
                  displayName = 'Venue Incharge';
                  icon = Icons.meeting_room_rounded;
                  color = Colors.orange;
                } else if (displayName.toLowerCase() == 'hod') {
                  displayName = 'Head of Department';
                  icon = Icons.account_balance_rounded;
                  color = Colors.purple;
                }

                // Highlight currently active role
                bool isActive = false;
                if (displayName.toLowerCase() == 'faculty' &&
                    widget.role == 'faculty') {
                  isActive = true;
                } else if (widget.title != null &&
                    widget.title!.toLowerCase().contains(
                      displayName.toLowerCase().replaceAll(' ', ''),
                    )) {
                  isActive = true;
                } else if (displayName.toLowerCase() == 'hod' &&
                    widget.title == 'HEAD OF DEPARTMENT') {
                  isActive = true;
                } else if (displayName.toLowerCase() == 'venue incharge' &&
                    widget.title == 'VENUE INCHARGE') {
                  isActive = true;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _switchRole(roleStr);
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isActive ? color : slate500.withOpacity(0.2),
                          width: isActive ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: isActive
                            ? color.withOpacity(0.05)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: slate900,
                              ),
                            ),
                          ),
                          if (isActive)
                            Icon(Icons.check_circle_rounded, color: color),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _switchRole(String targetRoleStr) async {
    final prefs = await SharedPreferences.getInstance();

    String newRole = 'student';
    String newTitle = '';
    String newScope = 'none';

    final targetLower = targetRoleStr.toLowerCase();

    if (targetLower == 'faculty') {
      newRole = 'faculty';
    } else if (targetLower == 'student') {
      newRole = 'student';
    } else if (targetLower == 'incharge') {
      newRole = 'role-user';
      newTitle = 'VENUE INCHARGE';
      newScope = 'infrastructure'; // Fallback
      if (_currentScopeDetails.toLowerCase().contains('infrastructure')) {
        newScope = 'infrastructure';
      }
    } else if (targetLower == 'hod') {
      newRole = 'role-user';
      newTitle = 'HEAD OF DEPARTMENT';
      newScope = 'department'; // Fallback
      if (_currentScopeDetails.toLowerCase().contains('department')) {
        newScope = 'department';
      }
    } else if (targetLower == 'principal') {
      newRole = 'role-user';
      newTitle = 'PRINCIPAL';
      newScope = 'institution'; // Fallback
      if (_currentScopeDetails.toLowerCase().contains('institution')) {
        newScope = 'institution';
      }
    } // New fallback below just in case.

    await prefs.setString('userRole', newRole);
    if (newTitle.isNotEmpty) {
      await prefs.setString('userTitle', newTitle);
      await prefs.setString('userScope', newScope);
    }

    if (mounted) {
      // Force app restart directly into RootWrapper with the newly switched state
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RootWrapper(
            initialLogin: true,
            initialAck: true,
            initialRole: newRole,
          ),
        ),
        (route) => false,
      );
    }
  }
}
