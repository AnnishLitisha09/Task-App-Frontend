import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/stat_card.dart';
import '../../components/task_card.dart';
import '../../components/section_header.dart';
import '../../components/reject_dialog.dart';
import '../common/task_detail_page.dart';

class FacultyPage extends StatefulWidget {
  const FacultyPage({super.key});

  @override
  State<FacultyPage> createState() => _FacultyPageState();
}

class _FacultyPageState extends State<FacultyPage> {
  // --- Logic: Data Lists ---
  List<Map<String, dynamic>> directives = [
    {
      "id": 1,
      "authority": "Dean Academics",
      "task": "Approve Internal Assessment Schema",
      "sub": "High Priority • Due Today",
      "color": AppTheme.brandAccent,
    },
    {
      "id": 2,
      "authority": "HOD - IT",
      "task": "Technical Seminar Guest Invite",
      "sub": "Review by Feb 12",
      "color": AppTheme.warning,
    },
  ];

  List<Map<String, dynamic>> schedule = [
    {
      "title": "Cloud Computing (Section A)",
      "sub": "Room 402 • 10:30 AM",
      "icon": Icons.cloud_queue_rounded,
      "color": AppTheme.brandAccent,
    },
  ];

  // --- Logic: Handlers ---
  void _acceptTask(int index) {
    setState(() {
      var task = directives.removeAt(index);
      schedule.add({
        "title": task['task'],
        "sub": "Added from Directives",
        "icon": Icons.assignment_turned_in_rounded,
        "color": AppTheme.success,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Task added to your schedule"),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _rejectTask(int index) {
    setState(() {
      directives.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Task rejected"), backgroundColor: AppTheme.danger),
    );
  }

  void _showRejectDialog(int index) {
    RejectDialog.show(
      context,
      taskTitle: directives[index]['task'],
      reasons: ["Scheduling Conflict", "Resource Unavailability", "Outside Expertise", "Other"],
      onConfirm: (reason, details) => _rejectTask(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: AppTheme.brandAccent.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                CustomAppBar(
                  title: "Dr. Alan Turing",
                  date: "Sunday, Feb 08",
                  notificationCount: directives.length,
                  profileImageUrl: 'https://i.pravatar.cc/150?u=faculty1',
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4,
                        children: [
                          StatCard(
                            label: "Pending",
                            value: "0${directives.length}",
                            icon: Icons.move_to_inbox,
                            color: AppTheme.brandAccent,
                          ),
                          StatCard(
                            label: "Classes",
                            value: "0${schedule.length}",
                            icon: Icons.school_rounded,
                            color: AppTheme.success,
                          ),
                          StatCard(label: "Students", value: "140", icon: Icons.people_alt_rounded, color: AppTheme.warning),
                          StatCard(label: "Hours", value: "32h", icon: Icons.timer_rounded, color: Colors.teal),
                        ],
                      ),
                      const SizedBox(height: 32),

                      SectionHeader(
                        title: "Incoming Directives",
                        isStatus: true,
                        count: directives.length,
                        onViewAll: () {},
                      ),

                      if (directives.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "No pending directives",
                              style: TextStyle(color: AppTheme.textSub, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      else
                        ...directives.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var data = entry.value;
                          final String heroTag = "directive_${data['task']}_${data['sub'].hashCode}";
                          return TaskCard(
                            title: data['task'],
                            sub: data['sub'],
                            accent: data['color'],
                            icon: Icons.assignment_turned_in_rounded,
                            heroTag: heroTag,
                            isRequest: true,
                            onAccept: () => _acceptTask(idx),
                            onReject: () => _showRejectDialog(idx),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskDetailsPage(
                                  taskData: {
                                    'title': data['task'],
                                    'sub': data['sub'],
                                    'accent': data['color'],
                                    'icon': Icons.assignment_turned_in_rounded,
                                    'heroTag': heroTag,
                                    'startDate': "Feb 08, 10:30 AM",
                                    'deadline': "Feb 08, 12:30 PM",
                                    'completionType': "APPROVAL",
                                    'isRequest': true,
                                    'authority': data['authority'],
                                  },
                                ),
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 32),

                      SectionHeader(title: "Today's Schedule", onViewAll: () {}),
                      ...schedule.map((item) {
                        final String heroTag = "task_${item['title']}_${item['sub'].hashCode}";
                        return TaskCard(
                          title: item['title'],
                          sub: item['sub'],
                          accent: item['color'],
                          icon: item['icon'],
                          heroTag: heroTag,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailsPage(
                                taskData: {
                                  'title': item['title'],
                                  'sub': item['sub'],
                                  'accent': item['color'],
                                  'icon': item['icon'],
                                  'heroTag': heroTag,
                                  'startDate': "Feb 08, 10:30 AM",
                                  'deadline': "Feb 08, 12:30 PM",
                                  'completionType': "OTP",
                                  "isRequest": false,
                                },
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 32),

                      SectionHeader(title: "Pending Paperwork", onViewAll: () {}),
                      _docItem("Monthly Attendance Report", "Required", Icons.description_outlined),
                      _docItem("Lab Equipment Requisition", "Awaiting Sign", Icons.border_color_rounded),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _docItem(String title, String status, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSub, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTheme.bodyMain.copyWith(fontSize: 14),
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              color: AppTheme.brandAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

