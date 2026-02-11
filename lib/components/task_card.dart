import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String sub;
  final Color accent;
  final IconData icon;
  final String? heroTag;
  final bool isRequest;
  final bool isApproval;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const TaskCard({
    super.key,
    required this.title,
    required this.sub,
    required this.accent,
    required this.icon,
    this.heroTag,
    this.isRequest = false,
    this.isApproval = false,
    this.onTap,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isRequest || isApproval ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPrimary.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyMain,
                    ),
                    Text(
                      sub,
                      style: AppTheme.bodySub,
                    ),
                  ],
                ),
              ),
              if (!isRequest && !isApproval)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.textSub.withOpacity(0.3),
                ),
            ],
          ),
          if (isRequest || isApproval) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _miniActionBtn("Reject", AppTheme.danger, onReject),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniActionBtn(
                    isApproval ? "Approve" : "Accept",
                    AppTheme.success,
                    onAccept,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (heroTag != null) {
      content = Hero(
        tag: heroTag!,
        child: Material(
          color: Colors.transparent,
          child: content,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: content,
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _miniActionBtn(String label, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
