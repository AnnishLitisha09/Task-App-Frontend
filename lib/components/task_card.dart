import 'package:flutter/material.dart';
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
  final VoidCallback? onTransfer;
  final String? acceptLabel;
  final String? rejectLabel;
  final Map<String, dynamic>? actionButton;
  final String? priority;
  final String? taskTypeName;
  final String? recurrence;

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
    this.onTransfer,
    this.acceptLabel,
    this.rejectLabel,
    this.actionButton,
    this.priority,
    this.taskTypeName,
    this.recurrence,
  });

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

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
                    Text(title, style: AppTheme.bodyMain),
                    Row(
                      children: [
                        Expanded(child: Text(sub, style: AppTheme.bodySub)),
                        if (priority != null) ...[
                          const SizedBox(width: 8),
                          _miniBadge(
                            priority!.toUpperCase(),
                            priority!.toLowerCase() == 'high' 
                                ? AppTheme.danger 
                                : (priority!.toLowerCase() == 'medium' ? AppTheme.warning : AppTheme.success)
                          ),
                        ],
                        if (taskTypeName != null && (taskTypeName!.toLowerCase().contains('floating') || taskTypeName!.toLowerCase().contains('long'))) ...[
                          const SizedBox(width: 4),
                          _miniBadge(taskTypeName!.toUpperCase(), AppTheme.brandPrimary),
                        ],
                        if (recurrence != null && recurrence!.toLowerCase() != 'none' && recurrence!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          _miniBadge(recurrence!.toUpperCase(), AppTheme.brandAccent),
                        ],
                      ],
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
            if (onAccept != null || onReject != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: _miniActionBtn(
                        rejectLabel ?? "Reject",
                        AppTheme.danger,
                        onReject,
                      ),
                    ),
                  if (onAccept != null && onReject != null)
                    const SizedBox(width: 12),
                  if (onAccept != null)
                    Expanded(
                      child: _miniActionBtn(
                        acceptLabel ?? (isApproval ? "Approve" : "Accept"),
                        AppTheme.success,
                        onAccept,
                      ),
                    ),
                ],
              ),
            ],
            if (onTransfer != null) ...[
              const SizedBox(height: 12),
              _miniActionBtn(
                "Transfer Task",
                AppTheme.brandAccent,
                onTransfer,
                isFullWidth: true,
              ),
            ],
          ],
          if (actionButton != null) ...[
            const SizedBox(height: 16),
            _miniActionBtn(
              (actionButton!['label'] as String).toUpperCase(),
              (actionButton!['label'] as String).toLowerCase().contains('proof') ? Colors.blue : AppTheme.brandAccent,
              onTap, // On dashboard, clicking the button usually goes to details or we can add onAction
              isFullWidth: true,
            ),
          ],
        ],
      ),
    );

    if (heroTag != null) {
      content = Hero(
        tag: heroTag!,
        child: Material(color: Colors.transparent, child: content),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: content,
      ),
    );
  }

  Widget _miniActionBtn(
    String label,
    Color color,
    VoidCallback? onTap, {
    bool isFullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: isFullWidth ? double.infinity : null,
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
