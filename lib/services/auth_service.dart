import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

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

  // Delete Account (Permanent)
  Future<void> deleteAccount() async {
    try {
      // 1. Force a session refresh to guarantee our JWT is pristine.
      // This prevents the "401 Invalid JWT" Edge Function Gateway error.
      final refreshResponse = await _client.auth.refreshSession();
      final session = refreshResponse.session ?? _client.auth.currentSession;
      
      if (session == null) {
        throw Exception('No active session found. Please log in again.');
      }

      // 2. Invoke the Edge Function. 
      // The SDK auto-injects 'Authorization: Bearer <token>' when using 'invoke'.
      final response = await _client.functions.invoke(
        'delete-user-account',
      );
      
      if (response.status != 200) {
        throw Exception(response.data['error'] ?? 'Deletion failed');
      }
      
      // 3. Local clean up
      await signOut();
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('401') || errorStr.contains('Invalid JWT') || errorStr.contains('Unauthorized')) {
        throw Exception('Your session expired. Please log out, log back in, and try again.');
      }
      throw Exception(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  Future<List<Map<String, dynamic>>> fetchDepartmentSubjects(String department, int semester) async {
    final data = await _client
        .from('subjects_bundle')
        .select('subject, paper_code')
        .eq('department', department)
        .eq('semester', semester);
    
    final subjects = (data as List)
        .map((row) => {
          'subject': row['subject'] as String,
          'paper_code': row['paper_code'] as String?,
        })
        .where((item) {
          final s = item['subject'] as String;
          final low = s.toLowerCase();
          return !low.contains('laboratory') && !RegExp(r'\blab\b').hasMatch(low);
        })
        .toList();
    
    subjects.sort((a, b) => (a['subject'] as String).compareTo(b['subject'] as String));
    return subjects;
  }

  /// Fetches the current user's profile data. Throws NetworkException if offline.
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final data = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
      return data;
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw NetworkException('You are currently offline.');
      }
      if (kDebugMode) print('Error fetching profile: $e');
      return null;
    }
  }

  /// Fetches distinct subjects for a department + semester
  Future<List<String>> fetchSubjects(String department, int semester) async {
    final data = await _client
        .from('notes')
        .select('subject')
        .eq('department', department)
        .eq('semester', semester);
    final subjects = (data as List)
        .map((row) => row['subject'] as String)
        .toSet()
        .toList()
      ..sort();
    return subjects;
  }

  /// Fetches unique unit counts for all subjects in a department + semester
  Future<Map<String, int>> fetchSubjectUnitCounts(String department, int semester) async {
    final data = await _client
        .from('notes')
        .select('subject, unit')
        .eq('department', department)
        .eq('semester', semester);
    
    final Map<String, Set<int>> subjectUnits = {};
    for (final row in (data as List)) {
      final sub = row['subject'] as String;
      final unit = row['unit'] as int;
      subjectUnits.putIfAbsent(sub, () => {}).add(unit);
    }
    
    return subjectUnits.map((sub, units) => MapEntry(sub, units.length));
  }

  /// Fetches notes for a department + semester + subject, ordered by unit
  Future<List<Map<String, dynamic>>> fetchNotes(
      String department, int semester, String subject, {String? paperCode}) async {
    try {
      final data = await _client.from('notes')
          .select()
          .eq('department', department)
          .eq('semester', semester)
          .eq('subject', subject)
          .order('unit', ascending: true)
          .order('uploaded_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  /// Fetches distinct semesters that have syllabus for a department
  Future<List<int>> fetchSyllabusSemesters(String department) async {
    final data = await _client
        .from('syllabus')
        .select('semester')
        .eq('department', department);
    final sems = (data as List)
        .map((row) => row['semester'] as int)
        .toSet()
        .toList()
      ..sort();
    return sems;
  }

  /// Fetches distinct subjects that have syllabus for a department + semester
  Future<List<Map<String, dynamic>>> fetchSyllabusSubjects(String department, int semester) async {
    final data = await _client
        .from('subjects_bundle')
        .select('subject, paper_code')
        .eq('department', department)
        .eq('semester', semester);
    
    final subjects = (data as List)
        .map((row) => {
          'subject': row['subject'] as String,
          'paper_code': row['paper_code'] as String?,
        })
        .toList();
    
    subjects.sort((a, b) => (a['subject'] as String).compareTo(b['subject'] as String));
    return subjects;
  }

  /// Fetches syllabus entries for a department + semester + subject
  Future<List<Map<String, dynamic>>> fetchSyllabus(
      String department, int semester, String subject, {String? paperCode}) async {
    final data = await _client.from('syllabus')
        .select()
        .eq('department', department)
        .eq('semester', semester)
        .eq('subject', subject)
        .order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Checks if the current user has premium access to a specific item
  Future<bool> checkPremiumAccess(String itemType, String itemId, {String? department}) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client.rpc('has_premium_access', params: {
      'target_user_id': user.id,
      'target_item_type': itemType,
      'target_item_id': itemId,
      'target_department': department,
    });
    return response as bool;
  }

  /// Fetches all purchases for the current user of a specific type
  Future<List<String>> fetchUserPurchases(String itemType) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('user_purchases')
        .select('item_id')
        .eq('user_id', user.id)
        .eq('item_type', itemType);
    
    return (data as List).map((row) => row['item_id'] as String).toList();
  }

  /// Fetches PYQ papers for a department + semester + subject, ordered by year desc

  /// Fetches distinct semesters that have PYQs for a department
  Future<List<int>> fetchPyqSemesters(String department) async {
    final data = await _client
        .from('pyq')
        .select('semester')
        .eq('department', department);
    final sems = (data as List)
        .map((row) => row['semester'] as int)
        .toSet()
        .toList()
      ..sort();
    return sems;
  }

  /// Fetches distinct subjects that have PYQs for a department + semester
  Future<List<String>> fetchPyqSubjects(String department, int semester) async {
    final data = await _client
        .from('pyq')
        .select('subject')
        .eq('department', department)
        .eq('semester', semester);
    final subjects = (data as List)
        .map((row) => row['subject'] as String)
        .toSet()
        .toList()
      ..sort();
    return subjects;
  }

  /// Fetches unique paper (year) counts for all subjects in a department + semester
  Future<Map<String, int>> fetchSubjectPyqCounts(String department, int semester) async {
    final data = await _client
        .from('pyq')
        .select('subject, year')
        .eq('department', department)
        .eq('semester', semester);
    
    final Map<String, Set<String>> subjectYears = {};
    for (final row in (data as List)) {
      final sub = row['subject'] as String;
      final year = row['year'].toString();
      subjectYears.putIfAbsent(sub, () => {}).add(year);
    }
    
    return subjectYears.map((sub, years) => MapEntry(sub, years.length));
  }

  /// Fetches unique important questions count for all subjects in a department + semester
  Future<Map<String, int>> fetchSubjectImpCounts(String department, int semester) async {
    final data = await _client
        .from('important_questions')
        .select('subject')
        .eq('department', department)
        .eq('semester', semester);

    final counts = <String, int>{};
    for (var row in (data as List)) {
      final sub = row['subject'] as String;
      counts[sub] = (counts[sub] ?? 0) + 1;
    }
    return counts;
  }

  /// Fetches Important Questions for a department + semester + subject
  Future<List<Map<String, dynamic>>> fetchImpQuestions(
      String department, int semester, String subject, {String? paperCode}) async {
    final data = await _client.from('important_questions')
        .select()
        .eq('department', department)
        .eq('semester', semester)
        .eq('subject', subject)
        .order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetches PYQ papers for a department + semester + subject, ordered by year desc
  Future<List<Map<String, dynamic>>> fetchPyqPapers(
      String department, int semester, String subject, {String? paperCode}) async {
    final data = await _client.from('pyq')
        .select()
        .eq('department', department)
        .eq('semester', semester)
        .eq('subject', subject)
        .order('year', ascending: false);
    return List<Map<String, dynamic>>.from(data);
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

  /// Uploads an avatar image and saves the URL to the profile
  Future<String> uploadAvatar(String filePath) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final ext = filePath.split('.').last.toLowerCase();
    final storagePath = '${user.id}/avatar.$ext';

    // Upload (upsert to overwrite existing)
    await _client.storage.from('avatars').upload(
      storagePath,
      File(filePath),
      fileOptions: const FileOptions(upsert: true),
    );

    // Get public URL
    final url = _client.storage.from('avatars').getPublicUrl(storagePath);

    // Save URL to profile
    await _client.from('profiles').update({
      'avatar_url': url,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    notifyListeners();
    return url;
  }

  /// Deletes the user's avatar
  Future<void> deleteAvatar() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Get current avatar path from profile
    final profile = await getProfile();
    final avatarUrl = profile?['avatar_url'] as String?;
    
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // Extract storage path from URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      // Path format: .../avatars/<userId>/avatar.<ext>
      final idx = pathSegments.indexOf('avatars');
      if (idx >= 0 && idx + 2 < pathSegments.length) {
        final storagePath = pathSegments.sublist(idx + 1).join('/');
        try {
          await _client.storage.from('avatars').remove([storagePath]);
        } catch (_) {
          // Ignore storage deletion errors
        }
      }
    }

    // Clear avatar_url in profile
    await _client.from('profiles').update({
      'avatar_url': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

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