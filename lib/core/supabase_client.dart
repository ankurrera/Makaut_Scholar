import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseClientService {
  static SupabaseClient? _client;
  static bool _initialized = false;
  static Future<void>? _initFuture;

  static SupabaseClient get client {
    if (!_initialized || _client == null) {
      // If we attempt to access before init, we could return a placeholder
      // or throw a more helpful error that suggests retrying.
      // For now, let's keep throwing but suggest the caller check isInitialized
      // or use a Service that handles the delay.
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
        final url = dotenv.env['SUPABASE_URL'];
        final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

        if (url == null || anonKey == null) {
          throw Exception('Supabase credentials missing in .env');
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
