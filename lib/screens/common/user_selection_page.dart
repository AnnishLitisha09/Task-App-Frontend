import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';

class UserSelectionPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialSelection;
  final bool multiSelect;
  final List<String>? allowedRoles;

  const UserSelectionPage({
    super.key,
    this.initialSelection = const [],
    this.multiSelect = true,
    this.allowedRoles,
  });

  @override
  State<UserSelectionPage> createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  // Navigation State
  int _currentLevel = 0; // 0: Role, 1: Dept, 2: Users
  String? _selectedRole;
  String? _selectedDept;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // API state
  final UserService _userService = UserService();
  Map<String, dynamic>? _apiData;
  bool _isLoading = true;
  String? _errorMessage;

  // Selection State
  late List<Map<String, dynamic>> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelection);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await _userService.getUsersByDepartment();
      if (mounted) {
        setState(() {
          _apiData = data;
          _isLoading = false;

          // Auto-select role if only one allowed
          if (widget.allowedRoles != null && widget.allowedRoles!.length == 1) {
            _selectedRole = widget.allowedRoles!.first;
            _currentLevel = 1;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _goBack() {
    if (_currentLevel >
        (widget.allowedRoles != null && widget.allowedRoles!.length == 1
            ? 1
            : 0)) {
      setState(() {
        _currentLevel--;
        if (_currentLevel == 0) _selectedRole = null;
        if (_currentLevel == 1) _selectedDept = null;
      });
    } else {
      Navigator.pop(context, _selectedItems);
    }
  }

  bool _isSelected(String id) {
    return _selectedItems.any(
      (u) => u['id'] == id || u['user_id']?.toString() == id,
    );
  }

  void _toggleItem(Map<String, dynamic> item) {
    // Users from API often don't have a 'type' field, while roles and depts do.
    final isRoleOrDept = item['type'] == 'role' || item['type'] == 'dept';

    if (!isRoleOrDept) {
      final id = (item['id'] ?? item['user_id'])?.toString() ?? '';
      setState(() {
        if (_isSelected(id)) {
          if (widget.multiSelect) {
            _selectedItems.removeWhere(
              (u) => (u['id'] ?? u['user_id'])?.toString() == id,
            );
          }
        } else {
          if (!widget.multiSelect) {
            _selectedItems = [item];
            Navigator.pop(context, _selectedItems);
          } else {
            _selectedItems.add(item);
          }
        }
      });
    } else {
      // Handle Group Toggle (Role or Dept)
      List<Map<String, dynamic>> usersInGroup = [];
      if (item['type'] == 'role') {
        final roleKey = item['roleKey'];
        if (roleKey == 'staff') {
          usersInGroup = List<Map<String, dynamic>>.from(
            _apiData!['staff'] ?? [],
          );
        } else {
          final Map<String, dynamic> depts = _apiData![roleKey] ?? {};
          for (var deptUsers in depts.values) {
            usersInGroup.addAll(List<Map<String, dynamic>>.from(deptUsers));
          }
        }
      } else if (item['type'] == 'dept') {
        final Map<String, dynamic> depts = _apiData![_selectedRole!] ?? {};
        usersInGroup = List<Map<String, dynamic>>.from(
          depts[item['name']] ?? [],
        );
      }

      setState(() {
        final allInGroupSelected = usersInGroup.every(
          (u) => _isSelected((u['user_id'] ?? u['id']).toString()),
        );

        if (allInGroupSelected) {
          // Deselect all
          for (var u in usersInGroup) {
            final uid = (u['user_id'] ?? u['id']).toString();
            _selectedItems.removeWhere(
              (existing) =>
                  (existing['user_id'] ?? existing['id']).toString() == uid,
            );
          }
        } else {
          // Select all (avoid duplicates)
          for (var u in usersInGroup) {
            final uid = (u['user_id'] ?? u['id']).toString();
            if (!_isSelected(uid)) {
              _selectedItems.add(u);
            }
          }
        }
      });
    }
  }

  int _getUserCount(String type, {String? roleKey, String? deptName}) {
    if (_apiData == null) return 0;
    if (type == 'role') {
      if (roleKey == 'staff') return (_apiData!['staff'] as List?)?.length ?? 0;
      final Map<String, dynamic>? depts =
          _apiData![roleKey] as Map<String, dynamic>?;
      if (depts == null) return 0;
      int count = 0;
      for (var userList in depts.values) {
        count += (userList as List).length;
      }
      return count;
    } else if (type == 'dept') {
      final Map<String, dynamic>? depts =
          _apiData![_selectedRole!] as Map<String, dynamic>?;
      return (depts?[deptName] as List?)?.length ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // ... rest of build method ...
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: _goBack,
        ),
        title: _currentLevel == 0 && _searchQuery.isEmpty
            ? const Text(
                "Select Role",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : _buildSearchField(),
        actions: [
          if (_selectedItems.isNotEmpty && widget.multiSelect)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_selectedItems.length} Selected",
                    style: const TextStyle(
                      color: AppTheme.brandAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildBreadcrumbs(),
          Expanded(child: _buildCurrentLevelView()),
          if (widget.multiSelect) _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    if (_currentLevel == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: Colors.grey[50],
      width: double.infinity,
      child: Row(
        children: [
          Text(
            _selectedRole ?? "",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          if (_selectedDept != null) ...[
            const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
            Text(
              _selectedDept!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: false,
      decoration: InputDecoration(
        hintText: _currentLevel == 0
            ? "Search Roles..."
            : (_currentLevel == 1
                  ? "Search Departments..."
                  : "Search Users..."),
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      style: const TextStyle(color: Colors.black, fontSize: 16),
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
    );
  }

  Widget _buildCurrentLevelView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            TextButton(onPressed: _fetchUserData, child: const Text("Retry")),
          ],
        ),
      );
    }
    if (_apiData == null) return const SizedBox.shrink();

    if (_currentLevel == 0) return _buildRoleList();
    if (_currentLevel == 1) return _buildDeptList();
    return _buildUserList();
  }

  Widget _buildRoleList() {
    final List<Map<String, dynamic>> roles = [
      {
        'title': "All Students",
        'subtitle': "Grouped by Department",
        'icon': Icons.groups_rounded,
        'type': 'role',
        'id': 'role_students',
        'roleKey': 'students',
      },
      {
        'title': "All Faculty",
        'subtitle': "Grouped by Department",
        'icon': Icons.person_search_rounded,
        'type': 'role',
        'id': 'role_faculty',
        'roleKey': 'faculty',
      },
      {
        'title': "Principal",
        'subtitle': "Institutional Head",
        'icon': Icons.account_box_rounded,
        'type': 'role',
        'id': 'role_principal',
        'roleKey': 'principal',
      },
      {
        'title': "Dean",
        'subtitle': "Institutional Dean",
        'icon': Icons.school_rounded,
        'type': 'role',
        'id': 'role_dean',
        'roleKey': 'dean',
      },
      {
        'title': "HODs",
        'subtitle': "Department Heads",
        'icon': Icons.admin_panel_settings_rounded,
        'type': 'role',
        'id': 'role_hods',
        'roleKey': 'hods',
      },
      {
        'title': "Staff",
        'subtitle': "Technical & Admin Staff",
        'icon': Icons.badge_rounded,
        'type': 'role',
        'id': 'role_staff',
        'roleKey': 'staff',
      },
    ];

    // Filter by allowedRoles
    final filteredRoles = widget.allowedRoles == null
        ? roles
        : roles
              .where(
                (r) =>
                    widget.allowedRoles!.contains(r['roleKey']) ||
                    widget.allowedRoles!.contains(
                      r['title'].toString().replaceFirst('All ', ''),
                    ),
              )
              .toList();

    // Filter by search query
    final displayRoles = _searchQuery.isEmpty
        ? filteredRoles
        : filteredRoles
              .where(
                (r) => r['title'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: displayRoles.length,
      itemBuilder: (context, index) {
        final role = displayRoles[index];
        final count = _getUserCount('role', roleKey: role['roleKey']);
        return _selectionTile(
          title: "${role['title']} ($count)",
          subtitle: role['subtitle'],
          icon: role['icon'],
          type: role['type'],
          id: role['id'],
          roleKey: role['roleKey'],
          onTap: () => setState(() {
            _selectedRole = role['roleKey'];
            // Staff jump straight to users (level 2) since it's a flat list
            if (_selectedRole == 'staff') {
              _currentLevel = 2;
              _selectedDept = 'Staff';
            } else {
              _currentLevel = 1;
            }
            _searchQuery = "";
            _searchController.clear();
          }),
        );
      },
    );
  }

  Widget _buildDeptList() {
    final Map<String, dynamic> roleDepts =
        _apiData![_selectedRole] as Map<String, dynamic>? ?? {};
    final depts = roleDepts.keys.toList();

    final displayDepts = _searchQuery.isEmpty
        ? depts
        : depts
              .where(
                (d) => d.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: displayDepts.length,
      itemBuilder: (context, index) {
        final deptName = displayDepts[index];
        final id = "dept_${_selectedRole}_$deptName";
        final count = _getUserCount('dept', deptName: deptName);
        return _selectionTile(
          title: "$deptName ($count)",
          subtitle: "Target all in $deptName",
          icon: Icons.account_balance_rounded,
          type: 'dept',
          id: id,
          onTap: () => setState(() {
            _selectedDept = deptName;
            _currentLevel = 2;
            _searchQuery = "";
            _searchController.clear();
          }),
        );
      },
    );
  }

  Widget _buildUserList() {
    List<Map<String, dynamic>> users = [];

    if (_selectedRole == 'staff') {
      users = List<Map<String, dynamic>>.from(_apiData!['staff'] ?? []);
    } else {
      final Map<String, dynamic> roleDepts =
          _apiData![_selectedRole] as Map<String, dynamic>? ?? {};
      users = List<Map<String, dynamic>>.from(roleDepts[_selectedDept] ?? []);
    }

    final displayUsers = _searchQuery.isEmpty
        ? users
        : users
              .where(
                (u) => (u['name'] ?? '').toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    if (displayUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No individual users found",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: displayUsers.length,
      itemBuilder: (context, index) {
        final user = displayUsers[index];
        final id = (user['user_id'] ?? user['id'])?.toString() ?? '';
        final isSelected = _isSelected(id);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.brandAccent.withOpacity(0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.brandAccent : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? AppTheme.brandAccent
                  : Colors.grey[100],
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.person_rounded,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
            ),
            title: Text(
              user['name'] ?? "Unknown",
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.brandAccent : Colors.black87,
              ),
            ),
            subtitle: Text(
              user['type'] ?? user['designation'] ?? _selectedRole ?? "",
              style: const TextStyle(fontSize: 12),
            ),
            trailing: widget.multiSelect
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleItem(user),
                    activeColor: AppTheme.brandAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () => _toggleItem(user),
          ),
        );
      },
    );
  }

  Widget _selectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String type,
    required String id,
    required VoidCallback onTap,
    String? roleKey,
  }) {
    List<Map<String, dynamic>> usersInGroup = [];
    if (type == 'role') {
      if (roleKey == 'staff') {
        usersInGroup = List<Map<String, dynamic>>.from(
          _apiData!['staff'] ?? [],
        );
      } else if (roleKey != null) {
        final Map<String, dynamic> depts = _apiData![roleKey] ?? {};
        for (var deptUsers in depts.values) {
          usersInGroup.addAll(List<Map<String, dynamic>>.from(deptUsers));
        }
      }
    } else if (type == 'dept') {
      final Map<String, dynamic> depts = _apiData![_selectedRole!] ?? {};
      final deptName = title.split(' (').first; // Extract name from title
      usersInGroup = List<Map<String, dynamic>>.from(depts[deptName] ?? []);
    }

    final isSelectedItem =
        usersInGroup.isNotEmpty &&
        usersInGroup.every(
          (u) => _isSelected((u['user_id'] ?? u['id']).toString()),
        );
    final isPartiallySelected =
        !isSelectedItem &&
        usersInGroup.any(
          (u) => _isSelected((u['user_id'] ?? u['id']).toString()),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelectedItem
            ? AppTheme.brandAccent.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelectedItem ? AppTheme.brandAccent : Colors.grey[200]!,
          width: isSelectedItem ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelectedItem
                ? AppTheme.brandAccent
                : AppTheme.brandAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelectedItem ? Colors.white : AppTheme.brandAccent,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.multiSelect)
              Checkbox(
                value: isSelectedItem,
                tristate: true,
                onChanged: (_) => _toggleItem({
                  'id': id,
                  'name': title.split(' (').first,
                  'type': type,
                  'roleKey': roleKey,
                }),
                activeColor: AppTheme.brandAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (isPartiallySelected) {
                    return AppTheme.brandAccent.withOpacity(0.5);
                  }
                  return null;
                }),
              ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedItems),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Confirm Selection",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
