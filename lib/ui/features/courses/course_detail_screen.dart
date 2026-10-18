import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/models/lesson_model.dart';
import '../../core/widgets/custom_button.dart';
import '../../viewmodels/course_viewmodel.dart';
import '../../viewmodels/download_viewmodel.dart';
import '../main/main_navigation_screen.dart';
import '../video/video_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  // Keep chapters expanded by default for quick browsing
  final Set<String> _expandedChapterIds = {};

  @override
  void initState() {
    super.initState();
    // Default open all chapters
    for (var chap in widget.course.chapters) {
      _expandedChapterIds.add(chap.id);
    }
  }

  void _openLesson(LessonModel lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          lesson: lesson,
          course: widget.course,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final courseVm = context.watch<CourseViewModel>();
    final downloadVm = context.watch<DownloadViewModel>();

    final progress = courseVm.getCourseProgress(widget.course);
    final allLessons = widget.course.allLessons;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible Hero AppBar
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.course.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _parseColor(widget.course.accentColor),
                              AppColors.primaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.course.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.course.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Course Overview Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges: Level, Rating, Duration, Chapters
                  Row(
                    children: [
                      _buildPill(
                        icon: Icons.bar_chart_rounded,
                        text: widget.course.level,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildPill(
                        icon: Icons.star_rounded,
                        text: widget.course.rating.toStringAsFixed(1),
                        iconColor: AppColors.warning,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildPill(
                        icon: Icons.schedule_rounded,
                        text: widget.course.totalDuration,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Instructor info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _parseColor(widget.course.accentColor).withOpacity(0.2),
                        child: Text(
                          widget.course.instructor.substring(0, 1),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _parseColor(widget.course.accentColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.course.instructor,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.course.instructorTitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'About This Course',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.course.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Course Progress Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Course Completion',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: progress >= 1.0 ? AppColors.accent : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0 ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start Learning / Resume Button
                  if (allLessons.isNotEmpty)
                    CustomButton(
                      text: progress > 0 ? 'Continue Learning' : 'Start First Lesson',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => _openLesson(allLessons.first),
                    ),
                  const SizedBox(height: 28),

                  // Chapters & Lessons Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Syllabus (${widget.course.chapters.length} Modules)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.course.totalLessonsCount} Lessons',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      _buildCourseDownloadButton(downloadVm, isDark),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // Chapters & Lessons List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chapter = widget.course.chapters[index];
                  return _buildChapterCard(
                    chapter: chapter,
                    chapterIndex: index + 1,
                    isDark: isDark,
                    courseVm: courseVm,
                    downloadVm: downloadVm,
                  );
                },
                childCount: widget.course.chapters.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String text,
    Color? iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard({
    required ChapterModel chapter,
    required int chapterIndex,
    required bool isDark,
    required CourseViewModel courseVm,
    required DownloadViewModel downloadVm,
  }) {
    final isExpanded = _expandedChapterIds.contains(chapter.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Chapter Header Accordion Toggle
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedChapterIds.remove(chapter.id);
                } else {
                  _expandedChapterIds.add(chapter.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$chapterIndex',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (chapter.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            chapter.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Lessons list when expanded
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: chapter.lessons.map((lesson) {
                  final isCompleted = courseVm.isLessonCompleted(lesson.id);
                  final isDownloaded = downloadVm.isDownloaded(lesson.id);
                  final isDownloading = downloadVm.isDownloading(lesson.id);
                  final isFailed = downloadVm.isFailed(lesson.id);
                  final progress = downloadVm.getDownloadProgress(lesson.id);

                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg.withOpacity(0.5) : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.accent.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      onTap: () => _openLesson(lesson),
                      leading: IconButton(
                        icon: Icon(
                          isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isCompleted ? AppColors.accent : AppColors.darkTextSecondary,
                          size: 22,
                        ),
                        onPressed: () {
                          courseVm.toggleLessonCompleted(lesson.id);
                        },
                      ),
                      title: Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lesson.duration,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          if (isDownloaded) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.offline_pin_rounded, size: 12, color: AppColors.accent),
                                  SizedBox(width: 3),
                                  Text(
                                    'Offline',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Download button / progress indicator
                          if (isDownloading) ...[
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress > 0 ? progress : null,
                                    strokeWidth: 3,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 14),
                                    onPressed: () => downloadVm.cancelDownload(lesson.id),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isDownloaded) ...[
                            IconButton(
                              icon: const Icon(Icons.download_done_rounded, color: AppColors.accent, size: 22),
                              tooltip: 'Downloaded locally. Tap to manage',
                              onPressed: () => _showDownloadOptions(context, lesson, downloadVm),
                            ),
                          ] else if (isFailed) ...[
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: AppColors.error, size: 22),
                              tooltip: 'Download failed. Tap to retry',
                              onPressed: () {
                                downloadVm.retryDownload(lesson.id);
                                _showDownloadStartedSnackBar(context, lesson.title);
                              },
                            ),
                          ] else ...[
                            IconButton(
                              icon: const Icon(Icons.file_download_outlined, size: 22),
                              tooltip: 'Download for offline playback',
                              onPressed: () {
                                downloadVm.startDownload(
                                  lesson: lesson,
                                  course: widget.course,
                                );
                                _showDownloadStartedSnackBar(context, lesson.title);
                              },
                            ),
                          ],
                          const SizedBox(width: 4),
                          // Play Icon
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showDownloadOptions(
    BuildContext context,
    LessonModel lesson,
    DownloadViewModel downloadVm,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  lesson.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'This video is downloaded and available offline.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.play_circle_filled_rounded, color: AppColors.primary),
                  title: const Text('Play Offline Video'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openLesson(lesson);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: const Text('Delete Download', style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(ctx).pop();
                    await downloadVm.deleteDownload(lesson.id);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Offline download deleted.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDownloadStartedSnackBar(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "$title"... Track progress in Downloads'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: AppColors.accent,
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            MainNavigationScreen.switchToDownloads();
          },
        ),
      ),
    );
  }

  Widget _buildCourseDownloadButton(DownloadViewModel downloadVm, bool isDark) {
    final isDownloaded = downloadVm.isCourseDownloaded(widget.course);
    final isDownloading = downloadVm.isCourseDownloading(widget.course);
    final downloadedCount = downloadVm.getCourseDownloadedCount(widget.course);
    final totalCount = widget.course.allLessons.length;

    if (isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withOpacity(0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.offline_pin_rounded, size: 16, color: AppColors.accent),
            SizedBox(width: 5),
            Text(
              'Course Saved',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      );
    }

    if (isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Downloading ($downloadedCount/$totalCount)...',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      icon: const Icon(Icons.download_for_offline_rounded, size: 16),
      label: const Text('Download Course', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        downloadVm.startCourseDownload(widget.course);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading entire course ($totalCount lessons)...'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'VIEW DOWNLOADS',
              textColor: AppColors.accent,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                MainNavigationScreen.switchToDownloads();
              },
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
