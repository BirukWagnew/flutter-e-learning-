import 'chapter_model.dart';
import 'lesson_model.dart';

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final String instructorTitle;
  final String thumbnailUrl;
  final String accentColor;
  final String category;
  final String level;
  final double rating;
  final String totalDuration;
  final List<ChapterModel> chapters;

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.instructorTitle,
    required this.thumbnailUrl,
    required this.accentColor,
    required this.category,
    required this.level,
    required this.rating,
    required this.totalDuration,
    required this.chapters,
  });

  int get totalChaptersCount => chapters.length;

  int get totalLessonsCount {
    int count = 0;
    for (var chap in chapters) {
      count += chap.lessons.length;
    }
    return count;
  }

  List<LessonModel> get allLessons {
    final list = <LessonModel>[];
    for (var chap in chapters) {
      list.addAll(chap.lessons);
    }
    return list;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor,
      'instructorTitle': instructorTitle,
      'thumbnailUrl': thumbnailUrl,
      'accentColor': accentColor,
      'category': category,
      'level': level,
      'rating': rating,
      'totalDuration': totalDuration,
      'chapters': chapters.map((c) => c.toJson()).toList(),
    };
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      instructor: json['instructor'] as String,
      instructorTitle: json['instructorTitle'] as String? ?? 'Instructor',
      thumbnailUrl: json['thumbnailUrl'] as String,
      accentColor: json['accentColor'] as String? ?? '#6366F1',
      category: json['category'] as String,
      level: json['level'] as String? ?? 'All Levels',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      totalDuration: json['totalDuration'] as String? ?? '30m',
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((c) => ChapterModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
