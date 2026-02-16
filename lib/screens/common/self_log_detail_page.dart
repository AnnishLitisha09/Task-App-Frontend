import 'package:flutter/material.dart';

class SelfLogDetailPage extends StatefulWidget {
  final Map<String, dynamic> log;

  const SelfLogDetailPage({super.key, required this.log});

  @override
  State<SelfLogDetailPage> createState() => _SelfLogDetailPageState();
}

class _SelfLogDetailPageState extends State<SelfLogDetailPage> {
  // Design Tokens - Aligned with TaskDetailsPage
  final Color brandPrimary = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color destructive = const Color(0xFFF43F5E);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final List documents = log['selectedDocuments'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildCustomAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header with side-aligned hours
            _buildPolishedHeader(log),
            const SizedBox(height: 32),

            // 2. Detail Grid (Date & Time)
            _buildDetailGrid([
              _detailItem(Icons.calendar_today_outlined, "DATE", log['date']),
              _detailItem(
                Icons.access_time_rounded,
                "TIME RANGE",
                '${log['startTime']} - ${log['endTime']}',
              ),
            ]),
            const SizedBox(height: 32),

            // 3. Description Section
            _buildSectionLabel("Activity Description"),
            const SizedBox(height: 12),
            _buildDescriptionBox(log['description']),
            const SizedBox(height: 32),

            // 5. Attachments Section
            if (documents.isNotEmpty) ...[
              _buildSectionLabel("Attached Documents"),
              const SizedBox(height: 16),
              ...documents.map((doc) => _buildDocumentTile(doc)),
            ],

            const SizedBox(height: 60), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildPolishedHeader(Map<String, dynamic> log) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryBadge(),
              const SizedBox(height: 12),
              Hero(
                tag: 'log_title_${log['title']}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    log['title'],
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textMain,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildManagedBySection(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        _buildSideHoursCard(log['duration'].toString()),
      ],
    );
  }

  Widget _buildSideHoursCard(String hours) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brandAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brandAccent.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            hours.endsWith('h') ? hours.replaceAll('h', '') : hours,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: brandAccent,
              height: 1,
            ),
          ),
          Text(
            "HOURS",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: brandAccent.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagedBySection() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 12,
          backgroundImage: NetworkImage(
            'https://ui-avatars.com/api/?name=User&background=6366F1&color=fff',
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(color: textSub, fontSize: 13),
            children: [
              const TextSpan(text: "Logged by "),
              TextSpan(
                text: "Me",
                style: TextStyle(color: textMain, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildCustomAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textMain,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        "Log Detail",
        style: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: brandAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "SELF LOGGED ACTIVITY",
        style: TextStyle(
          color: brandAccent,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDetailGrid(List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: surfaceColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: items[0]),
          Container(
            width: 1,
            height: 30,
            color: surfaceColor,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          Expanded(child: items[1]),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: brandAccent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: textSub,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textMain,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionBox(String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceColor),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 14,
          color: textMain.withOpacity(0.8),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: textSub,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDocumentTile(String docName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textSub.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.description_outlined,
              color: brandAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
                Text(
                  "Attached PDF Document",
                  style: TextStyle(fontSize: 11, color: textSub),
                ),
              ],
            ),
          ),
          Icon(
            Icons.open_in_new_rounded,
            color: textSub.withOpacity(0.5),
            size: 18,
          ),
        ],
      ),
    );
  }
}
