import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/leave_service.dart';

class NewLeaveRequestSheet extends StatefulWidget {
  const NewLeaveRequestSheet({super.key});

  @override
  State<NewLeaveRequestSheet> createState() => _NewLeaveRequestSheetState();
}

class _NewLeaveRequestSheetState extends State<NewLeaveRequestSheet> {
  String? _selectedCategory;
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _reasonController = TextEditingController();

  final Color brandAccent = const Color(0xFF6366F1);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  final List<String> _categories = [
    "Sick Leave",
    "Emergency Leave",
    "On-Duty (OD)",
    "General Permission (GP)",
    "Special Permission (SP)",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      // Use padding to handle the keyboard correctly
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        // Allows the whole sheet to scroll if keyboard pops up
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // This is the key: it hugs the content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // 2. Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "New Request",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: slate900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "Fill in the academic leave details below.",
                    style: TextStyle(color: slate500, fontSize: 14),
                  ),
                ],
              ),
            ),

            // 3. Form Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel("LEAVE TYPE"),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    icon: Icon(Icons.expand_more, color: brandAccent),
                    decoration: _inputDecoration(
                      icon: Icons.bookmark_border_rounded,
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),

                  const SizedBox(height: 20),

                  _fieldLabel("DURATION"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _dateTimeTile(
                          label: "FROM",
                          dt: _fromDate,
                          onTap: () => _pickDateTime(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dateTimeTile(
                          label: "TO",
                          dt: _toDate,
                          onTap: () => _pickDateTime(false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _fieldLabel("REASON FOR ABSENCE"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      icon: Icons.subject_rounded,
                      hint: "Briefly explain your reason...",
                    ),
                  ),

                  // This is the small gap you requested (reduced from 32+ to 20)
                  const SizedBox(height: 24),

                  // 4. Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_selectedCategory == null ||
                            _fromDate == null ||
                            _toDate == null ||
                            _reasonController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill all fields"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        // Map UI categories to API identifiers if needed
                        final leaveType = _selectedCategory!
                            .toLowerCase()
                            .replaceAll(" ", "_")
                            .replaceAll("(", "")
                            .replaceAll(")", "");

                        final bool success = await LeaveService().applyLeave(
                          leaveType: leaveType,
                          fromDate: DateFormat('yyyy-MM-dd').format(_fromDate!),
                          toDate: DateFormat('yyyy-MM-dd').format(_toDate!),
                          fromTime: DateFormat('HH:mm:ss').format(_fromDate!),
                          toTime: DateFormat('HH:mm:ss').format(_toDate!),
                          reason: _reasonController.text,
                        );

                        if (mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Application submitted successfully",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to submit application"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Submit Application",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ), // Bottom padding for the whole sheet
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: slate500.withOpacity(0.8),
        letterSpacing: 1.1,
      ),
    );
  }

  InputDecoration _inputDecoration({required IconData icon, String? hint}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: brandAccent, size: 22),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: brandAccent, width: 2),
      ),
    );
  }

  Widget _dateTimeTile({
    required String label,
    DateTime? dt,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: slate500,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dt == null ? "Select" : DateFormat('MMM dd').format(dt),
              style: TextStyle(
                color: slate900,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (dt != null)
              Text(
                DateFormat('hh:mm a').format(dt),
                style: TextStyle(
                  color: brandAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime(bool isFrom) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      final dt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (isFrom) {
        _fromDate = dt;
      } else {
        _toDate = dt;
      }
    });
  }
}
