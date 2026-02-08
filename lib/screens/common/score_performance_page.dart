import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScorePerformancePage extends StatelessWidget {
  const ScorePerformancePage({super.key});

  final Color brandAccent = const Color(0xFF6366F1);
  final Color penaltyRed = const Color(0xFFF87171);
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Performance", 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: brandAccent)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
    );
  }

  Widget _buildScoreOverview() {
    return Row(
      children: [
        // Total Score Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: brandAccent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: brandAccent.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Score", style: TextStyle(color: brandAccent, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Text("2,450", style: TextStyle(color: brandAccent, fontWeight: FontWeight.w900, fontSize: 32)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Penalty Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: penaltyRed.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: penaltyRed.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Penalties", style: TextStyle(color: penaltyRed, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Text("12", style: TextStyle(color: penaltyRed, fontWeight: FontWeight.w900, fontSize: 32)),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPerformanceGraphSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Score Trend", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: slate500.withOpacity(0.8))),
            Text("Last 7 Days", style: TextStyle(color: brandAccent, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 180,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          child: CustomPaint(
            painter: PerformanceChartPainter(brandAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskBreakdownHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text("Task Breakdown", 
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: slate500.withOpacity(0.8))),
    );
  }

  Widget _buildTaskBreakdownList() {
    final tasks = [
      {'title': 'Morning Sprint', 'score': '+450', 'penalty': '0', 'icon': Icons.bolt},
      {'title': 'UI Review', 'score': '+120', 'penalty': '-1', 'icon': Icons.palette},
      {'title': 'Client Call', 'score': '+800', 'penalty': '0', 'icon': Icons.phone},
    ];

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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Icon(task['icon'] as IconData, color: brandAccent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task['title']! as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(task['penalty'] == '0' ? "Perfect Completion" : "Late Submission", 
                      style: TextStyle(color: slate500.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(task['score']! as String, style: TextStyle(color: brandAccent, fontWeight: FontWeight.w800, fontSize: 15)),
                  if (task['penalty'] != '0')
                    Text("${task['penalty']} Penalty", style: TextStyle(color: penaltyRed, fontWeight: FontWeight.w600, fontSize: 11)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }
}

// Simple Painter for a Clean Performance Curve
class PerformanceChartPainter extends CustomPainter {
  final Color accent;
  PerformanceChartPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
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
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.9, size.width * 0.4, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.1, size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.2);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}