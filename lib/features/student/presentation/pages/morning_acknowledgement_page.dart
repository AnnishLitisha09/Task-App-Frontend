import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_button.dart';
import 'student_dashboard_page.dart';

class MorningAcknowledgementPage extends StatefulWidget {
  const MorningAcknowledgementPage({super.key});

  @override
  State<MorningAcknowledgementPage> createState() => _MorningAcknowledgementPageState();
}

class _MorningAcknowledgementPageState extends State<MorningAcknowledgementPage> {
  bool _isAcknowledged = false;

  // Dummy Data
  final List<Map<String, String>> _todaysTasks = [
    {
      'title': 'Submit Lab Report',
      'type': 'Academic',
      'deadline': '10:00 AM',
      'priority': 'High',
    },
    {
      'title': 'Library Duty',
      'type': 'Service',
      'deadline': '02:00 PM',
      'priority': 'Medium',
    },
    {
      'title': 'Mentor Meeting',
      'type': 'General',
      'deadline': '04:30 PM',
      'priority': 'Low',
    },
  ];

  void _handleAcknowledgement() {
    if (_isAcknowledged) {
      // Navigate to Dashboard using a nice fade transition
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const StudentDashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, d MMMM').format(now);
    final timeString = DateFormat('hh:mm a').format(now); // Mandatory timestamp display

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(bottom: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Text(
                        'Morning Briefing',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          timeString,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateString,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning Banner
                    if (_todaysTasks.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100, // Warning color, adjust for dark mode later
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You have ${_todaysTasks.length} pending tasks for today.",
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(),

                    Text(
                      "Today's Outline",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Task List
                    ..._todaysTasks.asMap().entries.map((entry) {
                      final task = entry.value;
                      final index = entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTaskTile(context, task),
                      ).animate().fadeIn(delay: (300 + (index * 100)).ms).slideX();
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Acknowledgement Area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _isAcknowledged,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _isAcknowledged = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          "I acknowledge my schedule and responsibilities for today.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Confirm & Proceed',
                    onPressed: _isAcknowledged ? _handleAcknowledgement : () {},
                    backgroundColor: _isAcknowledged 
                        ? Theme.of(context).primaryColor 
                        : Theme.of(context).disabledColor,
                  ),
                ],
              ),
            ).animate().slideY(begin: 1, end: 0, delay: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, Map<String, String> task) {
    Color priorityColor;
    switch (task['priority']) {
      case 'High': priorityColor = Colors.orange; break;
      case 'Medium': priorityColor = Colors.blue; break;
      default: priorityColor = Colors.green;
    }
    
    // Adjust for dark mode if using raw colors? 
    // Ideally use defined theme extensions, but for now this is okay.

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment_outlined, color: priorityColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      task['type']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(
                      task['deadline']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: priorityColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
