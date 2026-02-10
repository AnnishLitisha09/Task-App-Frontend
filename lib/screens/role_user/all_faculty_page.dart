import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AllFacultyPage extends StatefulWidget {
  const AllFacultyPage({super.key});

  @override
  State<AllFacultyPage> createState() => _AllFacultyPageState();
}

class _AllFacultyPageState extends State<AllFacultyPage> {
  // --- Design Tokens (Consistent with Dept Page) ---
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color dividerColor = const Color(0xFFF1F5F9);

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> allFaculty = [
    {
      "name": "Dr. Sarah Mitchell",
      "role": "Senior Professor",
      "dept": "Software Engineering",
      "status": "Active",
    },
    {
      "name": "Prof. James Wilson",
      "role": "HOD",
      "dept": "Civil Engineering",
      "status": "Active",
    },
    {
      "name": "Dr. Elena Rodriguez",
      "role": "Associate Professor",
      "dept": "Electrical Engineering",
      "status": "On Leave",
    },
    {
      "name": "Mr. David Chen",
      "role": "Lecturer",
      "dept": "Mechanical Engineering",
      "status": "Active",
    },
    {
      "name": "Dr. Amara Okafor",
      "role": "Research Lead",
      "dept": "Aerospace Engineering",
      "status": "Active",
    },
  ];

  List<Map<String, dynamic>> filteredFaculty = [];

  @override
  void initState() {
    super.initState();
    filteredFaculty = allFaculty;
  }

  void _filterSearch(String query) {
    setState(() {
      filteredFaculty = allFaculty
          .where(
            (f) =>
                f['name'].toLowerCase().contains(query.toLowerCase()) ||
                f['dept'].toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Flair
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
                _buildSearchBar(),
                Expanded(
                  child: filteredFaculty.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredFaculty.length,
                          itemBuilder: (context, index) =>
                              _buildFacultyItem(filteredFaculty[index]),
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
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _buildRoundButton(
            Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Text(
            "Faculty Directory",
            style: TextStyle(
              color: textMain,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: dividerColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: textSub, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterSearch,
                      style: TextStyle(
                        color: textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search name or department...",
                        hintStyle: TextStyle(
                          color: textSub.withOpacity(0.4),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: brandAccent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.filter_list_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFacultyItem(Map<String, dynamic> faculty) {
    bool isActive = faculty['status'] == "Active";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Placeholder / Icon
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: brandAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: brandAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      faculty['name'],
                      style: TextStyle(
                        color: textMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Dot
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${faculty['role']} • ${faculty['dept']}",
                  style: TextStyle(
                    color: textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(Icons.email_outlined),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildActionButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: surfaceColor, shape: BoxShape.circle),
      child: Icon(icon, color: brandAccent, size: 18),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_rounded,
            size: 60,
            color: textSub.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "No faculty members found",
            style: TextStyle(color: textSub, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: brandPrimary.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: textMain, size: 18),
      ),
    );
  }
}
