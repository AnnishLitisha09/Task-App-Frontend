import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/performance_stats.dart';
import '../../theme/app_theme.dart';

class ScorePerformancePage extends StatefulWidget {
  const ScorePerformancePage({super.key});

  @override
  State<ScorePerformancePage> createState() => _ScorePerformancePageState();
}

class _ScorePerformancePageState extends State<ScorePerformancePage> {
  PerformanceStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/stats/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("ScorePerformancePage: Response status: ${response.statusCode}");
      print("ScorePerformancePage: Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _stats = PerformanceStats.fromJson(data);
            _isLoading = false;
          });
        }
      } else {
        throw Exception(
          'Failed to load performance stats: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print("ScorePerformancePage: Error: $e");
      print("ScorePerformancePage: Stacktrace: $stackTrace");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppTheme.brandAccent,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text("Fetching your progress...", style: AppTheme.bodyMain),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.danger,
                  size: 48,
                ),
                const SizedBox(height: 24),
                Text("Something went wrong", style: AppTheme.h1),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySub,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _fetchStats,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Try Again"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Performance", style: AppTheme.h1),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        color: AppTheme.brandAccent,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildScoreOverview(),
              ),
              const SizedBox(height: 40),
              _buildPerformanceGraphSection(),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Task Breakdown"),
                    const SizedBox(height: 16),
                    _buildTaskBreakdownList(),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTheme.h2);
  }

  Widget _buildScoreOverview() {
    return Row(
      children: [
        _buildStatCard(
          label: "TOTAL",
          value: "${_stats?.totalScore ?? 0}",
          color: AppTheme.brandAccent,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: "PENALTY",
          value: "${_stats?.totalPenalty ?? 0}",
          color: AppTheme.danger,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: "EARNED",
          value: "${_stats?.totalEarnedScore ?? 0}",
          color: AppTheme.success,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: AppTheme.bentoDecoration(color),
        child: Column(
          children: [
            Text(
              label,
              style: AppTheme.overline.copyWith(color: color, fontSize: 8),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.h1.copyWith(color: color, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceGraphSection() {
    final dailyScores =
        _stats?.last7Days.map((e) => e.score.toDouble()).toList() ?? [];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Score Trend"),
                  const Text("Last 7 Days", style: AppTheme.bodySub),
                ],
              ),
              const Icon(
                Icons.trending_up_rounded,
                color: AppTheme.brandAccent,
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: dailyScores.isEmpty
                ? const Center(
                    child: Text("Not enough data", style: AppTheme.bodySub),
                  )
                : CustomPaint(
                    painter: PerformanceChartPainter(
                      AppTheme.brandAccent,
                      dailyScores,
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTaskBreakdownList() {
    final tasks = _stats?.taskDetails ?? [];

    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        width: double.infinity,
        decoration: AppTheme.bentoDecoration(AppTheme.textSub),
        child: const Column(
          children: [
            Icon(Icons.assignment_outlined, color: AppTheme.textSub, size: 40),
            SizedBox(height: 16),
            Text("No recent tasks completed", style: AppTheme.bodySub),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.brandAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: AppTheme.bodyMain),
                    Text(
                      task.submissionType.toUpperCase(),
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "+${task.earnedScore}",
                    style: AppTheme.bodyMain.copyWith(
                      color: AppTheme.brandAccent,
                    ),
                  ),
                  if (task.penaltyApplied > 0)
                    Text(
                      "-${task.penaltyApplied}",
                      style: AppTheme.caption.copyWith(color: AppTheme.danger),
                    ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class PerformanceChartPainter extends CustomPainter {
  final Color accent;
  final List<double> scores;
  PerformanceChartPainter(this.accent, this.scores);

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withOpacity(0.15), accent.withOpacity(0.01)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final double stepX = size.width / (scores.length - 1);

    double maxScore = scores.reduce((a, b) => a > b ? a : b);
    double minScore = scores.reduce((a, b) => a < b ? a : b);

    if (maxScore == minScore) {
      maxScore += 10;
      minScore = (minScore - 10).clamp(0, double.infinity);
    } else {
      maxScore += (maxScore - minScore) * 0.1;
      minScore = (minScore - (maxScore - minScore) * 0.1).clamp(
        0,
        double.infinity,
      );
    }

    final double range = maxScore - minScore;
    final path = Path();
    final fillPath = Path();
    List<Offset> points = [];

    for (int i = 0; i < scores.length; i++) {
      double x = i * stepX;
      double y = size.height - ((scores[i] - minScore) / range * size.height);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevPoint = points[i - 1];
        final currentPoint = points[i];
        final controlPoint1 = Offset(
          prevPoint.dx + (currentPoint.dx - prevPoint.dx) / 2,
          prevPoint.dy,
        );
        final controlPoint2 = Offset(
          prevPoint.dx + (currentPoint.dx - prevPoint.dx) / 2,
          currentPoint.dy,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
        fillPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 4, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
