import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AuthService extends ChangeNotifier {
  // Access the client via your existing service
  final SupabaseClient _client = SupabaseClientService.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

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
      notifyListeners(); // Notify app that auth state changed
    } catch (e) {
      rethrow;
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
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Signup failed');
      }

      // Insert profile data
      await _client.from('profiles').insert({
        'id': user.id,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
    notifyListeners();
  }
}