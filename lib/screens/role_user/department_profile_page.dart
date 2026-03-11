import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/department_wise_users_model.dart';
import '../faculty/student_detail_page.dart';

class DepartmentProfilePage extends StatefulWidget {
  final String departmentName;
  final DepartmentDetails details;

  const DepartmentProfilePage({
    super.key,
    required this.departmentName,
    required this.details,
  });

  @override
  State<DepartmentProfilePage> createState() => _DepartmentProfilePageState();
}

class _DepartmentProfilePageState extends State<DepartmentProfilePage> {
  final Color brandPrimary = const Color(0xFF6366F1);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);

  bool showStudents = false;
  final TextEditingController _searchController = TextEditingController();

  List<DeptUserDetails> get _filteredList {
    final baseList = showStudents
        ? widget.details.students
        : widget.details.faculty;
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return baseList;
    return baseList
        .where(
          (u) =>
              u.name.toLowerCase().contains(query) ||
              u.regNo.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHODCard(),
                  const SizedBox(height: 32),
                  _buildToggleBar(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: textSub.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No members found",
                        style: TextStyle(color: textSub),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final user = list[index];
                return _buildUserListItem(user, index);
              }, childCount: list.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildRoundButton(
          Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          widget.departmentName,
          style: TextStyle(
            color: textMain,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHODCard() {
    final hod = widget.details.hod;
    if (hod == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: brandPrimary.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: brandPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "HEAD OF DEPARTMENT",
                  style: TextStyle(
                    color: brandPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Hero(
                tag: 'hod-avatar',
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: brandPrimary.withOpacity(0.1),
                  child: Text(
                    hod.name[0].toUpperCase(),
                    style: TextStyle(
                      color: brandPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hod.name,
                      style: TextStyle(
                        color: textMain,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hod.email,
                      style: TextStyle(
                        color: textSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              _infoTile(Icons.assignment_ind_rounded, hod.regNo),
              const Spacer(),
              _actionIconButton(Icons.mail_outline_rounded),
              const SizedBox(width: 12),
              _actionIconButton(Icons.phone_in_talk_rounded),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _infoTile(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textSub),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: textMain,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _actionIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Icon(icon, color: textMain, size: 18),
    );
  }

  Widget _buildToggleBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildToggleOption(
            "Faculty",
            !showStudents,
            () => setState(() => showStudents = false),
          ),
          _buildToggleOption(
            "Students",
            showStudents,
            () => setState(() => showStudents = true),
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
          duration: 250.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                color: isActive ? brandPrimary : textSub,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: textSub, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              style: TextStyle(
                color: textMain,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: "Search name or ID...",
                hintStyle: TextStyle(
                  color: textSub.withOpacity(0.5),
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
                setState(() {});
              },
              child: Icon(Icons.close_rounded, color: textSub, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(DeptUserDetails user, int index) {
    return InkWell(
      onTap: showStudents
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentDetailPage(studentId: user.userId),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.03)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: (showStudents ? Colors.green : Colors.orange)
                  .withOpacity(0.1),
              child: Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  color: showStudents ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (showStudents)
              Icon(
                Icons.chevron_right_rounded,
                color: textSub.withOpacity(0.3),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
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
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
