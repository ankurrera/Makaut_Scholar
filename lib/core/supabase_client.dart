import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseClientService {
  static late final SupabaseClient client;

  static Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL']!;
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;
    await Supabase.initialize(url: url, anonKey: anonKey);
    client = Supabase.instance.client;
  }
}
