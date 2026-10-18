import 'package:flutter/material.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';

class CourseViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;

  List<CourseModel> _allCourses = [];
  List<CourseModel> _filteredCourses = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _completedLessonIds = {};

  CourseViewModel(this._courseRepository) {
    loadCourses(notifyInitial: false);
  }

  List<CourseModel> get courses => _filteredCourses;
  List<CourseModel> get allCourses => _allCourses;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<String> get completedLessonIds => _completedLessonIds;

  Future<void> loadCourses({bool notifyInitial = true}) async {
    _isLoading = true;
    _errorMessage = null;
    if (notifyInitial) {
      notifyListeners();
    }

    try {
      _allCourses = await _courseRepository.loadCourses();
      _categories = _courseRepository.getCategories();
      _completedLessonIds = _courseRepository.getCompletedLessons();
      _applyFilter();
    } catch (e) {
      _errorMessage = 'Unable to load course data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _applyFilter();
  }

  void _applyFilter() {
    _filteredCourses = _courseRepository.searchCourses(
      query: _searchQuery,
      category: _selectedCategory,
    );
    notifyListeners();
  }

  bool isLessonCompleted(String lessonId) {
    return _completedLessonIds.contains(lessonId);
  }

  Future<void> toggleLessonCompleted(String lessonId) async {
    await _courseRepository.toggleLessonCompleted(lessonId);
    _completedLessonIds = _courseRepository.getCompletedLessons();
    notifyListeners();
  }

  double getCourseProgress(CourseModel course) {
    final all = course.allLessons;
    if (all.isEmpty) return 0.0;
    int done = 0;
    for (final l in all) {
      if (_completedLessonIds.contains(l.id)) {
        done++;
      }
    }
    return done / all.length;
  }

  int get completedLessonsCount => _completedLessonIds.length;
}
