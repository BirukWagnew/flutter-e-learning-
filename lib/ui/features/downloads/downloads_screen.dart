import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/download_item.dart';
import '../../../data/models/lesson_model.dart';
import '../../core/widgets/state_views.dart';
import '../../viewmodels/course_viewmodel.dart';
import '../../viewmodels/download_viewmodel.dart';
import '../video/video_player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  final VoidCallback onBrowseCourses;

  const DownloadsScreen({
    super.key,
    required this.onBrowseCourses,
  });

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  // 0: All, 1: Downloaded, 2: Downloading
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final downloadVm = context.watch<DownloadViewModel>();
    final courseVm = context.watch<CourseViewModel>();

    final completedList = downloadVm.completedDownloads;
    final activeList = downloadVm.activeDownloads;
    final failedList = downloadVm.failedDownloads;
    final hasAny = downloadVm.hasAnyDownloads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Downloads'),
        actions: [
          if (completedList.isNotEmpty || failedList.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'clear_all') {
                  _confirmClearAll(context, downloadVm);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 20),
                      SizedBox(width: 10),
                      Text('Clear All Downloads', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: !hasAny
          ? EmptyStateView(
              icon: Icons.cloud_download_outlined,
              title: 'No Offline Videos Yet',
              description:
                  'Download lessons from any course to watch offline seamlessly without using mobile data.',
              buttonText: 'Browse Courses',
              onButtonPressed: widget.onBrowseCourses,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Storage & Status Overview Card
                _buildStorageOverview(downloadVm, isDark, completedList.length, activeList.length),
                const SizedBox(height: 20),

                // 2. Segmented Filter Tabs (All, Downloaded, Downloading)
                _buildFilterTabs(
                  allCount: downloadVm.allDownloads.length,
                  completedCount: completedList.length,
                  activeCount: activeList.length,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // 3. Tab Contents based on selection
                if (_selectedTabIndex == 0) ...[
                  // ALL TAB
                  if (activeList.isNotEmpty) ...[
                    _buildSectionHeader('DOWNLOADING IN PROGRESS (${activeList.length})', isDark),
                    const SizedBox(height: 10),
                    ...activeList.map((item) => _buildActiveDownloadCard(item, downloadVm, isDark)),
                    const SizedBox(height: 24),
                  ],

                  if (failedList.isNotEmpty) ...[
                    _buildSectionHeader('ACTION NEEDED (${failedList.length})', isDark, isWarning: true),
                    const SizedBox(height: 10),
                    ...failedList.map((item) => _buildFailedDownloadCard(item, downloadVm, isDark)),
                    const SizedBox(height: 24),
                  ],

                  if (completedList.isNotEmpty) ...[
                    _buildSectionHeader('READY FOR OFFLINE PLAYBACK (${completedList.length})', isDark),
                    const SizedBox(height: 10),
                    ...completedList.map((item) => _buildCompletedCard(item, downloadVm, courseVm, isDark)),
                  ] else if (activeList.isEmpty && failedList.isEmpty) ...[
                    _buildEmptyTabMessage('No offline lessons found in this section.', isDark),
                  ],
                ] else if (_selectedTabIndex == 1) ...[
                  // DOWNLOADED TAB
                  if (completedList.isEmpty)
                    _buildEmptyTabMessage('No completed downloads yet. Start downloading lessons to play offline.', isDark)
                  else ...[
                    _buildSectionHeader('SAVED OFFLINE (${completedList.length})', isDark),
                    const SizedBox(height: 10),
                    ...completedList.map((item) => _buildCompletedCard(item, downloadVm, courseVm, isDark)),
                  ],
                ] else if (_selectedTabIndex == 2) ...[
                  // DOWNLOADING TAB
                  if (activeList.isEmpty && failedList.isEmpty)
                    _buildEmptyTabMessage('No active downloads running right now.', isDark)
                  else ...[
                    if (activeList.isNotEmpty) ...[
                      _buildSectionHeader('CURRENTLY DOWNLOADING (${activeList.length})', isDark),
                      const SizedBox(height: 10),
                      ...activeList.map((item) => _buildActiveDownloadCard(item, downloadVm, isDark)),
                      const SizedBox(height: 20),
                    ],
                    if (failedList.isNotEmpty) ...[
                      _buildSectionHeader('FAILED / INTERRUPTED (${failedList.length})', isDark, isWarning: true),
                      const SizedBox(height: 10),
                      ...failedList.map((item) => _buildFailedDownloadCard(item, downloadVm, isDark)),
                    ],
                  ],
                ],
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  // ---------------- UI COMPONENTS ---------------- //

  Widget _buildStorageOverview(
    DownloadViewModel downloadVm,
    bool isDark,
    int completedCount,
    int activeCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.18),
            AppColors.secondary.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.folder_special_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offline Storage Used',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      downloadVm.totalFormattedStorageUsed,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completedCount ${completedCount == 1 ? 'lesson' : 'lessons'} available offline',
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
          if (activeCount > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Downloading $activeCount ${activeCount == 1 ? 'video' : 'videos'} in background...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterTabs({
    required int allCount,
    required int completedCount,
    required int activeCount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          _buildFilterTabItem(0, 'All ($allCount)', isDark),
          _buildFilterTabItem(1, 'Downloaded ($completedCount)', isDark),
          _buildFilterTabItem(2, 'Active ($activeCount)', isDark, hasBadge: activeCount > 0),
        ],
      ),
    );
  }

  Widget _buildFilterTabItem(int index, String label, bool isDark, {bool hasBadge = false}) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, {bool isWarning = false}) {
    return Row(
      children: [
        if (isWarning)
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
          ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isWarning
                ? AppColors.warning
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ],
    );
  }

  // ---------------- ACTIVE DOWNLOAD CARD ---------------- //

  Widget _buildActiveDownloadCard(
    DownloadItem item,
    DownloadViewModel downloadVm,
    bool isDark,
  ) {
    final pct = (item.progress * 100).toInt();
    final downloadedMb = (item.downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = item.totalBytes > 0
        ? (item.totalBytes / (1024 * 1024)).toStringAsFixed(1)
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                      item.lessonTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.courseTitle,
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
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.error),
                tooltip: 'Cancel Download',
                onPressed: () => downloadVm.cancelDownload(item.lessonId),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progress > 0 ? item.progress : null,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloading $pct%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '$downloadedMb MB / $totalMb MB',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- FAILED DOWNLOAD CARD ---------------- //

  Widget _buildFailedDownloadCard(
    DownloadItem item,
    DownloadViewModel downloadVm,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.error.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.lessonTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.errorMessage ?? 'Download interrupted. Tap retry to resume.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => downloadVm.deleteDownload(item.lessonId),
                child: Text(
                  'Dismiss',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => downloadVm.retryDownload(item.lessonId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- COMPLETED DOWNLOAD CARD ---------------- //

  Widget _buildCompletedCard(
    DownloadItem item,
    DownloadViewModel downloadVm,
    CourseViewModel courseVm,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          final course = courseVm.allCourses.firstWhere(
            (c) => c.id == item.courseId,
            orElse: () => courseVm.allCourses.isNotEmpty
                ? courseVm.allCourses.first
                : CourseModel(
                    id: item.courseId,
                    title: item.courseTitle,
                    description: '',
                    instructor: 'Instructor',
                    instructorTitle: '',
                    thumbnailUrl: '',
                    accentColor: '#6366F1',
                    category: 'Development',
                    level: 'All Levels',
                    rating: 5.0,
                    totalDuration: item.duration,
                    chapters: [],
                  ),
          );

          final lesson = LessonModel(
            id: item.lessonId,
            title: item.lessonTitle,
            duration: item.duration,
            videoUrl: item.videoUrl,
            description: 'Downloaded offline video',
            order: 1,
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                lesson: lesson,
                course: course,
              ),
            ),
          );
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: AppColors.accent,
            size: 26,
          ),
        ),
        title: Text(
          item.lessonTitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              item.courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Offline Ready',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.formattedSize,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 8),
                Text(
                  item.duration,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          tooltip: 'Delete download',
          onPressed: () {
            _confirmDelete(context, item.lessonId, item.lessonTitle, downloadVm);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyTabMessage(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 44,
              color: isDark ? AppColors.darkSurface : AppColors.lightBorder,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String lessonId,
    String title,
    DownloadViewModel downloadVm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Are you sure you want to remove "$title" from your offline storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await downloadVm.deleteDownload(lessonId);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, DownloadViewModel downloadVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Offline Data'),
        content: const Text(
          'Are you sure you want to delete all offline videos and clear storage?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await downloadVm.clearAllDownloads();
            },
            child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
