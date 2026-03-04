import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/user_service.dart';
import '../../models/department_users_model.dart';

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
  final Color errorRed = const Color(0xFFF43F5E);

  bool isStudentView = true;
  bool _isLoading = true;
  String? _error;
  DepartmentUsersResponse? _data;
  final TextEditingController _searchController = TextEditingController();

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
        setState(() {
          _data = response;
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
    if (_data == null) return [];
    List<DepartmentUser> baseList = isStudentView
        ? _data!.students
        : _data!.faculty;
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) return baseList;
    return baseList
        .where(
          (user) =>
              user.name.toLowerCase().contains(query) ||
              user.regNo.toLowerCase().contains(query),
        )
        .toList();
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? _buildErrorState()
                      : _buildList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final list = _filteredList;
    if (list.isEmpty) {
      return _buildEmptyState();
    }
    return AnimatedSwitcher(
      duration: 300.ms,
      switchInCurve: Curves.easeOut,
      child: RefreshIndicator(
        onRefresh: _fetchData,
        color: brandAccent,
        child: ListView.builder(
          key: ValueKey("${isStudentView}_${list.length}"),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final user = list[index];
            return _buildUniformCard(
              user,
              isStudentView ? Icons.school_outlined : Icons.badge_outlined,
            );
          },
        ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Department Dashboard",
                  style: TextStyle(
                    color: textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _data?.department.name ?? "Loading...",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
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
    int count = 0;
    if (_data != null) {
      count = title == "Students"
          ? _data!.counts.totalStudents
          : _data!.counts.totalFaculty;
    }

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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? brandAccent : textSub,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (_data != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? brandAccent.withOpacity(0.1)
                          : dividerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: isActive ? brandAccent : textSub,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
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
                      onChanged: (val) => setState(() {}),
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
        ],
      ),
    );
  }

  Widget _buildUniformCard(DepartmentUser user, IconData leadingIcon) {
    double penaltyVal = double.tryParse(user.penalty) ?? 0.0;
    String tag = user.userType == 'student'
        ? "Year ${user.year}"
        : (user.designation ?? "Faculty");

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
                      user.name,
                      style: TextStyle(
                        color: textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      user.regNo,
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
                  tag,
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
                "Score",
                user.score,
                successColor,
                Icons.insights_rounded,
              ),
              Container(height: 20, width: 1, color: dividerColor),
              _buildMetric(
                "Penalties",
                user.penalty,
                penaltyVal > 0 ? errorRed : textSub.withOpacity(0.3),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: dividerColor),
          const SizedBox(height: 16),
          Text(
            "No members found",
            style: TextStyle(color: textSub, fontSize: 16),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: errorRed, size: 48),
            const SizedBox(height: 16),
            Text(
              "Failed to load directory",
              style: TextStyle(
                color: textMain,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? "Unknown error occurred",
              textAlign: TextAlign.center,
              style: TextStyle(color: textSub, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: brandAccent),
              child: const Text(
                "Try Again",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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
