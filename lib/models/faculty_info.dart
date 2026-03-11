class FacultyInfo {
  final int id;
  final String name;
  final String? email;
  final String? regNo;
  final String department;
  final String type;
  final int menteeCount;
  final String penalty;

  FacultyInfo({
    required this.id,
    required this.name,
    this.email,
    this.regNo,
    required this.department,
    required this.type,
    this.menteeCount = 0,
    this.penalty = '0.00',
  });

  factory FacultyInfo.fromJson(Map<String, dynamic> json) {
    return FacultyInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      regNo: json['reg_no'],
      department: json['department'] ?? '',
      type: json['type'] ?? '',
      menteeCount: (json['mentee_count'] as num?)?.toInt() ?? 0,
      penalty: json['penalty']?.toString() ?? '0.00',
    );
  }
}
