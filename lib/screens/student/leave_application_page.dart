import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../components/new_leave_request_sheet.dart';
import '../../models/leave_model.dart';
import '../../services/leave_service.dart';
import 'package:intl/intl.dart';

class LeaveApplicationPage extends StatefulWidget {
  const LeaveApplicationPage({super.key});

  @override
  State<LeaveApplicationPage> createState() => _LeaveApplicationPageState();
}

class _LeaveApplicationPageState extends State<LeaveApplicationPage> {
  final LeaveService _leaveService = LeaveService();
  bool _isLoading = true;
  List<LeaveRecord> _leaves = [];
  AttendanceStats _attendance = AttendanceStats(totalDays: 0, presentDays: 0, absentDays: 0);

  final Color brandAccent = const Color(0xFF6366F1);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  // Status Colors
  final Color successGreen = const Color(0xFF10B981);
  final Color warningOrange = const Color(0xFFF59E0B);
  final Color errorRed = const Color(0xFFF43F5E);

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    setState(() => _isLoading = true);
    final result = await _leaveService.getMyLeaves();
    if (mounted) {
      setState(() {
        _leaves = result.leaves;
        _attendance = result.stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: slate900,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Leave Management",
          style: TextStyle(
            color: slate900,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: brandAccent),
            onPressed: _fetchLeaves,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLeaves,
        color: brandAccent,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: brandAccent))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  const SizedBox(height: 12),
                  _buildAttendanceOverview(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_sectionHeader("Activity History")],
                  ),
                  const SizedBox(height: 16),
                  if (_leaves.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: slate500.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No leave records found",
                              style: TextStyle(color: slate500, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: surfaceColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: slate900.withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _leaves.length,
                        separatorBuilder: (context, index) => _divider(),
                        itemBuilder: (context, index) {
                          final leave = _leaves[index];
                          Color statusColor = slate500;
                          if (leave.status == 'pending') {
                            statusColor = warningOrange;
                          } else if (leave.status == 'approved') {
                            statusColor = successGreen;
                          } else if (leave.status == 'rejected') {
                            statusColor = errorRed;
                          }

                          return _buildActivityTile(
                            leave.leaveType.toUpperCase().replaceAll("_", " "),
                            "${DateFormat('MMM dd').format(DateTime.parse(leave.fromDate))} - ${DateFormat('MMM dd').format(DateTime.parse(leave.toDate))}",
                            leave.status,
                            statusColor,
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyBottomSheet(context),
        backgroundColor: brandAccent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: const Text(
          "New Request",
          style: TextStyle(
            color: Color.fromARGB(255, 238, 238, 238),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        icon: const Icon(
          Icons.add_rounded,
          color: Color.fromARGB(255, 238, 238, 238),
        ),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
    );
  }

  // --- ATTENDANCE OVERVIEW CARD (Dynamic) ---
  Widget _buildAttendanceOverview() {
    final pct = _attendance.percentage;
    final pctStr = pct.toStringAsFixed(1);
    final pctInt = pct.toInt();

    // Determine standing label & color
    String standing;
    Color standingColor;
    if (pct >= 90) {
      standing = 'High Standing';
      standingColor = successGreen;
    } else if (pct >= 75) {
      standing = 'Satisfactory';
      standingColor = warningOrange;
    } else {
      standing = 'At Risk';
      standingColor = errorRed;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: surfaceColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: slate900.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school_rounded, color: brandAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "ACADEMIC ATTENDANCE",
                        style: TextStyle(
                          color: slate500,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$pctStr%",
                    style: TextStyle(
                      color: slate900,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    standing,
                    style: TextStyle(
                      color: standingColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // Circular progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: pct / 100,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: surfaceColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 90 ? brandAccent : (pct >= 75 ? warningOrange : errorRed),
                      ),
                    ),
                  ),
                  Text(
                    "$pctInt",
                    style: TextStyle(
                      color: slate900,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStatLight("${_attendance.totalDays}", "Total Days"),
                _vDividerSlate(),
                _miniStatLight("${_attendance.presentDays}", "Present"),
                _vDividerSlate(),
                _miniStatLight("${_attendance.absentDays}", "Absent"),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _miniStatLight(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: slate900,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: slate500,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _vDividerSlate() =>
      Container(height: 24, width: 1.5, color: Colors.grey.withOpacity(0.15));

  // --- UPDATED ACTIVITY TILE: Uses BrandAccent for Calendar Icons ---
  Widget _buildActivityTile(
    String type,
    String date,
    String status,
    Color statusColor,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: brandAccent.withOpacity(
            0.08,
          ), // Default Theme Color background
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.calendar_month_rounded,
          color: brandAccent,
          size: 18,
        ), // Default Brand Color
      ),
      title: Text(
        type,
        style: TextStyle(
          color: slate900,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(date, style: TextStyle(color: slate500, fontSize: 12)),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            color: statusColor,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: slate500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    thickness: 1,
    color: surfaceColor,
    indent: 20,
    endIndent: 20,
  );

  void _showApplyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewLeaveRequestSheet(),
    );
  }
}
