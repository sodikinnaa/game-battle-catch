import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // Base URL for the backend.
  // Using 10.0.2.2 for Android Emulator to access localhost
  // Base URL for the backend.
  static String get _baseUrl {
    // Priority 1: Use API_URL from .env if available
    final envUrl = dotenv.env['API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    // Priority 2: Fallback for local development
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  // The Google Sign In instance
  // Using explicit type to help analyzer if needed
  // The Google Sign In instance
  // Using explicit type to help analyzer if needed
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    // serverClientId MUST be a valid "Web application" Client ID.
    // We are using the one from .env (User provided: ...sta4.apps.googleusercontent.com)
    serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],
  );

  // Storage for tokens
  final _storage = const FlutterSecureStorage();

  // Sign in with Google and verify with backend
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('DEBUG: Initializing Google Sign In...');
      print('DEBUG: checking current user: ${_googleSignIn.currentUser}');

      // 1. Trigger the authentication flow
      print('DEBUG: Calling _googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('DEBUG: Google Sign In canceled by user.');
        return null;
      }

      print('DEBUG: Google User verified locally: ${googleUser.email}');
      print('DEBUG: Obtaining auth details...');

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // We need the idToken to send to the backend
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print('DEBUG: idToken present? ${idToken != null}');
      print('DEBUG: accessToken present? ${accessToken != null}');

      if (idToken == null) {
        print(
          'Error: ID Token is null. This might happen if serverClientId is missing or incorrect.',
        );
        throw Exception('Failed to retrieve ID Token from Google');
      }

      print('DEBUG: ID Token retrieved. Verifying with backend...');

      // 3. Send the ID token to the backend for verification
      return await _verifyTokenWithBackend(idToken);
    } catch (e) {
      print('DEBUG: Error during Google Sign In: $e');
      if (e.toString().contains("ApiException: 10")) {
        print("CRITICAL ERROR: ApiException: 10 detected.");
        print("Possible causes:");
        print(
          "1. SHA-1 Fingerprint mismatch. Did you add SHA-1: 75:B1:3D:BD:FB:A4:C3:8D:AF:24:FB:F9:EE:EA:34:60:84:C0:C3:7E to Firebase/Google Cloud Console?",
        );
        print(
          "2. Package Name mismatch. Is it 'com.example.frontend_game' in Console?",
        );
        print(
          "3. serverClientId is wrong. Do NOT use the Android Client ID. Use the WEB Client ID.",
        );
      }
      rethrow;
    }
  }

  // Sign in with Email and Password
  Future<Map<String, dynamic>> signInWithEmail(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _storage.write(
            key: 'access_token',
            value: data['token']['access_token'],
          );
          await _storage.write(
            key: 'refresh_token',
            value: data['token']['refresh_token'],
          );
        }
        if (data['user'] != null) {
          await _storage.write(
            key: 'user_data',
            value: jsonEncode(data['user']),
          );
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Register with Email and Password
  Future<Map<String, dynamic>> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _storage.write(
            key: 'access_token',
            value: data['token']['access_token'],
          );
          await _storage.write(
            key: 'refresh_token',
            value: data['token']['refresh_token'],
          );
        }
        if (data['user'] != null) {
          await _storage.write(
            key: 'user_data',
            value: jsonEncode(data['user']),
          );
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Helper to post the token to the backend
  Future<Map<String, dynamic>> _verifyTokenWithBackend(String idToken) async {
    final url = Uri.parse('$_baseUrl/auth/google/verify');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      print('Backend Response Status: ${response.statusCode}');
      print('Backend Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 4. Save the session tokens from the backend
        if (data['token'] != null) {
          await _storage.write(
            key: 'access_token',
            value: data['token']['access_token'],
          );
          await _storage.write(
            key: 'refresh_token',
            value: data['token']['refresh_token'],
          );
        }

        if (data['user'] != null) {
          await _storage.write(
            key: 'user_data',
            value: jsonEncode(data['user']),
          );
        }

        return data;
      } else {
        throw Exception('Backend verification failed: ${response.body}');
      }
    } catch (e) {
      print('Backend connection error: $e');
      rethrow;
    }
  }

  // Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$_baseUrl/user/profile');
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null) throw Exception("No access token found");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load profile: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update Profile
  Future<Map<String, dynamic>> updateProfile(
    String name,
    String avatarUrl,
  ) async {
    final url = Uri.parse('$_baseUrl/user/profile');
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null) throw Exception("No access token found");

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name, 'avatar_url': avatarUrl}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Update local user data if returned
        if (data['user'] != null) {
          await _storage.write(
            key: 'user_data',
            value: jsonEncode(data['user']),
          );
        }
        return data;
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get Teams
  Future<List<dynamic>> getTeams() async {
    final url = Uri.parse('$_baseUrl/teams');
    final accessToken = await _storage.read(key: 'access_token');

    Map<String, String> headers = {'Content-Type': 'application/json'};

    // Add token if available
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['teams'] ?? []; // Return the list of teams
      } else {
        throw Exception('Failed to load teams: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get Avatars
  Future<List<dynamic>> getAvatars() async {
    final url = Uri.parse('$_baseUrl/avatars');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['avatars'] ?? [];
      } else {
        throw Exception('Failed to load avatars: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get User Team
  Future<Map<String, dynamic>?> getUserTeam() async {
    final url = Uri.parse('$_baseUrl/user/team');
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // The response wrapper has 'data'
      } else if (response.statusCode == 404) {
        return null; // Not setup yet
      } else {
        // It might be that the user has no team, handle gracefully
        return null;
      }
    } catch (e) {
      print("Error fetching user team: $e");
      return null;
    }
  }

  // Save/Update User Team
  Future<Map<String, dynamic>> saveUserTeam(
    String teamId,
    String avatarId,
    String customName,
  ) async {
    final url = Uri.parse('$_baseUrl/user/team');
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) throw Exception("No access token found");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'team_id': teamId,
          'avatar_id': avatarId,
          'custom_name': customName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to save team: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get Player Teams (Other users)
  Future<List<dynamic>> getPlayerTeams() async {
    final url = Uri.parse('$_baseUrl/user-teams');
    final accessToken = await _storage.read(key: 'access_token');

    // Auth might be optional but recommended to filter out own team
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to load player teams: ${response.body}');
      }
    } catch (e) {
      print("Error fetching player teams: $e");
      return []; // Return empty list on error to not break UI
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // disconnect() ensures the user is fully logged out from Google on this app,
      // forcing the account picker to appear on the next login.
      await _googleSignIn.disconnect();
    } catch (e) {
      print("Error disconnecting: $e");
      // Fallback to sign out if disconnect fails (e.g. if not signed in)
      await _googleSignIn.signOut();
    }
    await _storage.deleteAll();
  }
}
