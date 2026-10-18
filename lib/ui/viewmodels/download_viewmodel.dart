import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/course_model.dart';
import '../../data/models/download_item.dart';
import '../../data/models/lesson_model.dart';
import '../../data/services/download_service.dart';
import '../../data/services/storage_service.dart';

class DownloadViewModel extends ChangeNotifier {
  final StorageService storageService;
  final DownloadService downloadService;

  Map<String, DownloadItem> _downloads = {};
  final Map<String, CourseModel> _knownCourses = {};

  /// Notifier triggered whenever a download finishes successfully
  final ValueNotifier<DownloadItem?> downloadCompletedNotifier = ValueNotifier(null);

  DownloadViewModel({
    required this.storageService,
    required this.downloadService,
  }) {
    _initializeDownloads();
  }

  Map<String, DownloadItem> get downloads => _downloads;

  List<DownloadItem> get allDownloads => _downloads.values.toList();

  List<DownloadItem> get completedDownloads => _downloads.values
      .where((item) => item.status == DownloadStatus.completed)
      .toList();

  List<DownloadItem> get activeDownloads => _downloads.values
      .where((item) => item.status == DownloadStatus.downloading)
      .toList();

  List<DownloadItem> get failedDownloads => _downloads.values
      .where((item) => item.status == DownloadStatus.failed)
      .toList();

  bool get hasAnyDownloads => _downloads.isNotEmpty;
  bool get hasActiveDownloads => activeDownloads.isNotEmpty;

  void registerCourse(CourseModel course) {
    _knownCourses[course.id] = course;
  }

  Future<void> _initializeDownloads() async {
    _downloads = storageService.getDownloadsRegistry();

    final keysToRemove = <String>[];
    for (final entry in _downloads.entries.toList()) {
      if (entry.value.status == DownloadStatus.completed) {
        final exists = await File(entry.value.localFilePath).exists();
        if (!exists) {
          keysToRemove.add(entry.key);
        }
      } else if (entry.value.status == DownloadStatus.downloading) {
        // Interrupted downloads marked as failed on fresh start so user can retry
        _downloads[entry.key] = entry.value.copyWith(
          status: DownloadStatus.failed,
          errorMessage: 'Download interrupted. Tap to resume.',
        );
        await storageService.saveDownloadItem(_downloads[entry.key]!);
      }
    }

    for (final key in keysToRemove) {
      _downloads.remove(key);
      await storageService.removeDownloadItem(key);
    }

    notifyListeners();
  }

  bool isDownloaded(String lessonId) {
    final item = _downloads[lessonId];
    if (item == null) return false;
    if (item.status != DownloadStatus.completed) return false;
    final file = File(item.localFilePath);
    return file.existsSync();
  }

  bool isDownloading(String lessonId) {
    final item = _downloads[lessonId];
    return item?.status == DownloadStatus.downloading;
  }

  bool isFailed(String lessonId) {
    final item = _downloads[lessonId];
    return item?.status == DownloadStatus.failed;
  }

  double getDownloadProgress(String lessonId) {
    return _downloads[lessonId]?.progress ?? 0.0;
  }

  DownloadItem? getDownloadItem(String lessonId) {
    return _downloads[lessonId];
  }

  String? getLocalFilePath(String lessonId) {
    if (isDownloaded(lessonId)) {
      return _downloads[lessonId]?.localFilePath;
    }
    return null;
  }

  // ---------------- SINGLE LESSON DOWNLOAD ---------------- //

