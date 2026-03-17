import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../../components/skeleton_loader.dart';
import '../../services/task_service.dart';
import 'verify_users_proof_page.dart';

class TaskVerificationPage extends StatefulWidget {
  const TaskVerificationPage({super.key});

  @override
  State<TaskVerificationPage> createState() => _TaskVerificationPageState();
}

class _TaskVerificationPageState extends State<TaskVerificationPage> {
  final TaskService _taskService = TaskService();
  List<dynamic> _verifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final dynamic response = await _taskService.getPendingVerifications();
      if (mounted) {
        setState(() {
          if (response is List) {
            _verifications = response;
          } else {
            _verifications = [];
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
          'Task Verification',
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
                ],
              ),
            )
          : _verifications.isEmpty
          ? const Center(
              child: Text(
                'No tasks awaiting verification',
                style: TextStyle(color: AppTheme.textSub),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppTheme.brandAccent,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _verifications.length,
                itemBuilder: (context, index) {
                  final item = _verifications[index];
                  final heroTag = 'verify_${item['assignment_id']}_$index';
                  
                  return TaskCard(
                    title: item['title'] ?? 'Task Review',
                    sub: 'Submitted by: ${item['assignee_name']}\nRole: ${item['assignee_role']}',
                    accent: AppTheme.brandAccent,
                    icon: Icons.fact_check_rounded,
                    heroTag: heroTag,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VerifyUsersProofPage(
                            taskId: item['task_id'],
                            taskTitle: item['title'] ?? 'Task Review',
                          ),
                        ),
                      );
                      if (result == 'refreshed') {
                        _fetch();
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}
