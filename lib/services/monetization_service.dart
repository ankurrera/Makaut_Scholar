import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/supabase_client.dart';

class MonetizationService extends ChangeNotifier {
  final _client = SupabaseClientService.client;
  int _previewInteractions = 0;
  int _nudgeThreshold = 3;

  MonetizationService() {
    _initInteractions();
    _fetchSettings();
  }

  Future<void> _initInteractions() async {
    final prefs = await SharedPreferences.getInstance();
    _previewInteractions = prefs.getInt('preview_interactions') ?? 0;
  }

  Future<void> _fetchSettings() async {
    try {
      final response = await _client
          .from('app_settings')
          .select('setting_value')
          .eq('setting_key', 'preview_interactions_threshold')
          .maybeSingle();

      if (response != null && response['setting_value'] != null) {
        _nudgeThreshold = int.tryParse(response['setting_value'].toString()) ?? 3;
      }
    } catch (e) {
      if (kDebugMode) print('Failed to fetch threshold: $e');
    }
  }

  /// Records an interaction and returns true if paywall nudge should trigger
  Future<bool> recordInteraction() async {
    final prefs = await SharedPreferences.getInstance();
    _previewInteractions++;
    await prefs.setInt('preview_interactions', _previewInteractions);
    return _previewInteractions >= _nudgeThreshold;
  }

  /// Resets interaction count (e.g. after user subscribes)
  Future<void> resetInteractions() async {
    _previewInteractions = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preview_interactions', 0);
  }

  /// Fetches Pricing for Subject (Tier 2) and Semester Bundle (Tier 3)
  /// Returns { 'subject_price': double, 'bundle_price': double?, 'purchased_subjects_count': int }
  Future<Map<String, dynamic>> getPricingDetails(String department, int semester, String subject) async {
    try {
      // 1. Get Subject Price and Bundle ID
      final targetSub = await _client
          .from('subjects_bundle')
          .select('subject_price, semester_bundle_id')
          .eq('department', department)
          .eq('semester', semester)
          .eq('subject', subject)
          .maybeSingle();

      if (targetSub == null) return {'subject_price': 0.0};

      final double subjectPrice = (targetSub['subject_price'] as num?)?.toDouble() ?? 0.0;
      final String? bundleId = targetSub['semester_bundle_id'] as String?;
      double? bundlePrice;

      if (bundleId != null) {
        final bundle = await _client
            .from('semester_bundles')
            .select('bundle_price')
            .eq('id', bundleId)
            .maybeSingle();
        if (bundle != null) {
          bundlePrice = (bundle['bundle_price'] as num?)?.toDouble();
        }
      }

      // 2. Count already purchased subjects in this semester
      final user = _client.auth.currentUser;
      int purchasedSubjects = 0;
      if (user != null) {
        // Find all subjects in this semester
        final allSemesterSubjectsResponse = await _client
            .from('subjects_bundle')
            .select('subject')
            .eq('department', department)
            .eq('semester', semester);
        
        final allSemesterSubjects = (allSemesterSubjectsResponse as List)
            .map((s) => s['subject'] as String)
            .toList();

        // Check user purchases for these subjects
        // item_id format typically: "subject_{dept}_{sem}_{subjectName}"
        if (allSemesterSubjects.isNotEmpty) {
           final purchases = await _client
              .from('user_purchases')
              .select('item_id')
              .eq('user_id', user.id)
              .eq('item_type', 'subject');
              
           final purchasedIds = (purchases as List).map((p) => p['item_id'] as String).toList();
           
           for (final sub in allSemesterSubjects) {
             final expectedId = 'subject_${department}_${semester}_$sub';
             if (purchasedIds.contains(expectedId)) {
               purchasedSubjects++;
             }
           }
        }
      }

      return <String, dynamic>{
        'subject_price': subjectPrice,
        'bundle_price': bundlePrice,
        'purchased_subjects_count': purchasedSubjects,
        'semester_bundle_id': bundleId,
      };
    } catch (e) {
      if (kDebugMode) print('Failed to fetch pricing: $e');
      return <String, dynamic>{'subject_price': 0.0};
    }
  }

