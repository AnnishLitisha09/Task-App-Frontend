import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile_model.dart';
import '../models/departmental_dashboard_model.dart';
import '../models/department_users_model.dart';

import '../models/activity_history_model.dart';
import '../models/staff_dashboard_model.dart';
import '../models/institutional_dashboard_model.dart';

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
}
