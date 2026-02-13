import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'user_selection_page.dart';
import 'package:intl/intl.dart';

class CreateTaskPage extends StatefulWidget {
  final Map<String, dynamic>? initialData; // Add this line

  const CreateTaskPage({super.key, this.initialData}); // Update constructor

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Branding
  final Color accent = const Color(0xFF6366F1);
  final Color bodyBg = const Color(0xFFFBFBFE);

  // --- FULLY COMPLIANT STATE (Matches JSON Schema) ---
  late Map<String, dynamic> _taskData;

  @override
  void initState() {
    super.initState();

    // 1. Define your full default template
    final Map<String, dynamic> defaultData = {
      'title': '',
      'description': '',
      'category': 'Academic',
      'priority': 'Medium',
      'taskType': 'Fixed Time Task',
      'ownerId': 'Admin User',
      'assigneeIds': <String>[],
      'targetType': 'Individual',
      'locationId': 'Main Hall',
      'resources': <String>[],
      'score': 100,
      'penaltyRule': {'penaltyValue': 5},
      'completionMethods': <String>[],
      'subTasks': <Map<String, dynamic>>[],
      'requiresApproval': true,
      'approvalAuthority': null, // Changed from String to Map or null
      'isPackageTask': false,
      'allowPause': false,
      'delegationAllowed': false,
      'autoEscalation': true,
      'mandatoryDocumentation': true,
      'requiredDocuments': <String>[],
      'endDate': DateTime.now().add(const Duration(days: 7)),
      'isFaculty': false,
      'facultyInCharge': null, // NEW
      'selectedAssignees': <Map<String, dynamic>>[],
    };

    // 2. Merge incoming data into the template
    if (widget.initialData != null) {
      _taskData = {...defaultData, ...widget.initialData!};
    } else {
      _taskData = defaultData;
    }
  } // Helper for Date Picker

