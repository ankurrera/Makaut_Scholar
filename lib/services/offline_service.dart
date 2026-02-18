import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum ResourceCategory {
  NOTES,
  SYLLABUS,
  PYQ,
  EXAM_FOCUS
}

class OfflineResource {
  final String id;
  final String title;
  final String url;
  final String localPath;
  final ResourceCategory category;
  final DateTime downloadedAt;

  OfflineResource({
    required this.id,
    required this.title,
    required this.url,
    required this.localPath,
    required this.category,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'localPath': localPath,
    'category': category.name,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  factory OfflineResource.fromJson(Map<String, dynamic> json) => OfflineResource(
    id: json['id'],
    title: json['title'],
    url: json['url'],
    localPath: json['localPath'],
    category: ResourceCategory.values.firstWhere((e) => e.name == json['category']),
    downloadedAt: DateTime.parse(json['downloadedAt']),
  );
}

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Dio _dio = Dio();
  final String _prefKey = 'offline_resources_registry';
  final Map<String, OfflineResource> _registry = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefKey);
    if (data != null) {
      final decoded = json.decode(data) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        _registry[key] = OfflineResource.fromJson(value);
      });
    }
  }

  Future<void> _saveRegistry() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _registry.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_prefKey, json.encode(map));
  }

  bool isDownloaded(String id) => _registry.containsKey(id);

  OfflineResource? getResource(String id) => _registry[id];

  List<OfflineResource> getByCategory(ResourceCategory category) {
    return _registry.values.where((r) => r.category == category).toList();
  }

  Future<void> downloadResource({
    required String id,
    required String title,
    required String url,
    required ResourceCategory category,
    Function(double)? onProgress,
  }) async {
    if (isDownloaded(id)) return;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${category.name.toLowerCase()}_${id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final savePath = '${dir.path}/$fileName';

    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      final resource = OfflineResource(
        id: id,
        title: title,
        url: url,
        localPath: savePath,
        category: category,
        downloadedAt: DateTime.now(),
      );

      _registry[id] = resource;
      await _saveRegistry();
    } catch (e) {
      throw 'Download failed: $e';
    }
  }

  Future<void> removeDownload(String id) async {
    final resource = _registry[id];
    if (resource != null) {
      final file = File(resource.localPath);
      if (await file.exists()) {
        await file.delete();
      }
      _registry.remove(id);
      await _saveRegistry();
    }
  }
}
