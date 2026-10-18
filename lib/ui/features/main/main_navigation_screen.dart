import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../viewmodels/download_viewmodel.dart';
import '../courses/course_list_screen.dart';
import '../downloads/downloads_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  /// Static notifier allowing any child view to switch navigation tabs
  static final ValueNotifier<int> tabNotifier = ValueNotifier(0);

  static void switchToDownloads() {
    tabNotifier.value = 1;
  }

  static void switchToCourses() {
    tabNotifier.value = 0;
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = MainNavigationScreen.tabNotifier.value;
    MainNavigationScreen.tabNotifier.addListener(_onTabNotification);

    // Listen to download completions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final downloadVm = context.read<DownloadViewModel>();
      downloadVm.downloadCompletedNotifier.addListener(_onDownloadCompleted);
    });
  }

  @override
  void dispose() {
    MainNavigationScreen.tabNotifier.removeListener(_onTabNotification);
    try {
      context.read<DownloadViewModel>().downloadCompletedNotifier.removeListener(_onDownloadCompleted);
    } catch (_) {}
    super.dispose();
  }

  void _onTabNotification() {
    if (mounted && _currentIndex != MainNavigationScreen.tabNotifier.value) {
      setState(() {
        _currentIndex = MainNavigationScreen.tabNotifier.value;
      });
    }
  }

  void _onDownloadCompleted() {
    if (!mounted) return;
    final item = context.read<DownloadViewModel>().downloadCompletedNotifier.value;
    if (item != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ "${item.lessonTitle}" is ready for offline playback!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: AppColors.accent,
            onPressed: () {
              MainNavigationScreen.switchToDownloads();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final downloadVm = context.watch<DownloadViewModel>();
    final completedCount = downloadVm.completedDownloads.length;
    final activeCount = downloadVm.activeDownloads.length;

    final screens = [
      const CourseListScreen(),
      DownloadsScreen(
        onBrowseCourses: () {
          setState(() {
            _currentIndex = 0;
            MainNavigationScreen.tabNotifier.value = 0;
          });
        },
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.primary.withOpacity(0.16),
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
              MainNavigationScreen.tabNotifier.value = index;
            });
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school_rounded, color: AppColors.primary),
              label: 'Courses',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: completedCount > 0 || activeCount > 0,
                label: Text(activeCount > 0 ? '$activeCount↓' : '$completedCount'),
                backgroundColor: activeCount > 0 ? AppColors.secondary : AppColors.primary,
                child: const Icon(Icons.download_for_offline_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: completedCount > 0 || activeCount > 0,
                label: Text(activeCount > 0 ? '$activeCount↓' : '$completedCount'),
                backgroundColor: activeCount > 0 ? AppColors.secondary : AppColors.primary,
                child: const Icon(Icons.download_for_offline_rounded, color: AppColors.primary),
              ),
              label: 'Downloads',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
