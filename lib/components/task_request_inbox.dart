import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TaskRequestInbox extends StatelessWidget {
  const TaskRequestInbox({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for requests
    final List<Map<String, String>> requests = [
      {
        "id": "1",
        "title": "Faculty Peer Review",
        "sender": "Dr. Aris (Physics Dept)",
        "deadline": "Today, 5:00 PM"
      },
      {
        "id": "2",
        "title": "Lab Equipment Audit",
        "sender": "Admin Office",
        "deadline": "Tomorrow, 10:00 AM"
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final item = requests[index];
        return _buildRequestCard(context, item);
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, String> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              CircleAvatar(
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                child: const Icon(Icons.assignment_ind_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(data['sender']!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectionModal(context, data['title']!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Color(0xFFFFE4E6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Reject"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {}, // Accept logic
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Accept"),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * (int.parse(data['id']!))).ms).slideY(begin: 0.1);
  }

  // --- THE REQUIREMENT: REJECTION MODAL ---
  void _showRejectionModal(BuildContext context, String taskTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RejectionBottomSheet(taskTitle: taskTitle),
    );
  }
}

// Separate StatefulWidget to handle the "Reason" validation logic
class _RejectionBottomSheet extends StatefulWidget {
  final String taskTitle;
  const _RejectionBottomSheet({required this.taskTitle});

  @override
  State<_RejectionBottomSheet> createState() => _RejectionBottomSheetState();
}

class _RejectionBottomSheetState extends State<_RejectionBottomSheet> {
  final _reasonController = TextEditingController();
  bool _canSubmit = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Reason for Rejection", 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text("Please provide a valid reason for declining: ${widget.taskTitle}",
            style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            onChanged: (val) => setState(() => _canSubmit = val.trim().length > 10),
            decoration: InputDecoration(
              hintText: "e.g. Overlapping lecture schedule...",
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text("Minimum 10 characters required", 
            style: TextStyle(fontSize: 11, color: _canSubmit ? Colors.green : Colors.redAccent)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _canSubmit ? () {
                // Handle the final rejection logic
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Task Rejected successfully"))
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Confirm Rejection", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}