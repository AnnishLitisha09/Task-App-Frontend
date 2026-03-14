import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';

class MorningAcknowledgementPage extends StatefulWidget {
  final VoidCallback onAcknowledged;
  const MorningAcknowledgementPage({super.key, required this.onAcknowledged});

  @override
  State<MorningAcknowledgementPage> createState() =>
      _MorningAcknowledgementPageState();
}

class _MorningAcknowledgementPageState
    extends State<MorningAcknowledgementPage> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  
  final Color brandAccent = const Color(0xFF6366F1);
  final Color textMain = const Color(0xFF1E293B);
  final Color textSub = const Color(0xFF64748B);
  final Color warningColor = const Color(0xFFF59E0B);
  final Color destructive = const Color(0xFFF43F5E);

  bool _isAcknowledged = false;
  bool _isLoading = true;
  bool _isActionLoading = false;
  List<dynamic> _unacknowledgedTasks = [];
  String _userName = "User";
  final String deadlineString = "08:45 AM";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.getUnacknowledgedTasks();
      final user = await _authService.getCurrentUser();
      setState(() {
        _unacknowledgedTasks = tasks;
        _userName = user['name'] ?? "User";
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching acknowledgement data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAcknowledge() async {
    if (!_isAcknowledged) return;
    
    setState(() => _isActionLoading = true);
    try {
      await _taskService.acknowledgeGeneral();
      widget.onAcknowledged();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Acknowledgement Error: $e")),
      );
      setState(() => _isActionLoading = false);
    }
  }

  // Logic to check if user is late
  bool _isLate() {
    final now = DateTime.now();
    final deadline = DateTime(now.year, now.month, now.day, 8, 45);
    return now.isAfter(deadline);
  }

  @override
  Widget build(BuildContext context) {
    String currentTime = DateFormat('hh:mm a').format(DateTime.now());
    bool late = _isLate();
    Color activeThemeColor = late ? destructive : warningColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: brandAccent.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(currentTime),
                  const SizedBox(height: 40),

                  // Dynamic Warning/Penalty Banner
                  _buildStatusBanner(activeThemeColor, late),

                  const SizedBox(height: 32),
                  Text(
                    "TODAY'S OVERVIEW",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: textSub,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: _unacknowledgedTasks.isEmpty 
                      ? Center(
                          child: Text(
                            "No specific tasks assigned for today yet.",
                            style: TextStyle(color: textSub, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _unacknowledgedTasks.length,
                        itemBuilder: (context, index) {
                          final task = _unacknowledgedTasks[index];
                          return _taskPreviewTile(
                            task['task_title'] ?? 'Task',
                            task['category'] ?? 'General',
                            task['priority'] ?? 'Standard',
                          );
                        },
                      ),
                  ),

                  _buildAcknowledgeSection(activeThemeColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Good Morning, $_userName",
          style: TextStyle(
            color: textMain,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.access_time_filled_rounded,
              size: 16,
              color: brandAccent,
            ),
            const SizedBox(width: 6),
            Text(
              "It is currently $time",
              style: TextStyle(
                color: textSub,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1);
  }

  Widget _buildStatusBanner(Color themeColor, bool late) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              late ? Icons.error_outline_rounded : Icons.priority_high_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  late ? "Late Acknowledgement" : "Action Required",
                  style: TextStyle(
                    color: themeColor.withDarkerColor(),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  late
                      ? "The $deadlineString deadline has passed. A penalty may be applied to your score."
                      : "Please acknowledge your tasks before $deadlineString to avoid penalties.",
                  style: TextStyle(
                    color: themeColor.withDarkerColor().withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack);
  }

  Widget _taskPreviewTile(String title, String type, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: brandAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    color: textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: textMain,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgeSection(Color btnColor) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isAcknowledged = !_isAcknowledged),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _isAcknowledged,
                  onChanged: (v) => setState(() => _isAcknowledged = v!),
                  activeColor: btnColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  "I acknowledge today's schedule",
                  style: TextStyle(
                    color: textMain,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: (_isAcknowledged && !_isActionLoading)
                ? _handleAcknowledge
                : null, // Fires callback to RootWrapper
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: _isActionLoading 
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  "Enter Dashboard",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Ref: ${DateFormat('HH:mm:ss').format(DateTime.now())}",
          style: TextStyle(color: textSub, fontSize: 10, letterSpacing: 1),
        ),
      ],
    );
  }
}

extension ColorExt on Color {
  Color withDarkerColor() =>
      HSLColor.fromColor(this).withLightness(0.2).toColor();
}
