import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'user_selection_page.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';
import '../../services/resource_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/user_service.dart';

class CreateTaskPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const CreateTaskPage({super.key, this.initialData});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  // Branding
  final Color accent = const Color(0xFF6366F1);
  final Color bodyBg = const Color(0xFFFBFBFE);

  // Services
  final ResourceService _resourceService = ResourceService();
  final UserService _userService = UserService();
  final TaskService _taskService = TaskService();

  // --- FULLY COMPLIANT STATE ---
  late Map<String, dynamic> _taskData;
  List<Map<String, dynamic>> _venues = [];
  List<dynamic> _taskTitles = [];
  bool _isLoadingVenues = false;
  bool _isLoadingTitles = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _fetchVenues();
    _fetchTaskTitles();

    // 1. Define your full default template
    final Map<String, dynamic> defaultData = {
      'taskCategory': 'Directive Task',
      'title': '',
      'task_title_id': null,
      'description': '',
      'category': 'Academic',
      'priority': 'Medium',
      'taskType': 'Fixed Time Task',
      'scope': 'Departmental',
      'institutionalApproval': false,
      'ownerId': 'Admin User',
      'assigneeIds': <String>[],
      'targetType': 'Individual',
      'locationId': 'None',
      'venue_id': null,
      'recurrenceType': 'Daily',
      'resources': <String>[],
      'score': 100,
      'penaltyRule': {'penaltyValue': 5},
      'completionMethods': <String>[],
      'subTasks': <Map<String, dynamic>>[],
      'requiresApproval': true,
      'approvalAuthority': null, // Changed from String to Map or null
      'isPackageTask': false,
      'maxHours': 0.0,
      'allowPause': false,
      'delegationAllowed': false,
      'autoEscalation': true,
      'mandatoryDocumentation': false,
      'requiredDocuments': <String>[],
      'endDate': DateTime.now().add(const Duration(days: 7)),
      'selectedDate': DateTime.now(), // NEW: Initialize for Fixed Time Task
      'startDate': DateTime.now(), // NEW: Initialize for other task types
      'isFaculty': false,
      'facultyInCharge': null, // NEW
      'selectedAssignees': <Map<String, dynamic>>[],
      // Self Log specific fields
      'activityDate': DateTime.now(),
      'startTime': const TimeOfDay(hour: 8, minute: 30),
      'endTime': const TimeOfDay(hour: 10, minute: 30),
      'calculatedHours': 2.0,
      'activityTags': <String>[],
      'attachDocuments': false,
      'selectedDocuments': <String>[],
      'is_document': true,
      'closure_ids': [1],
      // Bidding task specific
      'maxAcceptances': 3,
    };

    // 1. Start with template defaults
    final Map<String, dynamic> data = {...defaultData};

    // 2. Merge incoming data
    if (widget.initialData != null) {
      data.addAll(widget.initialData!);

      // 3. Normalize Task Category (Heuristic)
      if (data['taskCategory'] == null) {
        if (data['duration'] != null || data['activityDate'] != null) {
          data['taskCategory'] = 'Self Log';
        } else {
          data['taskCategory'] = 'Directive Task';
        }
      }

      // 4. Transform Keys (e.g. 'date' -> 'activityDate')
      if (data['taskCategory'] == 'Self Log') {
        if (data['date'] != null && data['activityDate'] == null) {
          data['activityDate'] = data['date'];
        }
        if (data['tags'] != null && data['activityTags'] == null) {
          data['activityTags'] = List<String>.from(data['tags']);
        }
        if (data['duration'] != null && data['calculatedHours'] == null) {
          final dur = data['duration'];
          if (dur is num) {
            data['calculatedHours'] = dur.toDouble();
          } else if (dur is String) {
            data['calculatedHours'] =
                double.tryParse(dur.replaceAll('h', '')) ?? 0.0;
          }
        }
      }

      // 5. Robust Type Casting/Parsing
      final List<String> keys = data.keys.toList();
      for (var key in keys) {
        final val = data[key];
        if (val == null) continue;

        // Date Parsing
        if ([
          'activityDate',
          'selectedDate',
          'startDate',
          'endDate',
        ].contains(key)) {
          if (val is String) {
            data[key] = _parseDateString(val);
          }
        }
        // Time Parsing
        else if (key.toLowerCase().contains('time')) {
          if (val is String) {
            data[key] = _parseTimeString(val);
          }
        }
      }
    }
    _taskData = data;
  }

  Future<void> _fetchVenues() async {
    setState(() => _isLoadingVenues = true);
    try {
      final venues = await _resourceService.getVenues();
      setState(() {
        _venues = venues;
        _isLoadingVenues = false;
        // Default stays 'None' — only set a venue if user explicitly picks one
      });
    } catch (e) {
      setState(() => _isLoadingVenues = false);
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final profile = await _userService.getUserProfile();
      setState(() {
        _userRole = profile.role;
      });
    } catch (e) {
      // Fallback
    }
  }

  Future<void> _fetchTaskTitles() async {
    setState(() => _isLoadingTitles = true);
    try {
      final titles = await _taskService.getTaskTitles();

      // Filter titles according to target_role
      final String userRoleLower = _userRole?.toLowerCase() ?? '';
      final filteredTitles = titles.where((t) {
        final targetRole =
            (t['target_role'] as String?)?.toLowerCase() ?? 'all';
        return targetRole == 'all' || targetRole == userRoleLower;
      }).toList();

      setState(() {
        _taskTitles = filteredTitles;
        _isLoadingTitles = false;
        // Auto-select first item if current title is empty
        if (_taskTitles.isNotEmpty &&
            (_taskData['title'] == null || _taskData['title'].isEmpty)) {
          final first = _taskTitles.first;
          _taskData['title'] = first['task_title'];
          _taskData['task_title_id'] = first['id'];
        }
      });
    } catch (e) {
      setState(() => _isLoadingTitles = false);
    }
  }

  DateTime _parseDateString(String dateStr) {
    try {
      // Handle "Feb 16, 2026" or similar common formats
      return DateFormat.yMMMd().parse(dateStr);
    } catch (e) {
      return DateTime.tryParse(dateStr) ?? DateTime.now();
    }
  }

  TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      // 1. Try AM/PM format (9:00 AM)
      final format = DateFormat.jm();
      final dt = format.parse(timeStr);
      return TimeOfDay.fromDateTime(dt);
    } catch (e) {
      try {
        // 2. Try HH:mm format (09:00)
        final format = DateFormat("HH:mm");
        final dt = format.parse(timeStr);
        return TimeOfDay.fromDateTime(dt);
      } catch (e2) {
        try {
          // 3. Try DateTime string (2026-02-16 09:00:00)
          final dt = DateTime.tryParse(timeStr);
          if (dt != null) return TimeOfDay.fromDateTime(dt);
          return null;
        } catch (e3) {
          return null;
        }
      }
    }
  }
  // Helper for Date Picker

  Future<void> _pickDate(String key) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _taskData[key],
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _taskData[key] = picked;
        if (_taskData['isPackageTask']) {
          _updatePackageMaxHours();
        }
      });
    }
  }

  void _updatePackageMaxHours() {
    double hours = 0.0;

    if (_taskData['taskType'] == 'Fixed Time Task') {
      final st = _taskData['startTime'] as TimeOfDay?;
      final et = _taskData['endTime'] as TimeOfDay?;
      if (st != null && et != null) {
        int m = (et.hour * 60 + et.minute) - (st.hour * 60 + st.minute);
        hours = m / 60.0;
      } else {
        hours = 8.0; // Default work day
      }
    } else {
      final start = _taskData['startDate'] as DateTime? ?? DateTime.now();
      final end = _taskData['endDate'] as DateTime? ?? DateTime.now();
      
      if (end.isBefore(start)) {
        hours = 0.0;
      } else {
        // Calculate inclusive working days
        int days = end.difference(start).inDays + 1;
        hours = days * 8.0; // Assume 8 hours per working day (8:30 - 16:30)
      }
    }

    setState(() {
      _taskData['maxHours'] = hours;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelfLog = _taskData['taskCategory'] == 'Self Log';
    return Scaffold(
      backgroundColor: bodyBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                children: [
                  _buildWorkingHoursBanner(),
                  _sectionWrapper(
                    title: isSelfLog ? "Activity Log" : "Identity",
                    subtitle: isSelfLog
                        ? "Record your personal achievements"
                        : "Basic details & Classification",
                    children: _buildSection1(),
                  ),
                  if (!isSelfLog) ...[
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
                ],
              ),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  // --- SECTION 1: IDENTITY & PACKAGE ---
  List<Widget> _buildSection1() {
    final bool isSelfLog = _taskData['taskCategory'] == 'Self Log';

    return [
      AbsorbPointer(
        absorbing: _userRole?.toLowerCase() == 'student',
        child: Opacity(
          opacity: _userRole?.toLowerCase() == 'student' ? 0.6 : 1.0,
          child: _modernDropdown(
            "TASK CATEGORY",
            ["Directive Task", "Self Log"],
            _taskData['taskCategory'],
            (v) => setState(() {
              _taskData['taskCategory'] = v;
            }),
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (_isLoadingTitles)
        const Center(child: CircularProgressIndicator())
      else
        _searchableDropdown(
          label: isSelfLog ? "ACTIVITY TITLE" : "TASK TITLE",
          items: _taskTitles.map((t) => t['task_title'].toString()).toList(),
          value: _taskData['title'],
          onChanged: (v) {
            final selectedTitle = _taskTitles.firstWhere(
              (t) => t['task_title'] == v,
              orElse: () => null,
            );
            setState(() {
              _taskData['title'] = v;
              if (selectedTitle != null) {
                _taskData['task_title_id'] = selectedTitle['id'];
              }
            });
          },
        ),
      const SizedBox(height: 14),
      _modernField(
        label: "DESCRIPTION",
        hint: "Details...",
        icon: Icons.notes,
        maxLines: isSelfLog ? 4 : 2,
        initialValue: _taskData['description'],
        onChanged: (v) => _taskData['description'] = v,
      ),
      const SizedBox(height: 14),
      if (isSelfLog) ...[
        _dateTile("ACTIVITY DATE", 'activityDate'),
        const SizedBox(height: 14),
        Text(
          "TIME DURATION",
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _timePicker(
                label: "START TIME",
                time: _taskData['startTime'],
                onTimePicked: (time) {
                  setState(() {
                    _taskData['startTime'] = time;
                    _calculateHours();
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _timePicker(
                label: "END TIME",
                time: _taskData['endTime'],
                onTimePicked: (time) {
                  setState(() {
                    _taskData['endTime'] = time;
                    _calculateHours();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _durationIndicator(),
        const SizedBox(height: 14),
        _modernToggle(
          "ATTACH PROOF/DOCUMENTATION",
          _taskData['attachDocuments'],
          (v) => setState(() => _taskData['attachDocuments'] = v),
        ),
        if (_taskData['attachDocuments']) ...[
          const SizedBox(height: 16),
          _documentAttachmentSection(),
        ],
      ] else ...[
        _modernDropdown(
          "PRIORITY",
          ["Low", "Medium", "High", "Critical"],
          _taskData['priority'],
          (v) => setState(() => _taskData['priority'] = v),
        ),
        const SizedBox(height: 16),
        _modernToggle(
          "IS PACKAGE TASK",
          _taskData['isPackageTask'] ?? false,
          (v) => setState(() {
            _taskData['isPackageTask'] = v;
            if (v) _updatePackageMaxHours();
          }),
        ),
      ],
    ];
  }

  Widget _durationIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: accent, size: 20),
          const SizedBox(width: 12),
          Text(
            "Duration: ${_taskData['calculatedHours'].toStringAsFixed(1)} hours",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: accent,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 2: TIME, VENUE & PAUSE ---
  List<Widget> _buildSection2() {
    final List<String> venueOptions = [
      'None',
      ..._venues.map((v) => v['name'].toString()),
    ];

    return [
      _modernDropdown(
        "TASK TYPE",
        ["Fixed Time Task", "Long Task", "Recurring Task", "Bidding Task"],
        _taskData['taskType'],
        (v) => setState(() {
          _taskData['taskType'] = v;
          if (_taskData['isPackageTask']) _updatePackageMaxHours();
        }),
      ),
      const SizedBox(height: 24),
      _modernDropdown(
        "VENUE / LOCATION",
        venueOptions,
        _taskData['locationId'],
        (v) {
          setState(() {
            _taskData['locationId'] = v;
            if (v == 'None') {
              _taskData['venue_id'] = null;
            } else {
              final selectedVenue = _venues.firstWhere(
                (venue) => venue['name'] == v,
                orElse: () => {},
              );
              _taskData['venue_id'] = selectedVenue['venue_id'];
            }
          });
        },
      ),
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
              child: _timePicker(
                label: "START TIME",
                time: _taskData['startTime'],
                onTimePicked: (v) => setState(() {
                  _taskData['startTime'] = v;
                  if (_taskData['isPackageTask']) _updatePackageMaxHours();
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _timePicker(
                label: "END TIME",
                time: _taskData['endTime'],
                onTimePicked: (v) => setState(() {
                  _taskData['endTime'] = v;
                  if (_taskData['isPackageTask']) _updatePackageMaxHours();
                }),
              ),
            ),
          ],
        ),
      ] else if (_taskData['taskType'] == "Recurring Task") ...[
        _modernDropdown(
          "RECURRENCE",
          ["Daily", "Weekly", "Monthly"],
          _taskData['recurrenceType'],
          (v) => setState(() => _taskData['recurrenceType'] = v),
        ),
        const SizedBox(height: 16),
        _dateTile("VALID FROM", 'startDate'),
        const SizedBox(height: 16),
        _dateTile("VALID UNTIL", 'endDate'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _timePicker(
                label: "START TIME",
                time: _taskData['startTime'],
                onTimePicked: (v) => setState(() {
                  _taskData['startTime'] = v;
                  if (_taskData['isPackageTask']) _updatePackageMaxHours();
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _timePicker(
                label: "END TIME",
                time: _taskData['endTime'],
                onTimePicked: (v) => setState(() {
                  _taskData['endTime'] = v;
                  if (_taskData['isPackageTask']) _updatePackageMaxHours();
                }),
              ),
            ),
          ],
        ),
      ] else if (_taskData['taskType'] == "Bidding Task") ...[
        _dateTile("VALID FROM", 'startDate'),
        const SizedBox(height: 16),
        _dateTile("VALID UNTIL", 'endDate'),
        const SizedBox(height: 16),
        _modernField(
          label: "MAX ACCEPTANCES",
          hint: "e.g. 3",
          icon: Icons.people_alt_outlined,
          isNumber: true,
          initialValue: _taskData['maxAcceptances']?.toString() ?? '3',
          onChanged: (v) => _taskData['maxAcceptances'] = int.tryParse(v) ?? 3,
        ),
      ] else ...[
        _dateTile(
          _taskData['isPackageTask'] ? "START DATE" : "VALID FROM",
          'startDate',
        ),
        if (!_taskData['isPackageTask']) ...[
          const SizedBox(height: 16),
          _dateTile("VALID UNTIL", 'endDate'),
        ],
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
        const SizedBox(height: 16),
        _modernToggle(
          "IS FACULTY NEEDED?",
          _taskData['isFaculty'],
          (v) => setState(() => _taskData['isFaculty'] = v),
        ),
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
      _dateTile("OVERALL PROJECT DEADLINE", 'endDate'),
      const SizedBox(height: 24),
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
              initialValue: _taskData['score']?.toString(),
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
              initialValue: _taskData['penaltyRule']?['penaltyValue']
                  ?.toString(),
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
        "REQUIRED RESOURCES",
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      _modernToggle(
        "REQUIRED DOCUMENTATION",
        _taskData['mandatoryDocumentation'],
        (v) => setState(() => _taskData['mandatoryDocumentation'] = v),
      ),
      const SizedBox(height: 16),
      _modernToggle(
        "IS MANDATORY TASK?",
        _taskData['is_mandatory_flag'] ?? false,
        (v) => setState(() => _taskData['is_mandatory_flag'] = v),
      ),
    ];
  }

  // --- SELF LOG FORM ---

  // --- HELPER METHODS FOR SELF LOG ---

  void _calculateHours() {
    final TimeOfDay? start = _taskData['startTime'];
    final TimeOfDay? end = _taskData['endTime'];

    if (start != null && end != null) {
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      final diffMinutes = endMinutes - startMinutes;

      setState(() {
        _taskData['calculatedHours'] = diffMinutes / 60.0;
      });
    }
  }

  Widget _timePicker({
    required String label,
    required dynamic
    time, // Use dynamic to prevent type crashes if parsing fails
    required Function(TimeOfDay) onTimePicked,
  }) {
    // Safe conversion to TimeOfDay
    final TimeOfDay? effectiveTime = time is TimeOfDay ? time : null;

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
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: effectiveTime ?? TimeOfDay.now(),
            );
            if (picked != null) {
              final bool isDirective =
                  _taskData['taskCategory'] == 'Directive Task';
              if (isDirective || _isWithinWorkingHours(picked)) {
                onTimePicked(picked);
              } else {
                _showErrorSnackBar(
                  "You can only select time between 08:30 AM and 04:30 PM for self logs!",
                );
              }
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
                Icon(Icons.access_time, color: accent, size: 20),
                const SizedBox(width: 12),
                Text(
                  effectiveTime != null
                      ? effectiveTime.format(context)
                      : "Select Time",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: effectiveTime != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _documentAttachmentSection() {
    final List<String> documents = _taskData['selectedDocuments'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              type: FileType.any,
            );

            if (result != null && result.files.isNotEmpty) {
              setState(() {
                for (var file in result.files) {
                  if (!_taskData['selectedDocuments'].contains(file.name)) {
                    _taskData['selectedDocuments'].add(file.name);
                  }
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, color: accent),
                const SizedBox(width: 12),
                Text(
                  "Tap to select files",
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        if (documents.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...documents.map(
            (doc) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file, color: accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(doc, style: const TextStyle(fontSize: 13)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _taskData['selectedDocuments'].remove(doc);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- UI COMPONENTS ---

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
        title: Text(
          _taskData[dataKey] != null
              ? DateFormat('yyyy-MM-dd').format(_taskData[dataKey])
              : "Select Date",
        ),
        trailing: const Icon(Icons.edit, size: 18),
        onTap: () => _pickDate(dataKey),
      ),
    ],
  );

  Widget _assigneeSection() {
    final List<Map<String, dynamic>> assignees =
        List<Map<String, dynamic>>.from(_taskData['selectedAssignees']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ASSIGN TO",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final List<Map<String, dynamic>>? result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserSelectionPage(
                  initialSelection: assignees,
                  allowedRoles: _getAssigneeRoles(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, color: accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        assignees.isEmpty
                            ? "Select Users, Roles or Depts"
                            : "${assignees.length} assigned",
                        style: TextStyle(
                          color: assignees.isEmpty
                              ? Colors.grey
                              : Colors.black87,
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
                if (assignees.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _buildAssigneeChips(assignees),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAssigneeChips(List<Map<String, dynamic>> assignees) {
    if (assignees.length > 5) {
      return [
        Chip(
          label: Text(
            "${assignees.length} Users Selected",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          backgroundColor: accent.withOpacity(0.1),
          side: BorderSide.none,
          avatar: Icon(Icons.group, size: 14, color: accent),
        ),
      ];
    }

    return assignees.map((a) {
      Color chipColor = accent;
      if (a['type'] == 'role') chipColor = Colors.orange;
      if (a['type'] == 'dept') chipColor = Colors.teal;

      return Chip(
        label: Text(a['name'] ?? "User", style: const TextStyle(fontSize: 10)),
        backgroundColor: chipColor.withOpacity(0.1),
        onDeleted: () {
          setState(() {
            _taskData['selectedAssignees'].remove(a);
          });
        },
        deleteIconColor: chipColor,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    }).toList();
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
              allowedRoles: _getApproverRoles(),
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
              allowedRoles: _getFacultyInChargeRoles(),
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
    String? initialValue,
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
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          onChanged: onChanged,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
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

  Widget _searchableDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    // 1. Sanitize and Deduplicate Items
    final List<String> sanitizedItems = items.map((e) => e.trim()).toList();
    final Set<String> itemSet = sanitizedItems.toSet();

    // 2. Ensure current value is in the set
    if (value != null && value.trim().isNotEmpty) {
      itemSet.add(value.trim());
    }

    final List<String> effectiveItems = itemSet.toList();

    // 3. Robust selection value
    String? dropdownValue = value?.trim();
    if (dropdownValue != null && !itemSet.contains(dropdownValue)) {
      dropdownValue = null;
    }
    if (dropdownValue == null && effectiveItems.isNotEmpty) {
      dropdownValue = effectiveItems.first;
    }

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
        InkWell(
          onTap: () async {
            if (effectiveItems.isEmpty) return;

            final String? selected = await showDialog<String>(
              context: context,
              builder: (BuildContext context) {
                return _SearchableDropdownDialog(
                  items: effectiveItems,
                  initialValue: dropdownValue,
                  title: label,
                );
              },
            );

            if (selected != null && selected != dropdownValue) {
              onChanged(selected);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dropdownValue ?? 'Select Item',
                    style: TextStyle(
                      fontSize: 13,
                      color: dropdownValue != null
                          ? Colors.black87
                          : Colors.grey[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _modernDropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    // 1. Sanitize and Deduplicate Items
    final List<String> sanitizedItems = items.map((e) => e.trim()).toList();
    final Set<String> itemSet = sanitizedItems.toSet();

    // 2. Ensure current value is in the set
    if (value != null && value.trim().isNotEmpty) {
      itemSet.add(value.trim());
    }

    final List<String> effectiveItems = itemSet.toList();

    // 3. Robust selection value
    String? dropdownValue = value?.trim();
    if (dropdownValue != null && !itemSet.contains(dropdownValue)) {
      dropdownValue = null;
    }
    if (dropdownValue == null && effectiveItems.isNotEmpty) {
      dropdownValue = effectiveItems.first;
    }

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
        _isLoadingVenues
            ? const LinearProgressIndicator(minHeight: 2)
            : DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                initialValue: dropdownValue,
                items: effectiveItems
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        value: val,
        onChanged: onChanged,
        activeColor: accent,
        contentPadding: EdgeInsets.zero,
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

  PreferredSizeWidget _buildAppBar() {
    final bool isDirective = _taskData['taskCategory'] == 'Directive Task';
    final bool isOpen = _isSystemWithinWorkingHours() || isDirective;
    return AppBar(
      backgroundColor: bodyBg,
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          const Text(
            "Task Command",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: (isOpen ? Colors.green : Colors.red).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isOpen ? Colors.green : Colors.red).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                      duration: 1.seconds,
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isOpen ? Colors.green : Colors.red)
                                .withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.5, 1.5),
                      duration: 1.seconds,
                    )
                    .fadeOut(duration: 1.seconds),
                const SizedBox(width: 6),
                Text(
                  isOpen ? "SYSTEM ACTIVE" : "SYSTEM LOCKED",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isOpen ? Colors.green : Colors.red,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.black,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildWorkingHoursBanner() {
    final bool isDirective = _taskData['taskCategory'] == 'Directive Task';
    if (isDirective || _isSystemWithinWorkingHours()) return const SizedBox();
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Creation Window Closed",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
                Text(
                  "Official window: 08:30 AM - 04:30 PM",
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.2, end: 0).fadeIn();
  }

  bool _isWithinWorkingHours(TimeOfDay time) {
    final int minutes = time.hour * 60 + time.minute;
    const int startMinutes = 8 * 60 + 30; // 08:30
    const int endMinutes = 16 * 60 + 30; // 16:30
    return minutes >= startMinutes && minutes <= endMinutes;
  }

  bool _isSystemWithinWorkingHours() {
    final now = DateTime.now();
    return _isWithinWorkingHours(TimeOfDay.fromDateTime(now));
  }

  Widget _sectionWrapper({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0,
          ),
        ),
        Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 12),
        ...children,
        const Divider(height: 32, thickness: 0.5),
      ],
    ),
  );

  Widget _buildBottomNavigation() {
    final bool isSelfLog = _taskData['taskCategory'] == 'Self Log';
    final bool isOpen = _isSystemWithinWorkingHours();
    // Directive tasks are always "open"
    final bool isCreationAllowed = !isSelfLog || isOpen;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Center(
        child: AnimatedContainer(
          duration: 300.ms,
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: isCreationAllowed
                ? (isSelfLog ? _submitSelfLog : _finishTaskCreation)
                : () => _showErrorSnackBar(
                    "Self logs can only be created between 08:30 AM and 04:30 PM",
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCreationAllowed ? accent : Colors.grey[100],
              foregroundColor: isCreationAllowed
                  ? Colors.white
                  : Colors.grey[400],
              elevation: isCreationAllowed ? 8 : 0,
              shadowColor: accent.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCreationAllowed
                      ? Icons.rocket_launch_rounded
                      : Icons.lock_person_rounded,
                  size: 20,
                  color: isCreationAllowed ? Colors.white : Colors.grey[400],
                ),
                const SizedBox(width: 12),
                Text(
                  isCreationAllowed
                      ? (isSelfLog ? "Log Achievement" : "Create Directive")
                      : "LOCKED: 08:30-16:30",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isCreationAllowed ? Colors.white : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getAssigneeRoles() {
    final role = _userRole?.toLowerCase() ?? '';
    final List<String> hierarchy = [
      'admin',
      'principal',
      'dean',
      'hod',
      'faculty',
      'student',
      'staff',
    ];
    int userIndex = hierarchy.indexOf(role);
    if (userIndex == -1) return ['students', 'staff'];

    final Map<String, String> keyMap = {
      'hod': 'hods',
      'student': 'students',
      'faculty': 'faculty',
      'staff': 'staff',
      'admin': 'admin',
      'principal': 'principal',
      'dean': 'dean',
    };

    return hierarchy.sublist(userIndex).map((r) => keyMap[r] ?? r).toList();
  }

  List<String> _getApproverRoles() {
    final role = _userRole?.toLowerCase() ?? '';
    final List<String> hierarchy = [
      'admin',
      'principal',
      'dean',
      'hod',
      'faculty',
      'student',
      'staff',
    ];
    int userIndex = hierarchy.indexOf(role);
    if (userIndex == -1) return ['admin', 'principal', 'dean', 'hods'];

    final Map<String, String> keyMap = {
      'hod': 'hods',
      'student': 'students',
      'faculty': 'faculty',
      'staff': 'staff',
      'admin': 'admin',
      'principal': 'principal',
      'dean': 'dean',
    };

    return hierarchy.sublist(0, userIndex).map((r) => keyMap[r] ?? r).toList();
  }

  List<String> _getFacultyInChargeRoles() {
    return ['faculty'];
  }

  void _finishTaskCreation() async {
    // Map completion methods to closure IDs
    List<int> closureIds = [];
    final methods = _taskData['completionMethods'] as List;
    for (var method in methods) {
      if (method == 'OTP Verify') closureIds.add(1);
      if (method == 'Photo Upload') closureIds.add(2);
      if (method == 'QR Scan') closureIds.add(3);
    }
    // Default to [1] if none selected
    if (closureIds.isEmpty) closureIds = [1];

    // Removed working hours check for directives (allowed 24/7)

    // Build task_type_data
    Map<String, dynamic> taskTypeData = {};

    if (_taskData['taskType'] == 'Recurring Task') {
      final recurrence = (_taskData['recurrenceType'] as String? ?? 'Daily')
          .toLowerCase();
      taskTypeData = {
        'task_name': 'Recurring Task',
        'recurrence': recurrence,
        'start_date': DateFormat('yyyy-MM-dd').format(_taskData['startDate']),
        'end_date': DateFormat('yyyy-MM-dd').format(_taskData['endDate']),
        'start_time': _taskData['startTime'] != null
            ? '${_taskData['startTime'].hour.toString().padLeft(2, '0')}:${_taskData['startTime'].minute.toString().padLeft(2, '0')}:00'
            : '11:00:00',
        'end_time': _taskData['endTime'] != null
            ? '${_taskData['endTime'].hour.toString().padLeft(2, '0')}:${_taskData['endTime'].minute.toString().padLeft(2, '0')}:00'
            : '12:00:00',
      };
    } else if (_taskData['taskType'] == 'Fixed Time Task') {
      taskTypeData = {
        'task_name': 'Fixed Time Task',
        'start_date': DateFormat(
          'yyyy-MM-dd',
        ).format(_taskData['selectedDate']),
        'end_date': DateFormat('yyyy-MM-dd').format(_taskData['selectedDate']),
        'start_time': _taskData['startTime'] != null
            ? '${_taskData['startTime'].hour.toString().padLeft(2, '0')}:${_taskData['startTime'].minute.toString().padLeft(2, '0')}:00'
            : '09:00:00',
        'end_time': _taskData['endTime'] != null
            ? '${_taskData['endTime'].hour.toString().padLeft(2, '0')}:${_taskData['endTime'].minute.toString().padLeft(2, '0')}:00'
            : '17:00:00',
      };
    } else if (_taskData['taskType'] == 'Bidding Task') {
      taskTypeData = {
        'task_name': 'Bidding Task',
        'start_date': DateFormat('yyyy-MM-dd').format(_taskData['startDate']),
        'end_date': DateFormat('yyyy-MM-dd').format(_taskData['endDate']),
        'max_acceptances': _taskData['maxAcceptances'] ?? 3,
      };
    } else {
      // Default for Long Task and others
      taskTypeData = {
        'task_name': _taskData['taskType'],
        'start_date': DateFormat('yyyy-MM-dd').format(_taskData['startDate']),
        'end_date': DateFormat('yyyy-MM-dd').format(_taskData['endDate']),
      };
    }

    // Only include venue_id if a real venue is selected (not 'None')
    final venueId =
        (_taskData['locationId'] == 'None' || _taskData['venue_id'] == null)
        ? null
        : _taskData['venue_id'];

    // Extract assignee IDs
    final List<Map<String, dynamic>> selected = List<Map<String, dynamic>>.from(
      _taskData['selectedAssignees'] ?? [],
    );

    List<int> assigneeIds = selected
        .map((a) {
          final id = a['id'] ?? a['user_id'];
          if (id is String) return int.tryParse(id) ?? 0;
          return id as int? ?? 0;
        })
        .where((id) => id > 0)
        .toList();

    final bool isMandatory = _taskData['is_mandatory_flag'] ?? false;
    final bool isBidding = _taskData['taskType'] == 'Bidding Task';

    // For bidding: build assign__groups from dept/role type assignees
    // For others: use individual assignee_ids
    List<Map<String, dynamic>> assignGroups = [];
    if (isBidding) {
      for (final a in selected) {
        if (a['type'] == 'dept' || a['type'] == 'role') {
          assignGroups.add({
            'role': (a['role'] ?? 'STUDENT').toString().toUpperCase(),
            if (a['department_id'] != null) 'department_id': a['department_id'],
          });
        } else {
          // Individual in a bidding task — wrap as group with just role
          assignGroups.add({
            'role': (a['role'] ?? 'STUDENT').toString().toUpperCase(),
          });
        }
      }
    }

    // Priority Mapping Logic
    int pVal = 2; // Default Medium
    switch ((_taskData['priority'] as String).toLowerCase()) {
      case 'critical':
      case 'high':
        pVal = 1;
        break;
      case 'medium':
        pVal = 2;
        break;
      case 'low':
        pVal = 3;
        break;
    }

    // Build the full payload matching the unified-create API
    final payload = <String, dynamic>{
      'task_title_id': _taskData['task_title_id'],
      'description': _taskData['description'] ?? '',
      'category': _taskData['category'],
      'priority': _taskData['priority'], // Send exact string (e.g. "High")
      'priority_level': pVal, // Also send integer level as requested
      'origin_type': 'directive',
      'score': _taskData['score'],
      'is_mandatory': isMandatory,
      'is_package': _taskData['isPackageTask'],
      'max_hours': _taskData['maxHours'] ?? 0.0,
      'is_document': _taskData['is_document'] ?? true,
      'is_pause_allowed': _taskData['allowPause'],
      'closure_ids': closureIds,
      'task_type_data': taskTypeData,
    };

    // Explicitly add due_date at root for package tracking
    if (_taskData['isPackageTask']) {
      final DateTime? end = _taskData['endDate'] ?? _taskData['selectedDate'];
      if (end != null) {
        payload['due_date'] = DateFormat('yyyy-MM-dd').format(end);
      }
    }

    if (_taskData['isPackageTask']) {
      double totalStepsHours = 0;
      payload['sub_tasks'] = (_taskData['subTasks'] as List).map((s) {
        final d = (s['duration'] as num?)?.toDouble() ?? 0.0;
        totalStepsHours += d;
        return {
          'title': s['title'],
          'assignee_id': s['assignee_id'],
          'order_index': s['order'],
          'allocated_hours': d,
        };
      }).toList();

      final maxLimit = (_taskData['maxHours'] as num?)?.toDouble() ?? 0.0;
      if (maxLimit > 0 && totalStepsHours > maxLimit) {
        _showErrorSnackBar(
          "Sum of sub-task hours (${totalStepsHours.toStringAsFixed(1)}) exceeds package limit (${maxLimit.toStringAsFixed(1)})",
        );
        return;
      }
    }

    // Only attach venue_id when user selected a real venue
    if (venueId != null) {
      payload['venue_id'] = venueId;
    }

    // Add faculty information if present
    if (_taskData['facultyInCharge'] != null) {
      payload['is_faculty'] = true;
      final fId =
          _taskData['facultyInCharge']['id'] ??
          _taskData['facultyInCharge']['user_id'];
      if (fId is String) {
        payload['faculty_id'] = int.tryParse(fId) ?? 0;
      } else {
        payload['faculty_id'] = fId as int? ?? 0;
      }
    } else {
      payload['is_faculty'] = false;
    }

    // Bidding tasks use group assignment, others use individual IDs
    if (isBidding) {
      payload['assign__groups'] = assignGroups;
    } else {
      payload['assignee_ids'] = assigneeIds;
    }

    try {
      print("========== DIRECTIVE CREATE PAYLOAD ==========");
      print(payload.toString());
      print("==============================================");
      final taskService = TaskService();
      await taskService.createTaskUnified(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to create task: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ).animate().shake(hz: 8, curve: Curves.easeInOut),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _submitSelfLog() async {
    if (!_isSystemWithinWorkingHours()) {
      _showErrorSnackBar(
        'Task creation is only allowed between 08:45 AM and 04:30 PM!',
      );
      return;
    }

    // Validate required fields
    if (_taskData['title'] == null || (_taskData['title'] as String).isEmpty) {
      _showErrorSnackBar('Please enter an activity title');
      return;
    }

    final TimeOfDay? st = _taskData['startTime'] is TimeOfDay
        ? _taskData['startTime']
        : null;
    final TimeOfDay? et = _taskData['endTime'] is TimeOfDay
        ? _taskData['endTime']
        : null;

    if (st == null || et == null) {
      _showErrorSnackBar('Please select valid start and end times');
      return;
    }

    // Build the activity date string
    final activityDate =
        _taskData['activityDate'] as DateTime? ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(activityDate);

    // Build time strings
    final startTimeStr =
        '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}:00';
    final endTimeStr =
        '${et.hour.toString().padLeft(2, '0')}:${et.minute.toString().padLeft(2, '0')}:00';

    final double hours =
        (_taskData['calculatedHours'] as num?)?.toDouble() ?? 0.0;

    // Build the unified-create payload for self-log
    final payload = {
      'task_title_id': _taskData['task_title_id'], // Added task_title_id
      'description': _taskData['description'] ?? '',
      'category': _taskData['category'] ?? 'Academic',
      'priority': 'Medium',
      'priority_level': 2,
      'origin_type': 'self-log',
      'is_document': _taskData['is_document'] ?? true,
      'closure_ids': _taskData['closure_ids'] ?? [1],
      'task_type_data': {
        'task_name': 'Self Log',
        'start_date': dateStr,
        'start_time': startTimeStr,
        'end_time': endTimeStr,
        'time_quota_hours': hours,
      },
    };

    try {
      print("========== SELF LOG CREATE PAYLOAD ==========");
      print(payload.toString());
      print("=============================================");
      final taskService = TaskService();
      await taskService.createTaskUnified(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity log submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to submit log: $e');
      }
    }
  }

  void _addSubTask() {
    setState(() {
      (_taskData['subTasks'] as List).add({
        'title': '',
        'assignee_id': null,
        'assignee_name': 'Select Assignee',
        'duration': 0.0,
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
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _userPickerTile(
                  label: "ASSIGNEE",
                  subtitle: subTask['assignee_name'] ?? "Select...",
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
                        subTask['assignee_id'] =
                            result.first['id'] ?? result.first['user_id'];
                        subTask['assignee_name'] = result.first['name'];
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _modernField(
                  label: "HOURS",
                  hint: "0.0",
                  isNumber: true,
                  initialValue: subTask['duration']?.toString(),
                  onChanged: (v) => setState(() {
                    subTask['duration'] = double.tryParse(v) ?? 0.0;
                  }),
                ),
              ),
            ],
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

// Custom Dialog for Searchable Dropdown
class _SearchableDropdownDialog extends StatefulWidget {
  final List<String> items;
  final String? initialValue;
  final String title;

  const _SearchableDropdownDialog({
    required this.items,
    this.initialValue,
    required this.title,
  });

  @override
  State<_SearchableDropdownDialog> createState() =>
      _SearchableDropdownDialogState();
}

class _SearchableDropdownDialogState extends State<_SearchableDropdownDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFF6366F1);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              0.7, // Max 70% of screen height
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Search ${widget.title}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _filterItems,
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // List of Items
            Expanded(
              child: _filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        "No options found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item == widget.initialValue;

                        return ListTile(
                          title: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? accent : Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check, color: accent, size: 20)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            Navigator.pop(context, item);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
