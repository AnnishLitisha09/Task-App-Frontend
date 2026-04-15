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
  final int? taskId;

  const CreateTaskPage({super.key, this.initialData, this.taskId});

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
  bool _isLoadingDetails = false;
  String? _userRole;
  int? _currentUserId;
  String? _excelFilePath; // Track uploaded excel file
  bool _isSubmitting = false; // NEW: Prevent represses

  @override
  void initState() {
    super.initState();
    _initializeData(); // Always run first so _taskData is set before any async call
    _fetchUserRole();
    _fetchVenues();
    _fetchTaskTitles();

    if (widget.taskId != null) {
      _fetchTaskDetails(); // Overwrites _taskData with server data
    }
  }

  void _initializeData() {
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
      'requiresApproval': false,
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
      'facultyInCharge': <Map<String, dynamic>>[], // Changed to List
      'selectedAssignees': <Map<String, dynamic>>[],
      // Self Log specific fields
      'activityDate': DateTime.now(),
      'startTime': const TimeOfDay(hour: 9, minute: 0),
      'endTime': const TimeOfDay(hour: 17, minute: 0),
      'calculatedHours': 2.0,
      'activityTags': <String>[],
      'attachDocuments': false,
      'selectedDocuments': <String>[],
      'is_document': false,
      'is_mandatory_flag': false,
      'closure_ids': [1],
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

      // 6. Handle taskType mapping if it comes from backend
      if (data['TaskTypes'] != null &&
          data['TaskTypes'] is List &&
          data['TaskTypes'].isNotEmpty) {
        final typeObj = data['TaskTypes'][0];
        String backendType = typeObj['task_name'] ?? 'Fixed Time Task';

        // Map canonical backend names to UI names
        if (backendType == 'Date-Only / Long Task') {
          data['taskType'] = 'Long Task';
        } else if (backendType == 'Bidding / Nomination Task') {
          data['taskType'] = 'Bidding Task';
        } else if (backendType == 'Fixed Time Task') {
          data['taskType'] = 'Fixed Time Task';
        } else if (backendType == 'Recurring Task') {
          data['taskType'] = 'Recurring Task';
        } else {
          data['taskType'] = backendType;
        }

        data['startDate'] = _parseDateString(typeObj['start_date']);
        data['endDate'] = _parseDateString(typeObj['end_date']);
        data['selectedDate'] = _parseDateString(typeObj['start_date']);

        // Pre-fill activityDate and selectedDate for Fixed/Floating/Bidding
        if (data['taskType'] == 'Fixed Time Task' ||
            data['taskType'] == 'Floating Task' ||
            data['taskType'] == 'Bidding Task') {
          data['activityDate'] = data['startDate'];
          data['selectedDate'] = data['startDate'];
        }

        data['startTime'] = _parseTimeString(typeObj['start_time']);
        data['endTime'] = _parseTimeString(typeObj['end_time']);
        data['maxAcceptances'] = typeObj['max_acceptances'] ?? 3;
      }

      // 7. Handle Selected Assignees Mapping
      if (data['selectedAssignees'] == null ||
          (data['selectedAssignees'] as List).isEmpty) {
        if (data['TaskAssigns'] != null && data['TaskAssigns'] is List) {
          data['selectedAssignees'] = (data['TaskAssigns'] as List)
              .map((a) {
                final u = a['User'];
                if (u == null) return <String, dynamic>{};
                final details =
                    u['Student'] ?? u['Faculty'] ?? u['Staff'] ?? u['RoleUser'];
                return {
                  'id': u['user_id'],
                  'user_id': u['user_id'],
                  'name': details?['name'] ?? 'Unknown User',
                  'role': u['role'],
                  'type': 'individual',
                  'status': a['status'] ?? 'pending',
                };
              })
              .where((m) => m.isNotEmpty)
              .toList();
        }
      }

      // 8. Handle Approval mapping
      if (data['requiresApproval'] == null &&
          data['requires_approval'] != null) {
        data['requiresApproval'] = data['requires_approval'];
      }
      if (data['approvalAuthority'] == null && data['approver_id'] != null) {
        data['approvalAuthority'] = {
          'user_id': data['approver_id'],
          'id': data['approver_id'],
          'name': 'Current Approver', // Best effort if name not available
        };
      }
    }
    _taskData = data;
  }

  Future<void> _fetchTaskDetails() async {
    setState(() => _isLoadingDetails = true);
    try {
      final task = await _taskService.getTaskDetails(widget.taskId!);
      setState(() {
        _normalizeAndSetData(task);
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() => _isLoadingDetails = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching task details: $e")),
        );
      }
      _initializeData(); // Fallback to empty if fetch fails
    }
  }

  void _normalizeAndSetData(Map<String, dynamic> rawData) {
    final Map<String, dynamic> data = Map.from(_taskData);

    // Detect format: exhaustive uses task_info wrapper; new /details endpoint is flat
    final bool isExhaustive = rawData.containsKey('task_info');
    final Map<String, dynamic> taskInfo = isExhaustive
        ? (rawData['task_info'] as Map<String, dynamic>? ?? rawData)
        : rawData;

    // Schedule key differs: exhaustive = 'schedule', details = 'type_details'
    final Map<String, dynamic>? schedule = isExhaustive
        ? rawData['schedule'] as Map<String, dynamic>?
        : rawData['type_details'] as Map<String, dynamic>?;

    // --- Core Fields ---
    data['task_id'] = taskInfo['task_id'];
    data['title'] = taskInfo['title'];
    data['task_title_id'] = taskInfo['task_title_id'];
    data['description'] = taskInfo['description'] ?? '';
    data['category'] = taskInfo['category'] ?? 'Academic';
    data['priority'] = _capitalize(taskInfo['priority'] ?? 'Medium');
    data['score'] =
        double.tryParse(taskInfo['score']?.toString() ?? '100.0') ?? 100.0;
    data['isPackageTask'] = taskInfo['is_package'] ?? false;
    data['allowPause'] = taskInfo['is_pause_allowed'] ?? false;
    data['is_document'] = taskInfo['is_document'] ?? false;
    data['is_mandatory_flag'] = taskInfo['is_mandatory'] ?? false;
    data['requiresApproval'] =
        taskInfo['approver_id'] != null ||
        taskInfo['is_approved'] == true ||
        (rawData['approval_detail']?['status'] == 'approved');
    data['origin_type'] = taskInfo['origin_type'];
    data['is_faculty'] = taskInfo['is_faculty'] ?? false;

    // Approver mapping
    if (taskInfo['approver_id'] != null) {
      data['approvalAuthority'] = {
        'id': taskInfo['approver_id'],
        'user_id': taskInfo['approver_id'],
        'name': taskInfo['approver']?['name'] ?? 'Approver',
      };
    }

    // Faculty mapping
    if (taskInfo['is_faculty'] == true && taskInfo['faculty'] != null) {
      data['facultyInCharge'] = [
        {
          'id': taskInfo['faculty']['user_id'],
          'user_id': taskInfo['faculty']['user_id'],
          'name': taskInfo['faculty']['name'] ?? 'Faculty',
          'type': 'individual',
        },
      ];
    }

    // --- Task Category ---
    if (taskInfo['origin_type'] == 'self-log') {
      data['taskCategory'] = 'Self Log';
    } else {
      data['taskCategory'] = 'Directive Task';
    }

    // --- Schedule ---
    if (schedule != null) {
      String rawName = schedule['task_name'] ?? 'Fixed Time Task';
      if (rawName == 'Date-Only / Long Task') {
        data['taskType'] = 'Long Task';
      } else if (rawName == 'Bidding / Nomination Task') {
        data['taskType'] = 'Bidding Task';
      } else if (rawName == 'Fixed Time Task') {
        data['taskType'] = 'Fixed Time Task';
      } else if (rawName == 'Recurring Task') {
        data['taskType'] = 'Recurring Task';
      } else {
        data['taskType'] = rawName;
      }
      data['startDate'] = _parseDateString(schedule['start_date'] ?? '');
      data['endDate'] = _parseDateString(schedule['end_date'] ?? '');
      data['selectedDate'] = data['startDate'];
      data['activityDate'] = data['startDate'];
      data['startTime'] = _parseTimeString(schedule['start_time']);
      data['endTime'] = _parseTimeString(schedule['end_time']);
      data['recurrenceType'] = _capitalize(schedule['recurrence'] ?? 'none');
      data['venue_id'] = schedule['venue_id'];
      data['maxHours'] =
          double.tryParse(schedule['time_quota_hours']?.toString() ?? '0.0') ??
          0.0;
      data['maxSlots'] = schedule['max_acceptances'] ?? 5;
    }

    // --- Assignees ---
    // Exhaustive: assignees.all[].assignee | Details: assignees[].user
    final dynamic rawAssignees = (rawData['assignees'] is Map)
        ? rawData['assignees']['all']
        : rawData['assignees'];

    if (rawAssignees != null && rawAssignees is List) {
      data['selectedAssignees'] = rawAssignees.map((a) {
        final Map<String, dynamic> user = a['user'] ?? a['assignee'] ?? a;
        return {
          'id': user['user_id'],
          'user_id': user['user_id'],
          'name': user['name'] ?? 'Unknown',
          'role': user['role'],
          'status': a['status'] ?? 'pending',
        };
      }).toList();
    }

    // --- Closures ---
    // New details format: closures[].closure_id
    // Exhaustive / old format: closure_ids[]
    if (rawData['closures'] != null && rawData['closures'] is List) {
      data['closure_ids'] = (rawData['closures'] as List)
          .map((c) => c['closure_id'])
          .whereType<int>()
          .toList();
    } else if (rawData['closure_ids'] != null &&
        rawData['closure_ids'] is List) {
      data['closure_ids'] = List<int>.from(rawData['closure_ids']);
    }

    // Map closure IDs to strings for UI completion methods
    if (data['closure_ids'] != null && data['closure_ids'] is List) {
      List<String> methods = [];
      for (var id in data['closure_ids']) {
        if (id == 1) methods.add('OTP Verify');
        if (id == 2) methods.add('Photo Upload');
        if (id == 3) methods.add('QR Scan');
      }
      data['completionMethods'] = methods;
    }

    _taskData = data;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Future<void> _fetchVenues() async {
    setState(() => _isLoadingVenues = true);
    try {
      final dateObj =
          _taskData['taskType'] == 'Fixed Time Task' ||
              _taskData['taskType'] == 'Floating Task' ||
              _taskData['taskType'] == 'Bidding Task'
          ? _taskData['selectedDate']
          : _taskData['startDate'];

      String? dateStr;
      if (dateObj is DateTime) {
        dateStr =
            "${dateObj.year}-${dateObj.month.toString().padLeft(2, '0')}-${dateObj.day.toString().padLeft(2, '0')}";
      }

      String? startTimeStr;
      if (_taskData['startTime'] is TimeOfDay) {
        final st = _taskData['startTime'] as TimeOfDay;
        startTimeStr =
            "${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}:00";
      }

      String? endTimeStr;
      if (_taskData['endTime'] is TimeOfDay) {
        final et = _taskData['endTime'] as TimeOfDay;
        endTimeStr =
            "${et.hour.toString().padLeft(2, '0')}:${et.minute.toString().padLeft(2, '0')}:00";
      }

      final venues = await _resourceService.getVenues(
        date: dateStr,
        startTime: startTimeStr,
        endTime: endTimeStr,
      );

      setState(() {
        _venues = venues;
        _isLoadingVenues = false;

        if (_taskData['venue_id'] != null) {
          final selectedVenue = _venues.firstWhere(
            (v) => v['venue_id'] == _taskData['venue_id'],
            orElse: () => {},
          );
          if (selectedVenue.isNotEmpty) {
            final name = selectedVenue['name'] ?? 'Unknown';
            final status =
                selectedVenue['booking_status'] ??
                selectedVenue['status'] ??
                'unknown';
            _taskData['locationId'] =
                '$name (${_capitalize(status.toString())})';
          } else {
            _taskData['locationId'] = 'None';
            _taskData['venue_id'] = null;
          }
        } else {
          _taskData['locationId'] = 'None';
        }
      });
    } catch (e) {
      debugPrint('Error fetching venues: $e');
      setState(() => _isLoadingVenues = false);
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final profile = await _userService.getUserProfile();
      setState(() {
        _userRole = profile.role;
        _currentUserId = profile.userId; // Fixed: use camelCase userId
      });
    } catch (e) {
      // Fallback
    }
  }

  Future<void> _fetchTaskTitles() async {
    setState(() => _isLoadingTitles = true);
    try {
      final titles = await _taskService.getTaskTitles();
      setState(() {
        _taskTitles =
            titles; // Removed role filtering: all roles' titles should come
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

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _excelFilePath = result.files.single.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Excel file attached: ${result.files.single.name}"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking file: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
      _fetchVenues();
    }
  }

  void _updatePackageMaxHours() {
    double totalStepsHours = 0;
    if (_taskData['subTasks'] != null) {
      for (var sub in (_taskData['subTasks'] as List)) {
        totalStepsHours += (sub['duration'] as num?)?.toDouble() ?? 0.0;
      }
    }

    setState(() {
      _taskData['maxHours'] = totalStepsHours;
    });
  }

  DateTime _calculatePackageEndTime(
    DateTime startDate,
    TimeOfDay startTime,
    double durationHours,
  ) {
    // Standard Working Hours: 08:30 AM - 04:30 PM (8 hours)
    // We'll use 8:30 to 16:30 for simplicity and consistency with other project parts
    const int workStartMinutes = 8 * 60 + 30;
    const int workEndMinutes = 16 * 60 + 30;
    // dailyWorkMinutes removed as it was unused across the project logic

    DateTime current = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );
    double remainingMinutes = durationHours * 60;

    // 1. Initial Normalization: Ensure current is not a Sunday
    while (current.weekday == DateTime.sunday) {
      current = current.add(const Duration(days: 1));
      current = DateTime(current.year, current.month, current.day, 8, 30);
    }

    // 2. Initial Normalization: Ensure current is within 08:30 - 16:30
    int currentMinutes = current.hour * 60 + current.minute;
    if (currentMinutes >= workEndMinutes) {
      current = current.add(const Duration(days: 1));
      while (current.weekday == DateTime.sunday) {
        current = current.add(const Duration(days: 1));
      }
      current = DateTime(current.year, current.month, current.day, 8, 30);
      currentMinutes = workStartMinutes;
    } else if (currentMinutes < workStartMinutes) {
      current = DateTime(current.year, current.month, current.day, 8, 30);
      currentMinutes = workStartMinutes;
    }

    while (remainingMinutes > 0) {
      // Skip Sundays
      if (current.weekday == DateTime.sunday) {
        current = current.add(const Duration(days: 1));
        current = DateTime(current.year, current.month, current.day, 8, 30);
        currentMinutes = workStartMinutes;
        continue;
      }

      int minutesAvailableToday = workEndMinutes - currentMinutes;

      if (remainingMinutes <= minutesAvailableToday) {
        current = current.add(Duration(minutes: remainingMinutes.round()));
        remainingMinutes = 0;
      } else {
        remainingMinutes -= minutesAvailableToday;
        current = current.add(const Duration(days: 1));
        current = DateTime(current.year, current.month, current.day, 8, 30);
        currentMinutes = workStartMinutes;
      }
    }
    return current;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDetails) {
      return Scaffold(
        backgroundColor: bodyBg,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

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
      ..._venues.map((v) {
        final name = v['name'] ?? 'Unknown';
        final status = v['booking_status'] ?? v['status'] ?? 'unknown';
        return '$name (${_capitalize(status.toString())})';
      }),
    ];

    final List<Widget> timeConfig = [];
    if (!(_taskData['isPackageTask'] ?? false)) {
      if (_taskData['taskType'] == "Fixed Time Task" ||
          _taskData['taskType'] == "Bidding Task") {
        timeConfig.addAll([
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
          if (_taskData['taskType'] == "Bidding Task") ...[
            const SizedBox(height: 16),
            _modernField(
              label: "AVAILABLE SLOTS",
              hint: "10",
              isNumber: true,
              initialValue: (_taskData['maxSlots'] ?? 5).toString(),
              onChanged: (v) => setState(() {
                _taskData['maxSlots'] = int.tryParse(v) ?? 5;
              }),
            ),
          ],
        ]);
      } else if (_taskData['taskType'] == "Recurring Task") {
        timeConfig.addAll([
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
        ]);
      } else if (_taskData['taskType'] == "Floating Task") {
        timeConfig.addAll([
          _dateTile("START DATE", 'startDate'),
          const SizedBox(height: 16),
          _dateTile("END DATE", 'endDate'),
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
              if (_taskData['taskCategory'] == 'Self Log')
                Expanded(
                  child: _timePicker(
                    label: "END TIME",
                    time: _taskData['endTime'],
                    onTimePicked: (v) => setState(() {
                      _taskData['endTime'] = v;
                      if (_taskData['isPackageTask']) _updatePackageMaxHours();
                    }),
                  ),
                )
              else
                Expanded(
                  child: _modernField(
                    label: "DURATION (HOURS)",
                    hint: "2.5",
                    isNumber: true,
                    initialValue: (_taskData['maxHours'] ?? 2.0).toString(),
                    onChanged: (v) => setState(() {
                      _taskData['maxHours'] = double.tryParse(v) ?? 0.0;
                    }),
                  ),
                ),
            ],
          ),
        ]);
      } else {
        timeConfig.addAll([
          _dateTile(
            _taskData['isPackageTask'] ? "START DATE" : "VALID FROM",
            'startDate',
          ),
          if (!_taskData['isPackageTask']) ...[
            const SizedBox(height: 16),
            _dateTile("VALID UNTIL", 'endDate'),
          ],
        ]);
      }
    }

    return [
      _modernDropdown(
        "TASK TYPE",
        [
          "Bidding Task",
          "Floating Task",
          "Long Task",
          "Fixed Time Task",
          "Recurring Task",
        ],
        _taskData['taskType'],
        (v) {
          setState(() {
            _taskData['taskType'] = v;
            if (v == 'Long Task') {
              _taskData['allowPause'] = true;
            }
            if (_taskData['isPackageTask']) _updatePackageMaxHours();
          });
          _fetchVenues();
        },
      ),
      const SizedBox(height: 24),
      if (timeConfig.isNotEmpty) ...[
        Text(
          "TIME CONFIGURATION",
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const Divider(height: 24),
        ...timeConfig,
        const SizedBox(height: 24),
      ],
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
              final selectedVenue = _venues.firstWhere((venue) {
                final n = venue['name'] ?? 'Unknown';
                final s =
                    venue['booking_status'] ?? venue['status'] ?? 'unknown';
                return '$n (${_capitalize(s.toString())})' == v;
              }, orElse: () => {});
              _taskData['venue_id'] = selectedVenue['venue_id'];
            }
          });
        },
      ),
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
    final DateTime startDt = _taskData['startDate'] ?? DateTime.now();
    final TimeOfDay startTm =
        _taskData['startTime'] ?? const TimeOfDay(hour: 8, minute: 30);
    final double totalHrs = _taskData['maxHours'] ?? 0.0;
    final DateTime estimatedEnd = _calculatePackageEndTime(
      startDt,
      startTm,
      totalHrs,
    );

    return [
      _dateTile("PROJECT START DATE", 'startDate'),
      const SizedBox(height: 16),
      _timePicker(
        label: "START TIME",
        time: _taskData['startTime'],
        onTimePicked: (v) => setState(() {
          _taskData['startTime'] = v;
        }),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "ESTIMATED COMPLETION",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${DateFormat('EEEE, MMM d').format(estimatedEnd)} at ${DateFormat('jm').format(estimatedEnd)}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Total Workflow: ${totalHrs.toStringAsFixed(1)} hours",
              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
            ),
          ],
        ),
      ),
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
        "IS DOCUMENT BASED / PROOF REQUIRED",
        _taskData['is_document'] ?? false,
        (v) => setState(() => _taskData['is_document'] = v),
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
                _fetchVenues();
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
                            : (_taskData['task_id'] != null
                                  ? "${assignees.length} Total Users"
                                  : "${assignees.length} assigned"),
                        style: TextStyle(
                          color: assignees.isEmpty
                              ? Colors.grey
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_taskData['task_id'] != null) ...[
                      _statBadge(
                        "ACCEPTED",
                        assignees
                            .where((a) => a['status'] == 'accepted')
                            .length,
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _statBadge(
                        "REJECTED",
                        assignees
                            .where((a) => a['status'] == 'rejected')
                            .length,
                        Colors.red,
                      ),
                      const SizedBox(width: 8),
                    ],
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
        const SizedBox(height: 12),
        _excelUploadTile(),
      ],
    );
  }

  Widget _statBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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

  Widget _excelUploadTile() {
    return InkWell(
      onTap: _pickExcelFile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _excelFilePath != null
              ? Colors.green.withOpacity(0.05)
              : Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _excelFilePath != null
                ? Colors.green.withOpacity(0.3)
                : Colors.blue.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _excelFilePath != null ? Icons.check_circle : Icons.upload_file,
              color: _excelFilePath != null ? Colors.green : Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _excelFilePath != null
                        ? "Excel Attached"
                        : "Bulk Assign via Excel",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _excelFilePath != null
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
                  if (_excelFilePath != null)
                    Text(
                      _excelFilePath!.split('/').last,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (_excelFilePath != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                onPressed: () => setState(() => _excelFilePath = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
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
    final List<Map<String, dynamic>> faculty = List<Map<String, dynamic>>.from(
      _taskData['facultyInCharge'] ?? [],
    );
    return Column(
      children: [
        _userPickerTile(
          label: "FACULTY IN-CHARGE",
          subtitle: faculty.isEmpty
              ? "Select Responsible Faculty"
              : "${faculty.length} faculty selected",
          icon: Icons.person_search_rounded,
          onTap: () async {
            final List<Map<String, dynamic>>? result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserSelectionPage(
                  initialSelection: faculty,
                  multiSelect: true,
                  allowedRoles: _getFacultyInChargeRoles(),
                ),
              ),
            );

            if (result != null) {
              setState(() {
                _taskData['facultyInCharge'] = result;
              });
            }
          },
        ),
        if (faculty.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: faculty.map((f) {
              return Chip(
                label: Text(
                  f['name'] ?? "Faculty",
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: Colors.orange.withOpacity(0.1),
                onDeleted: () {
                  setState(() {
                    _taskData['facultyInCharge'].remove(f);
                  });
                },
                deleteIconColor: Colors.orange,
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
            onPressed: isCreationAllowed && !_isSubmitting
                ? (isSelfLog ? _submitSelfLog : _finishTaskCreation)
                : (isCreationAllowed
                      ? null // Disable while submitting
                      : () => _showErrorSnackBar(
                          "Self logs can only be created between 08:30 AM and 04:30 PM",
                        )),
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
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCreationAllowed
                            ? Icons.rocket_launch_rounded
                            : Icons.lock_person_rounded,
                        size: 20,
                        color: isCreationAllowed
                            ? Colors.white
                            : Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isCreationAllowed
                            ? (isSelfLog
                                  ? (_taskData['task_id'] != null
                                        ? "Update Log"
                                        : "Log Achievement")
                                  : (_taskData['task_id'] != null
                                        ? "Update Directive"
                                        : "Create Directive"))
                            : "LOCKED: 08:30-16:30",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isCreationAllowed
                              ? Colors.white
                              : Colors.grey[400],
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
    if (userIndex == -1) return ['principal', 'dean', 'hods'];

    final Map<String, String> keyMap = {
      'hod': 'hods',
      'student': 'students',
      'faculty': 'faculty',
      'staff': 'staff',
      'admin': 'admin',
      'principal': 'principal',
      'dean': 'dean',
    };

    if (userIndex <= 1)
      return []; // Admin or Principal have no higher selectable roles
    return hierarchy.sublist(1, userIndex).map((r) => keyMap[r] ?? r).toList();
  }

  List<String> _getFacultyInChargeRoles() {
    return ['faculty'];
  }

  void _finishTaskCreation() async {
    if (_isSubmitting) return;

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

    // --- Deadline Validation (Prevent creating past tasks) ---
    if (_taskData['taskType'] == 'Fixed Time Task' ||
        _taskData['taskType'] == 'Bidding Task') {
      final DateTime? rawDate = _taskData['selectedDate'];
      final TimeOfDay? et = _taskData['endTime'];
      if (rawDate != null && et != null) {
        final now = DateTime.now();
        // Normalize to local date-only (strip time zone from UTC-parsed dates)
        final DateTime localDate = DateTime(
          rawDate.year,
          rawDate.month,
          rawDate.day,
        );
        final DateTime todayDate = DateTime(now.year, now.month, now.day);

        // Only check time if the date is today; past dates always fail
        bool isPast;
        if (localDate.isBefore(todayDate)) {
          isPast = true;
        } else if (localDate.isAtSameMomentAs(todayDate)) {
          // Same day: check if end time has already passed (with 1-min grace)
          final deadline = DateTime(
            now.year,
            now.month,
            now.day,
            et.hour,
            et.minute,
          );
          isPast = deadline.isBefore(now.subtract(const Duration(minutes: 1)));
        } else {
          isPast = false; // Future date
        }

        if (isPast) {
          _showErrorSnackBar("Cannot create a task with a past deadline.");
          return;
        }
      }
    }

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
            : '09:00:00',
        'end_time': _taskData['endTime'] != null
            ? '${_taskData['endTime'].hour.toString().padLeft(2, '0')}:${_taskData['endTime'].minute.toString().padLeft(2, '0')}:00'
            : '17:00:00',
        'time_quota_hours': _taskData['maxHours'] ?? 2.0,
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
            : null,
        'time_quota_hours': _taskData['maxHours'] ?? 2.0,
      };
    } else if (_taskData['isPackageTask']) {
      // Special mapping for Package Task: Use Start Date and Start Time
      taskTypeData = {
        'task_name': 'Package Task',
        'start_date': DateFormat('yyyy-MM-dd').format(_taskData['startDate']),
        'start_time': _taskData['startTime'] != null
            ? '${_taskData['startTime'].hour.toString().padLeft(2, '0')}:${_taskData['startTime'].minute.toString().padLeft(2, '0')}:00'
            : '08:30:00',
        'time_quota_hours': _taskData['maxHours'] ?? 0.0,
      };
    } else if (_taskData['taskType'] == 'Bidding Task') {
      taskTypeData = {
        'task_name': 'Bidding Task',
        'start_date': DateFormat(
          'yyyy-MM-dd',
        ).format(_taskData['selectedDate']),
        'end_date': DateFormat('yyyy-MM-dd').format(_taskData['selectedDate']),
        'start_time': _taskData['startTime'] != null
            ? '${_taskData['startTime'].hour.toString().padLeft(2, '0')}:${_taskData['startTime'].minute.toString().padLeft(2, '0')}:00'
            : '09:00:00',
        'end_time': _taskData['endTime'] != null
            ? '${_taskData['endTime'].hour.toString().padLeft(2, '0')}:${_taskData['endTime'].minute.toString().padLeft(2, '0')}:00'
            : null,
        'max_acceptances': _taskData['maxSlots'] ?? 5,
      };
    } else if (_taskData['taskType'] == 'Floating Task') {
      taskTypeData = {
        'task_name': 'Floating Task',
        'start_date': DateFormat('yyyy-MM-dd').format(_taskData['startDate']),
        'end_date': DateFormat('yyyy-MM-dd').format(_taskData['endDate']),
        'start_time': _taskData['startTime'] != null
            ? '${_taskData['startTime'].hour.toString().padLeft(2, '0')}:${_taskData['startTime'].minute.toString().padLeft(2, '0')}:00'
            : '09:00:00',
        'end_time': _taskData['endTime'] != null
            ? '${_taskData['endTime'].hour.toString().padLeft(2, '0')}:${_taskData['endTime'].minute.toString().padLeft(2, '0')}:00'
            : null,
        'time_quota_hours': _taskData['maxHours'] ?? 2.0,
      };
    } else {
      // Default for Task (Long Task) and others
      taskTypeData = {
        'task_name': _taskData['taskType'] == 'Task'
            ? 'Date-Only / Long Task'
            : _taskData['taskType'],
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
          final id = a['user_id'] ?? a['id'];
          if (id is String) return int.tryParse(id) ?? 0;
          return id as int? ?? 0;
        })
        .where((id) => id > 0)
        .toList();

    final bool isMandatory = _taskData['is_mandatory_flag'] ?? false;

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
      'title': _taskData['title'], // Explicitly include title
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
      'is_document': _taskData['is_document'] ?? false,
      'is_pause_allowed': _taskData['allowPause'],
      'closure_ids': closureIds,
      'task_type_data': taskTypeData,
      'requires_approval': _taskData['requiresApproval'] ?? false,
      'approver_id': _taskData['approvalAuthority'] != null
          ? (_taskData['approvalAuthority']!['id'] ??
                _taskData['approvalAuthority']!['user_id'])
          : null,
    };

    // Explicitly add due_date at root for package tracking
    if (_taskData['isPackageTask']) {
      final DateTime? start = _taskData['startDate'];
      final TimeOfDay? startT = _taskData['startTime'];
      final double totalH = _taskData['maxHours'] ?? 0.0;

      if (start != null && startT != null) {
        final DateTime end = _calculatePackageEndTime(start, startT, totalH);
        payload['due_date'] = DateFormat('yyyy-MM-dd').format(end);
        // Also update task_type_data with end info for completeness
        taskTypeData['end_date'] = payload['due_date'];
        taskTypeData['end_time'] =
            '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00';
      }
    }

    if (_taskData['isPackageTask']) {
      double totalStepsHours = 0;
      Set<int> subAssigneeIds = {};
      payload['sub_tasks'] = (_taskData['subTasks'] as List).map((s) {
        final d = (s['duration'] as num?)?.toDouble() ?? 0.0;
        totalStepsHours += d;
        final sid = s['assignee_id'];
        if (sid != null) subAssigneeIds.add(sid as int);
        return {
          'title': s['title'],
          'user_id': sid,
          'order_index': s['order'],
          'allocated_hours': d,
        };
      }).toList();

      // Ensure root assignee_ids includes all sub-task assignees for package robustnes
      for (var sid in subAssigneeIds) {
        if (!assigneeIds.contains(sid)) {
          assigneeIds.add(sid);
        }
      }

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
    final List<Map<String, dynamic>> facultyList =
        List<Map<String, dynamic>>.from(_taskData['facultyInCharge'] ?? []);
    if (facultyList.isNotEmpty) {
      payload['is_faculty'] = true;
      payload['faculty_ids'] = facultyList.map((f) {
        final id = f['id'] ?? f['user_id'];
        if (id is String) return int.tryParse(id) ?? 0;
        return id as int? ?? 0;
      }).toList();
    } else {
      payload['is_faculty'] = false;
      payload['faculty_ids'] = [];
    }

    // Only use individual IDs (Bidding Task removed)
    // Pass as user_id for the assignees in a flat list of integers
    payload['assignee_ids'] = assigneeIds;

    try {
      if (mounted) setState(() => _isSubmitting = true);

      final isEdit = _taskData['task_id'] != null;
      print(
        "========== DIRECTIVE ${isEdit ? 'UPDATE' : 'CREATE'} PAYLOAD ==========",
      );
      print(payload.toString());
      print("==============================================");
      final taskService = TaskService();

      if (isEdit) {
        await taskService.updateTaskUnified(
          _taskData['task_id'],
          payload,
          filePath: _excelFilePath,
        );
      } else {
        await taskService.createTaskUnified(payload, filePath: _excelFilePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Task updated successfully!'
                  : 'Task created successfully!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          'Failed to ${(_taskData['task_id'] != null) ? 'update' : 'create'} task: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    if (_isSubmitting) return;

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
      'title': _taskData['title'], // Explicitly include title
      'task_title_id': _taskData['task_title_id'], // Added task_title_id
      'description': _taskData['description'] ?? '',
      'category': _taskData['category'] ?? 'Academic',
      'priority': 'Medium',
      'priority_level': 2,
      'origin_type': 'self-log',
      'is_document': _taskData['attachDocuments'] ?? false,
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
      if (mounted) setState(() => _isSubmitting = true);

      final isEdit = _taskData['task_id'] != null;
      print(
        "========== SELF LOG ${isEdit ? 'UPDATE' : 'CREATE'} PAYLOAD ==========",
      );
      print(payload.toString());
      print("=============================================");
      final taskService = TaskService();

      if (isEdit) {
        await taskService.updateTaskUnified(
          _taskData['task_id'],
          payload,
          filePath: _excelFilePath,
        );
      } else {
        await taskService.createTaskUnified(payload, filePath: _excelFilePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Activity log updated successfully!'
                  : 'Activity log submitted successfully!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          'Failed to ${(_taskData['task_id'] != null) ? 'update' : 'submit'} log: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                    final List<Map<String, dynamic>>? result =
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const UserSelectionPage(multiSelect: false),
                          ),
                        );

                    if (result != null && result.isNotEmpty) {
                      setState(() {
                        // FIX: Always prioritize user_id (global) over id (table-specific PK)
                        subTask['assignee_id'] =
                            result.first['user_id'] ?? result.first['id'];
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
                    _updatePackageMaxHours();
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