  Future<void> _pickDate(String key) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _taskData[key],
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _taskData[key] = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bodyBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressBar(), // Now spans the full width
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _sectionWrapper(
                  title: "Identity",
                  subtitle: "Basic details & Classification",
                  children: _buildSection1(),
                ),
                _sectionWrapper(
                  title: "Time & Venue",
                  subtitle: "Configuration & Location",
                  children: _buildSection2(),
                ),
                _sectionWrapper(
                  title: "Responsibility",
                  subtitle: "Governance & Assignees",
                  children: _buildSection3(),
                ),
                _sectionWrapper(
                  title: "Closing Rules",
                  subtitle: "Evaluation & Resources",
                  children: _buildSection4(),
                ),
              ],
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  // --- SECTION 1: IDENTITY & PACKAGE ---
  List<Widget> _buildSection1() {
    return [
      _modernField(
        label: "TASK TITLE",
        hint: "Audit Report",
        icon: Icons.title,
        onChanged: (v) => _taskData['title'] = v,
      ),
      const SizedBox(height: 24),
      _modernField(
        label: "DESCRIPTION",
        hint: "Details...",
        icon: Icons.notes,
        maxLines: 2,
        onChanged: (v) => _taskData['description'] = v,
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: _modernDropdown("CATEGORY", [
              "Academic",
              "Administrative",
              "Compliance",
            ], (v) => _taskData['category'] = v),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _modernDropdown("PRIORITY", [
              "Low",
              "Medium",
              "High",
              "Critical",
            ], (v) => setState(() => _taskData['priority'] = v)),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _modernToggle(
        "IS PACKAGE TASK",
        _taskData['isPackageTask'],
        (v) => setState(() => _taskData['isPackageTask'] = v),
      ),
      const SizedBox(height: 12),
      _modernToggle(
        "IS FACULTY NEEDED?",
        _taskData['isFaculty'],
        (v) => setState(() => _taskData['isFaculty'] = v),
      ),
    ];
  }

  // --- SECTION 2: TIME, VENUE & PAUSE ---
  List<Widget> _buildSection2() {
    return [
      _modernDropdown("TASK TYPE", [
        "Fixed Time Task",
        "Long Task",
        "Recurring Task",
        "Bidding Task",
      ], (v) => setState(() => _taskData['taskType'] = v)),
      const SizedBox(height: 24),
      _modernDropdown("VENUE / LOCATION", [
        "Main Hall",
        "Lab 101",
        "Conference Room",
        "Remote",
      ], (v) => _taskData['locationId'] = v),
      const SizedBox(height: 32),
      Text(
        "TIME CONFIGURATION",
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
      const Divider(height: 32),
      if (_taskData['taskType'] == "Fixed Time Task") ...[
        _dateTile("SELECT DATE", 'selectedDate'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _modernField(
                label: "START TIME",
                hint: "09:00 AM",
                icon: Icons.access_time,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _modernField(
                label: "END TIME",
                hint: "05:00 PM",
                icon: Icons.access_time_filled,
              ),
            ),
          ],
        ),
      ] else ...[
        _dateTile("VALID FROM", 'startDate'),
        const SizedBox(height: 16),
        _dateTile("VALID UNTIL", 'endDate'),
      ],
      const SizedBox(height: 24),
      _modernToggle(
        "ALLOW PAUSE",
        _taskData['allowPause'],
        (v) => setState(() => _taskData['allowPause'] = v),
      ),
    ];
  }

  // --- SECTION 3: RESPONSIBILITY & APPROVAL ---
  List<Widget> _buildSection3() {
    if (!_taskData['isPackageTask']) {
      // Standard Single Task view
      return [
        _assigneeSection(),
        if (_taskData['isFaculty']) ...[
          const SizedBox(height: 16),
          _facultyInChargePicker(),
        ],
        const SizedBox(height: 16),
        _modernToggle(
          "REQUIRES APPROVAL",
          _taskData['requiresApproval'],
          (v) => setState(() => _taskData['requiresApproval'] = v),
        ),
        if (_taskData['requiresApproval']) _authorityPicker(),
      ];
    }

    // PACKAGE TASK VIEW: Sequential List
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "WORKFLOW SEQUENCE",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
          TextButton.icon(
            onPressed: _addSubTask,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add Step"),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ...(_taskData['subTasks'] as List).asMap().entries.map((entry) {
        int idx = entry.key;
        var sub = entry.value;
        return _buildSubTaskCard(idx, sub);
      }),
      if ((_taskData['subTasks'] as List).isEmpty)
        _emptyState("No steps added. Click 'Add Step' to begin the sequence."),
    ];
  }

  // --- SECTION 4: EVALUATION & RESOURCES ---
  List<Widget> _buildSection4() {
    return [
      Row(
        children: [
          Expanded(
            child: _modernField(
              label: "SCORE",
              hint: "100",
              icon: Icons.star,
              isNumber: true,
              onChanged: (v) => _taskData['score'] = int.tryParse(v) ?? 0,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _modernField(
              label: "PENALTY",
              hint: "5",
              icon: Icons.money_off,
              isNumber: true,
              onChanged: (v) => _taskData['penaltyRule']['penaltyValue'] =
                  int.tryParse(v) ?? 0,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text(
        "COMPLETION METHODS",
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      _multiSelectChips([
        "OTP Verify",
        "Photo Upload",
        "QR Scan",
        "Doc Upload",
      ], 'completionMethods'),
      const SizedBox(height: 24),
      Text(
        "REQUIRED RESOURCES",
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      _multiSelectChips([
        "Laptop",
        "Projector",
        "Vehicle",
        "Software",
      ], 'resources'),
      const SizedBox(height: 24),
      _modernToggle(
        "AUTO ESCALATION",
        _taskData['autoEscalation'],
        (v) => setState(() => _taskData['autoEscalation'] = v),
      ),
      _modernToggle(
        "MANDATORY DOCUMENTATION",
        _taskData['mandatoryDocumentation'],
        (v) => setState(() => _taskData['mandatoryDocumentation'] = v),
      ),
      _modernToggle(
        "ALLOW DELEGATION",
        _taskData['delegationAllowed'],
        (v) => setState(() => _taskData['delegationAllowed'] = v),
      ),
    ];
  }

  // --- UI COMPONENTS ---

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Bottom Track Line (The background grey line)
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(
                  horizontal: 5,
                ), // Half the dot width
                color: Colors.grey[200],
              ),

              // The actual dots and active lines
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return Row(
                    children: [
                      // The Indicator Dot
                      AnimatedContainer(
                        duration: 300.ms,
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          color: _currentStep >= index ? accent : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentStep >= index
                                ? accent
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: _currentStep == index
                              ? [
                                  BoxShadow(
                                    color: accent.withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ],
                  );
                }),
              ),

              // The Active Progress Line (Green/Accent overlay)
              // This sits between the background line and the dots
              Positioned(
                left: 6, // Radius of the dot
                right: 6,
                child: Row(
                  children: [
                    Expanded(
                      flex: _currentStep,
                      child: AnimatedContainer(
                        duration: 300.ms,
                        height: 2,
                        color: accent,
                      ),
                    ),
                    Expanded(flex: 3 - _currentStep, child: const SizedBox()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _dateTile(String label, String dataKey) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.black54,
        ),
      ),
      const SizedBox(height: 8),
      ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        leading: Icon(Icons.calendar_month, color: accent),
        title: Text(DateFormat('yyyy-MM-dd').format(_taskData[dataKey])),
        trailing: const Icon(Icons.edit, size: 18),
        onTap: () => _pickDate(dataKey),
      ),
    ],
  );

  Widget _assigneeSection() {
    final List assignees = _taskData['selectedAssignees'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ASSIGNEES",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final List<Map<String, dynamic>>? result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserSelectionPage(
                  initialSelection: List<Map<String, dynamic>>.from(
                    _taskData['selectedAssignees'],
                  ),
                ),
              ),
            );

            if (result != null) {
              setState(() {
                _taskData['selectedAssignees'] = result;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assignees.isEmpty
                        ? "Select Users, Roles or Depts"
                        : "${assignees.length} assigned",
                    style: TextStyle(
                      color: assignees.isEmpty ? Colors.grey : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (assignees.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: assignees.map<Widget>((item) {
              Color chipColor = accent;
              if (item['type'] == 'role') chipColor = Colors.orange;
              if (item['type'] == 'dept') chipColor = Colors.teal;

              return Chip(
                label: Text(
                  item['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onDeleted: () {
                  setState(() {
                    _taskData['selectedAssignees'].remove(item);
                  });
                },
                backgroundColor: chipColor.withOpacity(0.1),
                deleteIconColor: chipColor,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _authorityPicker() {
    final Map<String, dynamic>? authority = _taskData['approvalAuthority'];
    return _userPickerTile(
      label: "APPROVAL AUTHORITY",
      subtitle: authority != null
          ? authority['name']
          : "Select Higher Authority",
      icon: Icons.verified_user,
      onTap: () async {
        final List<Map<String, dynamic>>? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserSelectionPage(
              initialSelection: authority != null ? [authority] : [],
              multiSelect: false,
            ),
          ),
        );

        if (result != null && result.isNotEmpty) {
          setState(() {
            _taskData['approvalAuthority'] = result.first;
          });
        }
      },
    );
  }

  Widget _facultyInChargePicker() {
    final Map<String, dynamic>? faculty = _taskData['facultyInCharge'];
    return _userPickerTile(
      label: "FACULTY IN-CHARGE",
      subtitle: faculty != null
          ? faculty['name']
          : "Select Responsible Faculty",
      icon: Icons.person_search_rounded,
      onTap: () async {
        final List<Map<String, dynamic>>? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserSelectionPage(
              initialSelection: faculty != null ? [faculty] : [],
              multiSelect: false,
              fixedRole: "Faculty",
            ),
          ),
        );

        if (result != null && result.isNotEmpty) {
          setState(() {
            _taskData['facultyInCharge'] = result.first;
          });
        }
      },
    );
  }

  Widget _modernField({
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          onChanged: onChanged,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: accent, size: 18)
                : null,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modernDropdown(
    String label,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.first,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modernToggle(String label, bool val, Function(bool) onChanged) =>
      SwitchListTile.adaptive(
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        value: val,
        onChanged: onChanged,
        activeColor: accent,
        contentPadding: EdgeInsets.zero,
      );

  Widget _multiSelectChips(List<String> options, String stateKey) => Wrap(
    spacing: 8,
    children: options.map((e) {
      final isSelected = (_taskData[stateKey] as List).contains(e);
      return FilterChip(
        label: Text(
          e,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) => setState(
          () => selected
              ? _taskData[stateKey].add(e)
              : _taskData[stateKey].remove(e),
        ),
        selectedColor: accent,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
    }).toList(),
  );

  Widget _userPickerTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accent.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.add_circle_outline, color: Colors.grey, size: 20),
        ],
      ),
    ),
  );

  // --- NAVIGATION SCAFFOLDING ---

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: bodyBg,
    elevation: 0,
    centerTitle: true,
    title: const Text(
      "Create Directive",
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
        fontSize: 16,
      ),
    ),
    leading: const BackButton(color: Colors.black),
  );

  Widget _sectionWrapper({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 32),
        ...children,
      ],
    ),
  );

  Widget _buildBottomNavigation() => Container(
    padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: () => _moveStep(-1),
            child: const Text(
              "Back",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          )
        else
          const SizedBox(),
        ElevatedButton(
          onPressed: () =>
              _currentStep < 3 ? _moveStep(1) : _finishTaskCreation(),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            _currentStep == 3 ? "Complete" : "Continue",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  void _moveStep(int delta) {
    setState(() {
      _currentStep += delta;
      _pageController.animateToPage(
        _currentStep,
        duration: 400.ms,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _finishTaskCreation() {
    // Success Logic Here
  }

  void _addSubTask() {
    setState(() {
      (_taskData['subTasks'] as List).add({
        'title': '',
        'assigneeId': 'Select Assignee',
        'order': (_taskData['subTasks'] as List).length + 1,
      });
    });
  }

  Widget _buildSubTaskCard(int index, Map<String, dynamic> subTask) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: accent,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Step Title",
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => subTask['title'] = v,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => (_taskData['subTasks'] as List).removeAt(index),
                ),
              ),
            ],
          ),
          const Divider(),
          _userPickerTile(
            label: "ASSIGNEE FOR STEP ${index + 1}",
            subtitle: subTask['assigneeId'] ?? "Select Assignee",
            icon: Icons.person_add_alt_1,
            onTap: () async {
              final List<Map<String, dynamic>>? result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const UserSelectionPage(multiSelect: false),
                ),
              );

              if (result != null && result.isNotEmpty) {
                setState(() {
                  subTask['assigneeId'] = result.first['name'];
                });
              }
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1);
  }

  Widget _emptyState(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.none),
    ),
    child: Text(
      msg,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    ),
  );
}
