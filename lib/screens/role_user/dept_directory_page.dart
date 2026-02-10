import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DeptDirectoryPage extends StatefulWidget {
  const DeptDirectoryPage({super.key});

  @override
  State<DeptDirectoryPage> createState() => _DeptDirectoryPageState();
}

class _DeptDirectoryPageState extends State<DeptDirectoryPage> {
  // --- Design Tokens ---
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color dividerColor = const Color(0xFFF1F5F9);
  final Color successColor = const Color(0xFF10B981);
  final Color warningColor = const Color(0xFFF59E0B);

  bool isStudentView = true;
  final TextEditingController _searchController = TextEditingController();

  // Unified Data Structure for both Faculty and Students
  final List<Map<String, dynamic>> students = [
    {
      "name": "Alex Johnson",
      "id": "ENG-001",
      "score": "92.5",
      "penalty": "0",
      "tag": "3rd Year",
    },
    {
      "name": "Maria Garcia",
      "id": "ENG-042",
      "score": "88.0",
      "penalty": "1",
      "tag": "4th Year",
    },
    {
      "name": "Jordan Lee",
      "id": "ENG-015",
      "score": "76.4",
      "penalty": "3",
      "tag": "2nd Year",
    },
  ];

  final List<Map<String, dynamic>> faculty = [
    {
      "name": "Dr. Sarah Mitchell",
      "id": "FAC-101",
      "score": "98.2",
      "penalty": "0",
      "tag": "HOD",
    },
    {
      "name": "Prof. James Wilson",
      "id": "FAC-105",
      "score": "85.0",
      "penalty": "2",
      "tag": "Senior Prof",
    },
    {
      "name": "Dr. Elena Rodriguez",
      "id": "FAC-109",
      "score": "91.4",
      "penalty": "0",
      "tag": "Associate",
    },
  ];

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
              backgroundColor: brandAccent.withOpacity(0.04),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildToggleBar(),
                _buildSearchAndFilter(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: 300.ms,
                    switchInCurve: Curves.easeOut,
                    child: ListView.builder(
                      key: ValueKey(isStudentView),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: isStudentView
                          ? students.length
                          : faculty.length,
                      itemBuilder: (context, index) {
                        final item = isStudentView
                            ? students[index]
                            : faculty[index];
                        return _buildUniformCard(
                          item,
                          isStudentView
                              ? Icons.school_outlined
                              : Icons.badge_outlined,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          _buildRoundButton(
            Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Department",
                style: TextStyle(
                  color: textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Software Engineering",
                style: TextStyle(
                  color: textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildToggleOption(
            "Students",
            isStudentView,
            () => setState(() => isStudentView = true),
          ),
          _buildToggleOption(
            "Faculty",
            !isStudentView,
            () => setState(() => isStudentView = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: brandPrimary.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? brandAccent : textSub,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dividerColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: textSub, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: textMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Search by name or ID...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildIconButton(Icons.swap_vert_rounded),
          const SizedBox(width: 8),
          _buildIconButton(Icons.tune_rounded),
        ],
      ),
    );
  }

  Widget _buildUniformCard(Map<String, dynamic> data, IconData leadingIcon) {
    int penaltyCount = int.parse(data['penalty']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: brandAccent.withOpacity(0.08),
                child: Icon(leadingIcon, color: brandAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'],
                      style: TextStyle(
                        color: textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      data['id'],
                      style: TextStyle(
                        color: textSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  data['tag'],
                  style: TextStyle(
                    color: brandAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric(
                isStudentView ? "Score" : "Performance",
                "${data['score']}",
                successColor,
                Icons.insights_rounded,
              ),
              Container(height: 20, width: 1, color: dividerColor),
              _buildMetric(
                "Penalties",
                data['penalty'],
                penaltyCount > 0 ? warningColor : textSub.withOpacity(0.3),
                Icons.gavel_rounded,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildMetric(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textSub,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: textMain,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: brandAccent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildRoundButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: dividerColor),
        ),
        child: Icon(icon, color: textMain, size: 16),
      ),
    );
  }
}
