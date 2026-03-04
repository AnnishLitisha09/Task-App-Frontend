import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/student_service.dart';
import '../../services/user_service.dart';
import '../../models/student_model.dart';
import '../../components/task_card.dart';
import '../common/create_task_page.dart';

class SelfLogHistoryPage extends StatefulWidget {
  const SelfLogHistoryPage({super.key});

  @override
  State<SelfLogHistoryPage> createState() => _SelfLogHistoryPageState();
}

class _SelfLogHistoryPageState extends State<SelfLogHistoryPage> {
  final StudentService _studentService = StudentService();
  final UserService _userService = UserService();
  bool _isLoading = true;
  StudentDetail? _studentDetail;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final profile = await _userService.getUserProfile();
      // profile.profileData.id is typically the primary key for the student record
      final detail = await _studentService.getStudentDetails(
        profile.profileData.id,
      );
      if (mounted) {
        setState(() {
          _studentDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "My Self Logs",
          style: TextStyle(
            color: AppTheme.textMain,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.brandAccent,
            ),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppTheme.brandAccent,
        child: _isLoading
            ? _buildLoadingState()
            : _studentDetail == null || _studentDetail!.selfLogs.isEmpty
            ? _buildEmptyState()
            : _buildLogsList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTaskPage(
                initialData: {'taskCategory': 'Self Log'},
              ),
            ),
          );
          _fetchData();
        },
        backgroundColor: AppTheme.brandAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Add Log",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildLogsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _studentDetail!.selfLogs.length,
      itemBuilder: (context, index) {
        final log = _studentDetail!.selfLogs[index];
        final title = log['title'] ?? log['task_title'] ?? 'Untitled Activity';
        final category = log['category'] ?? 'Self Log';
        final status = (log['status'] ?? 'PENDING').toString().toUpperCase();

        return TaskCard(
          title: title,
          sub: "$category • $status",
          accent: AppTheme.brandAccent,
          icon: Icons.history_edu_rounded,
          onTap: () {
            // Navigator.push task detail if needed
          },
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.brandAccent.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_edu_rounded,
              size: 64,
              color: AppTheme.brandAccent.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No self logs tracked yet",
            style: TextStyle(
              color: AppTheme.textMain,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Start recording your personal learning activities and achievements.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSub, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTaskPage(
                    initialData: {'taskCategory': 'Self Log'},
                  ),
                ),
              );
              _fetchData();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text("Create First Log"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}
