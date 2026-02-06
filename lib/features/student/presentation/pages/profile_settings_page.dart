import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../main.dart'; // Import to access themeNotifier

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Current theme state
    final bool isDark = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionHeader(context, "Appearance"),
            _buildSettingTile(
              context,
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: "Dark Mode",
              trailing: Switch(
                value: isDark,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (val) {
                  themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSectionHeader(context, "Notifications"),
             _buildSettingTile(
              context,
              icon: Icons.notifications_active_outlined,
              title: "Push Notifications",
              trailing: Switch(
                value: true,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (val) {},
              ),
            ),
            _buildSettingTile(
              context,
              icon: Icons.email_outlined,
              title: "Email Updates",
              trailing: Switch(
                value: false,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (val) {},
              ),
            ),
             const SizedBox(height: 24),

            _buildSectionHeader(context, "Support"),
            _buildSettingTile(
              context,
              icon: Icons.help_outline_rounded,
              title: "Help Center",
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            _buildSettingTile(
              context,
              icon: Icons.info_outline_rounded,
              title: "About App",
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const SizedBox(height: 32),
            
            Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, {required IconData icon, required String title, required Widget trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        title: Text(
          title, 
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          )
        ),
        trailing: trailing,
      ),
    );
  }
}
