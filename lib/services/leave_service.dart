import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/leave_model.dart';

class LeaveService {
  final String _baseUrl =
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Apply for leave
  Future<bool> applyLeave({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String fromTime,
    required String toTime,
    required String reason,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${_baseUrl}leaves/apply'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'leave_type': leaveType,
          'from_date': fromDate,
          'to_date': toDate,
          'from_time': fromTime,
          'to_time': toTime,
          'reason': reason,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Apply leave error: $e');
      return false;
    }
  }

  // Get my leaves (Student)
  Future<List<LeaveRecord>> getMyLeaves() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${_baseUrl}leaves/my-leaves'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => LeaveRecord.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get my leaves error: $e');
      return [];
    }
  }

  // Get all leaves (Faculty)
  Future<List<LeaveRecord>> getFacultyLeaves() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${_baseUrl}leaves/faculty/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => LeaveRecord.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get faculty leaves error: $e');
      return [];
    }
  }

  // Get pending leaves (Faculty)
  Future<List<LeaveRecord>> getFacultyPendingLeaves() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${_baseUrl}leaves/faculty/pending'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => LeaveRecord.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get faculty pending leaves error: $e');
      return [];
    }
  }

  // Update leave status (Approve/Reject)
  Future<bool> updateLeaveStatus(int leaveId, String status) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${_baseUrl}leaves/$leaveId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update leave status error: $e');
      return false;
    }
  }
}
