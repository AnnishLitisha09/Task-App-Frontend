import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class UnifiedRejectDialog extends StatefulWidget {
  final String taskTitle;
  final VoidCallback onTransfer;
  final Function(String reason, String otherDetails) onReject;

  const UnifiedRejectDialog({
    super.key,
    required this.taskTitle,
    required this.onTransfer,
    required this.onReject,
  });

  @override
  State<UnifiedRejectDialog> createState() => _UnifiedRejectDialogState();

  static void show(
    BuildContext context, {
    required String taskTitle,
    required VoidCallback onTransfer,
    required Function(String reason, String otherDetails) onReject,
  }) {
    showDialog(
      context: context,
      builder: (context) => UnifiedRejectDialog(
        taskTitle: taskTitle,
        onTransfer: onTransfer,
        onReject: onReject,
      ),
    );
  }
}

class _UnifiedRejectDialogState extends State<UnifiedRejectDialog> {
  // View State: 'choice' or 'reject_form'
  String _view = 'choice';

  // Reject Form State
  String? selectedReason;
  final TextEditingController otherController = TextEditingController();
  final List<String> reasons = [
    "Scheduling Conflict",
    "Resource Unavailability",
    "Outside Expertise",
    "Other",
  ];

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: 300.ms,
            child: _view == 'choice' ? _buildChoiceView() : _buildRejectForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceView() {
    return Column(
      key: const ValueKey('choice'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          "Review Action",
          "Decide how to handle '${widget.taskTitle}'",
          Icons.rule_rounded,
        ),
        const SizedBox(height: 32),
        _actionButton(
          label: "Just Reject",
          subtitle: "Decline without transferring",
          icon: Icons.close_rounded,
          color: AppTheme.danger,
          onTap: () => setState(() => _view = 'reject_form'),
        ),
        const SizedBox(height: 16),
        _actionButton(
          label: "Transfer / Escalate",
          subtitle: "Assign to another faculty/HOD",
          icon: Icons.trending_up_rounded,
          color: AppTheme.brandAccent,
          onTap: () {
            Navigator.pop(context); // Close dialog
            widget.onTransfer(); // Trigger transfer
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[400])),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectForm() {
    return Column(
      key: const ValueKey('reject_form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildHeader(
                "Reason for Rejection",
                "Why are you declining this task?",
                Icons.feedback_outlined,
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _view = 'choice'),
              icon: Icon(Icons.arrow_back_rounded, color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: reasons.map((reason) {
            bool isSelected = selectedReason == reason;
            return GestureDetector(
              onTap: () => setState(() => selectedReason = reason),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.danger : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.danger : Colors.grey[200]!,
                  ),
                ),
                child: Text(
                  reason,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textMain,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedReason == "Other") ...[
          const SizedBox(height: 16),
          TextField(
            controller: otherController,
            autofocus: true,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Please provide details...",
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ).animate().fadeIn(),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                (selectedReason == null ||
                    (selectedReason == "Other" &&
                        otherController.text.trim().isEmpty))
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onReject(
                      selectedReason!,
                      otherController.text.trim(),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              disabledBackgroundColor: AppTheme.danger.withOpacity(0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Confirm Rejection",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, String sub, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.textMain, size: 24),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: const TextStyle(color: AppTheme.textSub, fontSize: 13),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textMain,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSub.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
