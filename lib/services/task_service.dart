import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/task_detail_model.dart';
import '../models/daily_report_model.dart';
import '../models/venue_dashboard_model.dart';
import '../models/venue_history_model.dart';
import '../models/managed_venues_model.dart';

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
        return data;
      } else {
        throw Exception(
          'Failed to load pending proofs: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching pending proofs: $e');
    }
  }

  Future<dynamic> getFacultyDashboardStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/faculty/stats/daily'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load faculty stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching faculty stats: $e');
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

  Future<VenueDetailsResponse> getVenueDetails({int? venueId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      String url = '${backendUrl}tasks/venue-details';
      if (venueId != null) {
        url += '?venue_id=$venueId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VenueDetailsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load venue details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching venue details: $e');
    }
  }

  Future<VenueDetailsResponse> getVenueDashboard() async {
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
        return VenueDetailsResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load venue dashboard: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching venue dashboard: $e');
    }
  }

  Future<ManagedVenuesResponse> getManagedVenues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/venues/my-list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ManagedVenuesResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load managed venues: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching managed venues: $e');
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

  Future<void> closeTask(
    int taskId, {
    required bool isCompleted,
    int? closureId,
    String? proof,
    String? reason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final Map<String, dynamic> payload = {'is_completed': isCompleted};
      if (closureId != null) payload['closure_id'] = closureId;
      if (proof != null) payload['proof'] = proof;
      if (reason != null) payload['reason'] = reason;

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/$taskId/close'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to close task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error closing task: $e');
    }
  }

  Future<dynamic> getPendingTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/pending'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load pending tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching pending tasks: $e');
    }
  }

  Future<List<dynamic>> getAllTasksToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('tasks')) {
          return data['tasks'] as List;
        }
        if (data is List) return data;
        return [];
      } else {
        throw Exception("Failed to load today's tasks: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching today's tasks: $e");
    }
  }

  Future<List<dynamic>> getEscalations({bool unread = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse(
          '${backendUrl}tasks/escalations/me${unread ? "?unread=true" : ""}',
        ),
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
        if (data is Map<String, dynamic> && data.containsKey('escalations')) {
          return data['escalations'] as List<dynamic>;
        }
        return data as List<dynamic>;
      } else {
        throw Exception('Failed to load escalations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching escalations: $e');
    }
  }

  Future<VenueHistoryResponse> getVenueHistory({
    int? venueId,
    int days = 7,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      String url = '${backendUrl}tasks/venue-history?days=$days';
      if (venueId != null) {
        url += '&venue_id=$venueId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VenueHistoryResponse.fromJson(data);
      } else {
        throw Exception('Failed to load venue history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching venue history: $e');
    }
  }

  Future<Map<String, dynamic>> generateOTP(int taskId, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/otp/generate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'task_id': taskId, 'type': type}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Handle variations in key names
        if (!data.containsKey('otp_code') && data.containsKey('data')) {
          if (data['data'] is Map && data['data'].containsKey('otp_code')) {
            return data['data'];
          }
        }
        return data;
      } else {
        throw Exception('Failed to generate: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating OTP: $e');
    }
  }

  Future<Map<String, dynamic>> verifyOTP(
    int assignmentId,
    String otpCode,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/otp/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'assignment_id': assignmentId,
          'otp_code': otpCode.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception('OTP Verification Error: $e');
    }
  }

  Future<void> acknowledgeGeneral() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/acknowledge-general'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to acknowledge: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error acknowledging: $e');
    }
  }
}