  /// Calculates dynamic bundle upgrade offer
  double calculateBundleUpgradePrice(double originalBundlePrice, int purchasedSubjectsCount, double individualSubjectPrice) {
    if (purchasedSubjectsCount >= 3) {
      // Flow 1 (Smart Upgrade Pricing)
      // "Semester Price - Sum of 3 subjects paid"
      final sumPaid = purchasedSubjectsCount * individualSubjectPrice; // Estimating based on current price
      final upgradePrice = originalBundlePrice - sumPaid;
      return upgradePrice > 0 ? upgradePrice : 0.0; // Ensure it's not negative
    }
    return originalBundlePrice;
  }

  /// Checks if the user has access to a specific unit
  /// Checks in order: unit purchase → subject purchase → bundle purchase
  Future<bool> checkUnitAccess(String department, int semester, String subject, int unit) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      // 1. Check unit-level purchase
      final unitId = 'unit_${department}_${semester}_${subject}_$unit';
      final unitRows = await _client
          .from('user_purchases')
          .select('id')
          .eq('user_id', user.id)
          .eq('item_type', 'unit')
          .eq('item_id', unitId)
          .limit(1);
      if ((unitRows as List).isNotEmpty) return true;

      // 2. Fall up to subject/bundle check
      return await checkSubjectAccess(department, semester, subject);
    } catch (e) {
      if (kDebugMode) print('checkUnitAccess error: $e');
      return false;
    }
  }

  /// Checks if the user has full subject access (subject or semester bundle purchase)
  Future<bool> checkSubjectAccess(String department, int semester, String subject) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      // 1. Check subject-level purchase
      final subjectId = 'subject_${department}_${semester}_$subject';
      final subRows = await _client
          .from('user_purchases')
          .select('id')
          .eq('user_id', user.id)
          .eq('item_type', 'subject')
          .eq('item_id', subjectId)
          .limit(1);
      if ((subRows as List).isNotEmpty) return true;

      // 2. Check semester bundle purchase
      final bundleId = 'bundle_${department}_${semester}';
      final bundleRows = await _client
          .from('user_purchases')
          .select('id')
          .eq('user_id', user.id)
          .eq('item_type', 'semester_bundle')
          .eq('item_id', bundleId)
          .limit(1);
      return (bundleRows as List).isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('checkSubjectAccess error: $e');
      return false;
    }
  }

  /// Fetches Semester Bundle pricing directly (Tier 3 Upfront)
  /// Returns { 'bundle_price': double, 'has_access': bool }
  Future<Map<String, dynamic>> getSemesterBundleInfo(String department, int semester) async {
    try {
      final bundle = await _client
          .from('semester_bundles')
          .select('bundle_price')
          .eq('department', department)
          .eq('semester', semester)
          .maybeSingle();

      if (bundle == null) return {'bundle_price': 0.0, 'has_access': false};

      final double bundlePrice = (bundle['bundle_price'] as num?)?.toDouble() ?? 0.0;
      
      final user = _client.auth.currentUser;
      bool hasAccess = false;
      
      if (user != null) {
        final bundleIdStr = 'bundle_${department}_${semester}';
        final bunRes = await _client.rpc('has_premium_access', params: {
          'target_user_id': user.id,
          'target_item_type': 'semester_bundle',
          'target_item_id': bundleIdStr,
          'target_department': department,
        });
        hasAccess = bunRes == true;
      }

      return {
        'bundle_price': bundlePrice,
        'has_access': hasAccess,
      };
    } catch (e) {
      if (kDebugMode) print('Failed to fetch bundle info: $e');
      return {'bundle_price': 0.0, 'has_access': false};
    }
  }
}
