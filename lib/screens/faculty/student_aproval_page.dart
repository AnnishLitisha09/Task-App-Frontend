import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../models/leave_model.dart';
import '../../services/leave_service.dart';

class StudentAprovalPage extends StatefulWidget {
  const StudentAprovalPage({super.key});

  @override
  State<StudentAprovalPage> createState() => _StudentAprovalPageState();
}

class _StudentAprovalPageState extends State<StudentAprovalPage> {
  final LeaveService _leaveService = LeaveService();
  bool _isLoading = true;
  bool _isHistoryView = false;
  List<LeaveRecord> _requests = [];
  String searchQuery = "";

  final Color brandAccent = const Color(0xFF6366F1);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color bgGray = const Color(0xFFF8FAFC);
  final Color accentIndigo = const Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    List<LeaveRecord> result;
    if (_isHistoryView) {
      result = await _leaveService.getFacultyLeaves();
    } else {
      result = await _leaveService.getFacultyPendingLeaves();
    }
    if (mounted) {
      setState(() {
        _requests = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleStatusUpdate(int id, String status) async {
    final success = await _leaveService.updateLeaveStatus(id, status);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Request ${status == 'approved' ? 'Approved' : 'Rejected'}",
          ),
          backgroundColor: status == 'approved'
              ? Colors.green
              : Colors.redAccent,
        ),
      );
      _fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _requests.where((req) {
      final name = req.user?.student?.name.toLowerCase() ?? "";
      final regNo = req.user?.student?.regNo.toLowerCase() ?? "";
      final search = searchQuery.toLowerCase();
      return name.contains(search) || regNo.contains(search);
    }).toList();

    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: bgGray,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Approvals",
          style: TextStyle(
            color: slate900,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: brandAccent),
            onPressed: _fetchRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTab("Pending", !_isHistoryView),
                  _buildTab("History", _isHistoryView),
                ],
              ),
            ),
          ),

          // Minimal Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Search name or ID...",
                hintStyle: TextStyle(
                  color: slate500.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: slate500, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? _buildSkeletonApprovals()
                : RefreshIndicator(
                    onRefresh: _fetchRequests,
                    color: brandAccent,
                    child: filtered.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.2,
                              ),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox_rounded,
                                      size: 64,
                                      color: slate500.withOpacity(0.2),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No requests found",
                                      style: TextStyle(
                                        color: slate500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildApprovalCard(filtered[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonApprovals() {
    Widget _shimmer({
      double w = double.infinity,
      double h = 14,
      double r = 8,
    }) =>
        Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(r),
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1300.ms, color: Colors.white.withOpacity(0.7));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 4,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmer(h: 18, r: 8),
                      const SizedBox(height: 6),
                      _shimmer(w: 110, h: 12, r: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _shimmer(w: 70, h: 26, r: 8),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _shimmer(w: 60, h: 38, r: 10),
                const SizedBox(width: 12),
                _shimmer(w: 24, h: 18, r: 6),
                const SizedBox(width: 12),
                _shimmer(w: 60, h: 38, r: 10),
              ],
            ),
            const SizedBox(height: 20),
            _shimmer(h: 12, r: 6),
            const SizedBox(height: 6),
            _shimmer(w: 200, h: 12, r: 6),
          ],
        ),
      ).animate().fadeIn(delay: (i * 60).ms),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isActive) {
            setState(() {
              _isHistoryView = label == "History";
              _fetchRequests();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? brandAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : slate500,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalCard(LeaveRecord req) {
    final student = req.user?.student;
    final name = student?.name ?? "Unknown Student";
    final regNo = student?.regNo ?? "No Reg No";
    final type = req.leaveType.toUpperCase().replaceAll("_", " ");
    final fromDate = DateFormat('dd MMM').format(DateTime.parse(req.fromDate));
    final toDate = DateFormat('dd MMM').format(DateTime.parse(req.toDate));
    final reason = req.reason;

    // Calculate days (simple difference)
    final from = DateTime.parse(req.fromDate);
    final to = DateTime.parse(req.toDate);
    final days = to.difference(from).inDays + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: slate900,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      regNo,
                      style: TextStyle(color: slate500, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: req.status == 'pending'
                      ? brandAccent.withOpacity(0.9)
                      : (req.status == 'approved' ? Colors.green : Colors.red),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date Range
          Row(
            children: [
              _dateTile("FROM", fromDate),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: slate500.withOpacity(0.2),
                  size: 18,
                ),
              ),
              _dateTile("TO", toDate),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentIndigo.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  days.toString(),
                  style: TextStyle(
                    color: accentIndigo,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            reason,
            style: TextStyle(color: slate500, fontSize: 14, height: 1.6),
          ),

          if (req.status == 'pending') ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _outlineGlassButton(
                    "Reject",
                    const Color(0xFFF43F5E),
                    onTap: () => _handleStatusUpdate(req.id, 'rejected'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _outlineGlassButton(
                    "Approve",
                    const Color(0xFF10B981),
                    onTap: () => _handleStatusUpdate(req.id, 'approved'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn().moveY(begin: 10, end: 0);
  }

  Widget _dateTile(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: slate500,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: TextStyle(
            color: slate900,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _outlineGlassButton(
    String label,
    Color themeColor, {
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: themeColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