  Future<void> startDownload({
    required LessonModel lesson,
    required CourseModel course,
  }) async {
    _knownCourses[course.id] = course;
    if (isDownloading(lesson.id)) return;

    var item = DownloadItem(
      lessonId: lesson.id,
      courseId: course.id,
      courseTitle: course.title,
      lessonTitle: lesson.title,
      duration: lesson.duration,
      videoUrl: lesson.videoUrl,
      localFilePath: '',
      status: DownloadStatus.downloading,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: 0,
      downloadedAt: DateTime.now(),
    );

    _downloads[lesson.id] = item;
    notifyListeners();

    try {
      final targetPath = await downloadService.getTargetFilePath(lesson.id);
      if (_downloads[lesson.id]?.status != DownloadStatus.downloading) return;

      item = item.copyWith(localFilePath: targetPath);
      _downloads[lesson.id] = item;
      await storageService.saveDownloadItem(item);
      await downloadService.downloadVideo(
        lessonId: lesson.id,
        videoUrl: lesson.videoUrl,
        destinationPath: targetPath,
        onProgress: (received, total) {
          final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          final currentTotal = total > 0
              ? total
              : (received > item.totalBytes ? received : item.totalBytes);

          item = item.copyWith(
            downloadedBytes: received,
            totalBytes: currentTotal,
            progress: progress,
            status: DownloadStatus.downloading,
          );
          _downloads[lesson.id] = item;
          notifyListeners();
        },
      );

      final finalSize = await downloadService.getFileSize(targetPath);
      final exists = await File(targetPath).exists();

      if (exists && finalSize > 0) {
        item = item.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          totalBytes: finalSize,
          downloadedBytes: finalSize,
          errorMessage: null,
        );
        _downloads[lesson.id] = item;
        await storageService.saveDownloadItem(item);
        notifyListeners();
        downloadCompletedNotifier.value = item;
      } else {
        throw Exception('Downloaded file is empty or unreadable.');
      }
    } catch (e) {
      if (_downloads[lesson.id]?.status == DownloadStatus.downloading) {
        item = item.copyWith(
          status: DownloadStatus.failed,
          errorMessage: 'Download failed: ${e.toString().split('\n').first}',
        );
        _downloads[lesson.id] = item;
        await storageService.saveDownloadItem(item);
        notifyListeners();
      }
    }
  }

  // ---------------- RETRY DOWNLOAD ---------------- //

  Future<void> retryDownload(String lessonId) async {
    final existing = _downloads[lessonId];
    if (existing == null) return;

    final course = _knownCourses[existing.courseId];
    final lesson = LessonModel(
      id: existing.lessonId,
      title: existing.lessonTitle,
      duration: existing.duration,
      videoUrl: existing.videoUrl,
      description: '',
      order: 1,
    );

    if (course != null) {
      await startDownload(lesson: lesson, course: course);
    } else {
      // Create minimal course placeholder for retry
      final fallbackCourse = CourseModel(
        id: existing.courseId.isNotEmpty ? existing.courseId : 'unknown_course',
        title: existing.courseTitle.isNotEmpty ? existing.courseTitle : 'Course',
        description: '',
        instructor: 'Instructor',
        instructorTitle: '',
        thumbnailUrl: '',
        accentColor: '#6366F1',
        category: 'Development',
        level: 'All Levels',
        rating: 5.0,
        totalDuration: existing.duration,
        chapters: [],
      );
      await startDownload(lesson: lesson, course: fallbackCourse);
    }
  }

  // ---------------- COURSE DOWNLOAD (ALL LESSONS) ---------------- //

  Future<void> startCourseDownload(CourseModel course) async {
    _knownCourses[course.id] = course;
    final all = course.allLessons;
    for (final lesson in all) {
      if (!isDownloaded(lesson.id) && !isDownloading(lesson.id)) {
        // Fire each download; Dio manages concurrent requests
        startDownload(lesson: lesson, course: course);
      }
    }
  }

  bool isCourseDownloaded(CourseModel course) {
    if (course.allLessons.isEmpty) return false;
    return course.allLessons.every((l) => isDownloaded(l.id));
  }

  bool isCourseDownloading(CourseModel course) {
    return course.allLessons.any((l) => isDownloading(l.id));
  }

  int getCourseDownloadedCount(CourseModel course) {
    return course.allLessons.where((l) => isDownloaded(l.id)).length;
  }

  double getCourseDownloadProgress(CourseModel course) {
    if (course.allLessons.isEmpty) return 0.0;
    double sum = 0.0;
    for (final l in course.allLessons) {
      if (isDownloaded(l.id)) {
        sum += 1.0;
      } else if (isDownloading(l.id)) {
        sum += getDownloadProgress(l.id);
      }
    }
    return sum / course.allLessons.length;
  }

  // ---------------- CANCEL / DELETE ---------------- //

  void cancelDownload(String lessonId) {
    downloadService.cancelDownload(lessonId);
    final item = _downloads[lessonId];
    if (item != null) {
      _downloads[lessonId] = item.copyWith(
        status: DownloadStatus.failed,
        errorMessage: 'Cancelled by user',
      );
      storageService.saveDownloadItem(_downloads[lessonId]!);
      notifyListeners();
    }
  }

  Future<void> deleteDownload(String lessonId) async {
    final item = _downloads[lessonId];
    if (item != null) {
      await downloadService.deleteFile(item.localFilePath);
      _downloads.remove(lessonId);
      await storageService.removeDownloadItem(lessonId);
      notifyListeners();
    }
  }

  Future<void> clearAllDownloads() async {
    for (final item in _downloads.values.toList()) {
      await downloadService.deleteFile(item.localFilePath);
    }
    final allKeys = _downloads.keys.toList();
    _downloads.clear();
    for (final key in allKeys) {
      await storageService.removeDownloadItem(key);
    }
    notifyListeners();
  }

  String get totalFormattedStorageUsed {
    int total = 0;
    for (final item in completedDownloads) {
      total += item.totalBytes;
    }
    if (total == 0) return '0 MB';
    final mb = total / (1024 * 1024);
    if (mb >= 1000) {
      final gb = mb / 1024;
      return '${gb.toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }
}
