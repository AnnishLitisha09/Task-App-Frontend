import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/skeleton_loader.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/resource_service.dart';

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
    // Calculate current available quantity
    final items = (groupedResource['items'] as List);
    final availableItem = items.firstWhere(
      (i) => i['status'] == 'available',
      orElse: () => {'quantity': 0},
    );
    final availableQty = availableItem['quantity'] as int;
    final totalQty = groupedResource['total_quantity'] as int;

    final totalQtyController = TextEditingController(text: totalQty.toString());
    final faultyQtyController = TextEditingController(text: "0");
    final reasonController = TextEditingController();
    String faultyStatus = 'damaged';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Manage Inventory: ${groupedResource['name']}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TOTAL QUANTITY", style: AppTheme.overline),
                const SizedBox(height: 8),
                TextField(
                  controller: totalQtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Total Items in Venue",
                    hintText: "Update total count",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text("REPORT FAULTY / DAMAGED", style: AppTheme.overline.copyWith(color: AppTheme.danger)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: faultyQtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Faulty Count",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: faultyStatus,
                        items: ['damaged', 'broken', 'under maintenance']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                            .toList(),
                        onChanged: (v) => setDialogState(() => faultyStatus = v!),
                        decoration: const InputDecoration(
                          labelText: "Issue Type",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: "Reason (Optional)",
                    hintText: "What happened?",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  "Available to report: $availableQty",
                  style: AppTheme.caption.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
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
                            'status': faultyStatus,
                            'reason': reasonController.text,
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
              child: const Text("Apply Changes"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Venue Inventory", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppTheme.textMain,
        actions: [
          IconButton(
            onPressed: _fetchData, 
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.brandAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.brandAccent)
            )
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Padding(padding: EdgeInsets.all(20), child: DashboardSkeleton())
          : _venueData == null
              ? Center(child: Text("No venue data found", style: AppTheme.bodySub))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final groupedResources = (_venueData!['grouped_resources'] as List? ?? []);
    
    return RepaintBoundary(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
        itemCount: groupedResources.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) return _buildVenueHeader();
          
          final r = groupedResources[index - 1] as Map<String, dynamic>;
          return _buildGroupedResourceCard(r);
        },
      ),
    );
  }

  Widget _buildVenueHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.brandPrimary, AppTheme.brandPrimary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPrimary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.inventory_2_rounded, 
              size: 100, color: Colors.white.withOpacity(0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _venueData!['location'] ?? 'Main Campus',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppTheme.success.withOpacity(0.4), blurRadius: 10)
                      ]
                    ),
                    child: Text(
                      (_venueData!['current_status'] ?? 'OPEN').toString().toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(_venueData!['name'] ?? 'Venue', 
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text("Total Resources Monitored", 
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, curve: Curves.easeOutBack);
  }

  Widget _buildGroupedResourceCard(Map<String, dynamic> r) {
    final items = (r['items'] as List);
    final available = items.firstWhere((i) => i['status'] == 'available', orElse: () => {'quantity': 0})['quantity'];
    final damaged = items.firstWhere((i) => i['status'] == 'damaged', orElse: () => {'quantity': 0})['quantity'];
    final broken = items.firstWhere((i) => i['status'] == 'broken', orElse: () => {'quantity': 0})['quantity'];
    final maintenance = items.firstWhere((i) => i['status'] == 'under maintenance', orElse: () => {'quantity': 0})['quantity'];

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPrimary.withOpacity(0.03),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.brandAccent.withOpacity(0.2), AppTheme.brandAccent.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.layers_rounded, color: AppTheme.brandAccent),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'] ?? 'Asset', 
                          style: AppTheme.h2.copyWith(fontSize: 18, color: AppTheme.textMain)),
                        const SizedBox(height: 2),
                        Text(r['description'] ?? 'Standard resource unit', 
                          style: AppTheme.bodySub.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  _buildTotalBadge(r['total_quantity'] as int),
                ],
              ),
            ),
            
            // Bento Grid for statuses
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildBentoItem("AVAILABLE", available, AppTheme.success, Icons.check_circle_rounded),
                      const SizedBox(width: 12),
                      _buildBentoItem("DAMAGED", damaged, AppTheme.warning, Icons.warning_amber_rounded),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildBentoItem("BROKEN", broken, AppTheme.danger, Icons.cancel_rounded),
                      const SizedBox(width: 12),
                      _buildBentoItem("FIXING", maintenance, Colors.blue, Icons.build_circle_rounded),
                    ],
                  ),
                ],
              ),
            ),
            
            // Manage Button
            InkWell(
              onTap: () => _showManageResourceDialog(r),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimary.withOpacity(0.02),
                  border: Border(top: BorderSide(color: AppTheme.dividerColor.withOpacity(0.5))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.settings_suggest_rounded, size: 18, color: AppTheme.brandAccent),
                    const SizedBox(width: 8),
                    Text("MANAGE INVENTORY", 
                      style: AppTheme.bodyMain.copyWith(fontSize: 13, color: AppTheme.brandAccent, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, curve: Curves.easeOut),
    );
  }

  Widget _buildTotalBadge(int total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.brandPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.brandPrimary.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(total.toString(), 
            style: const TextStyle(color: AppTheme.brandPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
          Text("TOTAL", style: AppTheme.overline.copyWith(fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildBentoItem(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count.toString(), 
                  style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, height: 1.1)),
                Text(label, style: AppTheme.caption.copyWith(fontSize: 8, color: color.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
