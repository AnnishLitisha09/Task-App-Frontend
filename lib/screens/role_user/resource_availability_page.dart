import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/skeleton_loader.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/resource_service.dart';
import '../../components/stat_card.dart';
import '../../services/venue_notifier.dart';
import '../../components/section_header.dart';

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
    VenueNotifier.venueNotifier.addListener(_fetchData);
  }

  @override
  void dispose() {
    VenueNotifier.venueNotifier.removeListener(_fetchData);
    super.dispose();
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
                        labelText: "Total Faulty Items",
                        hintText: "Enter total number of faulty items",
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
                            final int finalFaultyQty = int.tryParse(faultyQtyController.text) ?? 0;

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
                                'faulty_report': {
                                        'quantity': finalFaultyQty,
                                        'status': 'damaged',
                                      },
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
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.2)),
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
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 160,
              ),
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
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: "Status",
                value: status,
                icon: Icons.circle_notifications_rounded,
                color: isAvailable ? AppTheme.success : AppTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: "Resource Types",
                value: totalCount.toString(),
                icon: Icons.inventory_2_rounded,
                color: AppTheme.info,
              ),
            ),
          ],
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

    final int faultyCount = damaged + broken + maintenance;

    return InkWell(
      onTap: () => _showManageResourceDialog(r),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.surfaceColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandAccent.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (faultyCount > 0 ? AppTheme.warning : AppTheme.brandAccent).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: faultyCount > 0 ? AppTheme.warning : AppTheme.brandAccent,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              r['name'] ?? 'Asset',
              style: const TextStyle(
                color: AppTheme.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "Total: ${r['total_quantity']}",
              style: TextStyle(
                color: AppTheme.textSub.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildCountBadge(available.toString(), AppTheme.success),
                if (faultyCount > 0)
                  _buildCountBadge(faultyCount.toString(), AppTheme.danger),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildCountBadge(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
