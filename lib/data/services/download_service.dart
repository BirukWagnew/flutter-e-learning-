import 'dart:io';
import 'package:dio/dio.dart';
import 'app_path_service.dart';

class DownloadService {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 5),
                followRedirects: true,
                maxRedirects: 5,
              ),
            );

  Future<String> getDownloadsDirectoryPath() async {
    return AppPathService.getVideosDirectory();
  }

  Future<String> getTargetFilePath(String lessonId) async {
    final dirPath = await getDownloadsDirectoryPath();
    return '$dirPath/$lessonId.mp4';
  }

  Future<bool> doesFileExist(String filePath) async {
    final file = File(filePath);
    return file.exists();
  }

  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  Future<void> downloadVideo({
    required String lessonId,
    required String videoUrl,
    required String destinationPath,
    required void Function(int received, int total) onProgress,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[lessonId] = cancelToken;

    try {
      // Ensure directory exists
      final file = File(destinationPath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      await _dio.download(
        videoUrl,
        destinationPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          onProgress(received, total);
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ),
      );
    } finally {
      _cancelTokens.remove(lessonId);
    }
  }

  void cancelDownload(String lessonId) {
    if (_cancelTokens.containsKey(lessonId)) {
      _cancelTokens[lessonId]?.cancel('User cancelled download');
      _cancelTokens.remove(lessonId);
    }
  }

  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
