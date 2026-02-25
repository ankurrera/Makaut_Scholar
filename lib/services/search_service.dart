import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/models/search_result.dart';

class SearchService {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<List<SearchResult>> search({
    required String query,
    required String department,
    String filter = 'All',
  }) async {
    if (query.trim().isEmpty) return [];

    final List<SearchResult> results = [];

    // 1. NOTES
    if (filter == 'All' || filter == 'Notes') {
      final data = await _client
          .from('notes')
          .select()
          .or('paper_code.ilike.%$query%,and(department.eq.$department,or(subject.ilike.%$query%,title.ilike.%$query%))')
          .limit(10);
      results.addAll((data as List).map((e) => SearchResult.fromNotes(e)));
    }

    // 2. SYLLABUS
    if (filter == 'All' || filter == 'Syllabus') {
      final data = await _client
          .from('syllabus')
          .select()
          .or('paper_code.ilike.%$query%,and(department.eq.$department,or(subject.ilike.%$query%,title.ilike.%$query%))')
          .limit(10);
      results.addAll((data as List).map((e) => SearchResult.fromSyllabus(e)));
    }

    // 3. PYQs
    if (filter == 'All' || filter == 'PYQs') {
      final data = await _client
          .from('pyq')
          .select()
          .or('paper_code.ilike.%$query%,and(department.eq.$department,subject.ilike.%$query%)')
          .limit(10);
      results.addAll((data as List).map((e) => SearchResult.fromPyq(e)));
    }

    // 4. IMPORTANT
    if (filter == 'All' || filter == 'Important') {
      final data = await _client
          .from('important_questions')
          .select()
          .or('paper_code.ilike.%$query%,and(department.eq.$department,or(subject.ilike.%$query%,title.ilike.%$query%))')
          .limit(10);
      results.addAll((data as List).map((e) => SearchResult.fromImportant(e)));
    }

    return results;
  }
}
