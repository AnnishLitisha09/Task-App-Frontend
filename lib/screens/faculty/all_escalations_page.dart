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
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppTheme.brandAccent,
              child: _escalations.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'No escalated tasks',
                            style: TextStyle(color: AppTheme.textSub),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(24),
                      itemCount: _escalations.length,
                      itemBuilder: (context, index) {
                        final e = _escalations[index];
                        final heroTag =
                            'escalation_all_${e['task_id'] ?? e['id']}_$index';
                        final String title =
                            e['task_title']?.toString() ??
                            e['title']?.toString() ??
                            'Escalated Task';
                        final String sub =
                            e['reason']?.toString() ??
                            e['message']?.toString() ??
                            e['escalated_reason']?.toString() ??
                            'Requires attention';
                        final String dateStr = e['created_at'] != null
                            ? e['created_at'].toString().split('T').first
                            : 'N/A';
                        final String statusStr =
                            e['status']?.toString().toUpperCase() ?? 'PENDING';
                        return TaskCard(
                          title: title,
                          sub: '$sub • $dateStr',
                          accent: AppTheme.danger,
                          icon: Icons.priority_high_rounded,
                          heroTag: heroTag,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailsPage(
                                taskData: {
                                  'task_id': e['task_id'] ?? e['id'],
                                  'title': title,
                                  'sub': sub,
                                  'accent': AppTheme.danger,
                                  'icon': Icons.priority_high_rounded,
                                  'heroTag': heroTag,
                                  'startDate': dateStr,
                                  'deadline': e['end_date'] ?? 'N/A',
                                  'completionType': statusStr,
                                  'isRequest': false,
                                  'isEscalated': true,
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
