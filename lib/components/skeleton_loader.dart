import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A shimmer animation wrapper that pulses opacity to simulate loading.
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => Opacity(opacity: _animation.value, child: child),
      child: widget.child,
    );
  }
}

/// A simple rounded box placeholder.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Skeleton for a stat card (2×2 grid item).
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 2×2 skeleton grid of stat cards.
class SkeletonStatGrid extends StatelessWidget {
  const SkeletonStatGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: const [
        SkeletonStatCard(),
        SkeletonStatCard(),
        SkeletonStatCard(),
        SkeletonStatCard(),
      ],
    );
  }
}

/// Skeleton for a single TaskCard-style row.
class SkeletonTaskCard extends StatelessWidget {
  const SkeletonTaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A skeleton section header (title + "View All" placeholder).
class SkeletonSectionHeader extends StatelessWidget {
  const SkeletonSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 4),
        child: Row(
          children: [
            Container(
              height: 14,
              width: 160,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const Spacer(),
            Container(
              height: 12,
              width: 60,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A complete dashboard skeleton: stat grid + 2 section previews.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonStatGrid(),
          SizedBox(height: 32),
          SkeletonSectionHeader(),
          SkeletonTaskCard(),
          SkeletonTaskCard(),
          SizedBox(height: 24),
          SkeletonSectionHeader(),
          SkeletonTaskCard(),
          SkeletonTaskCard(),
        ],
      ),
    );
  }
}

/// A skeleton for the Task Details page.
class TaskDetailSkeleton extends StatelessWidget {
  const TaskDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 80, height: 24, radius: 12), // Priority badge
          const SizedBox(height: 24),
          const SkeletonBox(width: 250, height: 32, radius: 8), // Title
          const SizedBox(height: 12),
          const SkeletonBox(width: 150, height: 16, radius: 4), // Subtitle
          const SizedBox(height: 32),
          const SkeletonBox(width: double.infinity, height: 80, radius: 20), // Venue/Section
          const SizedBox(height: 24),
          const SkeletonBox(width: double.infinity, height: 80, radius: 20), // Timeframe
          const SizedBox(height: 24),
          const SkeletonBox(width: 120, height: 20, radius: 6), // Section label
          const SizedBox(height: 12),
          const SkeletonBox(width: double.infinity, height: 120, radius: 20), // Description
          const SizedBox(height: 32),
          const SkeletonBox(width: 120, height: 20, radius: 6), // Activity Log label
          const SizedBox(height: 12),
          const SkeletonBox(width: double.infinity, height: 100, radius: 20), // Timeline box
          const SizedBox(height: 48),
          const SkeletonBox(width: double.infinity, height: 56, radius: 16), // Bottom button placeholder
        ],
      ),
    );
  }
}

/// A branded spinner that uses the app logo instead of a native indicator.
class BrandSpinner extends StatelessWidget {
  final double size;
  const BrandSpinner({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/logo.jpg',
        width: size,
      )
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 800.ms)
      .shimmer(duration: 1200.ms, color: Colors.blue.withOpacity(0.1)),
    );
  }
}
