import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentAprovalPage extends StatefulWidget {
  const StudentAprovalPage({super.key});

  @override
  State<StudentAprovalPage> createState() => _StudentAprovalPageState();
}

class _StudentAprovalPageState extends State<StudentAprovalPage> {
  // --- Modern Minimal Palette ---
  final Color brandAccent = const Color(0xFF6366F1);

  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color bgGray = const Color(0xFFF8FAFC);
  final Color accentIndigo = const Color(0xFF6366F1);

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  final List<Map<String, String>> allRequests = [
    {
      "name": "Annish Litisha",
      "id": "7376232IT110",
      "type": "Sick Leave",
      "reason": "Severe migraine and doctor advised rest.",
      "from": "10 Feb",
      "to": "12 Feb",
      "days": "3",
    },
    {
      "name": "Sanjay Kumar",
      "id": "7376232IT152",
      "type": "On-Duty",
      "reason": "Attending Smart India Hackathon finals.",
      "from": "12 Feb",
      "to": "15 Feb",
      "days": "4",
    },
    {
      "name": "Rahul V",
      "id": "7376232IT144",
      "type": "Emergency",
      "reason": "Urgent travel to hometown for family ritual.",
      "from": "09 Feb",
      "to": "09 Feb",
      "days": "1",
    },
    {
      "name": "Priya Dharshini",
      "id": "7376232IT130",
      "type": "Permission",
      "reason": "Research work at the University Library.",
      "from": "Today",
      "to": "Today",
      "days": "1",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = allRequests.where((req) {
      return req['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          req['id']!.toLowerCase().contains(searchQuery.toLowerCase());
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
      ),
      body: Column(
        children: [
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  _buildApprovalCard(filtered[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, String> req) {
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
                      req['name']!,
                      style: TextStyle(
                        color: slate900,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      req['id']!,
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
                  color: brandAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  req['type']!.toUpperCase(),
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
              _dateTile("FROM", req['from']!),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: slate500.withOpacity(0.2),
                  size: 18,
                ),
              ),
              _dateTile("TO", req['to']!),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentIndigo.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  req['days']!,
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
            req['reason']!,
            style: TextStyle(color: slate500, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 28),

          // OUTLINE ONLY GLASS BUTTONS
          Row(
            children: [
              Expanded(
                child: _outlineGlassButton("Reject", const Color(0xFFF43F5E)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _outlineGlassButton("Approve", const Color(0xFF10B981)),
              ),
            ],
          ),
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

  // THE OUTLINE-ONLY GLASS BUTTON
  Widget _outlineGlassButton(String label, Color themeColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5,
          sigmaY: 5,
        ), // Subtle blur for the "glass" look
        child: InkWell(
          onTap: () {
            // Handle Action
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.transparent, // No fill color
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: themeColor.withOpacity(0.5), // Colored outline
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
