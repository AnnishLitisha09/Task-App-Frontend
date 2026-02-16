import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserSearchDialog extends StatefulWidget {
  final String title;
  const UserSearchDialog({super.key, this.title = "Transfer Task To"});

  @override
  State<UserSearchDialog> createState() => _UserSearchDialogState();

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? title,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          UserSearchDialog(title: title ?? "Transfer Task To"),
    );
  }
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Mock users data
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': '1',
      'name': 'Dr. Sarah Smith',
      'role': 'HOD - CS',
      'dept': 'Computer Science',
    },
    {
      'id': '2',
      'name': 'Prof. James Wilson',
      'role': 'Faculty',
      'dept': 'Information Tech',
    },
    {
      'id': '3',
      'name': 'Ms. Emily Davis',
      'role': 'Staff',
      'dept': 'Administration',
    },
    {
      'id': '4',
      'name': 'Dr. Robert Brown',
      'role': 'Principal',
      'dept': 'Institution',
    },
    {
      'id': '5',
      'name': 'Prof. Michael Chen',
      'role': 'Faculty',
      'dept': 'Mechanical',
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _mockUsers;
    return _mockUsers.where((user) {
      final name = user['name'].toString().toLowerCase();
      final role = user['role'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          role.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppTheme.h1.copyWith(fontSize: 20)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: "Search faculty or staff...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 48,
                            color: AppTheme.textSub.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text("No users found", style: AppTheme.bodySub),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.brandAccent.withOpacity(
                              0.1,
                            ),
                            child: Text(
                              user['name'][0],
                              style: const TextStyle(
                                color: AppTheme.brandAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(user['name'], style: AppTheme.bodyMain),
                          subtitle: Text(
                            "${user['role']} • ${user['dept']}",
                            style: AppTheme.bodySub.copyWith(fontSize: 12),
                          ),
                          onTap: () => Navigator.pop(context, user),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
