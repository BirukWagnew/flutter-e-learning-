import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/course_model.dart';
import '../services/storage_service.dart';

class CourseRepository {
  final StorageService _storageService;
  List<CourseModel> _cachedCourses = [];

  CourseRepository(this._storageService);

  Future<List<CourseModel>> loadCourses({bool forceReload = false}) async {
    if (_cachedCourses.isNotEmpty && !forceReload) {
      return _cachedCourses;
    }

    try {
      final jsonString = await rootBundle
          .loadString('assets/data/courses.json')
          .timeout(const Duration(seconds: 2), onTimeout: () => '{"courses": []}');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final rawList = data['courses'] as List<dynamic>? ?? [];

      _cachedCourses = rawList
          .map((item) => CourseModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return _cachedCourses;
    } catch (e) {
      return _cachedCourses;
    }
  }

  CourseModel? getCourseById(String courseId) {
    try {
      return _cachedCourses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }

  List<String> getCategories() {
    final categories = <String>{'All'};
    for (final course in _cachedCourses) {
      categories.add(course.category);
    }
    return categories.toList();
  }

  List<CourseModel> searchCourses({String query = '', String category = 'All'}) {
    final cleanQuery = query.trim().toLowerCase();

    return _cachedCourses.where((course) {
      final matchesCategory = category == 'All' || course.category == category;
      final matchesQuery = cleanQuery.isEmpty ||
          course.title.toLowerCase().contains(cleanQuery) ||
          course.description.toLowerCase().contains(cleanQuery) ||
          course.instructor.toLowerCase().contains(cleanQuery) ||
          course.category.toLowerCase().contains(cleanQuery);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  // ---------------- LESSON PROGRESS ---------------- //

  Set<String> getCompletedLessons() {
    return _storageService.getCompletedLessons();
  }

  Future<void> toggleLessonCompleted(String lessonId) async {
    final completed = _storageService.getCompletedLessons();
    final isDone = completed.contains(lessonId);
    await _storageService.markLessonCompleted(lessonId, !isDone);
  }

  double calculateCourseProgress(CourseModel course) {
    final completed = getCompletedLessons();
    final allLessons = course.allLessons;
    if (allLessons.isEmpty) return 0.0;

    int doneCount = 0;
    for (final l in allLessons) {
      if (completed.contains(l.id)) {
        doneCount++;
      }
    }
    return doneCount / allLessons.length;
  }
}
