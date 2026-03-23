import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/user_service.dart';
import '../../models/department_users_model.dart';

class LeaderBoardPage extends StatefulWidget {
  const LeaderBoardPage({super.key});

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color successColor = const Color(0xFF10B981);
  final Color gold = const Color(0xFFFFD700);
  final Color silver = const Color(0xFFC0C0C0);
  final Color bronze = const Color(0xFFCD7F32);

  bool _isLoading = true;
  String? _error;
  List<DepartmentUser> _allUsers = [];
  bool isStudentView = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await UserService().getHODDepartmentUsers();
      if (mounted) {
        List<DepartmentUser> users = [];
        users.addAll(response.students);
        users.addAll(response.faculty);
        
        // Sort by score descending
        users.sort((a, b) => double.parse(b.score).compareTo(double.parse(a.score)));

        setState(() {
          _allUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<DepartmentUser> get _filteredList {
    return _allUsers.where((u) => isStudentView ? u.userType == 'student' : u.userType == 'faculty').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Department Scoreboard",
          style: TextStyle(color: textMain, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildToggleBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _buildLeaderboardList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildToggleOption("Students", isStudentView, () => setState(() => isStudentView = true)),
          _buildToggleOption("Faculty", !isStudentView, () => setState(() => isStudentView = false)),
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
                      color: brandAccent.withOpacity(0.05),
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

  Widget _buildLeaderboardList() {
    final list = _filteredList;
    if (list.isEmpty) {
      return Center(child: Text("No data available", style: TextStyle(color: textSub)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final user = list[index];
        return _buildLeaderboardCard(user, index);
      },
    );
  }

  Widget _buildLeaderboardCard(DepartmentUser user, int index) {
    Color? rankColor;
    if (index == 0) rankColor = gold;
    else if (index == 1) rankColor = silver;
    else if (index == 2) rankColor = bronze;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildRankIndicator(index, rankColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(color: textMain, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  user.regNo,
                  style: TextStyle(color: textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user.score,
                style: TextStyle(color: brandAccent, fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Text(
                "Points",
                style: TextStyle(color: textSub, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildRankIndicator(int index, Color? color) {
    if (color != null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Center(
          child: Icon(Icons.emoji_events_rounded, color: color, size: 20),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: surfaceColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          (index + 1).toString(),
          style: TextStyle(color: textSub, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_error ?? "An error occurred"),
          TextButton(onPressed: _fetchData, child: const Text("Retry")),
        ],
      ),
    );
  }
}
