import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../../components/skeleton_loader.dart';
import '../../services/task_service.dart';
import '../common/task_detail_page.dart';

class AllProofsPage extends StatefulWidget {
  const AllProofsPage({super.key});

  @override
  State<AllProofsPage> createState() => _AllProofsPageState();
}

class _AllProofsPageState extends State<AllProofsPage> {
  final TaskService _taskService = TaskService();
  List<dynamic> _proofs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final dynamic response = await _taskService.getPendingProofs();
      if (mounted) {
        setState(() {
          if (response is Map && response.containsKey('tasks')) {
            _proofs = response['tasks'] as List;
          } else if (response is List) {
            _proofs = response;
          } else {
            _proofs = [];
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.brandPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pending Proofs',
          style: TextStyle(
            color: AppTheme.brandPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                  SkeletonTaskCard(),
                ],
              ),
            )
          : _proofs.isEmpty
          ? const Center(
              child: Text(
                'No pending proofs to review',
                style: TextStyle(color: AppTheme.textSub),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppTheme.brandAccent,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _proofs.length,
                itemBuilder: (context, index) {
                  final proof = _proofs[index];
                  final heroTag = 'proof_all_${proof['task_id']}_$index';
                  final timing = proof['timing'] ?? proof['deadline'];
                  final deadlineStr = timing != null
                      ? '${timing['end_date'] ?? 'N/A'} ${timing['end_time'] ?? ''}'
                      : 'N/A';
                  return TaskCard(
                    title: proof['title'] ?? 'Proof Task',
                    sub:
                        proof['description'] ??
                        'Proof Status: ${proof['proof_status'] ?? 'Pending'}',
                    accent: Colors.orange,
                    icon: Icons.photo_camera_rounded,
                    heroTag: heroTag,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': proof['task_id'],
                            'assignment_id': proof['assignment_id'],
                            'title': proof['title'],
                            'sub':
                                proof['description'] ??
                                'Awaiting proof verification',
                            'accent': Colors.orange,
                            'icon': Icons.photo_camera_rounded,
                            'heroTag': heroTag,
                            'deadline': deadlineStr,
                            'completionType': 'PROOF_REVIEW',
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
            ),
    );
  }
}
