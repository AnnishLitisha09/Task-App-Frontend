import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class UserSelectionPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialSelection;
  final bool multiSelect;
  final List<String>? allowedRoles; // NEW: To filter roles (e.g., ["Faculty", "HOD"])

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

  // Selection State
  late List<Map<String, dynamic>> _selectedItems;

  // Mock Data
  final Map<String, List<String>> _roleToDepts = {
    'Students': ['IT', 'Computer Science', 'Mechanical', 'Electrical'],
    'Faculty': ['IT', 'Computer Science', 'Physics', 'Mathematics'],
    'Staff': ['Administration', 'Maintenance', 'Library'],
  };

  final Map<String, List<Map<String, dynamic>>> _deptToUsers = {
    'IT': [
      {'id': 's1', 'name': 'Aditya Kumar', 'role': 'Student', 'type': 'user'},
      {'id': 's2', 'name': 'Bhavya Singh', 'role': 'Student', 'type': 'user'},
      {'id': 'f1', 'name': 'Dr. Ramesh Rao', 'role': 'Faculty', 'type': 'user'},
    ],
    'Computer Science': [
      {'id': 's3', 'name': 'Chirag Gupta', 'role': 'Student', 'type': 'user'},
      {'id': 's4', 'name': 'Deepak Verma', 'role': 'Student', 'type': 'user'},
      {
        'id': 'f2',
        'name': 'Prof. Sunita Williams',
        'role': 'Faculty',
        'type': 'user',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelection);
    if (widget.allowedRoles != null && widget.allowedRoles!.length == 1) {
      _selectedRole = widget.allowedRoles!.first;
      _currentLevel = 1;
    }
  }

  void _goBack() {
    if (_currentLevel > (widget.allowedRoles != null && widget.allowedRoles!.length == 1 ? 1 : 0)) {
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
    return _selectedItems.any((u) => u['id'] == id);
  }

  void _toggleItem(Map<String, dynamic> item) {
    setState(() {
      if (_isSelected(item['id'])) {
        if (widget.multiSelect) {
          _selectedItems.removeWhere((u) => u['id'] == item['id']);
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
  }

  @override
  Widget build(BuildContext context) {
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
        hintText: _currentLevel == 0 ? "Search Roles..." : (_currentLevel == 1 ? "Search Departments..." : "Search Users..."),
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
    if (_currentLevel == 0) return _buildRoleList();
    if (_currentLevel == 1) return _buildDeptList();
    return _buildUserList();
  }

  Widget _buildRoleList() {
    final List<Map<String, dynamic>> roles = [
      {
        'title': "All Students",
        'subtitle': "Target entire Student community",
        'icon': Icons.groups_rounded,
        'type': 'role',
        'id': 'role_students',
        'roleName': 'Students',
      },
      {
        'title': "All Faculty",
        'subtitle': "Target entire Faculty community",
        'icon': Icons.person_search_rounded,
        'type': 'role',
        'id': 'role_faculty',
        'roleName': 'Faculty',
      },
      {
        'title': "All Staff",
        'subtitle': "Target entire Staff community",
        'icon': Icons.badge_rounded,
        'type': 'role',
        'id': 'role_staff',
        'roleName': 'Staff',
      },
    ];

    // Filter by allowedRoles
    final filteredRoles = widget.allowedRoles == null 
        ? roles 
        : roles.where((r) => widget.allowedRoles!.contains(r['roleName'])).toList();

    // Filter by search query
    final displayRoles = _searchQuery.isEmpty 
        ? filteredRoles 
        : filteredRoles.where((r) => r['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: displayRoles.length,
      itemBuilder: (context, index) {
        final role = displayRoles[index];
        return _selectionTile(
          title: role['title'],
          subtitle: role['subtitle'],
          icon: role['icon'],
          type: role['type'],
          id: role['id'],
          onTap: () => setState(() {
            _selectedRole = role['roleName'];
            _currentLevel = 1;
            _searchQuery = ""; // Reset search on drill down
            _searchController.clear();
          }),
        );
      },
    );
  }

  Widget _buildDeptList() {
    final depts = _roleToDepts[_selectedRole] ?? [];
    final displayDepts = _searchQuery.isEmpty 
        ? depts 
        : depts.where((d) => d.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: displayDepts.length,
      itemBuilder: (context, index) {
        final deptName = displayDepts[index];
        final id = "dept_${_selectedRole}_$deptName";
        return _selectionTile(
          title: deptName,
          subtitle: "Target all in $deptName",
          icon: Icons.account_balance_rounded,
          type: 'dept',
          id: id,
          onTap: () => setState(() {
            _selectedDept = deptName;
            _currentLevel = 2;
            _searchQuery = ""; // Reset search
            _searchController.clear();
          }),
        );
      },
    );
  }

  Widget _buildUserList() {
    final users = _deptToUsers[_selectedDept] ?? [];
    final displayUsers = _searchQuery.isEmpty 
        ? users 
        : users.where((u) => u['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

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
        final isSelected = _isSelected(user['id']);
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
              user['name'],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.brandAccent : Colors.black87,
              ),
            ),
            subtitle: Text(user['role'], style: const TextStyle(fontSize: 12)),
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
  }) {
    final isSelectedItem = _isSelected(id);
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
                onChanged: (_) =>
                    _toggleItem({'id': id, 'name': title, 'type': type}),
                activeColor: AppTheme.brandAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
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
