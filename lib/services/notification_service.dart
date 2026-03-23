import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationService {
  final String _baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<List<NotificationModel>> getNotifications({int? venueId}) async {
    try {
      final token = await _getToken();
      String urlString = '${_baseUrl}notifications';
      if (venueId != null) {
        urlString += '?venue_id=$venueId';
      }
      final url = Uri.parse(urlString);
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notificationsJson = data['notifications'] ?? [];
        return notificationsJson.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${_baseUrl}notifications/$notificationId/read');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${_baseUrl}notifications/$notificationId');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }
  Future<int> getUnreadCount({int? venueId}) async {
    try {
      final token = await _getToken();
      String urlString = '${_baseUrl}notifications';
      if (venueId != null) {
        urlString += '?venue_id=$venueId';
      }
      final url = Uri.parse(urlString);
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notificationsJson = data['notifications'] ?? [];
        return notificationsJson.where((n) => n['is_read'] == 0 || n['is_read'] == false).length;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }
}
