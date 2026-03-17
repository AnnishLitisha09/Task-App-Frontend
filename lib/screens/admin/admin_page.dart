import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../components/section_header.dart';
import '../../services/resource_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final ResourceService _resourceService = ResourceService();
  bool _isDownloading = false;

  Future<void> _handleDownloadReport(bool isVenue) async {
    setState(() => _isDownloading = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Generating ${isVenue ? 'Venue' : 'Resource'} Report...")),
      );

      final List<int> bytes = isVenue 
          ? await _resourceService.downloadVenueReport()
          : await _resourceService.downloadResourceReport();

      String? fileName = isVenue 
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            CustomAppBar(
              title: "Admin Dashboard",
              date: formattedDate,
              notificationCount: 0,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SectionHeader(title: "System Reports"),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    title: "Venue Utilisation Report",
                    description: "View occupancy and booking trends across all venues.",
                    icon: Icons.analytics_rounded,
                    color: AppTheme.brandAccent,
                    onTap: () => _handleDownloadReport(true),
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    title: "Resource Inventory Report",
                    description: "Full breakdown of resources, statuses, and usage logs.",
                    icon: Icons.inventory_2_rounded,
                    color: AppTheme.success,
                    onTap: () => _handleDownloadReport(false),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
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
                  color: color.withOpacity(0.1),
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
                    Text(
                      description,
                      style: AppTheme.bodySub,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.file_download_rounded,
                color: AppTheme.textSub.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
