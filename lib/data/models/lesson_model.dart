class LessonModel {
  final String id;
  final String title;
  final String duration;
  final String videoUrl;
  final String description;
  final int order;

  const LessonModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.videoUrl,
    required this.description,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'videoUrl': videoUrl,
      'description': description,
      'order': order,
    };
  }

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      title: json['title'] as String,
      duration: json['duration'] as String,
      videoUrl: json['videoUrl'] as String,
      description: json['description'] as String? ?? '',
      order: json['order'] as int? ?? 1,
    );
  }
}
