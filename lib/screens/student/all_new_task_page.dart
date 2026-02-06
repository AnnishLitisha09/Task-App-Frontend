import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AllNewTasksPage extends StatelessWidget {
  // CALLBACK: This is the bridge to the MainWrapper
  final Function(Map<String, dynamic>) onAccept;

  const AllNewTasksPage({super.key, required this.onAccept});

  final Color brandAccent = const Color(0xFF6366F1);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color destructive = const Color(0xFFF43F5E);
  final Color successColor = const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Incoming Requests", 
          style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 20)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: 3, 
        itemBuilder: (context, index) {
          // Dummy data for simulation
          List<String> titles = ["Research Assistant", "Library Support", "Lab Supervisor"];
          return _buildRequestCard(context, titles[index], "Dept. of Science • ${index + 1}h ago", index + 10);
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, String title, String timestamp, int startTime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: brandAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.bolt_rounded, color: brandAccent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: textMain, fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(timestamp, style: TextStyle(color: textSub, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _actionBtn(context, "Reject", destructive, () => _showRejectDialog(context, title)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(context, "Accept", successColor, () {
                  // EXECUTE CALLBACK: Send data to MainWrapper
                  onAccept({
                    "title": title,
                    "sub": timestamp.split("•")[0].trim(),
                    "start": startTime, // Dynamic start time based on index
                    "dur": 90,         // 1.5 hours
                    "icon": Icons.task_alt_rounded,
                  });

                  Navigator.pop(context); // Go back
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Success: $title added to schedule"),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: successColor,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _actionBtn(BuildContext context, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String taskName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Reject Request", style: TextStyle(color: textMain, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text("Why are you declining '$taskName'?", style: TextStyle(color: textSub)),
            const SizedBox(height: 20),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter your reason here...",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: destructive, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text("Confirm Rejection", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}