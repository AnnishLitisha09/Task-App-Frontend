import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkUtils {
  static dynamic handleResponse(http.Response response) {
    print('Response status [${response.request?.url}]: ${response.statusCode}');
    
    if (response.body.isEmpty) {
      if (response.statusCode == 401) {
        throw Exception('401 Unauthorized: The request was rejected by the server or gateway (Check if Dev Tunnel is set to PUBLIC).');
      }
      throw Exception('Server returned an empty response. Details: ${response.statusCode} ${response.reasonPhrase}');
    }

    try {
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        // Handle common error structures
        String message = 'API Error ${response.statusCode}';
        if (data is Map) {
          message = data['message'] ?? data['error'] ?? message;
        }
        
        if (response.statusCode == 401) {
          message = 'Unauthorized: $message';
        }
        
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to parse server response [${response.statusCode}]. Ensure the backend is returning JSON.');
    }
  }
}
