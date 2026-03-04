class DepartmentUsersResponse {
  final bool success;
  final DepartmentInfo department;
  final UserCounts counts;
  final List<DepartmentUser> students;
  final List<DepartmentUser> faculty;

  DepartmentUsersResponse({
    required this.success,
    required this.department,
    required this.counts,
    required this.students,
    required this.faculty,
  });

  factory DepartmentUsersResponse.fromJson(Map<String, dynamic> json) {
    return DepartmentUsersResponse(
      success: json['success'] ?? false,
      department: DepartmentInfo.fromJson(json['department'] ?? {}),
      counts: UserCounts.fromJson(json['counts'] ?? {}),
      students: (json['students'] as List? ?? [])
          .map((e) => DepartmentUser.fromJson(e, 'student'))
          .toList(),
      faculty: (json['faculty'] as List? ?? [])
          .map((e) => DepartmentUser.fromJson(e, 'faculty'))
          .toList(),
    );
  }
}

class DepartmentInfo {
  final int id;
  final String name;

  DepartmentInfo({required this.id, required this.name});

  factory DepartmentInfo.fromJson(Map<String, dynamic> json) {
    return DepartmentInfo(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class UserCounts {
  final int totalStudents;
  final int totalFaculty;

  UserCounts({required this.totalStudents, required this.totalFaculty});

  factory UserCounts.fromJson(Map<String, dynamic> json) {
    return UserCounts(
      totalStudents: json['total_students'] ?? 0,
      totalFaculty: json['total_faculty'] ?? 0,
    );
  }
}

class DepartmentUser {
  final int userId;
  final String name;
  final String regNo;
  final String email;
  final int? year;
  final String? cGpa;
  final String score;
  final String penalty;
  final String status;
  final String? designation;
  final String userType; // 'student' or 'faculty'

  DepartmentUser({
    required this.userId,
    required this.name,
    required this.regNo,
    required this.email,
    this.year,
    this.cGpa,
    required this.score,
    required this.penalty,
    required this.status,
    this.designation,
    required this.userType,
  });

  factory DepartmentUser.fromJson(Map<String, dynamic> json, String type) {
    return DepartmentUser(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      regNo: json['reg_no'] ?? '',
      email: json['email'] ?? '',
      year: json['year'],
      cGpa: json['c_gpa'],
      score: json['score']?.toString() ?? '0.00',
      penalty: json['penalty']?.toString() ?? '0.00',
      status: json['status'] ?? 'active',
      designation: json['designation'],
      userType: type,
    );
  }
}
