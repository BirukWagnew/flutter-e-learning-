import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/lesson_model.dart';
import '../../core/widgets/custom_button.dart';
import '../../viewmodels/course_viewmodel.dart';
import '../../viewmodels/download_viewmodel.dart';
import '../main/main_navigation_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final LessonModel lesson;
  final CourseModel course;

  const VideoPlayerScreen({
    super.key,
    required this.lesson,
    required this.course,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late LessonModel _currentLesson;
  VideoPlayerController? _controller;
  bool _isPlayingOffline = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _playbackSpeed = 1.0;
  bool _isBuffering = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lesson;
    _initializePlayer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    _hideControlsTimer?.cancel();
    final downloadVm = context.read<DownloadViewModel>();
    final isOffline = downloadVm.isDownloaded(_currentLesson.id);
    final localPath = downloadVm.getLocalFilePath(_currentLesson.id);

    final oldController = _controller;
    _controller = null;
    await oldController?.dispose();

    if (!mounted) return;

    setState(() {
      _videoError = null;
      _isBuffering = true;
    });

    try {
      if (isOffline && localPath != null && await File(localPath).exists()) {
        _isPlayingOffline = true;
        _controller = VideoPlayerController.file(File(localPath));
      } else {
        _isPlayingOffline = false;
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(_currentLesson.videoUrl),
        );
      }

      await _controller!.initialize();
      _controller!.setPlaybackSpeed(_playbackSpeed);
      _controller!.play();

      _controller!.addListener(_playerListener);

      _startHideTimer();
    } catch (e) {
      setState(() {
        _videoError = 'Failed to load video: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
      }
    }
  }

  void _playerListener() {
    if (!mounted) return;
    final isBuff = _controller?.value.isBuffering ?? false;
    if (isBuff != _isBuffering) {
      setState(() {
        _isBuffering = isBuff;
      });
    }

    // Auto mark as completed when playback finishes
    final pos = _controller?.value.position ?? Duration.zero;
    final dur = _controller?.value.duration ?? Duration.zero;
    if (dur > Duration.zero && pos >= dur && !_controller!.value.isPlaying) {
      final courseVm = context.read<CourseViewModel>();
      if (!courseVm.isLessonCompleted(_currentLesson.id)) {
        courseVm.toggleLessonCompleted(_currentLesson.id);
      }
    }

    setState(() {});
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _hideControlsTimer?.cancel();
      setState(() {
        _showControls = true;
      });
    } else {
      _controller!.play();
      _startHideTimer();
      setState(() {});
    }
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    final total = _controller!.value.duration;

    if (target < Duration.zero) {
      _controller!.seekTo(Duration.zero);
    } else if (target > total) {
      _controller!.seekTo(total);
    } else {
      _controller!.seekTo(target);
    }
    _startHideTimer();
  }

  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _controller?.setPlaybackSpeed(speed);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  LessonModel? _getNextLesson() {
    final all = widget.course.allLessons;
    final currentIndex = all.indexWhere((l) => l.id == _currentLesson.id);
    if (currentIndex >= 0 && currentIndex < all.length - 1) {
      return all[currentIndex + 1];
    }
    return null;
  }

  LessonModel? _getPrevLesson() {
    final all = widget.course.allLessons;
    final currentIndex = all.indexWhere((l) => l.id == _currentLesson.id);
    if (currentIndex > 0) {
      return all[currentIndex - 1];
    }
    return null;
  }

  void _switchLesson(LessonModel nextLesson) {
    setState(() {
      _currentLesson = nextLesson;
    });
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final courseVm = context.watch<CourseViewModel>();
    final downloadVm = context.watch<DownloadViewModel>();

    final isLessonDone = courseVm.isLessonCompleted(_currentLesson.id);
    final isDownloaded = downloadVm.isDownloaded(_currentLesson.id);
    final isDownloading = downloadVm.isDownloading(_currentLesson.id);
    final isFailed = downloadVm.isFailed(_currentLesson.id);
    final downloadProgress = downloadVm.getDownloadProgress(_currentLesson.id);

    final nextLesson = _getNextLesson();
    final prevLesson = _getPrevLesson();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.course.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          // Playback speed dropdown
          PopupMenuButton<double>(
            initialValue: _playbackSpeed,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_playbackSpeed}x',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            onSelected: _changeSpeed,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0.75, child: Text('0.75x')),
              const PopupMenuItem(value: 1.0, child: Text('1.0x (Normal)')),
              const PopupMenuItem(value: 1.25, child: Text('1.25x')),
              const PopupMenuItem(value: 1.5, child: Text('1.5x')),
              const PopupMenuItem(value: 2.0, child: Text('2.0x')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Container
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: _videoError != null
                    ? _buildErrorView()
                    : (_controller != null && _controller!.value.isInitialized)
                        ? _buildVideoSurface()
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3,
                            ),
                          ),
              ),
            ),

            // Video Details and Actions Scroll Area
            Expanded(
              child: Container(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Offline/Online status badge & duration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _isPlayingOffline
                                  ? AppColors.accent.withOpacity(0.15)
                                  : AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isPlayingOffline
                                    ? AppColors.accent.withOpacity(0.4)
                                    : AppColors.primary.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isPlayingOffline
                                      ? Icons.offline_pin_rounded
                                      : Icons.wifi_tethering_rounded,
                                  size: 14,
                                  color: _isPlayingOffline ? AppColors.accent : AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isPlayingOffline
                                      ? 'Playing Offline File'
                                      : 'Streaming Online',
                                  style: TextStyle(
                                    color: _isPlayingOffline ? AppColors.accent : AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                _currentLesson.duration,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Lesson Title
                      Text(
                        _currentLesson.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      if (_currentLesson.description.isNotEmpty) ...[
                        Text(
                          _currentLesson.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Download & Mark Completed Action Cards
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Mark as completed button
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isLessonDone
                                        ? 'Lesson Completed'
                                        : 'Mark as Completed',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: isLessonDone,
                                  activeThumbColor: AppColors.accent,
                                  activeTrackColor: AppColors.accent.withOpacity(0.5),
                                  onChanged: (val) {
                                    courseVm.toggleLessonCompleted(_currentLesson.id);
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Offline Download Status row
                            Row(
                              children: [
                                Icon(
                                  isDownloaded
                                      ? Icons.check_circle_rounded
                                      : (isDownloading
                                          ? Icons.downloading_rounded
                                          : Icons.file_download_outlined),
                                  color: isDownloaded
                                      ? AppColors.accent
                                      : (isDownloading ? AppColors.primary : Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isDownloaded
                                            ? 'Stored on Device (Offline)'
                                            : (isDownloading
                                                ? 'Downloading ${(downloadProgress * 100).toInt()}%'
                                                : (isFailed
                                                    ? 'Download Interrupted'
                                                    : 'Available for Download')),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isFailed ? AppColors.error : null,
                                        ),
                                      ),
                                      Text(
                                        isDownloaded
                                            ? 'Play anytime without internet'
                                            : (isDownloading
                                                ? 'Saving MP4 locally...'
                                                : (isFailed
                                                    ? 'Download failed. Tap retry to resume'
                                                    : 'Tap download to store video locally')),
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
                                if (isDownloading) ...[
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: AppColors.error),
                                    tooltip: 'Cancel Download',
                                    onPressed: () => downloadVm.cancelDownload(_currentLesson.id),
                                  ),
                                ] else if (isDownloaded) ...[
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                    tooltip: 'Delete Local File',
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      await downloadVm.deleteDownload(_currentLesson.id);
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Offline file deleted.'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        // Reload player in streaming mode
                                        _initializePlayer();
                                      }
                                    },
                                  ),
                                ] else if (isFailed) ...[
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      downloadVm.retryDownload(_currentLesson.id);
                                    },
                                  ),
                                ] else ...[
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download_rounded, size: 16),
                                    label: const Text('Download'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      downloadVm.startDownload(
                                        lesson: _currentLesson,
                                        course: widget.course,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Downloading "${_currentLesson.title}"... Track in Downloads'),
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
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Navigation between lessons (Previous / Next)
                      Row(
                        children: [
                          if (prevLesson != null)
                            Expanded(
                              child: CustomButton(
                                text: 'Previous',
                                icon: Icons.arrow_back_rounded,
                                isOutlined: true,
                                onPressed: () => _switchLesson(prevLesson),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 12),
                          if (nextLesson != null)
                            Expanded(
                              child: CustomButton(
                                text: 'Next Lesson',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () => _switchLesson(nextLesson),
                              ),
                            )
                          else
                            const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSurface() {
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;

    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_controller!),

          // Buffering indicator
          if (_isBuffering)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),

          // Controls Overlay
          if (_showControls)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                color: Colors.black.withOpacity(0.55),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Spacer
                    const SizedBox(height: 10),

                    // Center playback controls: -10s, Play/Pause, +10s
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                          onPressed: () => _seekRelative(-10),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: IconButton(
                            iconSize: 32,
                            icon: Icon(
                              _controller!.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                          onPressed: () => _seekRelative(10),
                        ),
                      ],
                    ),

                    // Bottom progress bar and timestamps
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: AppColors.primary,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: pos.inMilliseconds.toDouble().clamp(
                                    0.0,
                                    dur.inMilliseconds.toDouble(),
                                  ),
                              min: 0.0,
                              max: dur.inMilliseconds > 0
                                  ? dur.inMilliseconds.toDouble()
                                  : 1.0,
                              onChanged: (val) {
                                _controller!.seekTo(Duration(milliseconds: val.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(pos),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDuration(dur),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: 10),
            Text(
              _videoError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _initializePlayer,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
