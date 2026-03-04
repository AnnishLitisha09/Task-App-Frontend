import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/student_model.dart';
import '../models/student_dashboard_model.dart';
import '../models/coupon_model.dart';

class StudentService {
  Future<StudentDashboard> getStudentDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

    final response = await http.get(
      Uri.parse('${backendUrl}users/dashboard/student'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return StudentDashboard.fromJson(data);
    } else {
      throw Exception(
        'Failed to load student dashboard: ${response.statusCode}',
      );
    }
  }

  Future<CouponDashboard> getAvailableCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

    final response = await http.get(
      Uri.parse('${backendUrl}coupons/available'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return CouponDashboard.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load coupons: ${response.statusCode}');
    }
  }

  Future<bool> redeemCoupon(int couponId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

    final response = await http.post(
      Uri.parse('${backendUrl}coupons/redeem'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'coupon_id': couponId}),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<RedeemedCouponDashboard> getRedeemedCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

    final response = await http.get(
      Uri.parse('${backendUrl}coupons/redeemed'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return RedeemedCouponDashboard.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to load redeemed coupons: ${response.statusCode}',
      );
    }
  }

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
