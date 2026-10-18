enum DownloadStatus {
  idle,
  downloading,
  completed,
  failed,
}

class DownloadItem {
  final String lessonId;
  final String courseId;
  final String courseTitle;
  final String lessonTitle;
  final String duration;
  final String videoUrl;
  final String localFilePath;
  final int totalBytes;
  final int downloadedBytes;
  final double progress; // 0.0 to 1.0
  final DownloadStatus status;
  final DateTime downloadedAt;
  final String? errorMessage;

  const DownloadItem({
    required this.lessonId,
    required this.courseId,
    required this.courseTitle,
    required this.lessonTitle,
    required this.duration,
    required this.videoUrl,
    required this.localFilePath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.progress = 0.0,
    this.status = DownloadStatus.idle,
    required this.downloadedAt,
    this.errorMessage,
  });

  String get formattedSize {
    if (totalBytes <= 0) return 'Unknown size';
    final mb = totalBytes / (1024 * 1024);
    if (mb < 1.0) {
      final kb = totalBytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedProgress {
    return '${(progress * 100).toInt()}%';
  }

  DownloadItem copyWith({
    String? lessonId,
    String? courseId,
    String? courseTitle,
    String? lessonTitle,
    String? duration,
    String? videoUrl,
    String? localFilePath,
    int? totalBytes,
    int? downloadedBytes,
    double? progress,
    DownloadStatus? status,
    DateTime? downloadedAt,
    String? errorMessage,
  }) {
    return DownloadItem(
      lessonId: lessonId ?? this.lessonId,
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      duration: duration ?? this.duration,
      videoUrl: videoUrl ?? this.videoUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'lessonTitle': lessonTitle,
      'duration': duration,
      'videoUrl': videoUrl,
      'localFilePath': localFilePath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'progress': progress,
      'status': status.name,
      'downloadedAt': downloadedAt.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      lessonId: json['lessonId'] as String,
      courseId: json['courseId'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      lessonTitle: json['lessonTitle'] as String,
      duration: json['duration'] as String? ?? '',
      videoUrl: json['videoUrl'] as String,
      localFilePath: json['localFilePath'] as String,
      totalBytes: json['totalBytes'] as int? ?? 0,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DownloadStatus.idle,
      ),
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : DateTime.now(),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
