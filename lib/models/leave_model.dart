class LeaveRecord {
  final int id;
  final int userId;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final String fromTime;
  final String toTime;
  final String reason;
  final String status;
  final DateTime createdAt;
  final LeaveUser? user;

  LeaveRecord({
    required this.id,
    required this.userId,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.fromTime,
    required this.toTime,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.user,
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRecord(
      id: json['id'],
      userId: json['user_id'],
      leaveType: json['leave_type'],
      fromDate: json['from_date'],
      toDate: json['to_date'],
      fromTime: json['from_time'],
      toTime: json['to_time'],
      reason: json['reason'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      user: json['User'] != null ? LeaveUser.fromJson(json['User']) : null,
    );
  }
}

class LeaveUser {
  final int userId;
  final String role;
  final Student? student;

  LeaveUser({required this.userId, required this.role, this.student});

  factory LeaveUser.fromJson(Map<String, dynamic> json) {
    return LeaveUser(
      userId: json['user_id'],
      role: json['role'],
      student: json['Student'] != null
          ? Student.fromJson(json['Student'])
          : null,
    );
  }
}

class Student {
  final String name;
  final String regNo;
  final int departmentId;
  final String? departmentName;

  Student({
    required this.name,
    required this.regNo,
    required this.departmentId,
    this.departmentName,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['name'],
      regNo: json['reg_no'],
      departmentId: json['department_id'],
      departmentName: json['Department'] != null
          ? json['Department']['name']
          : null,
    );
  }
}
