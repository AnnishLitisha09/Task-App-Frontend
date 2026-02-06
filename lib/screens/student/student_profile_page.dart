import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_app/screens/student/leave_application_page.dart';
import 'on_duty_wallet_page.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  // Theme Colors
  final Color brandAccent = const Color(0xFF6366F1);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color penaltyRed = const Color(0xFFF43F5E);
  final Color successGreen = const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: slate900,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Student Identity",
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
            _buildIdentityHeader(),
            const SizedBox(height: 24),

            // Performance Bar (Stats)
            _buildPerformanceBar(),

            const SizedBox(height: 32),

            // SECTION 1: Resources & Management
            _buildSettingsGroup("Resources & Requests", [
              _settingsTile(
                Icons.account_balance_wallet_outlined,
                "On-Duty Wallet",
                "12 Active coupons • Next expiry Feb 12",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnDutyWalletPage(),
                    ),
                  );
                },
              ),
              _settingsTile(
                Icons.event_note_outlined,
                "Leave Application",
                "Apply for leave or view status",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeaveApplicationPage(),
                    ),
                  );
                },
              ),
              _settingsTile(
                Icons.description_outlined,
                "Documentation",
                "Upload evidence or view pending files",
                onTap: () {
                  // Add documentation logic here
                },
              ),
            ]),

            // SECTION 2: Security & Session
            _buildSettingsGroup("Security", [
              _settingsTile(
                Icons.logout_rounded,
                "Sign Out",
                "Log out of the student portal",
                color: penaltyRed,
                onTap: () => _showLogoutConfirmation(context),
              ),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Profile Header ---
  Widget _buildIdentityHeader() {
    return Column(
      children: [
        Hero(
          tag: 'profile-image',
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: brandAccent.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 55,
                  backgroundImage: NetworkImage(
                    'https://img.freepik.com/premium-vector/purple-circle-with-white-person-icon_876006-6.jpg?w=360',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: brandAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Annish Litisha",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: slate900,
          ),
        ),
        Text(
          "ID: 7376232IT110",
          style: TextStyle(
            fontSize: 14,
            color: slate500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Performance Stats Bar ---
  Widget _buildPerformanceBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: slate500.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _performanceStat("2,450", "Total Score", brandAccent),
          _vDivider(),
          _performanceStat("12", "Penalties", penaltyRed),
          _vDivider(),
          _performanceStat("3.9", "Current GPA", successGreen),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
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
                // 1. Initialize SharedPreferences
                final prefs = await SharedPreferences.getInstance();

                // 2. DELETE ALL DATA
                // .clear() removes every key-value pair in your app's storage
                await prefs.clear();

                if (context.mounted) {
                  // 3. Reset Navigation
                  // This wipes the screen stack and goes back to '/'
                  // Since the prefs are clear, RootWrapper will show LoginPage
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
