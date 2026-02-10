import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StaffHistoryPage extends StatelessWidget {
  const StaffHistoryPage({super.key});

  // --- Style Palette ---
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Custom Inline Header (Replaced SliverAppBar)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 24, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: textMain,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "All Activities",
                      style: TextStyle(
                        color: textMain,
                        fontWeight: FontWeight.w800,
                        fontSize: 22, // Slightly larger for header feel
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Search & Filter Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: _buildSearchBar(),
              ),
            ),

            // 3. Activity List organized by Date
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildDateHeader("Today"),
                  _buildHistoryCard(
                    "Waste Collection",
                    "08:20 AM",
                    "Completed",
                    const Color(0xFF10B981),
                    Icons.delete_outline_rounded,
                  ),
                  _buildHistoryCard(
                    "General Maintenance",
                    "07:00 AM",
                    "Verified",
                    brandAccent,
                    Icons.settings_outlined,
                  ),

                  const SizedBox(height: 24),
                  _buildDateHeader("Yesterday"),
                  _buildHistoryCard(
                    "Pipe Leakage Repair",
                    "04:30 PM",
                    "Fixed",
                    const Color(0xFFF59E0B),
                    Icons.plumbing_rounded,
                  ),
                  _buildHistoryCard(
                    "Electrical Inspection",
                    "11:00 AM",
                    "Routine",
                    Colors.purple,
                    Icons.bolt_rounded,
                  ),
                  _buildHistoryCard(
                    "Staff Meeting",
                    "09:00 AM",
                    "Attended",
                    Colors.blueGrey,
                    Icons.groups_rounded,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textSub.withOpacity(0.05)),
      ),
      child: TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: textSub, size: 20),
          hintText: "Search history...",
          hintStyle: TextStyle(color: textSub.withOpacity(0.5), fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: textMain,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    String title,
    String time,
    String status,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brandPrimary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(color: textSub, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: textMain.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}
