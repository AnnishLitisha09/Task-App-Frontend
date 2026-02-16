import 'faculty_info.dart';

class FacultyProfile {
  final FacultyInfo facultyInfo;
  final List<dynamic> assignedStudents;
  final int studentCount;

  FacultyProfile({
    required this.facultyInfo,
    required this.assignedStudents,
    required this.studentCount,
  });

  factory FacultyProfile.fromJson(Map<String, dynamic> json) {
    return FacultyProfile(
      facultyInfo: FacultyInfo.fromJson(json['faculty_info'] ?? {}),
      assignedStudents: json['assigned_students'] ?? [],
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    );
  }
}
