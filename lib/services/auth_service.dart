import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AuthService extends ChangeNotifier {
  // Access the client via your existing service
  final SupabaseClient _client = SupabaseClientService.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  AuthService() {
    _client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }
      notifyListeners();
    } catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  // Sign Up
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // Store name in user metadata as well
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Signup failed: No user returned');
      }

      // If email confirmation is enabled, the session will be null.
      // In that case, skip profile insert (use a DB trigger instead)
      // or let the user confirm first.
      if (response.session != null) {
        // User is confirmed (email confirmation disabled) — insert profile
        await _client.from('profiles').upsert({
          'id': user.id,
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      notifyListeners();
    } catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://callback',
      );
    } catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  // Facebook Sign In
  Future<void> signInWithFacebook() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://callback',
      );
    } catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
    notifyListeners();
  }

  /// Fetches the current user's profile data
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final data = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
      return data;
    } catch (e) {
      if (kDebugMode) print('Error fetching profile: $e');
      return null;
    }
  }

  /// Updates the user's profile with additional details
  Future<void> updateProfile({
    required String name,
    required String phoneNumber,
    required String collegeName,
    required String department,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('profiles').upsert({
      'id': user.id,
      'name': name,
      'phone_number': phoneNumber,
      'college_name': collegeName,
      'department': department,
      'updated_at': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  /// Converts Supabase auth errors into user-friendly messages
  String _friendlyAuthError(dynamic error) {
    if (error is AuthApiException) {
      switch (error.code) {
        case 'over_email_send_rate_limit':
          // Extract wait time from message if possible
          final match = RegExp(r'after (\d+) seconds').firstMatch(error.message);
          final seconds = match?.group(1) ?? 'a few';
          return 'Too many attempts. Please wait $seconds seconds before trying again.';
        case 'user_already_exists':
          return 'An account with this email already exists. Try logging in instead.';
        case 'invalid_credentials':
          return 'Invalid email or password. Please check your credentials.';
        case 'email_not_confirmed':
          return 'Please check your email to confirm your account before logging in.';
        case 'user_not_found':
          return 'No account found for this email. Please sign up first.';
        case 'validation_failed':
          if (error.message.contains('Unsupported provider')) {
            return 'This login method is disabled in Supabase. Please enable it in the dashboard.';
          }
          return error.message;
        default:
          return error.message;
      }
    }
    // Strip "Exception:" prefix if present
    final msg = error.toString();
    if (msg.contains('Exception:')) {
      return msg.replaceAll('Exception:', '').trim();
    }
    return msg;
  }
}