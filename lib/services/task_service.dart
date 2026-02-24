import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/task_detail_model.dart';
import '../models/daily_report_model.dart';
import '../models/venue_dashboard_model.dart';

class TaskService {
  Future<TaskDetailModel> getTaskDetail(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/$taskId/detail'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TaskDetailModel.fromJson(data);
      } else {
        throw Exception('Failed to load task details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching task details: $e');
    }
  }

  Future<dynamic> getPendingProofs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/pending-proof'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // Return the raw response (can be Map or List)
      } else {
        throw Exception(
          'Failed to load pending proofs: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching pending proofs: $e');
    }
  }

  Future<Map<String, dynamic>> createTaskUnified(
    Map<String, dynamic> payload,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/unified-create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<Map<String, dynamic>> getMonthlySchedule(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      // Format date as YYYY-MM-DD
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/schedule/monthly?date=$dateStr'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to load monthly schedule: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching monthly schedule: $e');
    }
  }

  Future<DailyReportModel> getDailyReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/daily-report'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DailyReportModel.fromJson(data);
      } else {
        throw Exception('Failed to load daily report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching daily report: $e');
    }
  }

  Future<VenueDashboardResponse> getVenueDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/venue-dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VenueDashboardResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load venue dashboard: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching venue dashboard: $e');
    }
  }

  Future<List<dynamic>> getTaskTitles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/titles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as List<dynamic>;
      } else {
        throw Exception('Failed to load task titles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching task titles: $e');
    }
  }

  Future<void> acceptTask(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/$taskId/accept'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to accept task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error accepting task: $e');
    }
  }

  Future<void> rejectTask(
    int taskId,
    String reason, {
    int? transferToUserId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final payload = {'reason': reason};
      if (transferToUserId != null) {
        payload['transfer_to_user_id'] = transferToUserId.toString();
      }

      final response = await http.put(
        Uri.parse('${backendUrl}tasks/$taskId/reject'),

        // Uri.parse('${backendUrl}tasks/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reject task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error rejecting task: $e');
    }
  }

  Future<List<dynamic>> getEscalations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/escalations/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return data['data'] as List<dynamic>;
        }
        return data as List<dynamic>;
      } else {
        throw Exception('Failed to load escalations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching escalations: $e');
    }
  }
}
