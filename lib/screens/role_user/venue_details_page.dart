import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VenueDetailsPage extends StatefulWidget {
  const VenueDetailsPage({super.key});

  @override
  State<VenueDetailsPage> createState() => _VenueDetailsPageState();
}

class _VenueDetailsPageState extends State<VenueDetailsPage> {
  // --- Design Tokens ---
  final Color brandAccent = const Color(0xFF6366F1);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color successColor = const Color(0xFF10B981);
  final Color warningColor = const Color(0xFFF59E0B);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusRow(),
                  const SizedBox(height: 24),
                  _buildQuickStats(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Booking Requests", "4 New"),
                  _buildRequestCard("Tech Symposium 2026", "Feb 15 • 09:00 AM"),
                  const SizedBox(height: 24),
                  _buildSectionHeader("Booking History", "View All"),
                  _buildHistoryItem(
                    "Annual Convocation",
                    "Jan 20, 2026",
                    successColor,
                  ),
                  _buildHistoryItem(
                    "Placement Drive",
                    "Jan 12, 2026",
                    successColor,
                  ),
                  _buildHistoryItem(
                    "Music Fest",
                    "Jan 05, 2026",
                    Colors.redAccent,
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: brandAccent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTTGGNugQWH_yx2ZaReTajVjGsZLoUVK9SpkA&s',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Main Auditorium",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 4),

            Text(
              "CURRENT STATUS",
              style: TextStyle(
                color: textSub,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, color: successColor, size: 10),
                const SizedBox(width: 8),
                Text(
                  "Available Today",
                  style: TextStyle(
                    color: textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statTile(
          "128",
          "Total Bookings",
          brandAccent,
          Icons.calendar_month_rounded,
        ),
        const SizedBox(width: 12),
        _statTile(
          "04",
          "New Requests",
          warningColor,
          Icons.notification_important_rounded,
        ),
      ],
    );
  }

  Widget _statTile(String val, String label, Color col, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: col.withOpacity(0.1), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: col, size: 24),
            const SizedBox(height: 12),
            Text(
              val,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textMain,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textSub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: textSub,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            action,
            style: TextStyle(
              color: brandAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String title, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: warningColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: warningColor.withOpacity(0.2),
                child: Icon(Icons.bolt, color: warningColor),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(time, style: TextStyle(color: textSub, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniActionBtn("Reject", Colors.grey)),
              const SizedBox(width: 8),
              Expanded(child: _miniActionBtn("Approve", brandAccent)),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1);
  }

  Widget _miniActionBtn(String label, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, Color statusCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(color: statusCol, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: textMain, fontWeight: FontWeight.w600),
            ),
          ),
          Text(date, style: TextStyle(color: textSub, fontSize: 12)),
        ],
      ),
    );
  }
}
