import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/course_card.dart';
import '../../core/widgets/state_views.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/course_viewmodel.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authVm = context.watch<AuthViewModel>();
    final courseVm = context.watch<CourseViewModel>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => courseVm.loadCourses(),
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // Top Bar Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back 👋',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authVm.currentUser?.name ?? 'Learner',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => courseVm.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search courses, topics, instructors...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                courseVm.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // Category Filter Chips
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: courseVm.categories.length,
                    itemBuilder: (context, index) {
                      final cat = courseVm.categories[index];
                      final isSelected = cat == courseVm.selectedCategory;
                      return CategoryChip(
                        label: cat,
                        isSelected: isSelected,
                        onTap: () => courseVm.setSelectedCategory(cat),
                      );
                    },
                  ),
                ),
              ),

              // Course List Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Courses',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${courseVm.courses.length} Available',
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
              ),

              // Courses List / State Views
              if (courseVm.isLoading)
                const SliverFillRemaining(
                  child: LoadingStateView(message: 'Loading courses from local storage...'),
                )
              else if (courseVm.errorMessage != null)
                SliverFillRemaining(
                  child: ErrorStateView(
                    title: 'Failed to load courses',
                    errorMessage: courseVm.errorMessage!,
                    onRetry: () => courseVm.loadCourses(),
                  ),
                )
              else if (courseVm.courses.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateView(
                    title: 'No courses found',
                    description: _searchController.text.isNotEmpty
                        ? 'Try searching with different keywords or clearing filters.'
                        : 'No courses available in this category yet.',
                    buttonText: 'Reset Filters',
                    onButtonPressed: () {
                      _searchController.clear();
                      courseVm.setSearchQuery('');
                      courseVm.setSelectedCategory('All');
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final course = courseVm.courses[index];
                        final progress = courseVm.getCourseProgress(course);
                        return CourseCard(
                          course: course,
                          progress: progress,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CourseDetailScreen(course: course),
                              ),
                            );
                          },
                        );
                      },
                      childCount: courseVm.courses.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
