import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/skeleton_loader.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/resource_service.dart';
import '../../components/stat_card.dart';
import '../../components/section_header.dart';
import '../../components/task_card.dart';

class ResourceAvailabilityPage extends StatefulWidget {
  const ResourceAvailabilityPage({super.key});

  @override
  State<ResourceAvailabilityPage> createState() =>
      _ResourceAvailabilityPageState();
}

class _ResourceAvailabilityPageState extends State<ResourceAvailabilityPage> {
  final ResourceService _resourceService = ResourceService();
  bool _isLoading = true;
  Map<String, dynamic>? _venueData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _resourceService.getMyVenue();
      setState(() {
        _venueData = res;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching venue resources: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showManageResourceDialog(Map<String, dynamic> groupedResource) {
    final items = (groupedResource['items'] as List);
    final availableItem = items.firstWhere(
      (i) => i['status'] == 'available',
      orElse: () => {'quantity': 0},
    );
    final availableQty = availableItem['quantity'] as int;
    final totalQty = groupedResource['total_quantity'] as int;
    final damagedCount = items.firstWhere((i) => i['status'] == 'damaged', orElse: () => {'quantity': 0})['quantity'] as int;
    final brokenCount = items.firstWhere((i) => i['status'] == 'broken', orElse: () => {'quantity': 0})['quantity'] as int;
    final maintenanceCount = items.firstWhere((i) => i['status'] == 'under maintenance', orElse: () => {'quantity': 0})['quantity'] as int;
    final int currentFaultyTotal = damagedCount + brokenCount + maintenanceCount;

    final totalQtyController = TextEditingController(text: totalQty.toString());
    final faultyQtyController = TextEditingController(text: currentFaultyTotal.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.brandAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.settings_suggest_rounded, color: AppTheme.brandAccent, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Manage Inventory", style: AppTheme.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                            Text(groupedResource['name'] ?? 'Asset', 
                              style: AppTheme.h2.copyWith(fontSize: 18, color: AppTheme.textMain),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSub),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.surfaceColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  Text("STOCK COUNT", style: AppTheme.overline.copyWith(color: AppTheme.textSub)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalQtyController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Total Physical Items",
                      hintText: "Enter total count in venue",
                      prefixIcon: const Icon(Icons.inventory_rounded, size: 20),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Text("REPORT FAULTY", style: AppTheme.overline.copyWith(color: AppTheme.danger)),
                      const Spacer(),
                      Text("Max: $availableQty available", style: AppTheme.caption.copyWith(color: AppTheme.textSub)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.danger.withOpacity(0.08)),
                    ),
                    child: TextField(
                      controller: faultyQtyController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "Faulty / Damaged Items",
                        hintText: "Enter quantity to flag as faulty",
                        prefixIcon: const Icon(Icons.warning_amber_rounded, size: 20, color: AppTheme.danger),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Discard", style: TextStyle(color: AppTheme.textSub, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final newTotal = int.tryParse(totalQtyController.text);
                            final fQty = int.tryParse(faultyQtyController.text) ?? 0;

                            if (newTotal == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter a valid total quantity")),
                              );
                              return;
                            }

                            try {
                              final payload = {
                                'venue_id': _venueData!['venue_id'],
                                'name': groupedResource['name'],
                                'new_total_quantity': newTotal,
                                'faulty_report': fQty > 0
                                    ? {
                                        'quantity': fQty,
                                        'status': 'damaged',
                                      }
                                    : null,
                              };

                              await _resourceService.manageResource(payload);
                              Navigator.pop(context);
                              _fetchData();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Venue Inventory", 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.2)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppTheme.textMain,
        actions: [
          IconButton(
            onPressed: _fetchData, 
            icon: const Icon(Icons.refresh_rounded, size: 22, color: AppTheme.brandAccent)
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Padding(padding: EdgeInsets.all(24), child: DashboardSkeleton())
          : _venueData == null
              ? Center(child: Text("No venue data found", style: AppTheme.bodySub))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final groupedResources = (_venueData!['grouped_resources'] as List? ?? []);
    
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.brandAccent,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverToBoxAdapter(child: _buildVenueHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final r = groupedResources[index] as Map<String, dynamic>;
                  return _buildThemedResourceCard(r);
                },
                childCount: groupedResources.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueHeader() {
    final status = (_venueData!['current_status'] ?? 'OPEN').toString().toUpperCase();
    final bool isAvailable = status == 'OPEN' || status == 'AVAILABLE';
    final int totalCount = (_venueData!['grouped_resources'] as List? ?? []).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: "Managed Venue",
                value: _venueData!['name'] ?? 'Venue',
                icon: Icons.stadium_rounded,
                color: AppTheme.brandAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: "Current Status",
                value: status,
                icon: Icons.circle_notifications_rounded,
                color: isAvailable ? AppTheme.success : AppTheme.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          label: "Total Resource Types",
          value: totalCount.toString(),
          icon: Icons.inventory_2_rounded,
          color: AppTheme.info,
        ),
        const SizedBox(height: 32),
        const SectionHeader(title: "Deployed Inventory"),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildThemedResourceCard(Map<String, dynamic> r) {
    final items = (r['items'] as List);
    final available = items.firstWhere((i) => i['status'] == 'available', orElse: () => {'quantity': 0})['quantity'];
    final damaged = items.firstWhere((i) => i['status'] == 'damaged', orElse: () => {'quantity': 0})['quantity'];
    final broken = items.firstWhere((i) => i['status'] == 'broken', orElse: () => {'quantity': 0})['quantity'];
    final maintenance = items.firstWhere((i) => i['status'] == 'under maintenance', orElse: () => {'quantity': 0})['quantity'];

    final List<String> statusAlerts = [];
    if (damaged > 0) statusAlerts.add("$damaged Damaged");
    if (broken > 0) statusAlerts.add("$broken Broken");
    if (maintenance > 0) statusAlerts.add("$maintenance In Repair");

    final String statusInfo = statusAlerts.isNotEmpty 
        ? " • ${statusAlerts.join(", ")}" 
        : "";

    return TaskCard(
      title: r['name'] ?? 'Asset',
      sub: "Available: $available / Total: ${r['total_quantity']}$statusInfo",
      accent: statusAlerts.isNotEmpty ? AppTheme.warning : AppTheme.brandAccent,
      icon: Icons.layers_rounded,
      onTap: () => _showManageResourceDialog(r),
      heroTag: "resource_${r['name']}",
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }
}
