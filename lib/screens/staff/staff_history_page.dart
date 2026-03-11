import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/user_service.dart';
import '../../models/activity_history_model.dart';
import 'package:intl/intl.dart';

class StaffHistoryPage extends StatefulWidget {
  const StaffHistoryPage({super.key});

  @override
  State<StaffHistoryPage> createState() => _StaffHistoryPageState();
}

class _StaffHistoryPageState extends State<StaffHistoryPage> {
  // --- Style Palette ---
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color errorRed = const Color(0xFFF43F5E);

  bool _isLoading = true;
  String? _error;
  ActivityHistoryResponse? _data;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await UserService().getActivityHistory();
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

  IconData _getIcon(String title, String? category) {
    String t = title.toLowerCase();
    String? c = category?.toLowerCase();

    if (t.contains('waste') || c == 'sanitation') {
      return Icons.delete_outline_rounded;
    }
    if (t.contains('meeting') || c == 'meeting') return Icons.groups_rounded;
    if (t.contains('maintenance') || c == 'maintenance') {
      return Icons.settings_outlined;
    }
    if (t.contains('leak') || t.contains('plumb')) {
      return Icons.plumbing_rounded;
    }
    if (t.contains('electric') || t.contains('bolt')) return Icons.bolt_rounded;
    if (t.contains('inspect') || c == 'inspection') {
      return Icons.fact_check_outlined;
    }

    return Icons.history_rounded;
  }

  Color _getColor(String title, String? category) {
    String t = title.toLowerCase();

    if (t.contains('waste')) return const Color(0xFF10B981);
    if (t.contains('meeting')) return Colors.blueGrey;
    if (t.contains('maintenance')) return brandAccent;
    if (t.contains('leak')) return const Color(0xFFF59E0B);
    if (t.contains('electric')) return Colors.purple;
    if (t.contains('inspect')) return Colors.blue;

    return brandAccent;
  }

  List<ActivityItem> _filterItems(List<ActivityItem> items) {
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.title.toLowerCase().contains(query) ||
              (item.category?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchHistory,
          color: brandAccent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. Custom Inline Header
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
                          fontSize: 22,
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

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildErrorState())
              else if (_data == null ||
                  (_data!.history.today.isEmpty &&
                      _data!.history.yesterday.isEmpty))
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_filterItems(_data!.history.today).isNotEmpty) ...[
                        _buildDateHeader("Today"),
                        ..._filterItems(
                          _data!.history.today,
                        ).map((item) => _buildHistoryCard(item)),
                        const SizedBox(height: 24),
                      ],
                      if (_filterItems(
                        _data!.history.yesterday,
                      ).isNotEmpty) ...[
                        _buildDateHeader("Yesterday"),
                        ..._filterItems(
                          _data!.history.yesterday,
                        ).map((item) => _buildHistoryCard(item)),
                      ],
                      if (_filterItems(_data!.history.today).isEmpty &&
                          _filterItems(_data!.history.yesterday).isEmpty)
                        _buildEmptySearchState(),
                    ]),
                  ),
                ),
            ],
          ),
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
        controller: _searchController,
        onChanged: (val) => setState(() {}),
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

  Widget _buildHistoryCard(ActivityItem item) {
    // Format time if it's ISO, otherwise use as is
    String displayTime = item.time;
    try {
      DateTime dt = DateTime.parse(item.time);
      displayTime = DateFormat('hh:mm a').format(dt);
    } catch (_) {}

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
              color: _getColor(item.title, item.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getIcon(item.title, item.category),
              color: _getColor(item.title, item.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayTime,
                  style: TextStyle(color: textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          if (item.status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.status!,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: textSub.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "No activity history yet",
            style: TextStyle(
              color: textSub,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: textSub.withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            Text(
              "No results matching your search",
              style: TextStyle(color: textSub),
            ),
          ],
        ),
      ),
    );
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
              "Something went wrong",
              style: TextStyle(
                color: textMain,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? "Unknown error",
              textAlign: TextAlign.center,
              style: TextStyle(color: textSub, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
