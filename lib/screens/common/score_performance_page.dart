import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/performance_stats.dart';

class ScorePerformancePage extends StatefulWidget {
  const ScorePerformancePage({super.key});

  @override
  State<ScorePerformancePage> createState() => _ScorePerformancePageState();
}

class _ScorePerformancePageState extends State<ScorePerformancePage> {
  final Color brandAccent = const Color(0xFF6366F1);
  final Color penaltyRed = const Color(0xFFF87171);
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);

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
    } catch (e) {
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
        body: Center(child: CircularProgressIndicator(color: brandAccent)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Error loading data",
                style: TextStyle(
                  color: penaltyRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: slate500),
              ),
              TextButton(
                onPressed: _fetchStats,
                child: Text("Retry", style: TextStyle(color: brandAccent)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Performance",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: brandAccent,
          ),
        ),
        leading: const BackButton(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        color: brandAccent,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScoreOverview(),
              const SizedBox(height: 32),
              _buildPerformanceGraphSection(),
              const SizedBox(height: 32),
              _buildTaskBreakdownHeader(),
              _buildTaskBreakdownList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreOverview() {
    return Row(
      children: [
        _buildStatCard(
          label: "TOTAL SCORE",
          value: "${_stats?.totalScore ?? 0}",
          color: brandAccent,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: "PENALTIES",
          value: "${_stats?.totalPenalty ?? 0}",
          color: penaltyRed,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: "EARNED",
          value: "${_stats?.totalEarnedScore ?? 0}",
          color: Colors.green,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceGraphSection() {
    final dailyScores =
        _stats?.last7Days.map((e) => e.score.toDouble()).toList() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Score Trend",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: slate500.withOpacity(0.8),
              ),
            ),
            Text(
              "Last 7 Days",
              style: TextStyle(
                color: brandAccent,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 180,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          child: CustomPaint(
            painter: PerformanceChartPainter(brandAccent, dailyScores),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskBreakdownHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        "Task Breakdown",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: slate500.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildTaskBreakdownList() {
    final tasks = _stats?.taskDetails ?? [];

    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              color: slate500.withOpacity(0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              "No completed tasks yet",
              style: TextStyle(color: slate500, fontWeight: FontWeight.w600),
            ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  color: brandAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      task.submissionType,
                      style: TextStyle(
                        color: slate500.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "+${task.earnedScore}",
                    style: TextStyle(
                      color: brandAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (task.penaltyApplied > 0)
                    Text(
                      "-${task.penaltyApplied} Penalty",
                      style: TextStyle(
                        color: penaltyRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
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
        colors: [accent.withOpacity(0.2), accent.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final double stepX = size.width / (scores.length - 1);

    // Find min and max for scaling
    double maxScore = scores.reduce((a, b) => a > b ? a : b);
    double minScore = scores.reduce((a, b) => a < b ? a : b);

    // Ensure we have some range even if all scores are same
    if (maxScore == minScore) {
      maxScore += 10;
      minScore -= 10;
    }

    final double range = maxScore - minScore;

    for (int i = 0; i < scores.length; i++) {
      double x = i * stepX;
      // Flip y because (0,0) is top left
      double y =
          size.height -
          ((scores[i] - minScore) / range * size.height * 0.8 +
              (size.height * 0.1));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
