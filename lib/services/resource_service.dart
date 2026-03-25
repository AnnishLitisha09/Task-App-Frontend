import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './venue_notifier.dart';

class ResourceService {
  Future<Map<String, dynamic>?> getMyVenue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final selectedVenueId = VenueNotifier.currentVenueId;
      String url = '${backendUrl}resources/venue/my-venue';
      if (selectedVenueId != null) {
        url += '?venue_id=$selectedVenueId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data == null) return null;
        return data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load my venue: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching my venue: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVenues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/venues/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        // API returns { success: true, count: N, venues: [...] }
        if (body is Map && body['venues'] != null) {
          return (body['venues'] as List).cast<Map<String, dynamic>>();
        }
        // Fallback: if it happens to return a plain list
        if (body is List) return body.cast<Map<String, dynamic>>();
        return [];
      } else {
        throw Exception('Failed to load venues: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching venues: $e');
    }
  }

  Future<Map<String, dynamic>> getVenueBasicDetails(int venueId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}tasks/venue/$venueId/basic'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load venue details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching venue details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVenueResources(int venueId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}resources/venue/$venueId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> resources = data['resources'] ?? data['available_resources'] ?? [];
        return resources.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load resources: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching resources: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMaintenanceLogs({int? venueId, String? date}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      String url = '${backendUrl}resources/maintenance/logs';
      int? effectiveVenueId = venueId ?? VenueNotifier.currentVenueId;
      
      if (effectiveVenueId != null) {
        url = '${backendUrl}resources/venues/$effectiveVenueId/maintenance-logs';
      }

      // Add query parameters for date
      final queryParams = <String, String>{};
      if (date != null) queryParams['date'] = date;
      
      final uri = Uri.parse(url).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        List<dynamic> logs = [];
        if (data is Map && data.containsKey('logs')) {
          logs = data['logs'];
        } else if (data is List) {
          logs = data;
        }
        return logs.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching logs: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVenueStatusHistory(int venueId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}resources/venues/$venueId/status-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> history = data['history'] ?? [];
        return history.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load status history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching status history: $e');
    }
  }

  Future<void> addMaintenanceLog(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}resources/maintenance/logs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to add log');
      }
    } catch (e) {
      throw Exception('Error adding log: $e');
    }
  }
  Future<List<Map<String, dynamic>>> getMasterResources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}resources/master'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        List<dynamic> resources = [];
        if (data is Map && data.containsKey('resources')) {
          resources = data['resources'];
        } else if (data is List) {
          resources = data;
        }
        return resources.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load master resources: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching master resources: $e');
    }
  }

  Future<void> updateVenueStatus(int venueId, String status, {String? reason}) async {
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
        body: jsonEncode({
          'status': status,
          'reason': reason,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }

  Future<void> updateResourceQuantity(int resourceId, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.put(
        Uri.parse('${backendUrl}resources/$resourceId/quantity'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'quantity': quantity}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to update quantity');
      }
    } catch (e) {
      throw Exception('Error updating quantity: $e');
    }
  }

  Future<void> reportFaultyResource(int resourceId, int quantity, String status, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}resources/$resourceId/report-faulty'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quantity': quantity,
          'status': status,
          'reason': reason,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to report faulty resource');
      }
    } catch (e) {
      throw Exception('Error reporting faulty resource: $e');
    }
  }

  Future<void> manageResource(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.post(
        Uri.parse('${backendUrl}resources/manage-resource'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to manage resource');
      }
    } catch (e) {
      throw Exception('Error managing resource: $e');
    }
  }
  Future<List<int>> downloadVenueReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}resources/venues/export'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download venue report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading venue report: $e');
    }
  }

  Future<List<int>> downloadResourceReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}resources/export'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download resource report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading resource report: $e');
    }
  }

  Future<List<int>> getVenueUsageReport(String from, String to) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

      final response = await http.get(
        Uri.parse('${backendUrl}resources/venues/usage-report?from=$from&to=$to'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download usage report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading usage report: $e');
    }
  }
}