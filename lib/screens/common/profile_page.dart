import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_app/screens/student/leave_application_page.dart';
import '../student/on_duty_wallet_page.dart';

class ProfilePage extends StatelessWidget {
  final String role; // Pass 'student', 'faculty', etc.

  const ProfilePage({super.key, required this.role});

  // Theme Colors
  final Color brandAccent = const Color(0xFF6366F1);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color penaltyRed = const Color(0xFFF43F5E);
  final Color successGreen = const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    // Helper to keep logic clean
    final bool isFaculty = role == 'faculty';
    final bool isStudent = role == 'student';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          isFaculty ? "Faculty Profile" : "Student Identity",
          style: TextStyle(
            color: slate900,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildIdentityHeader(isFaculty),
            const SizedBox(height: 24),

            // Performance Bar (Passes the role to change metrics)
            _buildPerformanceBar(role),

            const SizedBox(height: 32),

            // SECTION: ROLE-SPECIFIC ACTIONS
            if (isStudent)
              _buildSettingsGroup("Resources & Requests", [
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

            if (isFaculty)
              _buildSettingsGroup("Management", [
                _settingsTile(
                  Icons.assignment_ind_outlined,
                  "Duty Roster",
                  "View assigned invigilation or duties",
                  onTap: () {},
                ),
                _settingsTile(
                  Icons.rate_review_outlined,
                  "Approve Requests",
                  "Review student OD and Leave forms",
                  onTap: () {},
                ),
              ]),

            // SECTION: COMMON SECURITY
            _buildSettingsGroup("Security", [
              _settingsTile(
                Icons.logout_rounded,
                "Sign Out",
                "Log out of the $role portal",
                color: penaltyRed,
                onTap: () => _showLogoutConfirmation(context),
              ),
            ]),

            const SizedBox(height: 110), // Space for floating nav
          ],
        ),
      ),
    );
  }

  // --- Identity Header (Uses Role to change labels) ---
  Widget _buildIdentityHeader(bool isFaculty) {
    return Column(
      children: [
        Hero(
          tag: 'profile-image',
          child: CircleAvatar(
            radius: 55,
            backgroundColor: brandAccent.withOpacity(0.1),
            backgroundImage: const NetworkImage(
              'https://img.freepik.com/premium-vector/purple-circle-with-white-person-icon_876006-6.jpg?w=360',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isFaculty ? "Dr. Alan Turing" : "Annish Litisha",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: slate900,
          ),
        ),
        Text(
          isFaculty ? "Faculty ID: 232CS1021" : " Student ID: 7376232IT110",
          style: TextStyle(
            fontSize: 14,
            color: slate500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Performance Stats (Switches metrics based on role string) ---
  Widget _buildPerformanceBar(String userRole) {
    List<Widget> stats = [];

    if (userRole == 'faculty') {
      stats = [
        _performanceStat("2,450", "Total Score", brandAccent),
        _vDivider(),
        _performanceStat("12", "Pass Rate", successGreen),
        _vDivider(),
        _performanceStat("12", "Publications", Colors.orange),
      ];
    } else {
      stats = [
        _performanceStat("2,450", "Total Score", brandAccent),
        _vDivider(),
        _performanceStat("12", "Penalties", penaltyRed),
        _vDivider(),
        _performanceStat("3.9", "GPA", successGreen),
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

  // --- Settings Group UI ---
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

  // --- Custom List Tile ---
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

  // --- Logout Functionality ---
  // --- Logout Functionality ---
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

                // 1. Wipe the data
                await prefs.clear();

                // 2. Extra safety: Ensure these keys are null/false
                await prefs.setBool('isLoggedIn', false);

                if (context.mounted) {
                  // 3. Clear the entire navigation stack and go to Root
                  // The UniqueKey() we added in main.dart will now catch this and reset
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
}
