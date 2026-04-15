import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile_model.dart';
import '../models/departmental_dashboard_model.dart';
import '../models/department_users_model.dart';
import '../models/department_wise_users_model.dart';

import '../models/activity_history_model.dart';
import '../models/staff_dashboard_model.dart';
import '../models/institutional_dashboard_model.dart';
import 'package:flutter/foundation.dart';

class UserService {
  Future<ActivityHistoryResponse> getActivityHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/dashboard/activity-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivityHistoryResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load activity history: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching activity history: $e');
    }
  }

  Future<DepartmentUsersResponse> getHODDepartmentUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/dashboard/hod/department-users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DepartmentUsersResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load department users: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching department users: $e');
    }
  }

  Future<DepartmentalDashboard> getDepartmentalDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

    final response = await http.get(
      Uri.parse('${backendUrl}users/dashboard/departmental'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return DepartmentalDashboard.fromJson(data);
    } else {
      throw Exception(
        'Failed to load departmental dashboard: ${response.statusCode}',
      );
    }
  }

  Future<UserProfile> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<Map<String, dynamic>> getUsersByDepartment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/by-department'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users by department: $e');
    }
  }

  Future<StaffDashboardResponse> getStaffDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/dashboard/staff'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StaffDashboardResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load staff dashboard: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching staff dashboard: $e');
    }
  }

  Future<InstitutionalDashboard> getInstitutionalDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/dashboard/institutional'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return InstitutionalDashboard.fromJson(data);
      } else {
        throw Exception(
          'Failed to load institutional dashboard: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching institutional dashboard: $e');
    }
  }

  Future<DepartmentWiseUsers> getDepartmentWiseUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/fetch/department-wise'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DepartmentWiseUsers.fromJson(data);
      } else {
        throw Exception(
          'Failed to load department-wise users: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching department-wise users: $e');
    }
  }

  Future<Map<String, dynamic>> getDepartmentalTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/dashboard/departmental-tasks'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load departmental tasks: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching departmental tasks: $e');
    }
  }

  // --- Admin User Management APIs ---

  /// Fetches all active users with their primary and secondary roles
  Future<Map<String, dynamic>> getAllUsersWithDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}users/dashboard/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load user management data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching all users: $e');
    }
  }

  /// Updates primary and secondary roles for a specific user
  Future<Map<String, dynamic>> updateUserRoles(
    String userId, {
    String? primaryRole,
    String? removeProfile,
    List<Map<String, dynamic>>? addAssignments,
    List<Map<String, dynamic>>? removeAssignments,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final Map<String, dynamic> body = {};
      if (primaryRole != null) body['primary_role'] = primaryRole;
      if (removeProfile != null) body['remove_profile'] = removeProfile;
      if (addAssignments != null) body['add_assignments'] = addAssignments;
      if (removeAssignments != null) body['remove_assignments'] = removeAssignments;

      final response = await http.put(
        Uri.parse('${backendUrl}users/$userId/roles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update user roles');
      }
    } catch (e) {
      throw Exception('Error updating user roles: $e');
    }
  }
  /// Updates the FCM token for the current user to support push notifications
  Future<bool> updateFcmToken(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}users/fcm-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      return false;
    }
  }
}
