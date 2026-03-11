class DepartmentWiseUsers {
  final Map<String, DepartmentDetails> departments;

  DepartmentWiseUsers({required this.departments});

  factory DepartmentWiseUsers.fromJson(Map<String, dynamic> json) {
    Map<String, DepartmentDetails> depts = {};
    json.forEach((key, value) {
      depts[key] = DepartmentDetails.fromJson(value);
    });
    return DepartmentWiseUsers(departments: depts);
  }
}

class DepartmentDetails {
  final DeptUserDetails? hod;
  final List<DeptUserDetails> students;
  final List<DeptUserDetails> faculty;

  DepartmentDetails({this.hod, required this.students, required this.faculty});

  factory DepartmentDetails.fromJson(Map<String, dynamic> json) {
    return DepartmentDetails(
      hod: json['hod'] != null ? DeptUserDetails.fromJson(json['hod']) : null,
      students: (json['students'] as List? ?? [])
          .map((e) => DeptUserDetails.fromJson(e))
          .toList(),
      faculty: (json['faculty'] as List? ?? [])
          .map((e) => DeptUserDetails.fromJson(e))
          .toList(),
    );
  }
}

class DeptUserDetails {
  final int userId;
  final String name;
  final String email;
  final String regNo;

  DeptUserDetails({
    required this.userId,
    required this.name,
    required this.email,
    required this.regNo,
  });

  factory DeptUserDetails.fromJson(Map<String, dynamic> json) {
    return DeptUserDetails(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      regNo: json['reg_no'] ?? '',
    );
  }
}
