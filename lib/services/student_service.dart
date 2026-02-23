import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/student_model.dart';

class StudentService {
  Future<List<StudentSummary>> getFacultyStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

    final response = await http.get(
      Uri.parse('${backendUrl}users/faculty/mentees'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> assignedStudents = data['assigned_students'] ?? [];
      return assignedStudents
          .map((json) => StudentSummary.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load mentees: ${response.statusCode}');
    }
  }

  Future<StudentDetail> getStudentDetails(int studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

    final response = await http.get(
      Uri.parse('${backendUrl}users/$studentId/activity'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return StudentDetail.fromJson(data);
    } else {
      throw Exception(
        'Failed to load student activity: ${response.statusCode}',
      );
    }
  }
}
