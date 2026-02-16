class FacultyInfo {
  final int id;
  final String name;
  final String email;
  final String regNo;
  final String department;
  final String type;

  FacultyInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.regNo,
    required this.department,
    required this.type,
  });

  factory FacultyInfo.fromJson(Map<String, dynamic> json) {
    return FacultyInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      regNo: json['reg_no'] ?? '',
      department: json['department'] ?? '',
      type: json['type'] ?? '',
    );
  }
}
