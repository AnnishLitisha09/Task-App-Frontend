import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  final Color brandAccent = const Color(0xFF6366F1);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: slate900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Profile", style: TextStyle(color: slate900, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: Icon(Icons.edit_outlined, color: brandAccent), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildQuickStats(),
            const SizedBox(height: 32),
            _buildSettingsGroup("Account Settings", [
              _settingsTile(Icons.person_outlined, "Personal Information", "View your details"),
              _settingsTile(Icons.school_outlined, "Academic Records", "Courses and GPA"),
              _settingsTile(Icons.security_outlined, "Security", "Password & Biometrics"),
            ]),
            _buildSettingsGroup("Activity", [
              _settingsTile(Icons.history_rounded, "Action Log", "Your recent activity history"),
              _settingsTile(Icons.notifications_none_rounded, "Notification Preferences", "Manage alerts"),
            ]),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {},
              child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: brandAccent.withOpacity(0.2), width: 2),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=alexj'),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: brandAccent, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ],
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text("Alex Johnson", 
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: slate900)),
        Text("ID: STU-2026-0882", 
          style: TextStyle(fontSize: 14, color: slate500, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Chip(
          label: const Text("Level 4 • Honors Student"),
          backgroundColor: brandAccent.withOpacity(0.1),
          labelStyle: TextStyle(color: brandAccent, fontSize: 12, fontWeight: FontWeight.bold),
          side: BorderSide.none,
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _singleStat("3.9", "GPA"),
          Container(height: 30, width: 1, color: slate500.withOpacity(0.1)),
          _singleStat("124", "Tasks Done"),
          Container(height: 30, width: 1, color: slate500.withOpacity(0.1)),
          _singleStat("12", "Coupons"),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _singleStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: slate900)),
        Text(label, style: TextStyle(fontSize: 12, color: slate500, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(title, 
            style: TextStyle(fontSize: 14, color: slate500, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, String sub) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: brandAccent, size: 20),
      ),
      title: Text(title, style: TextStyle(color: slate900, fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(sub, style: TextStyle(color: slate500, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, color: slate500.withOpacity(0.3), size: 14),
      onTap: () {},
    );
  }
}