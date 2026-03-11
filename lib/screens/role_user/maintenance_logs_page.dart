import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../components/skeleton_loader.dart';

class MaintenanceLogsPage extends StatefulWidget {
  const MaintenanceLogsPage({super.key});

  @override
  State<MaintenanceLogsPage> createState() => _MaintenanceLogsPageState();
}

class _MaintenanceLogsPageState extends State<MaintenanceLogsPage> {
  bool _isLoading = true;

  final List<Map<String, dynamic>> _logs = [
    {
      'title': 'AC Filter Cleaning',
      'location': 'Seminar Hall 1',
      'date': 'Feb 26, 2026',
      'status': 'Completed',
      'category': 'Electrical',
      'cost': '\$120',
      'actionTaken':
          'Cleaned all filters, checked gas pressure, and replaced 2 faulty sensors.',
      'engineer': 'Engr. David Smith',
    },
    {
      'title': 'Projector Bulb Replacement',
      'location': 'Conference Room 3',
      'date': 'Feb 24, 2026',
      'status': 'Requested',
      'category': 'Technical',
      'cost': '\$350',
      'actionTaken':
          'Bulb replacement requested after 2000 hours of usage limit.',
      'engineer': 'Pending Assignment',
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _showAddLogPopup() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final costController = TextEditingController();
    final actionController = TextEditingController();
    String selectedCategory = 'Electrical';
    String selectedStatus = 'Requested';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          title: Text(
            "New Maintenance Log",
            style: AppTheme.h1.copyWith(fontSize: 24),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField(
                    "Issue Title",
                    "e.g. Fan Repair",
                    titleController,
                  ),
                  const SizedBox(height: 24),
                  _buildField("Location", "e.g. Room 102", locationController),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          "Category",
                          [
                            'Electrical',
                            'Technical',
                            'Infrastructure',
                            'Maintenance',
                          ],
                          (v) => setDialogState(() => selectedCategory = v!),
                          selectedCategory,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildField(
                          "Cost Est.",
                          "\$0",
                          costController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildField(
                    "Actions / Description",
                    "Details...",
                    actionController,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: AppTheme.textSub,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty) return;
                setState(() {
                  _logs.insert(0, {
                    'title': titleController.text,
                    'location': locationController.text,
                    'date': 'Just Now',
                    'status': selectedStatus,
                    'category': selectedCategory,
                    'cost': costController.text.startsWith('\$')
                        ? costController.text
                        : '\$${costController.text}',
                    'actionTaken': actionController.text,
                    'engineer': 'Current User',
                  });
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Save Log",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSub.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSub.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.brandPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    ValueChanged<String?> onChanged,
    String current,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: current,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          isExpanded: true,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSub.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSub.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.brandAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Maintenance Activity",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppTheme.textMain,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLogPopup,
        backgroundColor: AppTheme.brandAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "New Log",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: DashboardSkeleton(),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final bool isDone = log['status'] == 'Completed';
                final color = isDone
                    ? AppTheme.success
                    : (log['status'] == 'In Progress'
                          ? AppTheme.brandAccent
                          : AppTheme.warning);

                return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: AppTheme.cardDecoration,
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        shape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        collapsedShape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        tilePadding: const EdgeInsets.all(20),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.build_circle_outlined,
                            color: color,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          log['title'],
                          style: AppTheme.h1.copyWith(fontSize: 20),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppTheme.textSub,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  log['location'],
                                  style: AppTheme.bodySub.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              log['cost'],
                              style: AppTheme.h1.copyWith(fontSize: 20),
                            ),
                            Text(
                              log['status'].toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            color: AppTheme.surfaceColor.withOpacity(0.5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "MAINTENANCE DETAILS",
                                  style: AppTheme.overline.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _detailRow("CATEGORY", log['category']),
                                _detailRow("DATE", log['date']),
                                _detailRow("ENGINEER", log['engineer']),
                                const Divider(height: 40),
                                Text(
                                  "RECORDS / ACTION TAKEN",
                                  style: AppTheme.overline.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  log['actionTaken'],
                                  style: AppTheme.bodySub.copyWith(
                                    color: AppTheme.textMain,
                                    height: 1.6,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .slideY(begin: 0.1, delay: (index * 100).ms)
                    .fadeIn();
              },
            ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodySub.copyWith(
              color: AppTheme.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
