import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'task_inbox_page.dart';
import 'task_detail_page.dart';
import 'notifications_page.dart';
import 'personal_calendar_page.dart';
import 'on_duty_wallet_page.dart';
import 'upload_documentation_page.dart';
import 'my_score_page.dart';
import 'profile_page.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Hide back button
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              'Student View',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
            },
            icon: Badge(
              label: const Text('3'),
              backgroundColor: Colors.red,
              child: Icon(Icons.notifications_outlined, color: Theme.of(context).primaryColor),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
             child: const CircleAvatar(
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=student'),
                radius: 18,
             ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100), // Extra padding for floating nav
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                Row(
                  children: [
                    Expanded(child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyScorePage())),
                      child: _buildStatCard(context, 'Score', '850', Icons.stars_rounded, Colors.amber)
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(context, 'Pending', '12', Icons.pending_actions, Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(context, 'Penalty', '0', Icons.warning_rounded, Colors.red)),
                  ],
                ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms),

                const SizedBox(height: 32),

                // New Task Requests (Inbox)
                _buildSectionHeader(context, 'Task Requests', '3 New', onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskInboxPage()));
                }),
                const SizedBox(height: 12),
                _buildRequestCard(context).animate().fadeIn(delay: 200.ms).slideX(),

                const SizedBox(height: 32),

                // Overdue Tasks
                _buildSectionHeader(context, 'Attention Needed', '1 Overdue', isWarning: true),
                const SizedBox(height: 12),
                _buildOverdueCard(context).animate().fadeIn(delay: 300.ms).slideX(),

                const SizedBox(height: 32),

                // Today's Tasks
                _buildSectionHeader(context, "Today's Tasks", 'See All'),
                const SizedBox(height: 12),
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 3,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildTaskRow(context, index);
                  },
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 32),
                
                // Documentation Pending
                GestureDetector(
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadDocumentationPage()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.upload_file_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload Pending Documents',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Medical Cert - 2 Days left',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ).animate().scale(delay: 500.ms),
              ],
            ),
          ),
          
          // Floating Bottom Navigation
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87, // Dark contrast for floating bar
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(context, Icons.dashboard_rounded, true, () {}),
                  _buildNavItem(context, Icons.calendar_today_rounded, false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalCalendarPage()))),
                  _buildNavItem(context, Icons.wallet_giftcard_rounded, false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnDutyWalletPage()))),
                  _buildNavItem(context, Icons.person_rounded, false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
                ],
              ),
            ).animate().slideY(begin: 1, end: 0, delay: 600.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white60,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String actionText, {bool isWarning = false, VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isWarning ? Theme.of(context).colorScheme.error : null,
          ),
        ),
        if (actionText.isNotEmpty)
          TextButton(
            onPressed: onTap ?? () {},
            child: Text(actionText, style: TextStyle(
              color: isWarning ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600
            )),
          ),
      ],
    );
  }

  Widget _buildRequestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: const Icon(Icons.science_outlined, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Lab Assistant Duty", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Requested by Prof. Smith", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("Service", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Reject"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Accept"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(Icons.warning_rounded, color: Theme.of(context).colorScheme.error),
        title: Text("Submit Project Report", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
        subtitle: const Text("Overdue by 2 hours", style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Widget _buildTaskRow(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskDetailPage()));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.task_alt_rounded, color: Theme.of(context).primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Physics Assignment", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Due Today, 5:00 PM", style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill_rounded, color: Colors.green, size: 32),
          ],
        ),
      ),
    );
  }
}
