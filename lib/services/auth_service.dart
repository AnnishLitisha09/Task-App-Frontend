import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    // Initialize with Web Client ID for ID token
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: clientId,
    );
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';
      final url = Uri.parse('${backendUrl}auth/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        // Parse error message if available
        String errorMessage = 'Login failed';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error during login: $e');
      rethrow;
    }
  }

  /// Sign in with Google and authenticate with backend
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Get the ID token
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      // Send token to backend for verification
      final response = await _authenticateWithBackend(idToken);

      return response;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  /// Send Google ID token to backend API
  Future<Map<String, dynamic>> _authenticateWithBackend(String idToken) async {
    try {
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'https://h6sp3f89-3002.inc1.devtunnels.ms/api/';
      final url = Uri.parse('${backendUrl}auth/google');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
          'Backend authentication failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error authenticating with backend: $e');
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Check if user is currently signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
