import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/task_card.dart';
import '../../components/skeleton_loader.dart';
import '../../services/task_service.dart';
import '../common/task_detail_page.dart';

class AllEscalationsPage extends StatefulWidget {
  final String userRole;

  const AllEscalationsPage({super.key, required this.userRole});

  @override
  State<AllEscalationsPage> createState() => _AllEscalationsPageState();
}

class _AllEscalationsPageState extends State<AllEscalationsPage> {
  final TaskService _taskService = TaskService();
  List<dynamic> _escalations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await _taskService.getEscalations();
      if (mounted) {
        setState(() {
          _escalations = data;
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
          'Escalated Tasks',
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
          : _escalations.isEmpty
          ? const Center(
              child: Text(
                'No escalated tasks',
                style: TextStyle(color: AppTheme.textSub),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppTheme.brandAccent,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _escalations.length,
                itemBuilder: (context, index) {
                  final e = _escalations[index];
                  final heroTag = 'escalation_all_${e['task_id']}_$index';
                  return TaskCard(
                    title: e['title'] ?? 'Escalated Task',
                    sub:
                        e['escalated_reason'] ??
                        e['description'] ??
                        'High Priority',
                    accent: AppTheme.danger,
                    icon: Icons.priority_high_rounded,
                    heroTag: heroTag,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(
                          taskData: {
                            'task_id': e['task_id'],
                            'title': e['title'],
                            'sub': e['description'],
                            'accent': AppTheme.danger,
                            'icon': Icons.priority_high_rounded,
                            'heroTag': heroTag,
                            'startDate': e['start_date'] ?? 'N/A',
                            'deadline': e['end_date'] ?? 'N/A',
                            'completionType': e['type'] ?? 'INFO',
                            'isRequest': false,
                            'authority': 'Administration',
                            'userRole': widget.userRole,
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
