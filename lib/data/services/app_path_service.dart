import 'dart:io';
import 'package:flutter/services.dart';

class AppPathService {
  static const MethodChannel _pathChannel = MethodChannel('com.abyssinia.elearning/path');
  static String? _cachedBaseDir;

  /// Returns a consistent, persistent directory for the app across platforms.
  static Future<String> getBaseDirectory() async {
    if (_cachedBaseDir != null) return _cachedBaseDir!;

    String basePath;
    if (Platform.isAndroid) {
      try {
        basePath = await _pathChannel.invokeMethod<String>('getAppDir') ?? Directory.systemTemp.path;
      } catch (_) {
        basePath = Directory.systemTemp.path;
      }
    } else if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        basePath = '$appData/AbyssiniaELearning';
      } else {
        basePath = Directory.systemTemp.path;
      }
    } else {
      basePath = Directory.systemTemp.path;
    }

    final dir = Directory(basePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedBaseDir = dir.path;
    return dir.path;
  }

  /// Directory where offline video files (.mp4) are stored.
  static Future<String> getVideosDirectory() async {
    final base = await getBaseDirectory();
    final videoDir = Directory('$base/elearning_videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir.path;
  }

  /// Path to the storage JSON file.
  static Future<String> getStorageFilePath() async {
    final base = await getBaseDirectory();
    return '$base/elearning_storage.json';
  }
}
