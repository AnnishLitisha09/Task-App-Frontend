import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/user_service.dart';
import '../common/task_detail_page.dart';

class ViewDeptTasks extends StatefulWidget {
  const ViewDeptTasks({super.key});

  @override
  State<ViewDeptTasks> createState() => _ViewDeptTasksState();
}

class _ViewDeptTasksState extends State<ViewDeptTasks> {
  // --- Design Tokens ---
  final Color brandPrimary = const Color(0xFF6366F1);
  final Color bgSlate = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF0F172A);
  final Color textLight = const Color(0xFF64748B);

  bool _isLoading = true;
  String? _error;
  List<dynamic> _allTasks = [];
  List<dynamic> _filteredTasks = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await UserService().getDepartmentalTasks();
      if (mounted) {
        setState(() {
          _allTasks = data['items'] ?? [];
          _applyFilters();
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

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    List<dynamic> baseList = _allTasks;

    if (_selectedCategory != "All") {
      baseList = baseList
          .where((t) => (t['category'] ?? '').toString() == _selectedCategory)
          .toList();
    }

    if (query.isNotEmpty) {
      baseList = baseList.where((t) {
        final title = (t['title'] ?? '').toString().toLowerCase();
        final creator = (t['creator_name'] ?? '').toString().toLowerCase();
        return title.contains(query) || creator.contains(query);
      }).toList();
    }

    setState(() {
      _filteredTasks = baseList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Sleek App Bar
          _buildAppBar(),

          // 2. Filters & Search (Toggle with Search Bar)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildToggleBar(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 3. Task List
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text("Error: $_error"),
                    TextButton(
                      onPressed: _fetchTasks,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredTasks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: textLight.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text("No tasks found", style: TextStyle(color: textLight)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildDeptTaskCard(context, _filteredTasks[index], index),
                  childCount: _filteredTasks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      backgroundColor: bgSlate,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildRoundButton(
          Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          "Dept Directives",
          style: TextStyle(
            color: textDark,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleBar() {
    final categories = ["All", "Academic", "Maintenance", "Administrative"];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            bool isActive = _selectedCategory == cat;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat);
                _applyFilters();
              },
              child: AnimatedContainer(
                duration: 250.ms,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive ? brandPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isActive ? Colors.white : textLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: textLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _applyFilters(),
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: "Search tasks or creators...",
                hintStyle: TextStyle(
                  color: textLight.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _applyFilters();
              },
              child: Icon(Icons.close_rounded, color: textLight, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildDeptTaskCard(BuildContext context, dynamic task, int index) {
    final String managerName = task['creator_name'] ?? "Unknown";
    final String taskTitle = task['title'] ?? "No Title";
    final String category = task['category'] ?? "General";
    final String timing = task['timing'] ?? "";
    final String createdAt = task['created_at'] ?? "";
    final int priority = task['priority'] ?? 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: textDark.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailsPage(
                    taskData: {'task_id': task['task_id'], 'title': taskTitle},
                    viewMode: 'viewonly',
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _badge(category, brandPrimary),
                      _priorityIndicator(priority),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    taskTitle,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _managedBySection(managerName),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  _bottomStats(timing, createdAt),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _managedBySection(String managerName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgSlate,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: brandPrimary.withOpacity(0.2),
            child: Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: brandPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MANAGED BY",
                style: TextStyle(
                  color: textLight,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                managerName,
                style: TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(
            Icons.verified_user_rounded,
            size: 16,
            color: Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _bottomStats(String timing, String createdAt) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CREATED AT",
              style: TextStyle(
                color: textLight,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              createdAt.split('T').first,
              style: TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "TIMING",
              style: TextStyle(
                color: textLight,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              timing,
              style: TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priorityIndicator(int priority) {
    String pStr = priority == 1 ? "High" : (priority == 2 ? "Medium" : "Low");
    Color pCol = priority == 1
        ? Colors.red
        : (priority == 2 ? Colors.orange : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pCol.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        pStr.toUpperCase(),
        style: TextStyle(color: pCol, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: textDark, size: 18),
      ),
    );
  }
}
