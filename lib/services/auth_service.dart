import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AuthService {
  final SupabaseClient _client = SupabaseClientService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(email: email, password: password);
      if (response.user == null) {
        throw Exception('Invalid credentials');
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signUp({required String name, required String email, required String password}) async {
    try {
      final response = await _client.auth.signUp(email: email, password: password);
      final user = response.user;
      if (user == null) {
        throw Exception('Signup failed');
      }
      // Insert profile data
      await _client.from('profiles').insert({
        'id': user.id,
        'name': name,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Session? get currentSession => _client.auth.currentSession;
}
