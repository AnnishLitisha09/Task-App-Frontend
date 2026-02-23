class StudentSummary {
  final int id;
  final String name;
  final String email;
  final String registerNumber;
  final String? avatarUrl;
  final double totalScore;
  final double totalPenalty;
  final String department;
  final String year;

  StudentSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.registerNumber,
    this.avatarUrl,
    this.totalScore = 0,
    this.totalPenalty = 0,
    this.department = 'Unknown',
    this.year = 'N/A',
  });

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    return StudentSummary(
      id: json['user_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Student',
      email: json['email'] ?? '',
      registerNumber: json['reg_no'] ?? json['register_number'] ?? 'N/A',
      avatarUrl: json['avatar_url'],
      totalScore: double.tryParse(json['score']?.toString() ?? '0') ?? 0.0,
      totalPenalty: double.tryParse(json['penalty']?.toString() ?? '0') ?? 0.0,
      department:
          json['Department']?['name'] ?? json['department'] ?? 'Unknown',
      year: json['year']?.toString() ?? 'N/A',
    );
  }
}

class StudentDetail extends StudentSummary {
  final List<dynamic> directives;
  final List<dynamic> selfLogs;
  final Map<String, dynamic> attendanceStats;

  StudentDetail({
    required super.id,
    required super.name,
    required super.email,
    required super.registerNumber,
    super.avatarUrl,
    super.totalScore,
    super.totalPenalty,
    super.department,
    super.year,
    this.directives = const [],
    this.selfLogs = const [],
    this.attendanceStats = const {},
  });

  factory StudentDetail.fromJson(Map<String, dynamic> json) {
    // API returns profile inside "profile", and tasks inside "today"
    final profileJson = json['profile'] ?? json;
    var summary = StudentSummary.fromJson(profileJson);

    final todayJson = json['today'] ?? {};

    return StudentDetail(
      id: summary.id,
      name: summary.name,
      email: summary.email,
      registerNumber: summary.registerNumber,
      avatarUrl: summary.avatarUrl,
      totalScore: summary.totalScore,
      totalPenalty: summary.totalPenalty,
      department: summary.department,
      year: summary.year,
      directives: todayJson['directives'] ?? [],
      selfLogs: todayJson['self_logs'] ?? [],
      attendanceStats: json['attendance_stats'] ?? {},
    );
  }
}
