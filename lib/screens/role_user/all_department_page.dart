import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AllDepartmentPage extends StatefulWidget {
  const AllDepartmentPage({super.key});

  @override
  State<AllDepartmentPage> createState() => _AllDepartmentPageState();
}

class _AllDepartmentPageState extends State<AllDepartmentPage> {
  // --- Design Tokens ---
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color dividerColor = const Color(0xFFF1F5F9);

  final TextEditingController _searchController = TextEditingController();

  // Data updated: Removed 'code', added 'faculties'
  final List<Map<String, dynamic>> departments = [
    {"name": "Computer Science", "faculties": "24", "students": "842"},
    {"name": "Business Finance", "faculties": "18", "students": "920"},
    {"name": "Architecture", "faculties": "12", "students": "315"},
    {"name": "IT Systems", "faculties": "15", "students": "524"},
    {"name": "Applied Arts", "faculties": "09", "students": "210"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle Background Decorative Element
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
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: departments.length,
                    itemBuilder: (context, index) =>
                        _buildDeptItem(departments[index]),
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
            "Departments",
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
                      style: TextStyle(
                        color: textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search department...",
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
          // Filter Icon Button
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: brandAccent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDeptItem(Map<String, dynamic> dept) {
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
          // Icon Container
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: brandAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.terminal_rounded, color: brandAccent, size: 24),
          ),
          const SizedBox(width: 16),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dept['name'],
                  style: TextStyle(
                    color: textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniBadge(
                      Icons.people_outline_rounded,
                      "${dept['faculties']} Faculty",
                    ),
                    const SizedBox(width: 12),
                    _buildMiniBadge(
                      Icons.school_outlined,
                      "${dept['students']} Students",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildMiniBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textSub),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: textSub,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
