import 'lesson_model.dart';

class ChapterModel {
  final String id;
  final String title;
  final String description;
  final int order;
  final List<LessonModel> lessons;

  const ChapterModel({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.lessons,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    };
  }

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      order: json['order'] as int? ?? 1,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((l) => LessonModel.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
