import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/section_header.dart';
import '../../services/resource_service.dart';
import 'package:provider/provider.dart';
import '../../store/app_store.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final ResourceService _resourceService = ResourceService();
  bool _isDownloading = false;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  int get _unreadNotifications => context.read<AppStore>().unreadNotifications;

  @override
  void initState() {
    super.initState();
    context.read<AppStore>().fetchUnreadNotifications();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.brandAccent,
              onPrimary: Colors.white,
              onSurface: AppTheme.textMain,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  Future<void> _handleDownloadReport(int reportType) async {
    // 0: Venue Overall, 1: Venue Usage (Timed), 2: Resource Inventory
    setState(() => _isDownloading = true);
    try {
      String label = "";
      List<int> bytes;

      if (reportType == 0) {
        label = "Overall Venue Report";
        bytes = await _resourceService.downloadVenueReport();
      } else if (reportType == 1) {
        label = "Venue Usage Report";
        final from = DateFormat('yyyy-MM-dd').format(_fromDate);
        final to = DateFormat('yyyy-MM-dd').format(_toDate);
        bytes = await _resourceService.getVenueUsageReport(from, to);
      } else {
        label = "Resource Inventory Report";
        bytes = await _resourceService.downloadResourceReport();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Generating $label...")));

      String fileName = (reportType == 0 || reportType == 1)
          ? 'admin_venue_utilisation_${DateTime.now().millisecondsSinceEpoch}.xlsx'
          : 'admin_resource_utilisation_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Admin Report:',
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
      );

      if (outputFile != null) {
        if (!Platform.isAndroid && !Platform.isIOS) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Report saved successfully!"),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, MMM dd').format(DateTime.now());

    return Consumer<AppStore>(
      builder: (context, store, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                CustomAppBar(
                  title: "Admin Dashboard",
                  date: formattedDate,
                  notificationCount: _unreadNotifications,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SectionHeader(title: "System Reports"),
                      const SizedBox(height: 16),
                      _buildReportCard(
                        title: "Venue Usage (Custom Range)",
                        description:
                            "From ${DateFormat('MMM dd, yyyy').format(_fromDate)} to ${DateFormat('MMM dd, yyyy').format(_toDate)}",
                        icon: Icons.date_range_rounded,
                        color: Colors.orange,
                        trailing: TextButton(
                          onPressed: _isDownloading ? null : _selectDateRange,
                          child: const Text(
                            "CHANGE",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () => _handleDownloadReport(1),
                      ),
                      const SizedBox(height: 16),
                      _buildReportCard(
                        title: "Venue Overall Export",
                        description:
                            "Full master list and current status of all venues.",
                        icon: Icons.analytics_rounded,
                        color: AppTheme.brandAccent,
                        onTap: () => _handleDownloadReport(0),
                      ),
                      const SizedBox(height: 16),
                      _buildReportCard(
                        title: "Resource Inventory Report",
                        description:
                            "Full breakdown of resources, statuses, and usage logs.",
                        icon: Icons.inventory_2_rounded,
                        color: AppTheme.success,
                        onTap: () => _handleDownloadReport(2),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: _isDownloading ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.bodyMain),
                    const SizedBox(height: 4),
                    Text(description, style: AppTheme.bodySub),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.file_download_rounded,
                    color: AppTheme.textSub.withAlpha(127),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
