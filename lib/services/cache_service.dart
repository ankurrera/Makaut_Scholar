import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _prefix = 'scholar_cache_';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> set(String key, dynamic value) async {
    if (_prefs == null) await init();
    try {
      final jsonStr = json.encode(value);
      await _prefs?.setString('$_prefix$key', jsonStr);
    } catch (e) {
      debugPrint('CacheService Error (set $key): $e');
    }
  }

  dynamic get(String key) {
    if (_prefs == null) return null;
    try {
      final jsonStr = _prefs?.getString('$_prefix$key');
      if (jsonStr != null) {
        return json.decode(jsonStr);
      }
    } catch (e) {
      debugPrint('CacheService Error (get $key): $e');
    }
    return null;
  }

  Future<void> remove(String key) async {
    if (_prefs == null) await init();
    await _prefs?.remove('$_prefix$key');
  }

  Future<void> clear() async {
    if (_prefs == null) await init();
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith(_prefix)) {
        await _prefs?.remove(key);
      }
    }
  }
}
