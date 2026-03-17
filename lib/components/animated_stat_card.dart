import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// A stat card that animates its numeric value from 0 to [numericValue].
/// If [value] is not parseable as a number (e.g. "0%"), it just displays [value].
class AnimatedStatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay; // milliseconds before counting starts

  const AnimatedStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.delay = 0,
  });

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnim;
  double _targetValue = 0;
  bool _isNumeric = false;

  @override
  void initState() {
    super.initState();
    _targetValue = double.tryParse(widget.value) ?? 0;
    _isNumeric = double.tryParse(widget.value) != null;

    _controller = AnimationController(
      vsync: this,
      duration: 1200.ms,
    );

    _countAnim = Tween<double>(begin: 0, end: _targetValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (_isNumeric) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newTarget = double.tryParse(widget.value) ?? 0;
      _isNumeric = double.tryParse(widget.value) != null;
      _countAnim = Tween<double>(
        begin: _controller.value * _targetValue,
        end: newTarget,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _targetValue = newTarget;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color.withOpacity(0.12),
            widget.color.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: widget.color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon with colored background
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.icon, color: widget.color, size: 20),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: 1.08,
                duration: 1800.ms,
                curve: Curves.easeInOut,
              ),

          // Value + label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isNumeric)
                AnimatedBuilder(
                  animation: _countAnim,
                  builder: (_, __) => Text(
                    _countAnim.value.toInt().toString(),
                    style: AppTheme.h1.copyWith(
                      fontSize: 26,
                      color: AppTheme.textMain,
                      letterSpacing: -1,
                    ),
                  ),
                )
              else
                Text(
                  widget.value,
                  style: AppTheme.h1.copyWith(
                    fontSize: 26,
                    color: AppTheme.textMain,
                    letterSpacing: -1,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: AppTheme.caption.copyWith(
                  color: widget.color.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
