import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Removed for security

class SupabaseClientService {
  static SupabaseClient? _client;
  static bool _initialized = false;
  static Future<void>? _initFuture;

  static SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw StateError(
          'Supabase has not been initialized. Please ensure internet is available.');
    }
    return _client!;
  }

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    if (_initFuture != null) return _initFuture;

    _initFuture = _performInit();
    return _initFuture;
  }

  static Future<void> _performInit() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        // Replaced dotenv with flutter compile-time variables
        const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
        const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

        if (url.isEmpty || anonKey.isEmpty) {
          throw Exception('Supabase credentials missing. Compile with --dart-define');
        }

        final supabase = await Supabase.initialize(
          url: url,
          anonKey: anonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        _client = supabase.client;
        _initialized = true;
        debugPrint('Supabase initialized successfully (Attempt $attempts)');
        return; // Success
      } catch (e) {
        debugPrint('Supabase initialization attempt $attempts failed: $e');
        if (attempts >= maxAttempts) {
          _initialized = false;
          _initFuture = null; // Allow retry on next manual call
          rethrow;
        }
        // Small delay before retry
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }
}
