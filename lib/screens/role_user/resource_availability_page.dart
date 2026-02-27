import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/skeleton_loader.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ResourceAvailabilityPage extends StatefulWidget {
  const ResourceAvailabilityPage({super.key});

  @override
  State<ResourceAvailabilityPage> createState() =>
      _ResourceAvailabilityPageState();
}

class _ResourceAvailabilityPageState extends State<ResourceAvailabilityPage> {
  bool _isLoading = true;

  final List<Map<String, dynamic>> _resources = [
    {
      'name': 'HD Projectors',
      'total': 12,
      'available': 8,
      'icon': Icons.videocam_rounded,
      'color': AppTheme.brandAccent,
      'category': 'Audio Visual',
      'working': 11,
      'faulty': 1,
      'software': 'v2.1 OK',
      'utilization': '65%',
    },
    {
      'name': 'Wireless Mics',
      'total': 20,
      'available': 14,
      'icon': Icons.mic_rounded,
      'color': AppTheme.success,
      'category': 'Audio Visual',
      'working': 18,
      'faulty': 2,
      'software': 'N/A',
      'utilization': '40%',
    },
    {
      'name': 'Laptops (Control)',
      'total': 15,
      'available': 3,
      'icon': Icons.laptop_mac_rounded,
      'color': Colors.orange,
      'category': 'IT Support',
      'working': 14,
      'faulty': 1,
      'software': 'Win11 Pro',
      'utilization': '90%',
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _showUpdateResourcePopup(int index) {
    final r = _resources[index];
    final totalController = TextEditingController(text: r['total'].toString());
    final availController = TextEditingController(
      text: r['available'].toString(),
    );
    final faultyController = TextEditingController(
      text: r['faulty'].toString(),
    );
    final softwareController = TextEditingController(text: r['software']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update Resource", style: AppTheme.h1.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text(r['name'], style: AppTheme.bodySub.copyWith(fontSize: 15)),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        "Total Units",
                        "Count",
                        totalController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildField(
                        "Available",
                        "Count",
                        availController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildField(
                  "Faulty Units",
                  "Count",
                  faultyController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                _buildField("Software Status", "v1.0 / OK", softwareController),
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
              setState(() {
                _resources[index]['total'] =
                    int.tryParse(totalController.text) ?? r['total'];
                _resources[index]['available'] =
                    int.tryParse(availController.text) ?? r['available'];
                _resources[index]['faulty'] =
                    int.tryParse(faultyController.text) ?? r['faulty'];
                _resources[index]['software'] = softwareController.text;

                int total = _resources[index]['total'];
                num used = total - _resources[index]['available'];
                _resources[index]['utilization'] = total > 0
                    ? '${((used / total) * 100).toInt()}%'
                    : '0%';
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: r['color'],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Save Changes",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
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
          style: const TextStyle(fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Resource Inventory",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppTheme.textMain,
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: DashboardSkeleton(),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              itemCount: _resources.length,
              itemBuilder: (context, index) {
                final r = _resources[index];

                return InkWell(
                      onTap: () => _showUpdateResourcePopup(index),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(28),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: (r['color'] as Color).withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    r['icon'],
                                    color: r['color'],
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['name'],
                                        style: AppTheme.h1.copyWith(
                                          fontSize: 20,
                                        ),
                                      ),
                                      Text(
                                        "${r['category']} Category",
                                        style: AppTheme.caption.copyWith(
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
                                      r['utilization'],
                                      style: AppTheme.h1.copyWith(
                                        color: r['color'],
                                        fontSize: 28,
                                      ),
                                    ),
                                    Text(
                                      "Utilized",
                                      style: AppTheme.caption.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMiniStat(
                                  "TOTAL UNITS",
                                  r['total'].toString(),
                                  null,
                                ),
                                _buildMiniStat(
                                  "AVAILABLE",
                                  r['available'].toString(),
                                  AppTheme.success,
                                ),
                                _buildMiniStat(
                                  "FAULTY UNITS",
                                  r['faulty'].toString(),
                                  AppTheme.danger,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Divider(color: AppTheme.surfaceColor),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.code_rounded,
                                      size: 16,
                                      color: AppTheme.textSub,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Software: ",
                                      style: AppTheme.caption.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      r['software'],
                                      style: AppTheme.caption.copyWith(
                                        color: AppTheme.textMain,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.success,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "SYSTEM OK",
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.success,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .slideY(begin: 0.1, delay: (index * 100).ms)
                    .fadeIn();
              },
            ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTheme.h1.copyWith(
            color: color ?? AppTheme.textMain,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}
