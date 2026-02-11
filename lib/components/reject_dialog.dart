import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class RejectDialog extends StatefulWidget {
  final String taskTitle;
  final List<String> reasons;
  final Function(String reason, String otherDetails) onConfirm;

  const RejectDialog({
    super.key,
    required this.taskTitle,
    required this.reasons,
    required this.onConfirm,
  });

  @override
  State<RejectDialog> createState() => _RejectDialogState();

  static void show(
    BuildContext context, {
    required String taskTitle,
    required List<String> reasons,
    required Function(String reason, String otherDetails) onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RejectDialog(
        taskTitle: taskTitle,
        reasons: reasons,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _RejectDialogState extends State<RejectDialog> {
  String? selectedReason;
  final TextEditingController otherController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 32,
          right: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSub.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Decline Task",
              style: AppTheme.h1.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              "Please provide a reason for declining '${widget.taskTitle}'",
              style: AppTheme.bodySub,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.reasons.map((reason) {
                bool isSelected = selectedReason == reason;
                return GestureDetector(
                  onTap: () => setState(() => selectedReason = reason),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.danger : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
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
            if (selectedReason == "Other")
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: TextField(
                  controller: otherController,
                  autofocus: true,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Please specify...",
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: AppTheme.textSub)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (selectedReason == null ||
                            (selectedReason == "Other" && otherController.text.trim().isEmpty))
                        ? null
                        : () {
                            widget.onConfirm(selectedReason!, otherController.text.trim());
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      disabledBackgroundColor: AppTheme.danger.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Confirm Decline",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
