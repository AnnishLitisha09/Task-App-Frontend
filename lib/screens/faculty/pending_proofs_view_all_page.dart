import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../common/task_detail_page.dart';

class PendingProofsViewAllPage extends StatelessWidget {
  final List<dynamic> proofs;

  const PendingProofsViewAllPage({
    super.key,
    required this.proofs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
          color: AppTheme.textMain,
        ),
        title: Row(
          children: [
            const Text(
              "Pending Proofs",
              style: TextStyle(
                color: AppTheme.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (proofs.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  proofs.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: proofs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 64,
                    color: AppTheme.textSub.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No pending proofs to review",
                    style: TextStyle(
                      color: AppTheme.textSub,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: proofs.length,
              itemBuilder: (context, idx) {
                final proof = proofs[idx];
                final String heroTag = "proof_all_${proof['task_id']}_$idx";
                final deadline = proof['deadline'];
                final String deadlineStr = deadline != null
                    ? "${deadline['end_date'] ?? 'N/A'} ${deadline['end_time'] ?? ''}"
                    : "N/A";

                return TaskCard(
                  title: proof['title'] ?? 'Proof Task',
                  sub: proof['description'] ??
                      'Proof Status: ${proof['proof_status'] ?? 'Pending'}',
                  accent: Colors.orange,
                  icon: Icons.photo_camera_rounded,
                  heroTag: heroTag,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailsPage(
                        taskData: {
                          'task_id': proof['task_id'],
                          'assignment_id': proof['assignment_id'],
                          'title': proof['title'],
                          'sub': proof['description'] ??
                              'Awaiting proof verification',
                          'accent': Colors.orange,
                          'icon': Icons.photo_camera_rounded,
                          'heroTag': heroTag,
                          'deadline': deadlineStr,
                          'completionType': "PROOF_REVIEW",
                          'isRequest': false,
                          'userRole': 'Faculty',
                          'is_document': proof['is_document'],
                          'status': proof['status'],
                          'proof_status': proof['proof_status'],
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
