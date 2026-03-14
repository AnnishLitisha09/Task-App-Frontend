import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'create_task_page.dart';
import 'task_creation_view_page.dart';
import 'self_log_detail_page.dart';
import '../../services/task_service.dart';
import 'package:intl/intl.dart';

class TaskManagementPage extends StatefulWidget {
  const TaskManagementPage({super.key});

  @override
  State<TaskManagementPage> createState() => _TaskManagementPageState();
}

class _TaskManagementPageState extends State<TaskManagementPage>
    with SingleTickerProviderStateMixin {
  final Color brandPrimary = const Color(0xFF6366F1);
  final Color bgSlate = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF0F172A);
  final Color textLight = const Color(0xFF64748B);
  late TabController _tabController;
  String _directiveSearchQuery = '';
  String _selfLogSearchQuery = '';

  List<Map<String, dynamic>> _directiveTasks = [];
  List<Map<String, dynamic>> _selfLogs = [];
  int _totalCount = 0;
  int _directiveCount = 0;
  int _selfLogCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDailyReport();
  }

  Future<void> _fetchDailyReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final taskService = TaskService();
      final report = await taskService.getDailyReport();

      if (mounted) {
        setState(() {
          _directiveTasks = report.directiveTasks
              .map(
                (t) => {
                  'task_id': t.taskId,
                  'title': t.title,
                  'category': t.category,
                  'taskType': t.originType,
                  'locationId': t.venue ?? 'N/A',
                  'priority': t.priority,
                  'completionMethods': t.closureMethods,
                  'selectedDate': t.time.startDate.isNotEmpty
                      ? DateTime.parse(t.time.startDate)
                      : DateTime.now(),
                  'description': t.description,
                  'status': t.status,
                },
              )
              .toList();

          _selfLogs = report.selfLogTasks
              .map(
                (t) => {
                  'task_id': t.taskId,
                  'title': t.title,
                  'description': t.description,
                  'startTime': t.time.startTime,
                  'endTime': t.time.endTime,
                  'duration': _calculateDuration(
                    t.time.startTime,
                    t.time.endTime,
                  ),
                  'date': DateFormat(
                    'MMM dd, yyyy',
                  ).format(DateTime.parse(t.time.startDate)),
                },
              )
              .toList();

          _directiveCount = report.directiveTaskCount;
          _selfLogCount = report.selfLogCount;
          _totalCount = report.totalTask;

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  double _calculateDuration(String start, String end) {
    try {
      final startTime = DateFormat("HH:mm:ss").parse(start);
      final endTime = DateFormat("HH:mm:ss").parse(end);
      return endTime.difference(startTime).inMinutes / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredDirectives {
    if (_directiveSearchQuery.isEmpty) return _directiveTasks;
    return _directiveTasks.where((task) {
      final title = task['title'].toString().toLowerCase();
      final query = _directiveSearchQuery.toLowerCase();
      return title.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_selfLogSearchQuery.isEmpty) return _selfLogs;
    return _selfLogs.where((log) {
      final title = log['title'].toString().toLowerCase();
      final description = log['description'].toString().toLowerCase();
      final query = _selfLogSearchQuery.toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      body: Stack(
        children: [
          // Decorative background blur for elegance
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandPrimary.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 70, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_buildGreeting(), _buildCreateButton()],
                    ),
                    const SizedBox(height: 32),
                    _buildLightStatsRow(),
                  ],
                ),
              ),
              // Tab Bar
              _buildTabBar(),
              // Tab Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchDailyReport,
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDirectiveTasksTab(),
                          _buildSelfLogsTab(),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: textDark.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [brandPrimary, brandPrimary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: brandPrimary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: textLight,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 18),
                SizedBox(width: 8),
                Text('Directive Tasks'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 18),
                SizedBox(width: 8),
                Text('My Self-Logs'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectiveTasksTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // SEARCH & FILTER BAR
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: _buildSearchBar(),
          ),
        ),
        // TASK LIST
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          sliver: _filteredDirectives.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: textLight.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No directives found',
                          style: TextStyle(fontSize: 16, color: textLight),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildElegantTaskCard(
                      _filteredDirectives[index],
                      index,
                    ),
                    childCount: _filteredDirectives.length,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSelfLogsTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: textDark.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _selfLogSearchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search self-logs...',
                hintStyle: TextStyle(color: textLight.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: brandPrimary),
                suffixIcon: _selfLogSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textLight),
                        onPressed: () =>
                            setState(() => _selfLogSearchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        // Self-logs list
        Expanded(
          child: _filteredLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: textLight.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selfLogSearchQuery.isEmpty
                            ? 'No self logs recorded yet'
                            : 'No logs match your search',
                        style: TextStyle(fontSize: 16, color: textLight),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredLogs[index];
                    return _buildSelfLogCard(log, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSelfLogCard(Map<String, dynamic> log, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelfLogDetailPage(log: log),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP ROW: Category & Duration
                  Row(
                    children: [
                      _badge("Self Log", Colors.blueGrey),
                      const Spacer(),
                      _badge(
                        '${(log['duration'] as num).toStringAsFixed(2)}h',
                        brandPrimary,
                      ),
                      const SizedBox(width: 8),
                      _buildLogMenu(log),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. TITLE & DATE
                  Text(
                    log['title'],
                    style: TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log['date'],
                        style: TextStyle(
                          color: textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: textLight),
                      const SizedBox(width: 4),
                      Text(
                        '${log['startTime']} - ${log['endTime']}',
                        style: TextStyle(
                          color: textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Directives",
          style: TextStyle(
            color: textDark,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Manage your academic workflows",
          style: TextStyle(
            color: textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2);
  }

  Widget _buildCreateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: brandPrimary,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTaskPage()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.easeOut);
  }

  Widget _buildLightStatsRow() {
    return Row(
      children: [
        _statChip(
          _totalCount.toString().padLeft(2, '0'),
          "Total",
          brandPrimary,
        ),
        const SizedBox(width: 12),
        _statChip(
          _directiveCount.toString().padLeft(2, '0'),
          "Directives",
          const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 12),
        _statChip(
          _selfLogCount.toString().padLeft(2, '0'),
          "Self-Logs",
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: textDark.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: textLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: textDark.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: textLight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _directiveSearchQuery = v),
              decoration: InputDecoration(
                hintText: "Search directives...",
                hintStyle: TextStyle(
                  color: textLight.withOpacity(0.5),
                  fontSize: 15,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          _actionCircle(Icons.tune_rounded), // Filter icon
        ],
      ),
    );
  }

  // ... existing imports

  Widget _buildElegantTaskCard(Map<String, dynamic> taskData, int index) {
    // Extracting dynamic data from the passed taskData
    final String taskTitle = taskData['title'] ?? "Untitled Directive";
    final String taskType = taskData['taskType'] ?? "Standard Task";
    final String priority = taskData['priority'] ?? "Medium";
    final String venue = taskData['locationId'] ?? "Unknown Venue";
    final List<String> methods = List<String>.from(
      taskData['completionMethods'] ?? [],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        // Ensures the splash effect stays inside the rounded corners
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              // CALLING THE VIEW PAGE HERE
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskViewPage(taskData: taskData),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP ROW: Category, Priority + THE NEW MENU
                  Row(
                    children: [
                      _badge(
                        taskData['category']?.toString() ?? "General",
                        brandPrimary,
                      ),
                      const SizedBox(width: 12),
                      _priorityIndicator(priority),
                      const Spacer(),
                      _buildCardMenu(index: index, taskData: taskData),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. TITLE & VENUE
                  Text(
                    taskTitle,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        venue,
                        style: TextStyle(
                          color: textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.layers_outlined, size: 14, color: textLight),
                      const SizedBox(width: 4),
                      Text(
                        taskType,
                        style: TextStyle(
                          color: textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // 3. BOTTOM ROW: Closing Methods & Due Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: methods.map((m) => _methodIcon(m)).toList(),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "DUE DATE",
                            style: TextStyle(
                              color: textLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(
                              (taskData['selectedDate'] as DateTime?) ??
                                  DateTime.now(),
                            ),
                            style: TextStyle(
                              color: textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }

  // --- MENU HELPER ---
  Widget _buildCardMenu({
    required int index,
    required Map<String, dynamic> taskData,
  }) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, color: textLight, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (value) {
        if (value == 'edit') {
          final Map<String, dynamic> dataToEdit = {
            ...taskData,
            'locationId': taskData['locationId'],
            'completionMethods': taskData['completionMethods'],
          };

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTaskPage(initialData: dataToEdit),
            ),
          );
        } else if (value == 'delete') {
          _showDeleteDialog(index);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: textDark, size: 20),
              const SizedBox(width: 12),
              const Text("Edit Directive"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  } // --- DELETE CONFIRMATION ---

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          "Delete Directive?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This action cannot be undone. All associated progress and documentation will be removed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              // Logic to remove from list
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  // --- NEW ATOMIC COMPONENTS FOR THE CARD ---

  Widget _priorityIndicator(String priority) {
    Color pColor;
    switch (priority) {
      case 'Critical':
        pColor = Colors.redAccent;
        break;
      case 'High':
        pColor = Colors.orangeAccent;
        break;
      case 'Low':
        pColor = Colors.blueAccent;
        break;
      default:
        pColor = Colors.greenAccent;
    }
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          priority.toUpperCase(),
          style: TextStyle(
            color: textDark,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _methodIcon(String method) {
    IconData icon;
    switch (method) {
      case 'QR Scan':
        icon = Icons.qr_code_scanner;
        break;
      case 'Photo':
        icon = Icons.camera_alt_outlined;
        break;
      case 'Doc Upload':
        icon = Icons.upload_file;
        break;
      default:
        icon = Icons.verified_outlined;
    }
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgSlate,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 16, color: brandPrimary),
    );
  }

  Widget _buildLogMenu(Map<String, dynamic> log) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, color: textLight, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTaskPage(
                initialData: {...log, 'taskCategory': 'Self Log'},
              ),
            ),
          );
        } else if (value == 'delete') {
          _showLogDeleteDialog(log);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: textDark),
              const SizedBox(width: 12),
              const Text("Edit Log"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              const Text("Delete", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogDeleteDialog(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Delete Activity?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          "This will permanently remove your activity log. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: textLight, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Mock delete
              setState(() {
                _selfLogs.remove(log);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Activity log deleted")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Delete",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _actionCircle(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgSlate,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: textDark),
    );
  }
}
