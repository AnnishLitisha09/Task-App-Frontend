class UserProfile {
  final int userId;
  final String role;
  final String status;
  final ProfileData profileData;

  UserProfile({
    required this.userId,
    required this.role,
    required this.status,
    required this.profileData,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] ?? 0,
      role: json['role'] ?? 'unknown',
      status: json['status'] ?? 'active',
      profileData: ProfileData.fromJson(json['profile'] ?? {}, json['role']),
    );
  }

  // Helper to normalize role for UI logic
  String get displayRole {
    if (role == 'role-user') {
      // Check for specific assignments if needed, or return generic
      return 'role-user';
    }
    return role;
  }
}

class ProfileData {
  final int id;
  final String name;
  final String email;
  final String? regNo; // For students/faculty
  final String? department; // For students
  final String? designation; // For staff
  final double? score; // For students
  final double? cGpa; // For students
  final String? avatarUrl;
  final double? penalty; // For faculty
  final int? studentCount; // For faculty
  final int? completedTasks; // For staff
  final int? pendingTasks; // For staff
  final Map<String, dynamic> stats; // For HOD/Principal
  final List<RoleAssignment> roleAssignments; // For role-users

  ProfileData({
    required this.id,
    required this.name,
    required this.email,
    this.regNo,
    this.department,
    this.designation,
    this.score,
    this.cGpa,
    this.penalty,
    this.studentCount,
    this.completedTasks,
    this.pendingTasks,
    this.avatarUrl,
    this.stats = const {},
    this.roleAssignments = const [],
  });

  factory ProfileData.fromJson(Map<String, dynamic> json, String? role) {
    // Helper to get nested values safely
    String? getNested(Map map, String key, [String? subKey]) {
      if (map[key] is Map && subKey != null) {
        return map[key][subKey]?.toString();
      }
      return map[key]?.toString();
    }

    // Default Name/Email from profile or AuthAccount
    final name = json['name'] ?? 'User';
    final email =
        json['email'] ?? getNested(json, 'AuthAccount', 'email') ?? '';

    // Specialized parsing based on role (or best effort)

    // Student Specific
    String? regNo = json['reg_no']; // Student/Faculty
    String? department = getNested(json, 'Department', 'name'); // Student
    double? score = double.tryParse(json['total_score']?.toString() ?? '0');
    double? cGpa = double.tryParse(json['c_gpa']?.toString() ?? '0');

    // Faculty Specific
    double? penalty;
    int? studentCount;
    if (role == 'faculty') {
      regNo = json['reg_no'];
      // Assuming penalty is available in faculty profile response
      penalty = double.tryParse(json['penalty']?.toString() ?? '0');
      studentCount = int.tryParse(json['student_count']?.toString() ?? '0');
    }

    // Staff Specific
    String? designation = json['designation'];
    int? completedTasks;
    int? pendingTasks;

    if (role == 'staff') {
      completedTasks = int.tryParse(json['completed_tasks']?.toString() ?? '0');
      pendingTasks = int.tryParse(json['pending_tasks']?.toString() ?? '0');
    }

    // Role User Specific (HOD/Principal)
    List<RoleAssignment> assignments = [];
    Map<String, dynamic> statsParams = {};

    if (json['role_assignments'] != null) {
      var list = json['role_assignments'] as List;
      assignments = list.map((e) => RoleAssignment.fromJson(e)).toList();

      // aggregatestats from first assignment for simplicity or specific logic
      if (assignments.isNotEmpty) {
        statsParams = assignments.first.stats;
      }
    }

    return ProfileData(
      id: json['id'] ?? json['user_id'] ?? 0,
      name: name,
      email: email,
      regNo: regNo,
      department: department,
      designation: designation,
      score: score,
      cGpa: cGpa,
      penalty: penalty,
      studentCount: studentCount,
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      stats: statsParams,
      roleAssignments: assignments,
      // Generate standard avatar if not provided
      avatarUrl:
          'https://ui-avatars.com/api/?name=${name.replaceAll(' ', '+')}&background=random',
    );
  }
}

class RoleAssignment {
  final String role;
  final String department;
  final Map<String, dynamic> stats;

  RoleAssignment({
    required this.role,
    required this.department,
    required this.stats,
  });

  factory RoleAssignment.fromJson(Map<String, dynamic> json) {
    return RoleAssignment(
      role: json['role'] ?? 'User',
      department: json['department'] ?? 'N/A',
      stats: json['stats'] ?? {},
    );
  }
}
