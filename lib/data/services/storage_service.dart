import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';
import '../models/download_item.dart';
import 'app_path_service.dart';

class StorageService {
  static const String _keyCurrentUser = 'elearning_current_user';
  static const String _keyRegisteredUsers = 'elearning_registered_users';
  static const String _keyCompletedLessons = 'elearning_completed_lessons';
  static const String _keyDownloadsRegistry = 'elearning_downloads_registry';
  static const String _keyThemeMode = 'elearning_theme_mode';

  static StorageService? _instance;
  final Map<String, dynamic> _data;
  final File? _file;

  StorageService._(this._data, this._file);

  static Future<StorageService> init() async {
    if (_instance != null) return _instance!;

    Map<String, dynamic> data = {};
    File? file;
    try {
      final filePath = await AppPathService.getStorageFilePath();
      file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          data = Map<String, dynamic>.from(jsonDecode(content) as Map);
        }
      }
    } catch (_) {
      // Fallback in memory
    }

    _instance = StorageService._(data, file);
    return _instance!;
  }

  Future<void> _persist() async {
    try {
      final f = _file;
      if (f != null) {
        if (!await f.parent.exists()) {
          await f.parent.create(recursive: true);
        }
        await f.writeAsString(jsonEncode(_data));
      }
    } catch (_) {}
  }

  // ---------------- AUTHENTICATION SESSION ---------------- //

  UserModel? getCurrentUser() {
    final raw = _data[_keyCurrentUser] as String?;
    if (raw == null || raw.isEmpty) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(raw);
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCurrentUser(UserModel user) async {
    final raw = jsonEncode(user.toJson());
    _data[_keyCurrentUser] = raw;
    await _persist();
  }

  Future<void> clearCurrentUser() async {
    _data.remove(_keyCurrentUser);
    await _persist();
  }

  // ---------------- REGISTERED USERS (Mock Database) ---------------- //

  Map<String, Map<String, dynamic>> getRegisteredUsers() {
    final raw = _data[_keyRegisteredUsers] as String?;
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveRegisteredUser({
    required UserModel user,
    required String password,
  }) async {
    final users = getRegisteredUsers();
    users[user.email.toLowerCase().trim()] = {
      'user': user.toJson(),
      'password': password,
    };
    _data[_keyRegisteredUsers] = jsonEncode(users);
    await _persist();
  }

  // ---------------- LESSON PROGRESS TRACKING (Bonus) ---------------- //

  Set<String> getCompletedLessons() {
    final raw = _data[_keyCompletedLessons];
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return {};
  }

  Future<void> markLessonCompleted(String lessonId, bool isCompleted) async {
    final set = getCompletedLessons();
    if (isCompleted) {
      set.add(lessonId);
    } else {
      set.remove(lessonId);
    }
    _data[_keyCompletedLessons] = set.toList();
    await _persist();
  }

  // ---------------- DOWNLOADS REGISTRY ---------------- //

  Map<String, DownloadItem> getDownloadsRegistry() {
    final raw = _data[_keyDownloadsRegistry] as String?;
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = <String, DownloadItem>{};
      for (final entry in decoded.entries) {
        map[entry.key] = DownloadItem.fromJson(Map<String, dynamic>.from(entry.value as Map));
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDownloadItem(DownloadItem item) async {
    final downloads = getDownloadsRegistry();
    downloads[item.lessonId] = item;
    final jsonMap = downloads.map((k, v) => MapEntry(k, v.toJson()));
    _data[_keyDownloadsRegistry] = jsonEncode(jsonMap);
    await _persist();
  }

  Future<void> removeDownloadItem(String lessonId) async {
    final downloads = getDownloadsRegistry();
    downloads.remove(lessonId);
    final jsonMap = downloads.map((k, v) => MapEntry(k, v.toJson()));
    _data[_keyDownloadsRegistry] = jsonEncode(jsonMap);
    await _persist();
  }

  // ---------------- THEME MODE ---------------- //

  String getThemeMode() {
    return (_data[_keyThemeMode] as String?) ?? 'system';
  }

  Future<void> saveThemeMode(String mode) async {
    _data[_keyThemeMode] = mode;
    await _persist();
  }
}
