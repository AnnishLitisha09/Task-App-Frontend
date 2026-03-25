import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../models/task_detail_model.dart';
import '../models/daily_report_model.dart';
import '../services/venue_notifier.dart';
import '../models/venue_dashboard_model.dart';
import '../models/venue_history_model.dart';
import '../models/managed_venues_model.dart';
import '../models/exhaustive_task_model.dart';

class TaskService {
  Future<Map<String, dynamic>> getTaskDetails(dynamic taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/${taskId.toString()}/details'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // New endpoint returns {success: true, task: {...}}
        if (data['success'] == true && data['task'] != null) {
          return data['task'] as Map<String, dynamic>;
        }
        return data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load task details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching task details: $e');
    }
  }

  Future<TaskDetailModel> getTaskDetail(dynamic taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/${taskId.toString()}/detail'),
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

  /// Submit proof document for a task that is already accepted/in-progress.
  /// This uses the dedicated /submit-proof endpoint with real file upload.
  Future<void> submitTaskProof(
    int taskId, {
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    int? obtainedScore,
    int? penalty,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final url = Uri.parse('${backendUrl}tasks/$taskId/submit-proof');
      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';

      if (obtainedScore != null) {
        request.fields['obtained_score'] = obtainedScore.toString();
      }
      if (penalty != null) {
        request.fields['penalty'] = penalty.toString();
      }

      if (kIsWeb && fileBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      } else if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        final errBody = jsonDecode(resp.body);
        throw Exception(errBody['message'] ?? 'Proof submission failed');
      }
    } catch (e) {
      throw Exception('Submit proof error: $e');
    }
  }

  /// Fallback JSON-based proof submit API if the backend doesn't support Multipart
  Future<void> submitTaskProofFallback(
    int taskId, {
    String? proof,
    int? obtainedScore,
    int? penalty,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final url = Uri.parse('${backendUrl}tasks/$taskId/submit-proof');
      
      final Map<String, dynamic> body = {};
      if (proof != null) body['proof'] = proof;
      if (obtainedScore != null) body['obtained_score'] = obtainedScore;
      if (penalty != null) body['penalty'] = penalty;

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Proof submission failed');
      }
    } catch (e) {
      throw Exception('Submit proof error: $e');
    }
  }

  Future<dynamic> getPendingVerifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/verification/pending'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load pending verifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching pending verifications: $e');
    }
  }

  Future<dynamic> getFacultyDashboardStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final selectedVenueId = VenueNotifier.currentVenueId;
      String urlStr = '${backendUrl}users/faculty/stats/daily';
      if (selectedVenueId != null) {
        urlStr += '?venue_id=$selectedVenueId';
      }

      final response = await http.get(
        Uri.parse(urlStr),
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
    Map<String, dynamic> payload, {
    String? filePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final url = Uri.parse('${backendUrl}tasks/unified-create');

      // Use MultipartRequest to support file upload
      final request = http.MultipartRequest('POST', url);

      // Add Headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add Fields (JSON payload)
      // The backend expects flat fields or JSON strings for nested objects
      payload.forEach((key, value) {
        if (value is Map || value is List) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      });

      // Add File if exists
      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to create task: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<Map<String, dynamic>> updateTaskUnified(
    int taskId,
    Map<String, dynamic> payload, {
    String? filePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final url = Uri.parse('${backendUrl}tasks/$taskId');

      // Use MultipartRequest to support file upload (via PUT)
      final request = http.MultipartRequest('PUT', url);

      // Add Headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add Fields (JSON payload)
      payload.forEach((key, value) {
        if (value != null) {
          if (value is Map || value is List) {
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Add File if exists
      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to update task: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  Future<Map<String, dynamic>> getMonthlySchedule(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

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

      int? vId = venueId ?? prefs.getInt('selectedVenueId');
      String url = '${backendUrl}tasks/venue-details';
      if (vId != null) {
        url += '?venue_id=$vId';
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

      int? vId = prefs.getInt('selectedVenueId');
      String url = '${backendUrl}tasks/venue-dashboard';
      if (vId != null) {
        url += '?venue_id=$vId';
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
        throw Exception(
          'Failed to load venue dashboard: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching venue dashboard: $e');
    }
  }

  Future<void> updateVenueStatus(
    int venueId,
    String status,
    String reason,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.put(
        Uri.parse('${backendUrl}tasks/venue/$venueId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status, 'reason': reason}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update venue status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating venue status: $e');
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
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Failed to accept task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error accepting task: $e');
    }
  }

  /// Approve a task as the designated higher-authority approver (approver_id).
  Future<void> approveTask(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.put(
        Uri.parse('${backendUrl}tasks/$taskId/approve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Failed to approve task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving task: $e');
    }
  }

  Future<void> selfAssignTask(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/$taskId/self-assign'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Failed to self-assign task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error self-assigning task: $e');
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
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Failed to reject task: ${response.statusCode}');
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
    int? obtainedScore,
    int? penalty,
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
      if (obtainedScore != null) payload['obtained_score'] = obtainedScore;
      if (penalty != null) payload['penalty'] = penalty;

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/$taskId/close'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Failed to close task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error closing task: $e');
    }
  }

  Future<ExhaustiveTaskModel> getExhaustiveTaskDetail(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/$taskId/exhaustive'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExhaustiveTaskModel.fromJson(data);
      } else {
        final errBody = jsonDecode(response.body);
        throw Exception(
          errBody['message'] ?? 'Failed to load exhaustive details: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching exhaustive task details: $e');
    }
  }

  Future<List<dynamic>> getUnacknowledgedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/today/unacknowledged'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load unacknowledged tasks: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching unacknowledged tasks: $e');
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
        body: jsonEncode({}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to acknowledge: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error acknowledging: $e');
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

      int? vId = venueId ?? prefs.getInt('selectedVenueId');
      String url = '${backendUrl}tasks/venue-history?days=$days';
      if (vId != null) {
        url += '&venue_id=$vId';
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

  Future<Map<String, dynamic>> generateOTP(int taskId, String otpType) async {
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
        body: jsonEncode({'task_id': taskId, 'type': otpType}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Failed to generate: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating OTP: $e');
    }
  }

  Future<Map<String, dynamic>> verifyOTP(
    int assignmentId,
    String otpCode, {
    String? filePath,
    int? obtainedScore,
    int? penalty,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final url = Uri.parse('${backendUrl}tasks/otp/verify');
      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['assignment_id'] = assignmentId.toString();
      request.fields['otp_code'] = otpCode.trim();
      
      if (obtainedScore != null) {
        request.fields['obtained_score'] = obtainedScore.toString();
      }
      if (penalty != null) {
        request.fields['penalty'] = penalty.toString();
      }

      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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

  Future<dynamic> getPendingTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/pending-upcoming'),
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

  Future<void> reviewTaskProof(int assignmentId, String status,
      {String? reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/assignment/$assignmentId/review-proof'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'reason': reason,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Review failed');
      }
    } catch (e) {
      throw Exception('Review Error: $e');
    }
  }

  Future<void> startActivity(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/$taskId/start-activity'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Start failed');
      }
    } catch (e) {
      throw Exception('Start Error: $e');
    }
  }

  Future<void> pauseTask(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.put(
        Uri.parse('${backendUrl}tasks/$taskId/pause'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Pause failed');
      }
    } catch (e) {
      throw Exception('Pause Error: $e');
    }
  }

  Future<void> resumeTask(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.put(
        Uri.parse('${backendUrl}tasks/$taskId/resume'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Resume failed');
      }
    } catch (e) {
      throw Exception('Resume Error: $e');
    }
  }

  Future<void> transferTask(int taskId, int transferToUserId, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/$taskId/transfer'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'transfer_to_user_id': transferToUserId,
          'reason': reason,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Transfer failed');
      }
    } catch (e) {
      throw Exception('Transfer Error: $e');
    }
  }

  Future<void> cancelTaskApproval(int taskId, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}tasks/$taskId/cancel-approval'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reason': reason,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Cancellation failed');
      }
    } catch (e) {
      throw Exception('Cancellation Error: $e');
    }
  }

  Future<void> rescheduleTaskExtended({
    required int taskId,
    required DateTime newStart,
    required DateTime newEnd,
    required bool selfAssign,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.put(
        Uri.parse('${backendUrl}tasks/$taskId/reschedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'new_date': DateFormat('yyyy-MM-dd').format(newStart),
          'new_time': DateFormat('HH:mm:ss').format(newStart),
          'new_end_date': DateFormat('yyyy-MM-dd').format(newEnd),
          'new_end_time': DateFormat('HH:mm:ss').format(newEnd),
          'self_assign': selfAssign,
        }),
      );

      if (response.statusCode != 200) {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Reschedule failed');
      }
    } catch (e) {
      throw Exception('Reschedule Error: $e');
    }
  }

  Future<void> rescheduleTask(int taskId, DateTime newTime) async {
    // Legacy support
    return rescheduleTaskExtended(
      taskId: taskId, 
      newStart: newTime, 
      newEnd: newTime.add(const Duration(hours: 2)), 
      selfAssign: true,
    );
  }
}
