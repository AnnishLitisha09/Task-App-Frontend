import 'package:flutter/material.dart';
import '../../components/skeleton_loader.dart';

class AllStaffSchedulePage extends StatefulWidget {
  const AllStaffSchedulePage({super.key});

  @override
  State<AllStaffSchedulePage> createState() => _AllStaffSchedulePageState();
}

class _AllStaffSchedulePageState extends State<AllStaffSchedulePage> {
  // Mock data – replace with real API when available
  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Regular Site Inspection',
      'time': '09:00 AM - 11:00 AM',
      'color': const Color(0xFF6366F1),
      'icon': Icons.visibility_rounded,
    },
    {
      'title': 'Staff Briefing',
      'time': '01:00 PM - 01:30 PM',
      'color': Colors.purple,
      'icon': Icons.groups_rounded,
    },
    {
      'title': 'Waste Management Review',
      'time': '03:00 PM - 04:00 PM',
      'color': const Color(0xFF10B981),
      'icon': Icons.recycling_rounded,
    },
    {
      'title': 'Security Round',
      'time': '05:00 PM - 05:30 PM',
      'color': const Color(0xFFF59E0B),
      'icon': Icons.security_rounded,
    },
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textMain = const Color(0xFF1E293B);
    final textSub = const Color(0xFF64748B);
    final brandPrimary = const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Today's Schedule",
          style: TextStyle(
            color: brandPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: brandPrimary.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: (task['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          task['icon'] as IconData,
                          color: task['color'] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title'] as String,
                              style: TextStyle(
                                color: textMain,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              task['time'] as String,
                              style: TextStyle(color: textSub, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: textSub.withOpacity(0.3),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
